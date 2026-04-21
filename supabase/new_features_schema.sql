-- Event Sphere - New Features Database Schema
-- Run this in Supabase SQL Editor

-- =====================================================
-- 1. Event Feedback & Ratings
-- =====================================================
CREATE TABLE IF NOT EXISTS event_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rating INT CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ,
  UNIQUE(event_id, user_id)
);

-- RLS for feedback
ALTER TABLE event_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view feedback" ON event_feedback FOR SELECT USING (true);
CREATE POLICY "Users can add feedback" ON event_feedback FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own feedback" ON event_feedback FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own feedback" ON event_feedback FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 2. Event Comments/Discussion
-- =====================================================
CREATE TABLE IF NOT EXISTS event_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  parent_id UUID REFERENCES event_comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- RLS for comments
ALTER TABLE event_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view comments" ON event_comments FOR SELECT USING (true);
CREATE POLICY "Users can add comments" ON event_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON event_comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON event_comments FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 3. User Points & Gamification
-- =====================================================
CREATE TABLE IF NOT EXISTS user_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  total_points INT DEFAULT 0,
  events_attended INT DEFAULT 0,
  badges TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- RLS for points
ALTER TABLE user_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view points" ON user_points FOR SELECT USING (true);
CREATE POLICY "System can manage points" ON user_points FOR ALL USING (true);

-- =====================================================
-- 4. Event Photos
-- =====================================================
CREATE TABLE IF NOT EXISTS event_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  caption TEXT,
  is_approved BOOLEAN DEFAULT true,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for photos
ALTER TABLE event_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view approved photos" ON event_photos FOR SELECT USING (is_approved = true);
CREATE POLICY "Users can upload photos" ON event_photos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own photos" ON event_photos FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 5. Performance Indexes
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_events_date ON events(date);
CREATE INDEX IF NOT EXISTS idx_events_society ON events(society_id);
CREATE INDEX IF NOT EXISTS idx_events_approval ON events(approval_status);
CREATE INDEX IF NOT EXISTS idx_registrations_user ON registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_registrations_event ON registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_society_members_society ON society_members(society_id);
CREATE INDEX IF NOT EXISTS idx_society_members_user ON society_members(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_event ON event_feedback(event_id);
CREATE INDEX IF NOT EXISTS idx_comments_event ON event_comments(event_id);
CREATE INDEX IF NOT EXISTS idx_photos_event ON event_photos(event_id);
CREATE INDEX IF NOT EXISTS idx_user_points_total ON user_points(total_points DESC);

-- =====================================================
-- 6. Event Timers (Start/Pause/Postpone)
-- =====================================================
CREATE TABLE IF NOT EXISTS event_timers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE UNIQUE,
  is_running BOOLEAN DEFAULT true,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  paused_at TIMESTAMPTZ,
  paused_duration_seconds INT DEFAULT 0,
  original_event_date TIMESTAMPTZ NOT NULL,
  postponed_to TIMESTAMPTZ,
  postpone_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- RLS for timers
ALTER TABLE event_timers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view timers" ON event_timers FOR SELECT USING (true);
CREATE POLICY "System can manage timers" ON event_timers FOR ALL USING (true);

CREATE INDEX IF NOT EXISTS idx_timers_event ON event_timers(event_id);

-- =====================================================
-- Done! All tables and indexes created.
-- =====================================================
