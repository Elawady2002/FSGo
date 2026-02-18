enum TripType {
  departureOnly(50.0),
  returnOnly(50.0),
  roundTrip(80.0);

  final double price;

  const TripType(this.price);

  String get displayName {
    switch (this) {
      case TripType.departureOnly:
        return 'ذهاب فقط';
      case TripType.returnOnly:
        return 'عودة فقط';
      case TripType.roundTrip:
        return 'ذهاب وعودة';
    }
  }

  /// Convert enum to database format (snake_case)
  String toDbValue() {
    switch (this) {
      case TripType.departureOnly:
        return 'departure_only';
      case TripType.returnOnly:
        return 'return_only';
      case TripType.roundTrip:
        return 'round_trip';
    }
  }

  /// Get TripType from database value
  static TripType fromDbValue(String value) {
    switch (value) {
      case 'departure_only':
        return TripType.departureOnly;
      case 'return_only':
        return TripType.returnOnly;
      case 'round_trip':
        return TripType.roundTrip;
      default:
        return TripType.departureOnly;
    }
  }
}
