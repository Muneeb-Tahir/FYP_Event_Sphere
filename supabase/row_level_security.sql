-- Event Sphere - Row Level Security (RLS) Policies
-- Run this in Supabase SQL Editor
-- All comparisons use TEXT casting for safety

-- ============================================================================
-- ENABLE RLS ON CORE TABLES
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE societies ENABLE ROW LEVEL SECURITY;
ALTER TABLE society_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users are viewable by everyone" ON users;
CREATE POLICY "Users are viewable by everyone" ON users
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
FOR UPDATE USING (id::text = auth.uid()::text);

-- NEW: Admins can update any user (for role management)
DROP POLICY IF EXISTS "Admins can update any user" ON users;
CREATE POLICY "Admins can update any user" ON users
FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users WHERE users.id::text = auth.uid()::text AND users.role = 'admin')
);

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users
FOR INSERT WITH CHECK (id::text = auth.uid()::text);

-- ============================================================================
-- EVENTS TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Approved events are viewable by everyone" ON events;
CREATE POLICY "Approved events are viewable by everyone" ON events
FOR SELECT USING (approval_status = 'approved');

DROP POLICY IF EXISTS "Admins can view all events" ON events;
CREATE POLICY "Admins can view all events" ON events
FOR SELECT USING (
  EXISTS (SELECT 1 FROM users WHERE users.id::text = auth.uid()::text AND users.role IN ('admin', 'president', 'vicePresident'))
);

DROP POLICY IF EXISTS "Creators can view own events" ON events;
CREATE POLICY "Creators can view own events" ON events
FOR SELECT USING (created_by::text = auth.uid()::text);

DROP POLICY IF EXISTS "Admins and presidents can create events" ON events;
CREATE POLICY "Admins and presidents can create events" ON events
FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM users WHERE users.id::text = auth.uid()::text AND users.role IN ('admin', 'president', 'vicePresident'))
);

DROP POLICY IF EXISTS "Creators and admins can update events" ON events;
CREATE POLICY "Creators and admins can update events" ON events
FOR UPDATE USING (
  created_by::text = auth.uid()::text OR
  EXISTS (SELECT 1 FROM users WHERE users.id::text = auth.uid()::text AND users.role = 'admin')
);

DROP POLICY IF EXISTS "Admins can delete events" ON events;
CREATE POLICY "Admins can delete events" ON events
FOR DELETE USING (
  EXISTS (SELECT 1 FROM users WHERE users.id::text = auth.uid()::text AND users.role = 'admin')
);

-- ============================================================================
-- REGISTRATIONS TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own registrations" ON registrations;
CREATE POLICY "Users can view own registrations" ON registrations
FOR SELECT USING (user_id::text = auth.uid()::text);

DROP POLICY IF EXISTS "Organizers can view event registrations" ON registrations;
CREATE POLICY "Organizers can view event registrations" ON registrations
FOR SELECT USING (
  EXISTS (SELECT 1 FROM events WHERE events.id::text = registrations.event_id::text AND events.created_by::text = auth.uid()::text)
);

DROP POLICY IF EXISTS "Admins can view all registrations" ON registrations;
CREATE POLICY "Admins can view all registrations" ON registrations
FOR SELECT USING (
  EXISTS (SELECT 1 FROM users WHERE users.id::text = auth.uid()::text AND users.role = 'admin')
);

DROP POLICY IF EXISTS "Users can create own registrations" ON registrations;
CREATE POLICY "Users can create own registrations" ON registrations
FOR INSERT WITH CHECK (user_id::text = auth.uid()::text);

DROP POLICY IF EXISTS "Users can delete own registrations" ON registrations;
CREATE POLICY "Users can delete own registrations" ON registrations
FOR DELETE USING (user_id::text = auth.uid()::text);

-- ============================================================================
-- SOCIETIES TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Societies are viewable by everyone" ON societies;
CREATE POLICY "Societies are viewable by everyone" ON societies
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage societies" ON societies;
CREATE POLICY "Admins can manage societies" ON societies
FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE users.id::text = auth.uid()::text AND users.role IN ('admin', 'super_admin'))
);

-- ============================================================================
-- SOCIETY MEMBERS TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Society members are viewable by everyone" ON society_members;
CREATE POLICY "Society members are viewable by everyone" ON society_members
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage society members" ON society_members;
CREATE POLICY "Admins can manage society members" ON society_members
FOR ALL USING (
  EXISTS (SELECT 1 FROM users WHERE users.id::text = auth.uid()::text AND users.role IN ('admin', 'super_admin', 'president', 'vice_president'))
);

-- ============================================================================
-- BOOKMARKS TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own bookmarks" ON bookmarks;
CREATE POLICY "Users can view own bookmarks" ON bookmarks
FOR SELECT USING (user_id::text = auth.uid()::text);

DROP POLICY IF EXISTS "Users can create own bookmarks" ON bookmarks;
CREATE POLICY "Users can create own bookmarks" ON bookmarks
FOR INSERT WITH CHECK (user_id::text = auth.uid()::text);

DROP POLICY IF EXISTS "Users can delete own bookmarks" ON bookmarks;
CREATE POLICY "Users can delete own bookmarks" ON bookmarks
FOR DELETE USING (user_id::text = auth.uid()::text);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
