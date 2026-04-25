-- Migration: Add is_featured column to events table
-- Purpose: Allows admins to manually mark events as featured for the carousel
-- Run this in the Supabase SQL Editor

ALTER TABLE events
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE;

-- Index for quick featured event queries
CREATE INDEX IF NOT EXISTS idx_events_is_featured
ON events (is_featured)
WHERE is_featured = TRUE AND deleted_at IS NULL;

COMMENT ON COLUMN events.is_featured IS 'When true, event appears in the Featured carousel on the Events page';
