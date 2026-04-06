/// Represents the current activity status of a driver
enum DriverActivityStatus {
  /// Driver is online and available for duty
  online,

  /// Driver is offline or not on active shift
  offline,

  /// Driver is currently on a trip
  onTrip,

  /// Driver is on break
  onBreak;

  /// Get the Arabic label for this status
  String get label {
    switch (this) {
      case DriverActivityStatus.online:
        return 'متاح';
      case DriverActivityStatus.offline:
        return 'خارج الخدمة';
      case DriverActivityStatus.onTrip:
        return 'في رحلة';
      case DriverActivityStatus.onBreak:
        return 'في استراحة';
    }
  }

  /// Get the color indicator for this status
  int get colorHex {
    switch (this) {
      case DriverActivityStatus.online:
        return 0xFF4CAF50; // Green
      case DriverActivityStatus.offline:
        return 0xFF9E9E9E; // Grey
      case DriverActivityStatus.onTrip:
        return 0xFFC9D420; // Lime (brand color)
      case DriverActivityStatus.onBreak:
        return 0xFFFF9800; // Orange
    }
  }
}
