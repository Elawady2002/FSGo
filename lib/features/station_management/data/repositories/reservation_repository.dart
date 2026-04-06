import 'package:supabase_flutter/supabase_flutter.dart';

/// Aggregated reservation row per destination for a date.
class ReservationSummary {
  final String destination;
  final int totalSeats;

  const ReservationSummary({
    required this.destination,
    required this.totalSeats,
  });
}

/// Fetches and aggregates future booking counts for fleet planning.
class ReservationRepository {
  final SupabaseClient _client;

  ReservationRepository(this._client);

  /// Returns the total reserved seats grouped by destination for [date].
  Future<List<ReservationSummary>> getReservationsForDate(
    DateTime date,
  ) async {
    final dateStr = _fmt(date);

    // Join bookings → schedules to get destination
    final rows = await _client
        .from('bookings')
        .select('passenger_count, schedule:schedule_id(destination)')
        .inFilter('status', ['pending', 'confirmed'])
        .gte('booking_date', dateStr)
        .lt('booking_date', _nextDay(dateStr));

    // Aggregate in Dart
    final Map<String, int> totals = {};
    for (final row in (rows as List)) {
      final scheduleJson = row['schedule'] as Map<String, dynamic>?;
      final dest = scheduleJson?['destination'] as String? ?? 'غير محدد';
      final count = (row['passenger_count'] as num?)?.toInt() ?? 1;
      totals[dest] = (totals[dest] ?? 0) + count;
    }

    return totals.entries
        .map((e) => ReservationSummary(destination: e.key, totalSeats: e.value))
        .toList()
      ..sort((a, b) => b.totalSeats.compareTo(a.totalSeats));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _nextDay(String dateStr) {
    final d = DateTime.parse(dateStr).add(const Duration(days: 1));
    return _fmt(d);
  }
}
