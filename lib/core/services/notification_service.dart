import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger_service.dart';

/// Push-notification-free notification system.
///
/// Architecture:
///   Supabase Realtime ──► schedules table UPDATE event
///       └─► driver_id = current user  ──► flutter_local_notifications
///
/// No Firebase. No external push service.
/// Works when the app is open (foreground/background on same device session).
/// For true background push (app killed), a Supabase Edge Function + APNs
/// direct integration would be needed — but Realtime covers the key use case.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  RealtimeChannel? _channel;
  bool _initialized = false;

  // ── Init ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    await _initLocalNotifications();
    _initialized = true;
    LoggerService.info('NotificationService initialized (Supabase Realtime)');
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // ── Realtime subscription ──────────────────────────────────────

  /// Call after user logs in — subscribes to schedule assignments for this driver.
  Future<void> subscribeToAssignments(String driverId) async {
    if (!_initialized) await initialize();

    // Cancel any previous subscription
    await _channel?.unsubscribe();

    _channel = Supabase.instance.client
        .channel('driver-assignments-$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'schedules',
          callback: (payload) => _onScheduleUpdate(payload, driverId),
        )
        .subscribe();

    LoggerService.info('Subscribed to schedule assignments for driver $driverId');
  }

  /// Call on logout.
  Future<void> unsubscribe() async {
    await _channel?.unsubscribe();
    _channel = null;
    LoggerService.info('Unsubscribed from schedule assignments');
  }

  // ── Event handlers ─────────────────────────────────────────────

  void _onScheduleUpdate(PostgresChangePayload payload, String driverId) {
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    final newDriverId = newRecord['driver_id'] as String?;
    final oldDriverId = oldRecord['driver_id'] as String?;
    final isApproved = newRecord['is_approved'] as bool? ?? false;

    // Only notify when driver_id is newly set to this driver
    if (newDriverId != driverId || newDriverId == oldDriverId || !isApproved) {
      return;
    }

    final origin = newRecord['origin'] as String? ?? '';
    final destination = newRecord['destination'] as String? ?? '';
    final time = newRecord['departure_time'] as String? ?? '';
    final scheduleId = newRecord['id'] as String? ?? '';

    LoggerService.info('New assignment for driver $driverId: $origin → $destination');

    _showLocalNotification(
      id: scheduleId.hashCode.abs(),
      title: 'مهمة جديدة 🚗',
      body: 'رحلة $origin → $destination الساعة $time',
      payload: scheduleId,
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'driver_assignments',
      'تعيينات السائق',
      channelDescription: 'إشعارات مهام الرحلات الجديدة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // scheduleId is in response.payload
    // Navigate to DutyDashboardPage via a global navigator key if needed.
    final scheduleId = response.payload;
    LoggerService.info('Notification tapped → schedule: $scheduleId');
  }

  // ── Manual trigger (for testing) ──────────────────────────────

  Future<void> showTestNotification() async {
    await _showLocalNotification(
      id: 0,
      title: 'اختبار الإشعارات',
      body: 'الإشعارات تعمل بشكل صحيح ✓',
    );
  }
}
