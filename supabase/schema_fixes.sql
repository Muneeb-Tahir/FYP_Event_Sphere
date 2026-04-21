-- Event Sphere — Schema Fixes Migration
-- Adds missing columns and fixes RLS policy mismatches
-- Run this in Supabase SQL Editor AFTER existing migrations

-- =====================================================
-- 1. USERS TABLE — Missing Columns
-- =====================================================

-- Gender field (used by auth_service.dart during profile creation)
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender TEXT;

-- FCM token for push notifications (used by notification_service.dart)
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- =====================================================
-- 2. REGISTRATIONS TABLE — Missing Columns
-- =====================================================

-- Show in attendee list toggle (used by registration_service.dart & registration model)
ALTER TABLE registrations ADD COLUMN IF NOT EXISTS show_in_list BOOLEAN DEFAULT TRUE;

-- =====================================================
-- 3. EVENTS TABLE — Missing Columns
-- =====================================================

-- Event end time (currently events only have a start date/time)
ALTER TABLE events ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ;

-- =====================================================
-- 4. FIX RLS POLICIES — camelCase → snake_case Mismatch
-- The rbac_migration.sql changed roles to snake_case but
-- row_level_security.sql still uses camelCase 'vicePresident'
-- =====================================================

-- Fix: Events SELECT policy for admins (was using 'vicePresident' camelCase)
DROP POLICY IF EXISTS "Admins can view all events" ON events;
CREATE POLICY "Admins can view all events" ON events
FOR SELECT USING (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'president', 'vice_president', 'super_admin'))
);

-- Fix: Events INSERT policy (was using 'vicePresident' camelCase)
DROP POLICY IF EXISTS "Admins and presidents can create events" ON events;
CREATE POLICY "Admins and presidents can create events" ON events
FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'president', 'vice_president', 'super_admin'))
);

-- Fix: Events UPDATE policy
DROP POLICY IF EXISTS "Creators and admins can update events" ON events;
CREATE POLICY "Creators and admins can update events" ON events
FOR UPDATE USING (
  created_by = auth.uid()
  OR EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'president', 'vice_president', 'super_admin'))
);

-- Fix: Events DELETE policy
DROP POLICY IF EXISTS "Admins can delete events" ON events;
CREATE POLICY "Admins can delete events" ON events
FOR DELETE USING (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'super_admin'))
);

-- Also fix: remove ::text casting in users policies for performance
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
FOR UPDATE USING (id = auth.uid());

DROP POLICY IF EXISTS "Admins can update any user" ON users;
CREATE POLICY "Admins can update any user" ON users
FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'super_admin'))
);

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users
FOR INSERT WITH CHECK (id = auth.uid());

-- =====================================================
-- 5. Performance Indexes for new columns
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON users(fcm_token) WHERE fcm_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_events_end_date ON events(end_date);

-- =====================================================
-- 6. RPC: Delete User Account (SECURITY DEFINER)
-- Called by auth_service.dart deleteAccount()
-- =====================================================
CREATE OR REPLACE FUNCTION delete_user_account(user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete profile row
  DELETE FROM users WHERE id = user_id;
  -- Delete auth user (requires service_role via SECURITY DEFINER)
  -- Note: In Supabase, you may need to use the management API instead.
  -- This is a placeholder — configure via Supabase dashboard if needed.
END;
$$;

-- =====================================================
-- 7. RPC: Atomic Point Increment (avoids race condition)
-- Called by gamification_service.dart _addPoints()
-- =====================================================
CREATE OR REPLACE FUNCTION increment_user_points(
  p_user_id UUID,
  p_points INTEGER,
  p_increment_events BOOLEAN DEFAULT FALSE
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE user_points
  SET
    total_points = total_points + p_points,
    events_attended = CASE WHEN p_increment_events THEN events_attended + 1 ELSE events_attended END,
    updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$;

-- =====================================================
-- Done! Run: SELECT 'Schema fixes applied successfully' AS status;
-- =====================================================
