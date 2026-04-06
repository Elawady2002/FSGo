import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/trip_management/data/models/trip_session_model.dart';

/// Subscribes to Supabase Realtime changes on the `bookings` table
/// for a given schedule + date, emitting updated [SeatCounter] values.
class RealtimeSeatService {
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  RealtimeSeatService(this._client);

  /// Start listening for boarding count changes.
  ///
  /// [scheduleId]  — the schedule being monitored
  /// [date]        — the trip date
  /// [onUpdate]    — called with the new [SeatCounter] on every change
  void subscribe({
    required String scheduleId,
    required DateTime date,
    required void Function(SeatCounter counter) onUpdate,
  }) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    _channel = _client
        .channel('seat_counter_${scheduleId}_$dateStr')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'schedule_id',
            value: scheduleId,
          ),
          callback: (_) async {
            final counter = await _fetchCounter(scheduleId, dateStr);
            onUpdate(counter);
          },
        )
        .subscribe();
  }

  /// Fetch current scanned / capacity counts from Supabase.
  Future<SeatCounter> _fetchCounter(
    String scheduleId,
    String dateStr,
  ) async {
    // Total capacity from schedule
    final scheduleRow = await _client
        .from('schedules')
        .select('capacity')
        .eq('id', scheduleId)
        .single();
    final capacity = (scheduleRow['capacity'] as num?)?.toInt() ?? 0;

    // Scanned = sum of passenger_count where boarding_status = 'boarded'
    final boardedRows = await _client
        .from('bookings')
        .select('passenger_count')
        .eq('schedule_id', scheduleId)
        .eq('boarding_status', 'boarded')
        .gte('booking_date', dateStr)
        .lt('booking_date', _nextDay(dateStr));

    final scanned = (boardedRows as List).fold<int>(
      0,
      (sum, row) => sum + ((row['passenger_count'] as num?)?.toInt() ?? 1),
    );

    return SeatCounter(scanned: scanned, capacity: capacity);
  }

  /// Fetch the current counter once (no subscription).
  Future<SeatCounter> fetchOnce({
    required String scheduleId,
    required DateTime date,
  }) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _fetchCounter(scheduleId, dateStr);
  }

  void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
  }

  String _nextDay(String dateStr) {
    final d = DateTime.parse(dateStr).add(const Duration(days: 1));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
