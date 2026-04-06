import 'package:hive_flutter/hive_flutter.dart';
import '../models/trip_session_model.dart';

/// Hive-based local cache for TripSession state.
///
/// Allows the driver dashboard to display the last-known trip status
/// and seat count when the device is briefly offline.
class TripCacheService {
  static const String _boxName = 'trip_sessions';

  static Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  String _key(String scheduleId, DateTime date) {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${scheduleId}_$d';
  }

  /// Persist the current [TripSessionModel] locally.
  Future<void> save(TripSessionModel session) async {
    final key = _key(session.scheduleId, session.date);
    await _box.put(key, {
      'schedule_id': session.scheduleId,
      'date': session.date.toIso8601String(),
      'driver_id': session.driverId,
      'status': session.status.toJson(),
      'scanned': session.seatCounter.scanned,
      'capacity': session.seatCounter.capacity,
      'cached_at': DateTime.now().toIso8601String(),
    });
  }

  /// Load a cached [TripSessionModel] or null if not cached.
  TripSessionModel? load(String scheduleId, DateTime date) {
    final raw = _box.get(_key(scheduleId, date));
    if (raw == null) return null;
    return TripSessionModel(
      scheduleId: raw['schedule_id'] as String,
      date: DateTime.parse(raw['date'] as String),
      driverId: raw['driver_id'] as String,
      status: TripStatus.fromJson(raw['status'] as String),
      seatCounter: SeatCounter(
        scanned: raw['scanned'] as int,
        capacity: raw['capacity'] as int,
      ),
    );
  }

  /// Remove stale entries older than 48 hours.
  Future<void> evictStale() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    final staleKeys = <dynamic>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      final cachedAt = DateTime.tryParse(raw['cached_at'] as String? ?? '');
      if (cachedAt != null && cachedAt.isBefore(cutoff)) {
        staleKeys.add(key);
      }
    }
    await _box.deleteAll(staleKeys);
  }
}
