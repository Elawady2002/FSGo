// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookingRepositoryHash() => r'e0f339f0fae207f3f7bc7e3c92250f0e92b23541';

/// See also [bookingRepository].
@ProviderFor(bookingRepository)
final bookingRepositoryProvider =
    AutoDisposeProvider<BookingRepository>.internal(
      bookingRepository,
      name: r'bookingRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bookingRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BookingRepositoryRef = AutoDisposeProviderRef<BookingRepository>;
String _$userBookingsHash() => r'fd9185e1e28d21cdc72b9fef9ecaec893a42a4d5';

/// See also [userBookings].
@ProviderFor(userBookings)
final userBookingsProvider =
    AutoDisposeFutureProvider<List<BookingEntity>>.internal(
      userBookings,
      name: r'userBookingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userBookingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserBookingsRef = AutoDisposeFutureProviderRef<List<BookingEntity>>;
String _$upcomingBookingHash() => r'd2fee3f00a3bd953911f72d8bb65380a723d0c58';

/// See also [upcomingBooking].
@ProviderFor(upcomingBooking)
final upcomingBookingProvider =
    AutoDisposeFutureProvider<BookingEntity?>.internal(
      upcomingBooking,
      name: r'upcomingBookingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$upcomingBookingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpcomingBookingRef = AutoDisposeFutureProviderRef<BookingEntity?>;
String _$bookingStateHash() => r'c08d719d2e20ddeaf219fbcb78bd92089a36721b';

/// See also [BookingState].
@ProviderFor(BookingState)
final bookingStateProvider =
    NotifierProvider<BookingState, BookingStateModel>.internal(
      BookingState.new,
      name: r'bookingStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bookingStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BookingState = Notifier<BookingStateModel>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
