import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger_service.dart';

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in the background isolate
  LoggerService.info(
    'Background FCM: ${message.notification?.title} — ${message.data}',
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  /// Call once after Supabase.initialize() in main()
  Future<void> initialize() async {
    // ── 1. Initialize Firebase ─────────────────────────────────────
    // SETUP REQUIRED:
    //   Android: place google-services.json  → driver/android/app/
    //   iOS:     place GoogleService-Info.plist → driver/ios/Runner/
    //   Then run: flutter pub get
    try {
      await Firebase.initializeApp();
    } catch (e) {
      LoggerService.warning(
        'Firebase not configured yet. Push notifications disabled. '
        'Add google-services.json (Android) and GoogleService-Info.plist (iOS).',
      );
      return;
    }

    // ── 2. Register background handler ─────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // ── 3. Request permission (iOS / Android 13+) ──────────────────
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    LoggerService.info(
        'FCM permission: ${settings.authorizationStatus.name}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // ── 4. Get & save device token ─────────────────────────────────
    await _refreshAndSaveToken();

    // Token may rotate — keep it updated
    _fcm.onTokenRefresh.listen(_saveToken);

    // ── 5. Foreground messages ─────────────────────────────────────
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // ── 6. Notification tap (background → foreground) ──────────────
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // ── 7. iOS: show notifications while app is in foreground ──────
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    LoggerService.info('NotificationService initialized ✓');
  }

  // ── Token management ───────────────────────────────────────────

  Future<void> _refreshAndSaveToken() async {
    try {
      String? token;
      if (Platform.isIOS) {
        // iOS needs APNs token first
        await _fcm.getAPNSToken();
      }
      token = await _fcm.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      LoggerService.error('Failed to get FCM token', error: e);
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token}).eq('id', userId);
      LoggerService.info('FCM token saved for user $userId');
    } catch (e) {
      LoggerService.error('Failed to save FCM token', error: e);
    }
  }

  // ── Message handlers ───────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    LoggerService.info(
        'Foreground FCM: ${message.notification?.title}');
    // The system shows the notification automatically on Android 13+.
    // For older Android or custom banners, show a SnackBar/overlay here
    // using a global navigator key.
  }

  void _onNotificationTap(RemoteMessage message) {
    LoggerService.info('Notification tapped: ${message.data}');
    // Navigate to DutyDashboardPage when driver taps the notification.
    // Use a GlobalKey<NavigatorState> passed from main() if needed.
    final scheduleId = message.data['schedule_id'];
    if (scheduleId != null) {
      LoggerService.info('Navigate to schedule: $scheduleId');
      // navigatorKey.currentState?.push(...)
    }
  }

  /// Call on logout to clean up the token from DB
  Future<void> clearToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('users')
        .update({'fcm_token': null}).eq('id', userId);
    await _fcm.deleteToken();
  }
}
