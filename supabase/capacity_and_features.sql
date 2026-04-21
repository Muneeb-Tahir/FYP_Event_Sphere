-- Event Sphere - Capacity & Additional Features Schema (SAFE VERSION)
-- Run this in Supabase SQL Editor
-- This version handles existing objects gracefully

-- =====================================================
-- 1. Add Capacity Fields to Events Table
-- =====================================================
ALTER TABLE events ADD COLUMN IF NOT EXISTS max_attendees INT;
ALTER TABLE events ADD COLUMN IF NOT EXISTS current_attendees INT DEFAULT 0;
ALTER TABLE events ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

-- Create function to update current_attendees count
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

-- Create trigger for auto-updating attendee count
DROP TRIGGER IF EXISTS update_attendees_on_registration ON registrations;
CREATE TRIGGER update_attendees_on_registration
AFTER INSERT OR DELETE ON registrations
FOR EACH ROW EXECUTE FUNCTION update_event_attendee_count();

-- =====================================================
-- 2. Event Reminders Table
-- =====================================================
CREATE TABLE IF NOT EXISTS event_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  remind_at TIMESTAMPTZ NOT NULL,
  is_sent BOOLEAN DEFAULT false,
  reminder_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, event_id, reminder_type)
);

-- RLS for reminders (DROP existing policies first)
ALTER TABLE event_reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own reminders" ON event_reminders;
DROP POLICY IF EXISTS "Users can create own reminders" ON event_reminders;
DROP POLICY IF EXISTS "Users can delete own reminders" ON event_reminders;

CREATE POLICY "Users can view own reminders" ON event_reminders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own reminders" ON event_reminders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own reminders" ON event_reminders FOR DELETE USING (auth.uid() = user_id);

-- Index for cron job queries
CREATE INDEX IF NOT EXISTS idx_reminders_pending ON event_reminders(remind_at, is_sent) WHERE is_sent = false;

-- =====================================================
-- 3. Event Waitlist Table
-- =====================================================
CREATE TABLE IF NOT EXISTS event_waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  position INT NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  promoted_at TIMESTAMPTZ,
  UNIQUE(event_id, user_id)
);

-- RLS for waitlist
ALTER TABLE event_waitlist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view waitlist" ON event_waitlist;
DROP POLICY IF EXISTS "Users can join waitlist" ON event_waitlist;
DROP POLICY IF EXISTS "Users can leave waitlist" ON event_waitlist;

CREATE POLICY "Anyone can view waitlist" ON event_waitlist FOR SELECT USING (true);
CREATE POLICY "Users can join waitlist" ON event_waitlist FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave waitlist" ON event_waitlist FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_waitlist_event ON event_waitlist(event_id, position);

-- =====================================================
-- 4. Event Resources Table
-- =====================================================
CREATE TABLE IF NOT EXISTS event_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT,
  description TEXT,
  uploaded_by UUID REFERENCES users(id),
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for resources
ALTER TABLE event_resources ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view resources" ON event_resources;
DROP POLICY IF EXISTS "Presidents can manage resources" ON event_resources;

CREATE POLICY "Anyone can view resources" ON event_resources FOR SELECT USING (true);
CREATE POLICY "Presidents can manage resources" ON event_resources FOR ALL USING (true);

CREATE INDEX IF NOT EXISTS idx_resources_event ON event_resources(event_id);

-- =====================================================
-- 5. Event Committees Table
-- =====================================================
CREATE TABLE IF NOT EXISTS event_committees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  responsibilities TEXT,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

-- RLS for committees
ALTER TABLE event_committees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view committees" ON event_committees;
DROP POLICY IF EXISTS "Presidents can manage committees" ON event_committees;

CREATE POLICY "Anyone can view committees" ON event_committees FOR SELECT USING (true);
CREATE POLICY "Presidents can manage committees" ON event_committees FOR ALL USING (true);

CREATE INDEX IF NOT EXISTS idx_committees_event ON event_committees(event_id);

-- =====================================================
-- 6. Event Recurrence Fields
-- =====================================================
ALTER TABLE events ADD COLUMN IF NOT EXISTS recurrence_rule TEXT;
ALTER TABLE events ADD COLUMN IF NOT EXISTS series_id UUID;
ALTER TABLE events ADD COLUMN IF NOT EXISTS is_series_parent BOOLEAN DEFAULT false;

-- =====================================================
-- Done! All migrations applied safely.
-- =====================================================
