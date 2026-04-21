-- Create profile-images bucket in Supabase Storage
-- Run this in Supabase SQL Editor

-- Create the storage bucket for profile images
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Allow anyone to view profile images (public read)
CREATE POLICY "Public profile images read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-images');

-- Allow authenticated users to upload their own profile image
CREATE POLICY "Users can upload own profile image"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile-images'
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to update their own profile image
CREATE POLICY "Users can update own profile image"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile-images'
  AND auth.role() = 'authenticated'
);

-- Allow authenticated users to delete their own profile image
CREATE POLICY "Users can delete own profile image"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile-images'
  AND auth.role() = 'authenticated'
);

-- Verify bucket was created
SELECT * FROM storage.buckets WHERE id = 'profile-images';
