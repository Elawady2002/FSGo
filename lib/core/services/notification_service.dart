// ignore_for_file: avoid_print

/// Push notification service — Firebase Cloud Messaging (FCM)
///
/// SETUP REQUIRED before this activates:
/// 1. Create a Firebase project at console.firebase.google.com
/// 2. Add Android (com.abdallah.fielsekkia.driver) & iOS apps in Firebase
/// 3. Download google-services.json → driver/android/app/
/// 4. Download GoogleService-Info.plist → driver/ios/Runner/
/// 5. Add firebase_core + firebase_messaging to pubspec.yaml
/// 6. Run: dart run build_runner build
/// 7. Uncomment the imports and code below
///
/// Supabase Webhook to trigger FCM:
/// - Table: schedules | Event: UPDATE | When: driver_id changes
/// - Payload: POST to your Edge Function URL
/// - Edge Function uses admin FCM SDK to send to driver's device token

class NotificationService {
  static NotificationService? _instance;
  NotificationService._();
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  // FCM device token for this device — saved to users table after init
  String? _deviceToken;
  String? get deviceToken => _deviceToken;

  /// Call once at app startup (after Supabase.initialize)
  Future<void> initialize() async {
    // TODO: Uncomment after adding firebase_core + firebase_messaging
    //
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    //
    // final messaging = FirebaseMessaging.instance;
    //
    // // Request permission (iOS)
    // await messaging.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );
    //
    // _deviceToken = await messaging.getToken();
    // if (_deviceToken != null) {
    //   await _saveTokenToDb(_deviceToken!);
    // }
    //
    // // Handle foreground messages
    // FirebaseMessaging.onMessage.listen(_onMessage);
    //
    // // Handle notification taps when app is in background
    // FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    print('[NotificationService] Firebase not yet configured — see setup instructions in this file.');
  }

  /// Save FCM token to Supabase users table for server-side targeting
  Future<void> _saveTokenToDb(String token) async {
    // TODO: Uncomment after setup
    // final userId = Supabase.instance.client.auth.currentUser?.id;
    // if (userId == null) return;
    // await Supabase.instance.client
    //     .from('users')
    //     .update({'fcm_token': token})
    //     .eq('id', userId);
  }

  void _onMessage(dynamic message) {
    // TODO: Show in-app banner using top_notification.dart widget
    print('[NotificationService] Foreground message: $message');
  }

  void _onMessageOpenedApp(dynamic message) {
    // TODO: Navigate to DutyDashboardPage when driver taps notification
    print('[NotificationService] Notification tapped: $message');
  }
}

// ── Supabase Edge Function template (deploy separately) ────────
//
// File: supabase/functions/notify-driver/index.ts
//
// import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
//
// serve(async (req) => {
//   const { record } = await req.json();
//   if (!record.driver_id || !record.is_approved) {
//     return new Response("skip", { status: 200 });
//   }
//
//   // Fetch driver's FCM token from users table
//   const { data: driver } = await supabaseAdmin
//     .from("users")
//     .select("fcm_token")
//     .eq("id", record.driver_id)
//     .single();
//
//   if (!driver?.fcm_token) return new Response("no token", { status: 200 });
//
//   // Send via FCM HTTP v1 API
//   const response = await fetch("https://fcm.googleapis.com/v1/projects/YOUR_PROJECT/messages:send", {
//     method: "POST",
//     headers: {
//       "Authorization": `Bearer ${Deno.env.get("FCM_ACCESS_TOKEN")}`,
//       "Content-Type": "application/json",
//     },
//     body: JSON.stringify({
//       message: {
//         token: driver.fcm_token,
//         notification: {
//           title: "مهمة جديدة",
//           body: `رحلة ${record.origin} → ${record.destination} في ${record.departure_time}`,
//         },
//         data: { schedule_id: record.id },
//       },
//     }),
//   });
//
//   return new Response(await response.text(), { status: response.status });
// });
