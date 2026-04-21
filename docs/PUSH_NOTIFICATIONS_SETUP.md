# Push Notifications Setup Guide

## 1. Firebase Setup (Already Done)
Your app already has Firebase configured with `google-services.json` and FCM dependencies.

## 2. Supabase Database Setup

Run this SQL in Supabase SQL Editor:
```sql
-- Add fcm_token column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
```

Or for a separate tokens table, run: `supabase/create_user_tokens_table.sql`

## 3. Deploy Supabase Edge Function

### Install Supabase CLI (if not installed)
```bash
npm install -g supabase
```

### Login and link project
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

### Deploy the function
```bash
cd d:\FYP\event_sphere_2(FYP)\event_sphere
supabase functions deploy send-notification
```

### Set FCM Server Key
Get your FCM Server Key from Firebase Console → Project Settings → Cloud Messaging → Server key

```bash
supabase secrets set FCM_SERVER_KEY=YOUR_SERVER_KEY_HERE
```

## 4. Test Push Notifications

1. Run the app: `flutter run`
2. Create a new event
3. All users subscribed to `all_users` topic will receive a push notification

## Architecture Summary

| Component | Technology |
|-----------|------------|
| Push notifications (app closed) | Firebase Cloud Messaging |
| Trigger from backend | Supabase Edge Functions |
| Store tokens | users.fcm_token column |
| Topic subscriptions | FCM Topics (all_users, society_*) |

## Available Notification Methods

```dart
// Notify all users about new event
NotificationService.notifyNewEvent(eventName, societyName, eventId);

// Notify specific user
NotificationService.notifyUser(userId, title, body);

// Notify society members
NotificationService.notifySocietyMembers(societyId, title, body);

// Subscribe user to society updates
NotificationService.subscribeToSociety(societyId);
```
