-- Soft Delete Migration for Events
-- This adds a deleted_at column to preserve deleted events in the database

-- Add deleted_at column
ALTER TABLE events ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- Create index for efficient querying of non-deleted events
CREATE INDEX IF NOT EXISTS idx_events_deleted_at ON events(deleted_at);

-- Update RLS policies to exclude soft-deleted events from normal queries
-- but allow admins to see deleted events when needed

-- Comment: After running this migration:
-- 1. Events with deleted_at = NULL are active
-- 2. Events with deleted_at = timestamp are soft-deleted
-- 3. The chatbot's "past events" query will include soft-deleted events
