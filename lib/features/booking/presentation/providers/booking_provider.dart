import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/trip_type.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/entities/university_entity.dart';
import '../../domain/entities/station_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/datasources/booking_data_source.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'booking_provider.g.dart';

// Booking Repository Provider
@riverpod
BookingRepository bookingRepository(Ref ref) {
  final dataSource = BookingDataSourceImpl();
  // Watch auth provider to ensure repository is rebuilt when auth state changes
  final userAsync = ref.watch(authProvider);
  final user = userAsync.value;

  return BookingRepositoryImpl(dataSource, () {
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  });
}

// User Bookings Provider
@riverpod
Future<List<BookingEntity>> userBookings(Ref ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final result = await repository.getUserBookings();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (bookings) => bookings,
  );
}

// Upcoming Booking Provider
@riverpod
Future<BookingEntity?> upcomingBooking(Ref ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final result = await repository.getUpcomingBooking();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (booking) => booking,
  );
}

@Riverpod(keepAlive: true)
class BookingState extends _$BookingState {
  @override
  BookingStateModel build() {
    final now = DateTime.now();
    final initialDate = now.hour >= 7
        ? DateTime(now.year, now.month, now.day + 1)
        : now;

    return BookingStateModel(
      tripType: TripType.departureOnly, // Default to single trip
      isToUniversity: true, // Default to university trip
      selectedPlanIndex: 1, // Default to Monthly
      selectedDate: initialDate,
      selectedDepartureTime: null,
      selectedReturnTime: null,
      selectionType: BookingSelectionType.seat,
      passengerCount: 1,
      splitPreference: true,
      isLadiesOnly: false,
    );
  }

  void setSelectionType(BookingSelectionType value) {
    state = state.copyWith(selectionType: value);
  }

  void setPassengerCount(int value) {
    state = state.copyWith(passengerCount: value);
  }

  void setSplitPreference(bool value) {
    state = state.copyWith(splitPreference: value);
  }

  void setIsLadiesOnly(bool value) {
    state = state.copyWith(isLadiesOnly: value);
  }

  void setIsToUniversity(bool value) {
    state = state.copyWith(isToUniversity: value);
  }

  void selectTripType(TripType tripType) {
    state = state.copyWith(tripType: tripType);
  }

  void selectPlan(int index) {
    state = state.copyWith(selectedPlanIndex: index);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      selectedDepartureSchedule: null,
      selectedReturnSchedule: null,
      selectedDepartureTime: null,
      selectedReturnTime: null,
    );
  }

  void selectDepartureSchedule(ScheduleEntity? schedule) {
    state = state.copyWith(
      selectedDepartureSchedule: schedule,
      selectedDepartureTime: schedule?.departureTime,
    );
  }

  void selectReturnSchedule(ScheduleEntity? schedule) {
    state = state.copyWith(
      selectedReturnSchedule: schedule,
      selectedReturnTime: schedule?.departureTime,
    );
  }

  void selectDepartureTime(String? time) {
    state = state.copyWith(selectedDepartureTime: time);
  }

  void selectReturnTime(String? time) {
    state = state.copyWith(selectedReturnTime: time);
  }

  void setLocationData({
    required CityEntity city,
    UniversityEntity? university,
    required StationEntity pickupStation,
    StationEntity? arrivalStation,
    bool? isToUniversity,
  }) {
    // Debug logging to trace data flow
    debugPrint('🔵 setLocationData called:');
    debugPrint('   City: ${city.nameAr}');
    debugPrint('   University: ${university?.nameAr}');
    debugPrint('   Pickup Station: ${pickupStation.nameAr}');
    debugPrint('   Arrival Station: ${arrivalStation?.nameAr}');
    debugPrint('   isToUniversity: $isToUniversity');

    state = state.copyWith(
      selectedCity: city,
      selectedUniversity: university,
      selectedStation: pickupStation,
      selectedArrivalStation: arrivalStation,
      isToUniversity: isToUniversity ?? state.isToUniversity,
    );

    debugPrint('🟢 State updated - City now: ${state.selectedCity?.nameAr}');
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
    // For the simplified UI, any selection is enough
    return state.selectedDepartureSchedule != null ||
        state.selectedReturnSchedule != null ||
        state.selectedDepartureTime != null ||
        state.selectedReturnTime != null;
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
      // Use selected schedule ID if available, otherwise use default
      final scheduleId =
          state.selectedDepartureSchedule?.id ??
          state.selectedReturnSchedule?.id ??
          '00000000-0000-0000-0000-000000000000';

      final result = await repository.createBooking(
        scheduleId: scheduleId,
        bookingDate: state.selectedDate,
        tripType: state.tripType.toDbValue(),
        pickupStationId: state.selectedStation?.id,
        dropoffStationId: state.isToUniversity
            ? null
            : state.selectedArrivalStation?.id,
        departureTime: state.selectedDepartureTime,
        returnTime: state.selectedReturnTime,
        paymentProofImage: paymentProofImage,
        transferNumber: transferNumber,
        totalPrice: totalPrice,
        selectionType: state.selectionType,
        passengerCount: state.passengerCount,
        splitPreference: state.splitPreference,
        isLadies: state.isLadiesOnly,
      );

      return result.fold(
        (failure) => failure.message,
        (_) => null, // Success
      );
    } catch (e) {
      return 'حدث خطأ أثناء الحجز: $e';
    }
  }

  Future<String?> updateBooking(
    BookingRepository repository, {
    required String bookingId,
  }) async {
    if (!isBookingComplete) {
      return 'يرجى إكمال جميع بيانات الحجز';
    }

    try {
      final result = await repository.updateBooking(
        bookingId: bookingId,
        bookingDate: state.selectedDate,
        tripType: state.tripType.toDbValue(),
        pickupStationId: state.selectedStation?.id,
        dropoffStationId: state.isToUniversity
            ? null
            : state.selectedArrivalStation?.id,
        departureTime: state.selectedDepartureTime,
        returnTime: state.selectedReturnTime,
        totalPrice: totalPrice,
        selectionType: state.selectionType,
        passengerCount: state.passengerCount,
        splitPreference: state.splitPreference,
        isLadies: state.isLadiesOnly,
      );

      return result.fold(
        (failure) => failure.message,
        (_) => null, // Success
      );
    } catch (e) {
      return 'حدث خطأ أثناء تعديل الحجز: $e';
    }
  }
}

class BookingStateModel {
  final TripType tripType;
  final bool isToUniversity;
  final int selectedPlanIndex;
  final DateTime selectedDate;
  final String? selectedDepartureTime;
  final String? selectedReturnTime;
  final ScheduleEntity? selectedDepartureSchedule;
  final ScheduleEntity? selectedReturnSchedule;
  final CityEntity? selectedCity;
  final UniversityEntity? selectedUniversity;
  final StationEntity? selectedStation;
  final StationEntity? selectedArrivalStation;
  final BookingSelectionType selectionType;
  final int passengerCount;
  final bool splitPreference;
  final bool isLadiesOnly;

  BookingStateModel({
    required this.tripType,
    required this.isToUniversity,
    required this.selectedPlanIndex,
    required this.selectedDate,
    this.selectedDepartureTime,
    this.selectedReturnTime,
    this.selectedDepartureSchedule,
    this.selectedReturnSchedule,
    this.selectedCity,
    this.selectedUniversity,
    this.selectedStation,
    this.selectedArrivalStation,
    this.selectionType = BookingSelectionType.seat,
    this.passengerCount = 1,
    this.splitPreference = true,
    this.isLadiesOnly = false,
  });

  BookingStateModel copyWith({
    TripType? tripType,
    bool? isToUniversity,
    int? selectedPlanIndex,
    DateTime? selectedDate,
    String? selectedDepartureTime,
    String? selectedReturnTime,
    ScheduleEntity? selectedDepartureSchedule,
    ScheduleEntity? selectedReturnSchedule,
    CityEntity? selectedCity,
    UniversityEntity? selectedUniversity,
    StationEntity? selectedStation,
    StationEntity? selectedArrivalStation,
    BookingSelectionType? selectionType,
    int? passengerCount,
    bool? splitPreference,
    bool? isLadiesOnly,
  }) {
    return BookingStateModel(
      tripType: tripType ?? this.tripType,
      isToUniversity: isToUniversity ?? this.isToUniversity,
      selectedPlanIndex: selectedPlanIndex ?? this.selectedPlanIndex,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedDepartureTime:
          selectedDepartureTime ?? this.selectedDepartureTime,
      selectedReturnTime: selectedReturnTime ?? this.selectedReturnTime,
      selectedDepartureSchedule:
          selectedDepartureSchedule ?? this.selectedDepartureSchedule,
      selectedReturnSchedule:
          selectedReturnSchedule ?? this.selectedReturnSchedule,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedUniversity: selectedUniversity ?? this.selectedUniversity,
      selectedStation: selectedStation ?? this.selectedStation,
      selectedArrivalStation:
          selectedArrivalStation ?? this.selectedArrivalStation,
      selectionType: selectionType ?? this.selectionType,
      passengerCount: passengerCount ?? this.passengerCount,
      splitPreference: splitPreference ?? this.splitPreference,
      isLadiesOnly: isLadiesOnly ?? this.isLadiesOnly,
    );
  }
}
