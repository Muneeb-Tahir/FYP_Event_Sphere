-- Fix RLS policy for events table to allow attendee count updates
-- Run this in Supabase SQL Editor

-- Allow service role and authenticated users to update current_attendees
DROP POLICY IF EXISTS "Anyone can update attendee count" ON events;

CREATE POLICY "Anyone can update attendee count"
ON events FOR UPDATE
USING (true)
WITH CHECK (true);

-- Alternative: More restrictive policy (only current_attendees column)
-- This won't work as RLS is row-level not column-level
-- So we use the above policy

-- Verify policies
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'events';

-- OPTIONAL: Fix existing events with wrong count
-- This updates all events to have correct current_attendees
UPDATE events
SET current_attendees = (
  SELECT COUNT(*) FROM registrations
  WHERE registrations.event_id = events.id
);
