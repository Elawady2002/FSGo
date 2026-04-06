import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../../domain/entities/passenger_entity.dart';

class DriverDutyDataSource {
  final SupabaseClient _client;

  DriverDutyDataSource(this._client);

  /// Fetch all approved schedules assigned to this driver
  Future<List<CoordinatorScheduleEntity>> getMyAssignedSchedules(
    String driverId,
  ) async {
    final response = await _client
        .from('schedules')
        .select()
        .eq('driver_id', driverId)
        .eq('is_approved', true)
        .eq('is_active', true)
        .order('departure_time');

    return (response as List).map((json) {
      return CoordinatorScheduleEntity(
        id: json['id'] as String,
        coordinatorId: json['coordinator_id'] as String? ?? '',
        origin: json['origin'] as String? ?? '',
        destination: json['destination'] as String? ?? '',
        departureTime: json['departure_time'] as String? ?? '',
        availableDays: List<String>.from(
          (json['available_days'] as List?) ?? [],
        ),
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0,
        adminMargin: (json['admin_margin'] as num?)?.toDouble() ?? 0,
        isApproved: true,
        isActive: true,
        driverId: driverId,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  /// Fetch the passenger manifest for a schedule on a specific date
  Future<List<PassengerEntity>> getPassengerManifest({
    required String scheduleId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Join bookings with users to get passenger names
    final response = await _client
        .from('bookings')
        .select('*, user:user_id(id, full_name, phone)')
        .eq('schedule_id', scheduleId)
        .gte('booking_date', dateStr)
        .lt('booking_date', _nextDayStr(date))
        .inFilter('status', ['pending', 'confirmed']);

    return (response as List).map((json) {
      final userJson = json['user'] as Map<String, dynamic>? ?? {};
      final isSubscriber = json['subscription_id'] != null;
      final boardingStr = json['boarding_status'] as String? ?? 'booked';

      return PassengerEntity(
        bookingId: json['id'] as String,
        userId: json['user_id'] as String,
        fullName: userJson['full_name'] as String? ?? 'مجهول',
        phone: userJson['phone'] as String? ?? '',
        paymentType: isSubscriber
            ? PassengerPaymentType.subscriber
            : PassengerPaymentType.cash,
        boardingStatus: boardingStr == 'boarded'
            ? PassengerBoardingStatus.boarded
            : PassengerBoardingStatus.booked,
        passengerCount: (json['passenger_count'] as num?)?.toInt() ?? 1,
        isLadies: json['is_ladies'] as bool? ?? false,
      );
    }).toList();
  }

  /// Mark a passenger as boarded
  Future<void> checkInPassenger(String bookingId) async {
    await _client
        .from('bookings')
        .update({'boarding_status': 'boarded'}).eq('id', bookingId);
  }

  String _nextDayStr(DateTime date) {
    final next = date.add(const Duration(days: 1));
    return '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
  }
}
