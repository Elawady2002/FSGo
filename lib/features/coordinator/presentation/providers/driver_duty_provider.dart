import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/driver_duty_data_source.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../../domain/entities/passenger_entity.dart';

// ── DI ────────────────────────────────────────────────────────

final driverDutyDataSourceProvider = Provider<DriverDutyDataSource>((ref) {
  return DriverDutyDataSource(Supabase.instance.client);
});

// ── Assigned Schedules ─────────────────────────────────────────

final driverAssignedSchedulesProvider =
    FutureProvider.family<List<CoordinatorScheduleEntity>, String>(
        (ref, driverId) async {
  final ds = ref.watch(driverDutyDataSourceProvider);
  return ds.getMyAssignedSchedules(driverId);
});

// ── Passenger Manifest ─────────────────────────────────────────

class ManifestKey {
  final String scheduleId;
  final DateTime date;
  ManifestKey(this.scheduleId, this.date);

  @override
  bool operator ==(Object other) =>
      other is ManifestKey &&
      other.scheduleId == scheduleId &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day;

  @override
  int get hashCode => Object.hash(scheduleId, date.year, date.month, date.day);
}

class ManifestState {
  final List<PassengerEntity> passengers;
  final bool isLoading;
  final String? error;

  const ManifestState({
    this.passengers = const [],
    this.isLoading = false,
    this.error,
  });

  ManifestState copyWith({
    List<PassengerEntity>? passengers,
    bool? isLoading,
    String? error,
  }) {
    return ManifestState(
      passengers: passengers ?? this.passengers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get boardedCount =>
      passengers.where((p) => p.isBoarded).length;
  int get totalSeats =>
      passengers.fold(0, (sum, p) => sum + p.passengerCount);
}

class ManifestNotifier extends StateNotifier<ManifestState> {
  final DriverDutyDataSource _dataSource;
  final String _scheduleId;
  final DateTime _date;

  ManifestNotifier(this._dataSource, this._scheduleId, this._date)
      : super(const ManifestState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final passengers = await _dataSource.getPassengerManifest(
        scheduleId: _scheduleId,
        date: _date,
      );
      state = state.copyWith(passengers: passengers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> checkIn(String bookingId) async {
    await _dataSource.checkInPassenger(bookingId);
    final updated = state.passengers.map((p) {
      if (p.bookingId == bookingId) {
        return PassengerEntity(
          bookingId: p.bookingId,
          userId: p.userId,
          fullName: p.fullName,
          phone: p.phone,
          paymentType: p.paymentType,
          boardingStatus: PassengerBoardingStatus.boarded,
          passengerCount: p.passengerCount,
          isLadies: p.isLadies,
        );
      }
      return p;
    }).toList();
    state = state.copyWith(passengers: updated);
  }
}

final manifestProvider =
    StateNotifierProvider.family<ManifestNotifier, ManifestState, ManifestKey>(
        (ref, key) {
  final ds = ref.watch(driverDutyDataSourceProvider);
  return ManifestNotifier(ds, key.scheduleId, key.date);
});
