import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/trip_type.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/entities/university_entity.dart';
import '../../domain/entities/station_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/datasources/booking_data_source.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'booking_provider.g.dart';

// Booking Repository Provider
@riverpod
BookingRepository bookingRepository(BookingRepositoryRef ref) {
  final dataSource = BookingDataSourceImpl();
  // Watch auth provider to ensure repository is rebuilt when auth state changes
  final user = ref.watch(authProvider);

  return BookingRepositoryImpl(dataSource, () {
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  });
}

// User Bookings Provider
@riverpod
Future<List<BookingEntity>> userBookings(UserBookingsRef ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final result = await repository.getUserBookings();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (bookings) => bookings,
  );
}

// Upcoming Booking Provider
@riverpod
Future<BookingEntity?> upcomingBooking(UpcomingBookingRef ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final result = await repository.getUpcomingBooking();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (booking) => booking,
  );
}

@riverpod
class BookingState extends _$BookingState {
  @override
  BookingStateModel build() {
    return BookingStateModel(
      tripType: TripType.roundTrip, // Default to round trip
      selectedPlanIndex: 1, // Default to Monthly
      selectedDate: DateTime.now(),
      selectedDepartureTime: null,
      selectedReturnTime: null,
    );
  }

  void selectTripType(TripType tripType) {
    state = state.copyWith(tripType: tripType);
  }

  void selectPlan(int index) {
    state = state.copyWith(selectedPlanIndex: index);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void selectDepartureTime(String? time) {
    state = state.copyWith(selectedDepartureTime: time);
  }

  void selectReturnTime(String? time) {
    state = state.copyWith(selectedReturnTime: time);
  }

  void setLocationData({
    required CityEntity city,
    required UniversityEntity university,
    required StationEntity station,
  }) {
    state = state.copyWith(
      selectedCity: city,
      selectedUniversity: university,
      selectedStation: station,
    );
  }

  bool get isSameDayBookingAllowed {
    final now = DateTime.now();
    if (isSameDay(now, state.selectedDate)) {
      return now.hour < 7;
    }
    return true;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get isBookingComplete {
    // Must have required times based on trip type
    switch (state.tripType) {
      case TripType.departureOnly:
        return state.selectedDepartureTime != null;
      case TripType.returnOnly:
        return state.selectedReturnTime != null;
      case TripType.roundTrip:
        return state.selectedDepartureTime != null &&
            state.selectedReturnTime != null;
    }
  }

  double get totalPrice => state.tripType.price;

  Future<String?> createBooking(
    BookingRepository repository, {
    String? paymentProofImage,
    String? transferNumber,
  }) async {
    if (!isBookingComplete) {
      return 'يرجى إكمال جميع بيانات الحجز';
    }

    try {
      // Generate a temporary UUID for schedule_id
      // In a real app, this should come from the selected schedule
      const scheduleId = '00000000-0000-0000-0000-000000000000';

      final result = await repository.createBooking(
        scheduleId: scheduleId,
        bookingDate: state.selectedDate,
        tripType: state.tripType.toDbValue(),
        pickupStationId: state.selectedStation?.id,
        dropoffStationId: state.selectedStation?.id,
        departureTime: state.selectedDepartureTime,
        returnTime: state.selectedReturnTime,
        paymentProofImage: paymentProofImage,
        transferNumber: transferNumber,
        totalPrice: totalPrice,
      );

      return result.fold(
        (failure) => failure.message,
        (_) => null, // Success
      );
    } catch (e) {
      return 'حدث خطأ أثناء الحجز: $e';
    }
  }
}

class BookingStateModel {
  final TripType tripType;
  final int selectedPlanIndex;
  final DateTime selectedDate;
  final String? selectedDepartureTime;
  final String? selectedReturnTime;
  final CityEntity? selectedCity;
  final UniversityEntity? selectedUniversity;
  final StationEntity? selectedStation;

  BookingStateModel({
    required this.tripType,
    required this.selectedPlanIndex,
    required this.selectedDate,
    this.selectedDepartureTime,
    this.selectedReturnTime,
    this.selectedCity,
    this.selectedUniversity,
    this.selectedStation,
  });

  BookingStateModel copyWith({
    TripType? tripType,
    int? selectedPlanIndex,
    DateTime? selectedDate,
    String? selectedDepartureTime,
    String? selectedReturnTime,
    CityEntity? selectedCity,
    UniversityEntity? selectedUniversity,
    StationEntity? selectedStation,
  }) {
    return BookingStateModel(
      tripType: tripType ?? this.tripType,
      selectedPlanIndex: selectedPlanIndex ?? this.selectedPlanIndex,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedDepartureTime:
          selectedDepartureTime ?? this.selectedDepartureTime,
      selectedReturnTime: selectedReturnTime ?? this.selectedReturnTime,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedUniversity: selectedUniversity ?? this.selectedUniversity,
      selectedStation: selectedStation ?? this.selectedStation,
    );
  }
}
