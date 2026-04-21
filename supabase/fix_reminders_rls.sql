-- Create event_reminders table if it doesn't exist
-- Run this in Supabase SQL Editor

-- Create the table
CREATE TABLE IF NOT EXISTS event_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  remind_at TIMESTAMP WITH TIME ZONE NOT NULL,
  is_sent BOOLEAN DEFAULT FALSE,
  reminder_type TEXT NOT NULL DEFAULT 'hour',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, event_id, reminder_type)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_event_reminders_user ON event_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_event_reminders_event ON event_reminders(event_id);
CREATE INDEX IF NOT EXISTS idx_event_reminders_remind_at ON event_reminders(remind_at);

-- Enable RLS
ALTER TABLE event_reminders ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies
DROP POLICY IF EXISTS "Users can view own reminders" ON event_reminders;
DROP POLICY IF EXISTS "Users can insert own reminders" ON event_reminders;
DROP POLICY IF EXISTS "Users can update own reminders" ON event_reminders;
DROP POLICY IF EXISTS "Users can delete own reminders" ON event_reminders;
DROP POLICY IF EXISTS "Service role access" ON event_reminders;

-- Create permissive policies for all authenticated users
CREATE POLICY "Users can view own reminders"
ON event_reminders FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own reminders"
ON event_reminders FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reminders"
ON event_reminders FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reminders"
ON event_reminders FOR DELETE
USING (auth.uid() = user_id);

-- Also allow service role full access
CREATE POLICY "Service role access"
ON event_reminders FOR ALL
USING (auth.role() = 'service_role');

-- Verify table and policies
SELECT 'Table created/verified' AS status;
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'event_reminders';
