-- ============================================================================
-- RBAC SYSTEM REDESIGN - Complete Migration Script
-- Run this in Supabase SQL Editor
-- NOTE: Uses 'users' table (not 'profiles') to match your existing schema
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- PHASE 1: SCHEMA CHANGES ON USERS TABLE
-- ============================================================================

-- Add audit columns to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS last_modified_by uuid REFERENCES users(id),
ADD COLUMN IF NOT EXISTS last_modified_at timestamptz DEFAULT now();

-- STEP 1: DROP existing constraints FIRST (before any updates)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users DROP CONSTRAINT IF EXISTS profiles_role_check;

-- STEP 2: Migrate existing role values from camelCase to snake_case
UPDATE users SET role = 'vice_president' WHERE role = 'vicePresident';
UPDATE users SET role = 'super_admin' WHERE role = 'superAdmin';

-- STEP 3: Add new constraint with snake_case values
ALTER TABLE users ADD CONSTRAINT users_role_check
CHECK (role IN ('student', 'vice_president', 'president', 'admin', 'super_admin'));

-- ============================================================================
-- PHASE 2: NEW TABLES
-- ============================================================================

-- Role Requests Table (for upgrade workflow)
CREATE TABLE IF NOT EXISTS role_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  requested_role text NOT NULL CHECK (requested_role IN ('vice_president', 'president')),
  reason text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by uuid REFERENCES users(id),
  reviewed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Role Changes Audit Table
CREATE TABLE IF NOT EXISTS role_changes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_user uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  old_role text NOT NULL,
  new_role text NOT NULL,
  changed_by uuid NOT NULL REFERENCES users(id),
  changed_at timestamptz DEFAULT now()
);

-- Enable RLS on new tables
ALTER TABLE role_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_changes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PHASE 3: PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_role_requests_user_id ON role_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_role_requests_status ON role_requests(status);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_role_changes_target ON role_changes(target_user);
CREATE INDEX IF NOT EXISTS idx_role_changes_changed_at ON role_changes(changed_at DESC);

-- ============================================================================
-- PHASE 4: SECURE RPC FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION change_user_role(target_user_id uuid, new_role text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller_role text;
  target_role text;
BEGIN
  -- Validate new_role is valid
  IF new_role NOT IN ('student', 'vice_president', 'president', 'admin', 'super_admin') THEN
    RAISE EXCEPTION 'Invalid role: %', new_role;
  END IF;

  -- Get caller's role
  SELECT role INTO caller_role FROM users WHERE id = auth.uid();

  IF caller_role IS NULL THEN
    RAISE EXCEPTION 'Caller not found or not authenticated';
  END IF;

  -- Get target's current role
  SELECT role INTO target_role FROM users WHERE id = target_user_id;

  IF target_role IS NULL THEN
    RAISE EXCEPTION 'Target user not found';
  END IF;

  -- RULE 1: Nobody can change super_admin
  IF target_role = 'super_admin' THEN
    RAISE EXCEPTION 'Cannot modify super_admin';
  END IF;

  -- RULE 2: Nobody can promote to super_admin
  IF new_role = 'super_admin' THEN
    RAISE EXCEPTION 'Cannot promote to super_admin';
  END IF;

  -- RULE 3: Only admin/super_admin can change roles
  IF caller_role NOT IN ('admin', 'super_admin') THEN
    RAISE EXCEPTION 'Insufficient permissions to change roles';
  END IF;

  -- RULE 4: Admin cannot modify other admins
  IF caller_role = 'admin' AND target_role = 'admin' THEN
    RAISE EXCEPTION 'Admins cannot modify other admins';
  END IF;

  -- RULE 5: Only super_admin can create/demote admins
  IF (new_role = 'admin' OR target_role = 'admin') AND caller_role != 'super_admin' THEN
    RAISE EXCEPTION 'Only super_admin can manage admin roles';
  END IF;

  -- RULE 6: Cannot change own role
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot change your own role';
  END IF;

  -- RULE 7: No change if same role
  IF target_role = new_role THEN
    RAISE EXCEPTION 'User already has this role';
  END IF;

  -- All checks passed - update with race condition protection
  UPDATE users
  SET role = new_role,
      last_modified_by = auth.uid(),
      last_modified_at = now()
  WHERE id = target_user_id
    AND role = target_role;  -- Ensure role hasn't changed since we read it

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Role update failed (possible concurrent modification)';
  END IF;

  -- Log the change for audit
  INSERT INTO role_changes (target_user, old_role, new_role, changed_by)
  VALUES (target_user_id, target_role, new_role, auth.uid());
END;
$$;

-- Make function owner postgres to bypass RLS when executing
ALTER FUNCTION public.change_user_role(uuid, text) OWNER TO postgres;

-- ============================================================================
-- PHASE 5: RLS POLICIES - ROLE_REQUESTS TABLE
-- ============================================================================

-- Insert: users can create requests for themselves
DROP POLICY IF EXISTS "role_requests_insert_own" ON role_requests;
CREATE POLICY "role_requests_insert_own" ON role_requests
FOR INSERT WITH CHECK (user_id = auth.uid());

-- Select: requester can see their own requests
DROP POLICY IF EXISTS "role_requests_select_own" ON role_requests;
CREATE POLICY "role_requests_select_own" ON role_requests
FOR SELECT USING (user_id = auth.uid());

-- Select: admins can see all requests
DROP POLICY IF EXISTS "role_requests_select_admins" ON role_requests;
CREATE POLICY "role_requests_select_admins" ON role_requests
FOR SELECT USING (
  EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('admin', 'super_admin'))
);

-- Update: only admins can approve/reject requests
DROP POLICY IF EXISTS "role_requests_update_admins" ON role_requests;
CREATE POLICY "role_requests_update_admins" ON role_requests
FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('admin', 'super_admin'))
);

-- Delete: admins can delete requests
DROP POLICY IF EXISTS "role_requests_delete_admins" ON role_requests;
CREATE POLICY "role_requests_delete_admins" ON role_requests
FOR DELETE USING (
  EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('admin', 'super_admin'))
);

-- ============================================================================
-- PHASE 6: RLS POLICIES - ROLE_CHANGES TABLE (Audit)
-- ============================================================================

-- Select: only admins/super_admin can view audit log
DROP POLICY IF EXISTS "role_changes_select_admins" ON role_changes;
CREATE POLICY "role_changes_select_admins" ON role_changes
FOR SELECT USING (
  EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('admin', 'super_admin'))
);

-- No insert/update/delete policies - only RPC can insert

-- ============================================================================
-- PHASE 7: HELPER FUNCTION FOR ROLE HIERARCHY
-- ============================================================================

CREATE OR REPLACE FUNCTION get_role_rank(role_name text)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN CASE role_name
    WHEN 'student' THEN 1
    WHEN 'vice_president' THEN 2
    WHEN 'president' THEN 3
    WHEN 'admin' THEN 4
    WHEN 'super_admin' THEN 5
    ELSE 0
  END;
END;
$$;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check RLS is enabled
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'role_requests', 'role_changes')
ORDER BY tablename;

-- Check function exists
SELECT proname, prosecdef
FROM pg_proc
WHERE proname = 'change_user_role';

-- Check indexes
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('users', 'role_requests', 'role_changes');
