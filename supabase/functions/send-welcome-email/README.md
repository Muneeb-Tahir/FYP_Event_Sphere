# Welcome Email Setup Guide

## 1. Get Resend API Key (Free)

1. Go to [resend.com](https://resend.com) and sign up
2. Create an API key at Dashboard → API Keys
3. Save the API key (starts with `re_`)

## 2. Deploy the Edge Function

```bash
# Install Supabase CLI if not installed
npm install -g supabase

# Login to Supabase
supabase login

# Link your project (use your project ref)
supabase link --project-ref dnzpfbcbfwpfczduqsag

# Set the Resend API key as secret
supabase secrets set RESEND_API_KEY=re_YOUR_API_KEY_HERE

# Deploy the function
supabase functions deploy send-welcome-email
```

## 3. Run the Database Trigger SQL

1. Go to Supabase Dashboard → SQL Editor
2. Open `supabase/welcome_email_trigger.sql`
3. Run the SQL

## 4. Test It!

1. Create a new account in your app
2. Check the email inbox for the welcome email
3. Check Edge Function logs: Supabase Dashboard → Edge Functions → send-welcome-email → Logs

## Troubleshooting

- **No email received?** Check Edge Function logs for errors
- **pg_net error?** Enable the extension: `CREATE EXTENSION pg_net;`
- **Resend error?** Verify your API key is set correctly

## Customization

Edit `supabase/functions/send-welcome-email/index.ts` to customize:
- Email subject
- Email HTML template
- "From" address (use your verified domain in Resend)
