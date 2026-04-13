// Supabase Edge Function: notify-driver
//
// NOTE: Push notifications are handled entirely via Supabase Realtime on the
// client side (flutter_local_notifications + onPostgresChanges subscription
// in NotificationService). No FCM or external push service is required.
//
// This file is kept as a placeholder in case server-side notification logic
// is needed in the future (e.g., for killed-app background push via APNs direct
// integration). For now it simply acknowledges the webhook and returns 200.

Deno.serve(async (_req: Request) => {
  return new Response(
    JSON.stringify({ ok: true, note: "Notifications handled via Supabase Realtime on client" }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
