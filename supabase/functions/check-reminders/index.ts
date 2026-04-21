// Supabase Edge Function: check-reminders
// Scheduled function to send 30-minute event reminder notifications

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        console.log("🔔 Checking for events starting in ~30 minutes...");

        // Get current time and calculate 30-minute window
        const now = new Date();
        const in25Min = new Date(now.getTime() + 25 * 60 * 1000);
        const in35Min = new Date(now.getTime() + 35 * 60 * 1000);

        // Find events starting in 25-35 minutes
        const { data: upcomingEvents, error: eventsError } = await supabase
            .from("events")
            .select("id, title, date, society_id")
            .gte("date", in25Min.toISOString())
            .lte("date", in35Min.toISOString())
            .eq("approval_status", "approved");

        if (eventsError) {
            throw new Error(`Failed to fetch events: ${eventsError.message}`);
        }

        console.log(`Found ${upcomingEvents?.length || 0} events in reminder window`);

        if (!upcomingEvents || upcomingEvents.length === 0) {
            return new Response(
                JSON.stringify({ success: true, message: "No events in reminder window", sent: 0 }),
                { headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        let totalSent = 0;

        for (const event of upcomingEvents) {
            console.log(`Processing event: ${event.title} (${event.id})`);

            // Get registered users for this event - using 'registrations' table
            const { data: registrations, error: regError } = await supabase
                .from("registrations")
                .select("user_id, users!inner(id, fcm_token, name)")
                .eq("event_id", event.id);

            if (regError) {
                console.error(`Failed to get registrations for ${event.id}: ${regError.message}`);
                continue;
            }

            console.log(`Found ${registrations?.length || 0} registrations`);

            for (const reg of registrations || []) {
                const user = reg.users as { id: string; fcm_token: string | null; name: string };

                if (!user?.fcm_token) {
                    console.log(`No FCM token for user ${user?.id}`);
                    continue;
                }

                // Check if reminder already sent
                const { data: existingReminder } = await supabase
                    .from("event_reminders_sent")
                    .select("id")
                    .eq("event_id", event.id)
                    .eq("user_id", user.id)
                    .eq("reminder_type", "30min")
                    .single();

                if (existingReminder) {
                    console.log(`Reminder already sent for user ${user.id}, event ${event.id}`);
                    continue;
                }

                // Send notification via send-notification function
                try {
                    const notifResponse = await fetch(
                        `${supabaseUrl}/functions/v1/send-notification`,
                        {
                            method: "POST",
                            headers: {
                                "Authorization": `Bearer ${supabaseServiceKey}`,
                                "Content-Type": "application/json",
                            },
                            body: JSON.stringify({
                                title: "⏰ Event Starting Soon!",
                                body: `Your event "${event.title}" starts in 30 minutes. Come before you're late!`,
                                token: user.fcm_token,
                                data: { eventId: event.id, type: "reminder" },
                            }),
                        }
                    );

                    const notifResult = await notifResponse.json();
                    console.log(`Notification result for ${user.id}:`, notifResult);

                    if (notifResult.success) {
                        // Record that reminder was sent
                        await supabase.from("event_reminders_sent").insert({
                            event_id: event.id,
                            user_id: user.id,
                            reminder_type: "30min",
                        });
                        totalSent++;
                        console.log(`✅ Reminder sent to ${user.name} for ${event.title}`);
                    }
                } catch (notifError) {
                    console.error(`Failed to send notification: ${notifError}`);
                }
            }
        }

        console.log(`🔔 Total reminders sent: ${totalSent}`);

        return new Response(
            JSON.stringify({ success: true, eventCount: upcomingEvents.length, sent: totalSent }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    } catch (error) {
        console.error("Error:", error.message);
        return new Response(
            JSON.stringify({ success: false, error: error.message }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
        );
    }
});
