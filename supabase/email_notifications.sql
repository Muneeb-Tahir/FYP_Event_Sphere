-- ============================================================
-- CUSTOM EMAIL NOTIFICATION SYSTEM
-- Run this SQL in Supabase SQL Editor
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================================
-- EMAIL TEMPLATES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.email_templates (
  id TEXT PRIMARY KEY,
  subject TEXT NOT NULL,
  body_html TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default templates
INSERT INTO public.email_templates (id, subject, body_html) VALUES
('event_approved',
 'Your Event Has Been Approved! 🎉',
 '<h2>Great News!</h2>
  <p>Your event <strong>{{event_title}}</strong> has been approved by the admin.</p>
  <p><strong>Date:</strong> {{event_date}}</p>
  <p><strong>Venue:</strong> {{event_venue}}</p>
  <p>Students can now register for your event. Good luck!</p>
  <br>
  <p>Best regards,<br><strong>Event Sphere Team</strong></p>'),

('event_rejected',
 'Event Submission Update',
 '<h2>Event Status Update</h2>
  <p>Unfortunately, your event <strong>{{event_title}}</strong> was not approved.</p>
  <p><strong>Reason:</strong> {{rejection_reason}}</p>
  <p>You can modify your event and resubmit it for review.</p>
  <br>
  <p>Best regards,<br><strong>Event Sphere Team</strong></p>'),

('event_reminder',
 'Reminder: {{event_title}} is Tomorrow! 📅',
 '<h2>Event Reminder</h2>
  <p>Don''t forget! You''re registered for:</p>
  <p><strong>Event:</strong> {{event_title}}</p>
  <p><strong>Date:</strong> {{event_date}}</p>
  <p><strong>Time:</strong> {{event_time}}</p>
  <p><strong>Venue:</strong> {{event_venue}}</p>
  <p>See you there!</p>
  <br>
  <p>Best regards,<br><strong>Event Sphere Team</strong></p>'),

('new_announcement',
 'New Announcement: {{announcement_title}}',
 '<h2>📢 New Announcement</h2>
  <p><strong>{{announcement_title}}</strong></p>
  <p>{{announcement_content}}</p>
  <br>
  <p>Best regards,<br><strong>Event Sphere Team</strong></p>'),

('member_added',
 'Welcome to {{society_name}}! 🎊',
 '<h2>Welcome!</h2>
  <p>You have been added to <strong>{{society_name}}</strong>.</p>
  <p>Your role: <strong>{{member_role}}</strong></p>
  <p>You can now participate in society events and activities.</p>
  <br>
  <p>Best regards,<br><strong>Event Sphere Team</strong></p>'),

('member_removed',
 'Society Membership Update',
 '<h2>Membership Update</h2>
  <p>You have been removed from <strong>{{society_name}}</strong>.</p>
  <p>If you believe this is an error, please contact the society president.</p>
  <br>
  <p>Best regards,<br><strong>Event Sphere Team</strong></p>')

ON CONFLICT (id) DO UPDATE SET
  subject = EXCLUDED.subject,
  body_html = EXCLUDED.body_html;

-- ============================================================
-- HELPER FUNCTION: Send Email via Edge Function
-- ============================================================
CREATE OR REPLACE FUNCTION send_notification_email(
  p_to TEXT,
  p_subject TEXT,
  p_html TEXT,
  p_type TEXT DEFAULT 'general'
) RETURNS void AS $$
DECLARE
  supabase_url TEXT := 'https://dnzpfbcbfwpfczduqsag.supabase.co';
BEGIN
  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/send-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('supabase.service_role_key', true)
    ),
    body := jsonb_build_object(
      'to', p_to,
      'subject', p_subject,
      'html', p_html,
      'type', p_type
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- TRIGGER: Event Approval/Rejection Email
-- ============================================================
CREATE OR REPLACE FUNCTION notify_event_status_change()
RETURNS TRIGGER AS $$
DECLARE
  creator_email TEXT;
  event_title TEXT;
  event_date TEXT;
  event_venue TEXT;
  template_subject TEXT;
  template_body TEXT;
  final_body TEXT;
BEGIN
  -- Only trigger on status change
  IF OLD.approval_status = NEW.approval_status THEN
    RETURN NEW;
  END IF;

  -- Get creator email
  SELECT email INTO creator_email FROM public.users WHERE id = NEW.created_by;

  IF creator_email IS NULL THEN
    RETURN NEW;
  END IF;

  event_title := NEW.title;
  event_date := TO_CHAR(NEW.date::DATE, 'Mon DD, YYYY');
  event_venue := COALESCE(NEW.venue, 'TBA');

  IF NEW.approval_status = 'approved' THEN
    SELECT subject, body_html INTO template_subject, template_body
    FROM public.email_templates WHERE id = 'event_approved';

    final_body := REPLACE(REPLACE(REPLACE(template_body,
      '{{event_title}}', event_title),
      '{{event_date}}', event_date),
      '{{event_venue}}', event_venue);

    PERFORM send_notification_email(creator_email, template_subject, final_body, 'event_approved');

  ELSIF NEW.approval_status = 'rejected' THEN
    SELECT subject, body_html INTO template_subject, template_body
    FROM public.email_templates WHERE id = 'event_rejected';

    final_body := REPLACE(REPLACE(template_body,
      '{{event_title}}', event_title),
      '{{rejection_reason}}', COALESCE(NEW.rejection_reason, 'No reason provided'));

    PERFORM send_notification_email(creator_email, template_subject, final_body, 'event_rejected');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_event_status_change ON public.events;
CREATE TRIGGER on_event_status_change
  AFTER UPDATE OF approval_status ON public.events
  FOR EACH ROW
  EXECUTE FUNCTION notify_event_status_change();

-- ============================================================
-- TRIGGER: Society Member Added/Removed Email
-- ============================================================
CREATE OR REPLACE FUNCTION notify_membership_change()
RETURNS TRIGGER AS $$
DECLARE
  member_email TEXT;
  society_name TEXT;
  member_role TEXT;
  template_subject TEXT;
  template_body TEXT;
  final_subject TEXT;
  final_body TEXT;
BEGIN
  -- Get member email
  SELECT email INTO member_email FROM public.users WHERE id = COALESCE(NEW.user_id, OLD.user_id);

  -- Get society name
  SELECT name INTO society_name FROM public.societies WHERE id = COALESCE(NEW.society_id, OLD.society_id);

  IF member_email IS NULL OR society_name IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  IF TG_OP = 'INSERT' THEN
    member_role := COALESCE(NEW.role, 'Member');

    SELECT subject, body_html INTO template_subject, template_body
    FROM public.email_templates WHERE id = 'member_added';

    final_subject := REPLACE(template_subject, '{{society_name}}', society_name);
    final_body := REPLACE(REPLACE(template_body,
      '{{society_name}}', society_name),
      '{{member_role}}', member_role);

    PERFORM send_notification_email(member_email, final_subject, final_body, 'member_added');

  ELSIF TG_OP = 'DELETE' THEN
    SELECT subject, body_html INTO template_subject, template_body
    FROM public.email_templates WHERE id = 'member_removed';

    final_body := REPLACE(template_body, '{{society_name}}', society_name);

    PERFORM send_notification_email(member_email, template_subject, final_body, 'member_removed');
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_membership_change ON public.society_members;
CREATE TRIGGER on_membership_change
  AFTER INSERT OR DELETE ON public.society_members
  FOR EACH ROW
  EXECUTE FUNCTION notify_membership_change();

-- ============================================================
-- TRIGGER: New Announcement Email
-- ============================================================
CREATE OR REPLACE FUNCTION notify_new_announcement()
RETURNS TRIGGER AS $$
DECLARE
  template_subject TEXT;
  template_body TEXT;
  final_subject TEXT;
  final_body TEXT;
  member_email TEXT;
  member_cursor CURSOR FOR
    SELECT u.email
    FROM public.users u
    JOIN public.society_members sm ON sm.user_id = u.id
    WHERE sm.society_id = NEW.society_id;
BEGIN
  SELECT subject, body_html INTO template_subject, template_body
  FROM public.email_templates WHERE id = 'new_announcement';

  final_subject := REPLACE(template_subject, '{{announcement_title}}', NEW.title);
  final_body := REPLACE(REPLACE(template_body,
    '{{announcement_title}}', NEW.title),
    '{{announcement_content}}', NEW.content);

  -- Send to all society members
  FOR member_email IN member_cursor LOOP
    PERFORM send_notification_email(member_email, final_subject, final_body, 'announcement');
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_announcement ON public.announcements;
CREATE TRIGGER on_new_announcement
  AFTER INSERT ON public.announcements
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_announcement();

-- ============================================================
-- CRON JOB: Event Reminder (24 hours before)
-- Note: Requires pg_cron extension enabled
-- ============================================================
CREATE OR REPLACE FUNCTION send_event_reminders()
RETURNS void AS $$
DECLARE
  event_record RECORD;
  registration_record RECORD;
  template_subject TEXT;
  template_body TEXT;
  final_subject TEXT;
  final_body TEXT;
BEGIN
  SELECT subject, body_html INTO template_subject, template_body
  FROM public.email_templates WHERE id = 'event_reminder';

  -- Find events happening tomorrow
  FOR event_record IN
    SELECT e.*, e.date::DATE as event_date
    FROM public.events e
    WHERE e.approval_status = 'approved'
    AND e.date::DATE = CURRENT_DATE + INTERVAL '1 day'
  LOOP
    final_subject := REPLACE(template_subject, '{{event_title}}', event_record.title);
    final_body := REPLACE(REPLACE(REPLACE(REPLACE(template_body,
      '{{event_title}}', event_record.title),
      '{{event_date}}', TO_CHAR(event_record.event_date, 'Mon DD, YYYY')),
      '{{event_time}}', COALESCE(event_record.time, 'TBA')),
      '{{event_venue}}', COALESCE(event_record.venue, 'TBA'));

    -- Send to all registered users
    FOR registration_record IN
      SELECT u.email
      FROM public.registrations r
      JOIN public.users u ON u.id = r.user_id
      WHERE r.event_id = event_record.id
    LOOP
      PERFORM send_notification_email(registration_record.email, final_subject, final_body, 'event_reminder');
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule reminder job to run daily at 9 AM (uncomment to enable)
-- SELECT cron.schedule('event-reminders', '0 9 * * *', 'SELECT send_event_reminders()');

-- ============================================================
-- GRANT PERMISSIONS
-- ============================================================
GRANT USAGE ON SCHEMA net TO postgres, authenticated, service_role;
GRANT EXECUTE ON FUNCTION send_notification_email TO postgres, service_role;
