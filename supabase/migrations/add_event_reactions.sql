-- Migration: Create event_reactions table for like/dislike system
-- Run this in the Supabase SQL Editor

-- 1. Create the reactions table
CREATE TABLE IF NOT EXISTS event_reactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction_type TEXT NOT NULL CHECK (reaction_type IN ('like', 'dislike')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Each user can only have ONE reaction per event
    UNIQUE(event_id, user_id)
);

-- 2. Add like/dislike count columns to events table
ALTER TABLE events ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0;
ALTER TABLE events ADD COLUMN IF NOT EXISTS dislike_count INTEGER DEFAULT 0;

-- 3. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_event_reactions_event_id ON event_reactions(event_id);
CREATE INDEX IF NOT EXISTS idx_event_reactions_user_id ON event_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_event_reactions_type ON event_reactions(event_id, reaction_type);

-- 4. Enable RLS
ALTER TABLE event_reactions ENABLE ROW LEVEL SECURITY;

-- 5. RLS policies
CREATE POLICY "Users can view all reactions" ON event_reactions
    FOR SELECT USING (true);

CREATE POLICY "Users can insert own reactions" ON event_reactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reactions" ON event_reactions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reactions" ON event_reactions
    FOR DELETE USING (auth.uid() = user_id);

-- 6. Function to update event like/dislike counts (called by trigger)
CREATE OR REPLACE FUNCTION update_event_reaction_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- Recalculate counts for the affected event
    IF TG_OP = 'DELETE' THEN
        UPDATE events SET
            like_count = (SELECT COUNT(*) FROM event_reactions WHERE event_id = OLD.event_id AND reaction_type = 'like'),
            dislike_count = (SELECT COUNT(*) FROM event_reactions WHERE event_id = OLD.event_id AND reaction_type = 'dislike')
        WHERE id = OLD.event_id;
        RETURN OLD;
    ELSE
        UPDATE events SET
            like_count = (SELECT COUNT(*) FROM event_reactions WHERE event_id = NEW.event_id AND reaction_type = 'like'),
            dislike_count = (SELECT COUNT(*) FROM event_reactions WHERE event_id = NEW.event_id AND reaction_type = 'dislike')
        WHERE id = NEW.event_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Trigger to auto-update counts on every reaction change
DROP TRIGGER IF EXISTS trigger_update_reaction_counts ON event_reactions;
CREATE TRIGGER trigger_update_reaction_counts
    AFTER INSERT OR UPDATE OR DELETE ON event_reactions
    FOR EACH ROW EXECUTE FUNCTION update_event_reaction_counts();

COMMENT ON TABLE event_reactions IS 'Stores user like/dislike reactions for events';
COMMENT ON COLUMN events.like_count IS 'Cached count of likes (updated by trigger)';
COMMENT ON COLUMN events.dislike_count IS 'Cached count of dislikes (updated by trigger)';
