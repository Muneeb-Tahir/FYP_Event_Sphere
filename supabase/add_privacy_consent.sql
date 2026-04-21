-- Event Sphere - Add Privacy Consent Column
-- Run this in Supabase SQL Editor

-- Add show_in_list column to registrations table
ALTER TABLE registrations ADD COLUMN IF NOT EXISTS show_in_list BOOLEAN DEFAULT true;

-- Comment: If show_in_list is true, user's name is visible in participants list
-- If false, user will be shown as "Anonymous"

