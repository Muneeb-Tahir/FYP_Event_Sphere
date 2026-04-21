-- Create table to track sent event reminders (prevents duplicate notifications)
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS event_reminders_sent (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reminder_type TEXT NOT NULL DEFAULT '30min', -- '30min', '1hour', '1day' etc
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(event_id, user_id, reminder_type)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_reminders_event_id ON event_reminders_sent(event_id);
CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON event_reminders_sent(user_id);

-- Enable RLS
ALTER TABLE event_reminders_sent ENABLE ROW LEVEL SECURITY;

-- Service role can manage all reminders
CREATE POLICY "Service role can manage reminders"
ON event_reminders_sent FOR ALL
USING (auth.role() = 'service_role');

-- Users can view their own reminders
CREATE POLICY "Users can view own reminders"
ON event_reminders_sent FOR SELECT
USING (auth.uid() = user_id);
