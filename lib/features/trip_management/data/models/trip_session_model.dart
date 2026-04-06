import 'package:equatable/equatable.dart';

/// Status of a trip instance.
enum TripStatus {
  scheduled,
  in_progress,
  completed,
  cancelled;

  String toJson() => name;

  static TripStatus fromJson(String value) {
    return TripStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => TripStatus.scheduled,
    );
  }

  String get label {
    switch (this) {
      case TripStatus.scheduled:
        return 'مجدول';
      case TripStatus.in_progress:
        return 'جارٍ';
      case TripStatus.completed:
        return 'مكتمل';
      case TripStatus.cancelled:
        return 'ملغي';
    }
  }
}

/// Live seat counter for a trip instance.
class SeatCounter extends Equatable {
  final int scanned;
  final int capacity;

  const SeatCounter({required this.scanned, required this.capacity});

  int get remaining => capacity - scanned;
  double get fraction => capacity > 0 ? scanned / capacity : 0;

  /// Display label e.g. "7 / 14"
  String get label => '$scanned / $capacity';

  SeatCounter copyWith({int? scanned, int? capacity}) => SeatCounter(
        scanned: scanned ?? this.scanned,
        capacity: capacity ?? this.capacity,
      );

  @override
  List<Object?> get props => [scanned, capacity];
}

/// Trip session — maps to a `schedules` row for a given date.
class TripSessionModel extends Equatable {
  final String scheduleId;
  final DateTime date;
  final String driverId;
  final TripStatus status;
  final SeatCounter seatCounter;

  const TripSessionModel({
    required this.scheduleId,
    required this.date,
    required this.driverId,
    required this.status,
    required this.seatCounter,
  });

  factory TripSessionModel.fromJson(Map<String, dynamic> json) {
    return TripSessionModel(
      scheduleId: json['schedule_id'] as String,
      date: DateTime.parse(json['date'] as String),
      driverId: json['driver_id'] as String,
      status: TripStatus.fromJson(json['status'] as String? ?? 'scheduled'),
      seatCounter: SeatCounter(
        scanned: (json['scanned_count'] as num?)?.toInt() ?? 0,
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  TripSessionModel copyWith({
    TripStatus? status,
    SeatCounter? seatCounter,
  }) =>
      TripSessionModel(
        scheduleId: scheduleId,
        date: date,
        driverId: driverId,
        status: status ?? this.status,
        seatCounter: seatCounter ?? this.seatCounter,
      );

  @override
  List<Object?> get props => [scheduleId, date, driverId, status, seatCounter];
}
