-- Add category column to societies table
-- Run this migration in Supabase SQL Editor

-- Add category column to societies table
ALTER TABLE societies
ADD COLUMN IF NOT EXISTS category TEXT;

-- Optional: Create an index for faster category filtering
CREATE INDEX IF NOT EXISTS idx_societies_category ON societies(category);

-- Optional: Create a lookup table for society categories (for reference only)
-- CREATE TABLE IF NOT EXISTS society_categories (
--   id SERIAL PRIMARY KEY,
--   name TEXT UNIQUE NOT NULL,
--   color TEXT,
--   icon TEXT,
--   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );

-- -- Insert default categories
-- INSERT INTO society_categories (name, color) VALUES
--   ('Tech', '#3B82F6'),
--   ('Sports', '#22C55E'),
--   ('Cultural', '#F59E0B'),
--   ('Academic', '#6366F1'),
--   ('Music', '#EC4899'),
--   ('Literary & Debating', '#8B5CF6'),
--   ('Drama & Performing Arts', '#EC4899'),
--   ('Art & Design', '#F43F5E'),
--   ('Community Service', '#22C55E'),
--   ('Entrepreneurship', '#F59E0B'),
--   ('Science & Innovation', '#0EA5E9'),
--   ('Gaming & Esports', '#6366F1'),
--   ('Environmental', '#10B981')
-- ON CONFLICT (name) DO NOTHING;

-- Verify the change
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'societies' AND column_name = 'category';
