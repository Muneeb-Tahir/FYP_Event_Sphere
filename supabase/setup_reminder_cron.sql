-- Set up scheduled job for event reminders
-- Run this in Supabase SQL Editor
-- IMPORTANT: First enable pg_cron and pg_net extensions in Dashboard -> Database -> Extensions

-- Enable extensions (if not already done)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;
-- CREATE EXTENSION IF NOT EXISTS pg_net;

-- Schedule the check-reminders function to run every 5 minutes
SELECT cron.schedule(
  'event-reminders-check',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://dnzpfbcbfwpfczduqsag.supabase.co/functions/v1/check-reminders',
    headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRuenBmYmNiZndwZmN6ZHVxc2FnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4ODM3NDcsImV4cCI6MjA4MDQ1OTc0N30.7a1GE0NBObSdeeVYTJzPjQEdKwUEiCqhYz9ob9Sy6W8", "Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- View scheduled jobs
SELECT * FROM cron.job;

-- To remove the job (if needed):
-- SELECT cron.unschedule('event-reminders-check');
