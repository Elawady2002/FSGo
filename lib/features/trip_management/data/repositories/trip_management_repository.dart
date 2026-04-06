import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_session_model.dart';

/// Handles trip lifecycle operations (start, close) against Supabase.
class TripManagementRepository {
  final SupabaseClient _client;

  TripManagementRepository(this._client);

  /// Fetch the current trip status for a schedule on a date.
  Future<TripStatus> getTripStatus({
    required String scheduleId,
    required DateTime date,
  }) async {
    final dateStr = _fmt(date);
    final rows = await _client
        .from('trip_sessions')
        .select('status')
        .eq('schedule_id', scheduleId)
        .eq('date', dateStr)
        .limit(1);

    if ((rows as List).isEmpty) return TripStatus.scheduled;
    return TripStatus.fromJson(rows.first['status'] as String? ?? 'scheduled');
  }

  /// Start the trip:
  /// 1. Upserts a `trip_sessions` row with status = `in_progress`.
  /// 2. Calls the Supabase RPC `process_no_show_refunds` which closes
  ///    unboarded bookings and refunds the fare (not the commission).
  Future<void> startTrip({
    required String scheduleId,
    required String driverId,
    required DateTime date,
  }) async {
    final dateStr = _fmt(date);

    // Upsert the trip session row
    await _client.from('trip_sessions').upsert({
      'schedule_id': scheduleId,
      'driver_id': driverId,
      'date': dateStr,
      'status': 'in_progress',
    }, onConflict: 'schedule_id,date');

    // Trigger no-show refund RPC (server-side logic)
    await _client.rpc('process_no_show_refunds', params: {
      'p_schedule_id': scheduleId,
      'p_date': dateStr,
    });
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
