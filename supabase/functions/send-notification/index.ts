// Supabase Edge Function: send-notification
// Sends push notifications via Firebase Cloud Messaging V1 API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface NotificationPayload {
  title: string;
  body: string;
  token?: string;
  userId?: string;
  topic?: string;
  data?: Record<string, string>;
}

// Base64URL encode
function base64UrlEncode(str: string): string {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

// Get OAuth2 access token using service account
async function getAccessToken(): Promise<string> {
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL")!;
  const privateKeyPem = Deno.env.get("FIREBASE_PRIVATE_KEY")!.replace(/\\n/g, "\n");

  const now = Math.floor(Date.now() / 1000);

  // JWT header and payload
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: clientEmail,
    sub: clientEmail,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(payload));
  const unsignedToken = `${headerB64}.${payloadB64}`;

  // Import private key
  const pemContents = privateKeyPem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  // Sign the token
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const signatureB64 = base64UrlEncode(String.fromCharCode(...new Uint8Array(signature)));
  const jwt = `${unsignedToken}.${signatureB64}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenResponse.json();

  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }

  return tokenData.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") || "event-sphere01";
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const payload: NotificationPayload = await req.json();
    const { title, body, token, userId, topic, data } = payload;

    console.log("Received notification request:", { title, body, topic, userId });

    if (!title || !body) {
      throw new Error("title and body are required");
    }

    let targetToken = token;

    // If userId provided, fetch their FCM token
    if (userId && !targetToken) {
      const { data: userData, error } = await supabase
        .from("users")
        .select("fcm_token")
        .eq("id", userId)
        .single();

      if (error || !userData?.fcm_token) {
        console.log("No FCM token found for user:", userId);
        throw new Error(`No FCM token found for user: ${userId}`);
      }
      targetToken = userData.fcm_token;
    }

    // Get OAuth2 access token
    console.log("Getting access token...");
    const accessToken = await getAccessToken();
    console.log("Access token obtained successfully");

    // Build FCM V1 message
    let fcmPayload: Record<string, unknown>;

    if (topic) {
      fcmPayload = {
        message: {
          topic: topic,
          notification: { title, body },
          data: data || {},
        },
      };
    } else if (targetToken) {
      fcmPayload = {
        message: {
          token: targetToken,
          notification: { title, body },
          data: data || {},
        },
      };
    } else {
      throw new Error("Either token, userId, or topic must be provided");
    }

    console.log("Sending FCM request to project:", projectId);

    // Send via FCM V1 API
    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmPayload),
      }
    );

    const fcmResult = await fcmResponse.json();
    console.log("FCM response:", fcmResult);

    return new Response(
      JSON.stringify({ success: fcmResponse.ok, result: fcmResult }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: fcmResponse.ok ? 200 : 400,
      }
    );
  } catch (error) {
    console.error("Error:", error.message);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
