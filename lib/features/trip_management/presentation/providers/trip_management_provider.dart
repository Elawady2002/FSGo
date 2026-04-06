import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/trip_session_model.dart';
import '../../data/repositories/trip_management_repository.dart';
import '../../data/services/trip_cache_service.dart';
import '../../../../core/services/realtime_seat_service.dart';
import '../../../coordinator/presentation/providers/driver_duty_provider.dart';

// ── DI ────────────────────────────────────────────────────────

final tripManagementRepositoryProvider =
    Provider<TripManagementRepository>((ref) {
  return TripManagementRepository(Supabase.instance.client);
});

final realtimeSeatServiceProvider = Provider<RealtimeSeatService>((ref) {
  return RealtimeSeatService(Supabase.instance.client);
});

// ── Trip Session State ─────────────────────────────────────────

class TripSessionState {
  final TripStatus status;
  final SeatCounter seatCounter;
  final bool isStarting;
  final String? error;

  const TripSessionState({
    this.status = TripStatus.scheduled,
    this.seatCounter = const SeatCounter(scanned: 0, capacity: 0),
    this.isStarting = false,
    this.error,
  });

  TripSessionState copyWith({
    TripStatus? status,
    SeatCounter? seatCounter,
    bool? isStarting,
    String? error,
  }) =>
      TripSessionState(
        status: status ?? this.status,
        seatCounter: seatCounter ?? this.seatCounter,
        isStarting: isStarting ?? this.isStarting,
        error: error,
      );
}

// ── TripSession Notifier ───────────────────────────────────────

class TripSessionNotifier extends StateNotifier<TripSessionState> {
  final TripManagementRepository _repo;
  final RealtimeSeatService _realtime;
  final ManifestKey _key;
  final String _driverId;

  final TripCacheService _cache = TripCacheService();

  TripSessionNotifier(
    this._repo,
    this._realtime,
    this._key,
    this._driverId,
  ) : super(const TripSessionState()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Serve cached state immediately (offline-first)
    final cached = _cache.load(_key.scheduleId, _key.date);
    if (cached != null) {
      state = state.copyWith(
        status: cached.status,
        seatCounter: cached.seatCounter,
      );
    }

    // 2. Fetch live state from Supabase
    try {
      final status = await _repo.getTripStatus(
        scheduleId: _key.scheduleId,
        date: _key.date,
      );
      final counter = await _realtime.fetchOnce(
        scheduleId: _key.scheduleId,
        date: _key.date,
      );
      state = state.copyWith(status: status, seatCounter: counter);
      _persist(status, counter);
    } catch (_) {
      // Network unavailable — cached state remains shown
    }

    // 3. Subscribe to live realtime updates
    _realtime.subscribe(
      scheduleId: _key.scheduleId,
      date: _key.date,
      onUpdate: (counter) {
        if (!mounted) return;
        state = state.copyWith(seatCounter: counter);
        _persist(state.status, counter);
      },
    );
  }

  void _persist(TripStatus status, SeatCounter counter) {
    _cache.save(TripSessionModel(
      scheduleId: _key.scheduleId,
      date: _key.date,
      driverId: _driverId,
      status: status,
      seatCounter: counter,
    ));
  }

  Future<void> startTrip() async {
    if (state.status != TripStatus.scheduled) return;
    state = state.copyWith(isStarting: true, error: null);
    try {
      await _repo.startTrip(
        scheduleId: _key.scheduleId,
        driverId: _driverId,
        date: _key.date,
      );
      final newStatus = TripStatus.in_progress;
      state = state.copyWith(status: newStatus, isStarting: false);
      _persist(newStatus, state.seatCounter);
    } catch (e) {
      state = state.copyWith(
        isStarting: false,
        error: 'فشل تشغيل الرحلة: ${e.toString()}',
      );
    }
  }

  @override
  void dispose() {
    _realtime.unsubscribe();
    super.dispose();
  }
}

final tripSessionProvider = StateNotifierProvider.family<
    TripSessionNotifier, TripSessionState, ({ManifestKey key, String driverId})>(
  (ref, args) {
    final repo = ref.watch(tripManagementRepositoryProvider);
    final realtime = ref.watch(realtimeSeatServiceProvider);
    return TripSessionNotifier(repo, realtime, args.key, args.driverId);
  },
);
