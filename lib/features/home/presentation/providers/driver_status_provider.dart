import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/driver_activity_status.dart';

class DriverStatusNotifier extends StateNotifier<DriverActivityStatus> {
  DriverStatusNotifier() : super(DriverActivityStatus.offline);

  void setOnline() => state = DriverActivityStatus.online;
  void setOffline() => state = DriverActivityStatus.offline;
  void setOnTrip() => state = DriverActivityStatus.onTrip;
  void setOnBreak() => state = DriverActivityStatus.onBreak;

  void updateStatusBasedOnTrips(bool hasTrips) {
    state = hasTrips ? DriverActivityStatus.online : DriverActivityStatus.offline;
  }

  bool get isAvailable => state == DriverActivityStatus.online;
  bool get isOffline => state == DriverActivityStatus.offline;
}

final driverStatusProvider =
    StateNotifierProvider<DriverStatusNotifier, DriverActivityStatus>(
  (_) => DriverStatusNotifier(),
);
