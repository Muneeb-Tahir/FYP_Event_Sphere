-- Supabase Database Schema for Event Sphere
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/dnzpfbcbfwpfczduqsag/sql

-- ============================================
-- STORAGE BUCKETS (Run this first!)
-- ============================================
-- Create event-images bucket for event posters
INSERT INTO storage.buckets (id, name, public)
VALUES ('event-images', 'event-images', true)
ON CONFLICT (id) DO NOTHING;

-- Create profile-images bucket for user avatars
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for event-images bucket
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'event-images');
CREATE POLICY "Authenticated users can upload event images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'event-images' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update their own event images" ON storage.objects FOR UPDATE USING (bucket_id = 'event-images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can delete their own event images" ON storage.objects FOR DELETE USING (bucket_id = 'event-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================
-- 1. USERS TABLE (extends auth.users)
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'student' CHECK (role IN ('student', 'vice_president', 'president', 'admin', 'super_admin')),
  society_ids TEXT[] DEFAULT '{}',
  bio TEXT,
  phone TEXT,
  profile_image_url TEXT,
  joined_date TIMESTAMPTZ DEFAULT NOW(),
  email_confirmed BOOLEAN DEFAULT FALSE,
  gender TEXT DEFAULT 'male',
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. EVENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  date TIMESTAMPTZ NOT NULL,
  venue TEXT NOT NULL,
  society_id TEXT,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  category TEXT DEFAULT 'General',
  image_url TEXT,
  capacity INTEGER,
  max_attendees INTEGER,
  current_attendees INTEGER DEFAULT 0,
  end_date TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  is_featured BOOLEAN DEFAULT FALSE,
  like_count INTEGER DEFAULT 0,
  dislike_count INTEGER DEFAULT 0,
  approved_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. REGISTRATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  registered_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'registered',
  checked_in BOOLEAN DEFAULT FALSE,
  checked_in_at TIMESTAMPTZ,
  UNIQUE(user_id, event_id)
);

-- ============================================
-- 4. BOOKMARKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, event_id)
);

-- ============================================
-- 5. SOCIETIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.societies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  president_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5b. SOCIETY MEMBERS TABLE (Junction Table)
-- ============================================
CREATE TABLE IF NOT EXISTS public.society_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  society_id UUID NOT NULL REFERENCES public.societies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(society_id, user_id)
);

-- ============================================
-- 6. ANNOUNCEMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  society_id TEXT,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

-- ============================================
-- 7. EXPENSES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  category TEXT,
  description TEXT,
  receipt_url TEXT,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  approved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. POLLS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  options JSONB NOT NULL,
  votes JSONB DEFAULT '{}',
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  society_id TEXT,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT TRUE,
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.societies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Users: Everyone can read, users can update their own profile
CREATE POLICY "Users are viewable by everyone" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own record" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- Events: Everyone can read approved events, creators can manage their own
CREATE POLICY "Approved events are viewable by everyone" ON public.events FOR SELECT USING (true);
CREATE POLICY "Users can create events" ON public.events FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Creators can update their events" ON public.events FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Admins can update all events" ON public.events FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- Registrations: Users can manage their own registrations
CREATE POLICY "Users can view their registrations" ON public.registrations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Event creators can view registrations" ON public.registrations FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.events WHERE id = event_id AND created_by = auth.uid())
);
CREATE POLICY "Users can register for events" ON public.registrations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unregister" ON public.registrations FOR DELETE USING (auth.uid() = user_id);

-- Bookmarks: Users can manage their own bookmarks
CREATE POLICY "Users can view their bookmarks" ON public.bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can add bookmarks" ON public.bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove bookmarks" ON public.bookmarks FOR DELETE USING (auth.uid() = user_id);

-- Societies: Everyone can read, admins can manage
CREATE POLICY "Societies are viewable by everyone" ON public.societies FOR SELECT USING (true);
CREATE POLICY "Admins can create societies" ON public.societies FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Admins can update societies" ON public.societies FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Admins can delete societies" ON public.societies FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- Announcements: Everyone can read, admins/presidents can create
CREATE POLICY "Announcements are viewable by everyone" ON public.announcements FOR SELECT USING (true);
CREATE POLICY "Admins can create announcements" ON public.announcements FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'president'))
);

-- ============================================
-- REALTIME SUBSCRIPTIONS
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.registrations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookmarks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_events_date ON public.events(date);
CREATE INDEX IF NOT EXISTS idx_events_status ON public.events(approval_status);
CREATE INDEX IF NOT EXISTS idx_events_category ON public.events(category);
CREATE INDEX IF NOT EXISTS idx_registrations_user ON public.registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_registrations_event ON public.registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON public.bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_society_members_society ON public.society_members(society_id);
CREATE INDEX IF NOT EXISTS idx_society_members_user ON public.society_members(user_id);

-- ============================================
-- SOCIETY MEMBERS RLS POLICIES
-- ============================================
ALTER TABLE public.society_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Society members viewable by all" ON public.society_members FOR SELECT USING (true);
CREATE POLICY "Admins can manage all society members" ON public.society_members FOR ALL USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Presidents can manage their society members" ON public.society_members FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.societies s
    WHERE s.id = society_id AND s.president_id = auth.uid()
  )
);

-- ============================================
-- ADDITIONAL TABLES (used by app services)
-- ============================================

-- 9. EVENT FEEDBACK (ratings & reviews)
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
CREATE POLICY "Feedback viewable by all" ON public.event_feedback FOR SELECT USING (true);
CREATE POLICY "Users can manage own feedback" ON public.event_feedback FOR ALL USING (auth.uid() = user_id);

-- 10. EVENT WAITLIST (queue when events are full)
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
CREATE POLICY "Waitlist viewable by all" ON public.event_waitlist FOR SELECT USING (true);
CREATE POLICY "Users can manage own waitlist" ON public.event_waitlist FOR ALL USING (auth.uid() = user_id);

-- 11. EVENT REACTIONS (like/dislike)
CREATE TABLE IF NOT EXISTS public.event_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  reaction_type TEXT NOT NULL CHECK (reaction_type IN ('like', 'dislike')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);
ALTER TABLE public.event_reactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Reactions viewable by all" ON public.event_reactions FOR SELECT USING (true);
CREATE POLICY "Users can manage own reactions" ON public.event_reactions FOR ALL USING (auth.uid() = user_id);

-- 12. EVENT COMMENTS (discussions)
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
CREATE POLICY "Comments viewable by all" ON public.event_comments FOR SELECT USING (true);
CREATE POLICY "Authenticated users can comment" ON public.event_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can manage own comments" ON public.event_comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON public.event_comments FOR DELETE USING (auth.uid() = user_id);

-- 13. EVENT PHOTOS (gallery)
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
CREATE POLICY "Approved photos viewable by all" ON public.event_photos FOR SELECT USING (true);
CREATE POLICY "Authenticated users can upload photos" ON public.event_photos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own photos" ON public.event_photos FOR DELETE USING (auth.uid() = user_id);

-- 14. EVENT RESOURCES (files and links)
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
CREATE POLICY "Resources viewable by all" ON public.event_resources FOR SELECT USING (true);
CREATE POLICY "Authenticated users can add resources" ON public.event_resources FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Uploaders can delete resources" ON public.event_resources FOR DELETE USING (auth.uid() = uploaded_by);

-- 15. EVENT REMINDERS
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
CREATE POLICY "Users can manage own reminders" ON public.event_reminders FOR ALL USING (auth.uid() = user_id);

-- 16. EVENT COMMITTEES (organizing team)
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
CREATE POLICY "Committees viewable by all" ON public.event_committees FOR SELECT USING (true);
CREATE POLICY "Event creators can manage committees" ON public.event_committees FOR ALL USING (
  EXISTS (SELECT 1 FROM public.events e WHERE e.id = event_id AND e.created_by = auth.uid())
);

-- 17. USER POINTS (gamification)
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
CREATE POLICY "Points viewable by all" ON public.user_points FOR SELECT USING (true);
CREATE POLICY "System can manage points" ON public.user_points FOR ALL USING (auth.role() = 'authenticated');

-- 18. ROLE REQUESTS (role upgrade requests)
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
CREATE POLICY "Users can view own requests" ON public.role_requests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all requests" ON public.role_requests FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);
CREATE POLICY "Users can create requests" ON public.role_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can update requests" ON public.role_requests FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- 19. ROLE CHANGES (audit log)
CREATE TABLE IF NOT EXISTS public.role_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_user UUID REFERENCES public.users(id) ON DELETE CASCADE,
  old_role TEXT NOT NULL,
  new_role TEXT NOT NULL,
  changed_by UUID REFERENCES public.users(id),
  changed_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.role_changes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view role changes" ON public.role_changes FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- ============================================
-- ADDITIONAL INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_event_feedback_event ON public.event_feedback(event_id);
CREATE INDEX IF NOT EXISTS idx_event_comments_event ON public.event_comments(event_id);
CREATE INDEX IF NOT EXISTS idx_event_reactions_event ON public.event_reactions(event_id);
CREATE INDEX IF NOT EXISTS idx_event_waitlist_event ON public.event_waitlist(event_id);
CREATE INDEX IF NOT EXISTS idx_event_reminders_user ON public.event_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_user_points_total ON public.user_points(total_points DESC);

-- ============================================
-- ADDITIONAL REALTIME SUBSCRIPTIONS
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_comments;

-- ============================================
-- PROFILE IMAGES STORAGE BUCKET
-- ============================================
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-images', 'profile-images', true) ON CONFLICT DO NOTHING;
CREATE POLICY "Public profile image access" ON storage.objects FOR SELECT USING (bucket_id = 'profile-images');
CREATE POLICY "Users can upload profile images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'profile-images' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update profile images" ON storage.objects FOR UPDATE USING (bucket_id = 'profile-images' AND auth.role() = 'authenticated');
