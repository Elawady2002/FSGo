// Supabase Edge Function: notify-driver
// Triggered by a Supabase Database Webhook on schedules UPDATE
//
// SETUP (in Supabase Dashboard):
//   Database → Webhooks → Create a new hook
//   Table: schedules | Events: UPDATE
//   URL: https://<project-ref>.supabase.co/functions/v1/notify-driver
//   HTTP Method: POST
//   Headers: Authorization: Bearer <service-role-key>
//
// SECRETS (supabase secrets set --env-file .env.supabase):
//   FCM_SERVER_KEY = your Firebase Cloud Messaging server key
//                   (Firebase Console → Project Settings → Cloud Messaging → Server key)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

serve(async (req: Request) => {
  try {
    const body = await req.json();

    // Supabase webhook payload: { type, table, record, old_record }
    const record = body.record as Record<string, unknown>;
    const oldRecord = body.old_record as Record<string, unknown>;

    // Only fire when driver_id is newly set (was null, now has value)
    const newDriverId = record?.driver_id as string | null;
    const oldDriverId = oldRecord?.driver_id as string | null;
    const isApproved = record?.is_approved as boolean;

    if (!newDriverId || newDriverId === oldDriverId || !isApproved) {
      return new Response(
        JSON.stringify({ skipped: true, reason: "no new driver assignment" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    // Fetch driver's FCM token
    const { data: driver, error: driverErr } = await supabase
      .from("users")
      .select("fcm_token, full_name")
      .eq("id", newDriverId)
      .single();

    if (driverErr || !driver?.fcm_token) {
      console.warn("No FCM token for driver:", newDriverId);
      return new Response(
        JSON.stringify({ skipped: true, reason: "no fcm token" }),
        { status: 200 },
      );
    }

    const origin = record.origin as string ?? "";
    const destination = record.destination as string ?? "";
    const departureTime = record.departure_time as string ?? "";
    const scheduleId = record.id as string;

    // Send FCM notification via legacy HTTP API
    const fcmPayload = {
      to: driver.fcm_token,
      priority: "high",
      notification: {
        title: "مهمة جديدة 🚗",
        body: `رحلة ${origin} → ${destination} الساعة ${departureTime}`,
        sound: "default",
      },
      data: {
        schedule_id: scheduleId,
        type: "new_assignment",
        origin,
        destination,
        departure_time: departureTime,
      },
    };

    const fcmResponse = await fetch(
      "https://fcm.googleapis.com/fcm/send",
      {
        method: "POST",
        headers: {
          "Authorization": `key=${FCM_SERVER_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmPayload),
      },
    );

    const fcmResult = await fcmResponse.json();
    console.log("FCM result:", JSON.stringify(fcmResult));

    return new Response(
      JSON.stringify({ success: true, fcm: fcmResult }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("notify-driver error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
