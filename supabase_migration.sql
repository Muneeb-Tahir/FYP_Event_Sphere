-- ============================================
-- EVENT SPHERE: MIGRATION SCRIPT (SAFE TO RE-RUN)
-- Run this in Supabase Dashboard → SQL Editor
-- Uses DROP IF EXISTS + CREATE to avoid duplicate errors
-- ============================================

-- ============================================
-- 1. UPDATE USERS TABLE
-- ============================================
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE public.users ADD CONSTRAINT users_role_check 
  CHECK (role IN ('student', 'vice_president', 'president', 'admin', 'super_admin'));
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'male';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- ============================================
-- 2. UPDATE EVENTS TABLE
-- ============================================
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS max_attendees INTEGER;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS current_attendees INTEGER DEFAULT 0;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS dislike_count INTEGER DEFAULT 0;
ALTER TABLE public.events ALTER COLUMN category SET DEFAULT 'General';

-- ============================================
-- 3. EVENT FEEDBACK
-- ============================================
CREATE TABLE IF NOT EXISTS public.event_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);
ALTER TABLE public.event_feedback ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Feedback viewable by all" ON public.event_feedback;
CREATE POLICY "Feedback viewable by all" ON public.event_feedback FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can manage own feedback" ON public.event_feedback;
CREATE POLICY "Users can manage own feedback" ON public.event_feedback FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 4. EVENT WAITLIST
-- ============================================
CREATE TABLE IF NOT EXISTS public.event_waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  promoted_at TIMESTAMPTZ,
  UNIQUE(event_id, user_id)
);
ALTER TABLE public.event_waitlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Waitlist viewable by all" ON public.event_waitlist;
CREATE POLICY "Waitlist viewable by all" ON public.event_waitlist FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can manage own waitlist" ON public.event_waitlist;
CREATE POLICY "Users can manage own waitlist" ON public.event_waitlist FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 5. EVENT REACTIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.event_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  reaction_type TEXT NOT NULL CHECK (reaction_type IN ('like', 'dislike')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);
ALTER TABLE public.event_reactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Reactions viewable by all" ON public.event_reactions;
CREATE POLICY "Reactions viewable by all" ON public.event_reactions FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can manage own reactions" ON public.event_reactions;
CREATE POLICY "Users can manage own reactions" ON public.event_reactions FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 6. EVENT COMMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.event_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  parent_id UUID REFERENCES public.event_comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.event_comments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Comments viewable by all" ON public.event_comments;
CREATE POLICY "Comments viewable by all" ON public.event_comments FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can comment" ON public.event_comments;
CREATE POLICY "Authenticated users can comment" ON public.event_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can manage own comments" ON public.event_comments;
CREATE POLICY "Users can manage own comments" ON public.event_comments FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own comments" ON public.event_comments;
CREATE POLICY "Users can delete own comments" ON public.event_comments FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 7. EVENT PHOTOS
-- ============================================
CREATE TABLE IF NOT EXISTS public.event_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  caption TEXT,
  is_approved BOOLEAN DEFAULT TRUE,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.event_photos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Approved photos viewable by all" ON public.event_photos;
CREATE POLICY "Approved photos viewable by all" ON public.event_photos FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can upload photos" ON public.event_photos;
CREATE POLICY "Authenticated users can upload photos" ON public.event_photos FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own photos" ON public.event_photos;
CREATE POLICY "Users can delete own photos" ON public.event_photos FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 8. EVENT RESOURCES
-- ============================================
CREATE TABLE IF NOT EXISTS public.event_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT DEFAULT 'document',
  description TEXT,
  uploaded_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.event_resources ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Resources viewable by all" ON public.event_resources;
CREATE POLICY "Resources viewable by all" ON public.event_resources FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can add resources" ON public.event_resources;
CREATE POLICY "Authenticated users can add resources" ON public.event_resources FOR INSERT WITH CHECK (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Uploaders can delete resources" ON public.event_resources;
CREATE POLICY "Uploaders can delete resources" ON public.event_resources FOR DELETE USING (auth.uid() = uploaded_by);

-- ============================================
-- 9. EVENT REMINDERS
-- ============================================
CREATE TABLE IF NOT EXISTS public.event_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  remind_at TIMESTAMPTZ NOT NULL,
  is_sent BOOLEAN DEFAULT FALSE,
  reminder_type TEXT DEFAULT 'day',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, event_id, reminder_type)
);
ALTER TABLE public.event_reminders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own reminders" ON public.event_reminders;
CREATE POLICY "Users can manage own reminders" ON public.event_reminders FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 10. EVENT COMMITTEES
-- ============================================
CREATE TABLE IF NOT EXISTS public.event_committees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'volunteer',
  responsibilities TEXT,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);
ALTER TABLE public.event_committees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Committees viewable by all" ON public.event_committees;
CREATE POLICY "Committees viewable by all" ON public.event_committees FOR SELECT USING (true);
DROP POLICY IF EXISTS "Event creators can manage committees" ON public.event_committees;
CREATE POLICY "Event creators can manage committees" ON public.event_committees FOR ALL USING (
  EXISTS (SELECT 1 FROM public.events e WHERE e.id = event_id AND e.created_by = auth.uid())
);

-- ============================================
-- 11. USER POINTS (gamification)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  total_points INTEGER DEFAULT 0,
  events_attended INTEGER DEFAULT 0,
  badges TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.user_points ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Points viewable by all" ON public.user_points;
CREATE POLICY "Points viewable by all" ON public.user_points FOR SELECT USING (true);
DROP POLICY IF EXISTS "System can manage points" ON public.user_points;
CREATE POLICY "System can manage points" ON public.user_points FOR ALL USING (auth.role() = 'authenticated');

-- ============================================
-- 12. ROLE REQUESTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.role_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  requested_role TEXT NOT NULL,
  reason TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES public.users(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.role_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own requests" ON public.role_requests;
CREATE POLICY "Users can view own requests" ON public.role_requests FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Admins can view all requests" ON public.role_requests;
CREATE POLICY "Admins can view all requests" ON public.role_requests FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);
DROP POLICY IF EXISTS "Users can create requests" ON public.role_requests;
CREATE POLICY "Users can create requests" ON public.role_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Admins can update requests" ON public.role_requests;
CREATE POLICY "Admins can update requests" ON public.role_requests FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- ============================================
-- 13. ROLE CHANGES (audit log)
-- ============================================
CREATE TABLE IF NOT EXISTS public.role_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_user UUID REFERENCES public.users(id) ON DELETE CASCADE,
  old_role TEXT NOT NULL,
  new_role TEXT NOT NULL,
  changed_by UUID REFERENCES public.users(id),
  changed_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.role_changes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can view role changes" ON public.role_changes;
CREATE POLICY "Admins can view role changes" ON public.role_changes FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_event_feedback_event ON public.event_feedback(event_id);
CREATE INDEX IF NOT EXISTS idx_event_comments_event ON public.event_comments(event_id);
CREATE INDEX IF NOT EXISTS idx_event_reactions_event ON public.event_reactions(event_id);
CREATE INDEX IF NOT EXISTS idx_event_waitlist_event ON public.event_waitlist(event_id);
CREATE INDEX IF NOT EXISTS idx_event_reminders_user ON public.event_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_user_points_total ON public.user_points(total_points DESC);

-- ============================================
-- PROFILE IMAGES STORAGE BUCKET
-- ============================================
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-images', 'profile-images', true) ON CONFLICT DO NOTHING;
DROP POLICY IF EXISTS "Public profile image access" ON storage.objects;
CREATE POLICY "Public profile image access" ON storage.objects FOR SELECT USING (bucket_id = 'profile-images');
DROP POLICY IF EXISTS "Users can upload profile images" ON storage.objects;
CREATE POLICY "Users can upload profile images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'profile-images' AND auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Users can update profile images" ON storage.objects;
CREATE POLICY "Users can update profile images" ON storage.objects FOR UPDATE USING (bucket_id = 'profile-images' AND auth.role() = 'authenticated');

-- ============================================
-- DONE! Migration complete.
-- ============================================
