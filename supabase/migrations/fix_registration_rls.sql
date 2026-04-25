-- Fix: Allow all authenticated users to view registrations
-- This fixes the attendee count bug where RLS prevented users from seeing 
-- other users' registrations, causing the count to always show 1.
-- Run this in Supabase SQL Editor

-- Drop the restrictive policy
DROP POLICY IF EXISTS "Users can view own registrations" ON registrations;

-- Replace with: All authenticated users can view registrations
-- Registration data (who's attending) is public event information
CREATE POLICY "Authenticated users can view registrations" ON registrations
FOR SELECT USING (auth.uid() IS NOT NULL);

-- Keep existing organizer and admin policies (they're now redundant but harmless)
-- DROP POLICY IF EXISTS "Organizers can view event registrations" ON registrations;
-- DROP POLICY IF EXISTS "Admins can view all registrations" ON registrations;

-- Also add UPDATE policy so organizers can check-in attendees
DROP POLICY IF EXISTS "Organizers can update registrations" ON registrations;
CREATE POLICY "Organizers can update registrations" ON registrations
FOR UPDATE USING (
  -- User can update own registration
  user_id::text = auth.uid()::text
  OR
  -- Event organizer can update (for check-in)
  EXISTS (SELECT 1 FROM events WHERE events.id::text = registrations.event_id::text AND events.created_by::text = auth.uid()::text)
  OR
  -- Admins can update any registration
  EXISTS (SELECT 1 FROM users WHERE users.id::text = auth.uid()::text AND users.role IN ('admin', 'super_admin', 'president'))
);

-- Verify
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'registrations';
