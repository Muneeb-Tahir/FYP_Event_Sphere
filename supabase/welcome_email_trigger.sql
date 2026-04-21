-- Welcome Email Database Trigger (FIXED - Non-blocking)
-- This version won't block signups if email fails
-- Run this in Supabase SQL Editor

-- First, let's drop the problematic trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Enable the http extension (more reliable than pg_net)
CREATE EXTENSION IF NOT EXISTS http;

-- Create a safer trigger function with error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Use a NOTIFY approach or just log for now
  -- The email will be sent via a separate cron job or app-level call

  -- For now, just log that a new user was created
  RAISE NOTICE 'New user created: %', NEW.email;

  -- Always return NEW to not block the signup
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't block signup
    RAISE WARNING 'Welcome email trigger error: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create a safer trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
