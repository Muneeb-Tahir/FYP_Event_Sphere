-- Delete User RPC Function
-- Run this in Supabase SQL Editor
-- This function allows admins/super_admins to delete users from both auth and public tables

-- ============================================================================
-- DELETE USER RPC FUNCTION
-- ============================================================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS delete_user_completely(UUID);

-- Create the delete_user_completely function
CREATE OR REPLACE FUNCTION delete_user_completely(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_role TEXT;
  target_role TEXT;
BEGIN
  -- Get caller's role
  SELECT role INTO caller_role
  FROM users
  WHERE id = auth.uid();

  -- Only admin or super_admin can delete users
  IF caller_role IS NULL OR caller_role NOT IN ('admin', 'super_admin') THEN
    RAISE EXCEPTION 'Only admins can delete users';
  END IF;

  -- Get target user's role
  SELECT role INTO target_role
  FROM users
  WHERE id = target_user_id;

  -- Check if target exists
  IF target_role IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- Prevent deleting super_admin
  IF target_role = 'super_admin' THEN
    RAISE EXCEPTION 'Cannot delete super_admin';
  END IF;

  -- Prevent admin from deleting other admins (only super_admin can)
  IF target_role = 'admin' AND caller_role = 'admin' THEN
    RAISE EXCEPTION 'Admins cannot delete other admins';
  END IF;

  -- Prevent self-deletion
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot delete yourself';
  END IF;

  -- Delete from related tables first (cascade)
  DELETE FROM registrations WHERE user_id = target_user_id;
  DELETE FROM society_members WHERE user_id = target_user_id;
  DELETE FROM bookmarks WHERE user_id = target_user_id;
  DELETE FROM role_requests WHERE user_id = target_user_id;
  DELETE FROM role_changes WHERE target_user = target_user_id OR changed_by = target_user_id;

  -- Delete from public.users
  DELETE FROM users WHERE id = target_user_id;

  -- Delete from auth.users (requires SECURITY DEFINER)
  DELETE FROM auth.users WHERE id = target_user_id;

END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_completely(UUID) TO authenticated;

-- Change owner to postgres for auth.users access
ALTER FUNCTION delete_user_completely(UUID) OWNER TO postgres;

-- ============================================================================
-- UPDATE RLS POLICY FOR USERS TABLE (Add DELETE policy)
-- ============================================================================

-- Add delete policy for admins (as fallback, though RPC is preferred)
DROP POLICY IF EXISTS "Admins can delete users" ON users;
CREATE POLICY "Admins can delete users" ON users
FOR DELETE USING (
  EXISTS (SELECT 1 FROM users u WHERE u.id::text = auth.uid()::text AND u.role IN ('admin', 'super_admin'))
);

-- Also update the admin update policy to include super_admin
DROP POLICY IF EXISTS "Admins can update any user" ON users;
CREATE POLICY "Admins can update any user" ON users
FOR UPDATE USING (
  EXISTS (SELECT 1 FROM users u WHERE u.id::text = auth.uid()::text AND u.role IN ('admin', 'super_admin'))
);

SELECT 'User deletion function created successfully!' as status;
