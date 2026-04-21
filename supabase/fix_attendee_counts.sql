-- Event Sphere - Fix Attendee Counts
-- Run this in Supabase SQL Editor to sync current_attendees

-- 1. Update all events to have correct current_attendees based on actual registrations
UPDATE events
SET current_attendees = (
  SELECT COUNT(*)
  FROM registrations
  WHERE registrations.event_id = events.id
);

-- 2. Verify the trigger exists (this will show if it's working)
-- If this returns nothing, the trigger needs to be recreated
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers
WHERE trigger_name = 'update_attendees_on_registration';

-- 3. Make sure the function exists
-- The trigger function should already exist from capacity_and_features.sql
-- But here it is again just in case:

CREATE OR REPLACE FUNCTION update_event_attendee_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE events SET current_attendees = current_attendees + 1 WHERE id = NEW.event_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE events SET current_attendees = GREATEST(current_attendees - 1, 0) WHERE id = OLD.event_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. Recreate the trigger
DROP TRIGGER IF EXISTS update_attendees_on_registration ON registrations;
CREATE TRIGGER update_attendees_on_registration
AFTER INSERT OR DELETE ON registrations
FOR EACH ROW EXECUTE FUNCTION update_event_attendee_count();

-- Done! The trigger should now auto-update current_attendees on registration changes.
