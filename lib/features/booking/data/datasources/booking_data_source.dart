import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/booking_entity.dart';
import '../models/booking_model.dart';

abstract class BookingDataSource {
  Future<BookingModel> createBooking({
    required String userId,
    required String scheduleId,
    required DateTime bookingDate,
    required String tripType,
    String? pickupStationId,
    String? dropoffStationId,
    String? departureTime,
    String? returnTime,
    String? paymentProofImage,
    String? transferNumber,
    required double totalPrice,
    BookingSelectionType selectionType = BookingSelectionType.seat,
    int passengerCount = 1,
    bool splitPreference = true,
    bool isLadies = false,
  });

  /// Create a booking from a subscription
  Future<BookingModel> createSubscriptionBooking({
    required String userId,
    required String subscriptionId,
    required String scheduleId,
    required DateTime bookingDate,
    required String tripType,
    String? pickupStationId,
    String? dropoffStationId,
    String? departureTime,
    String? returnTime,
    required double totalPrice,
    bool isLadies = false,
  });

  Future<List<BookingModel>> getUserBookings(String userId);
  Future<BookingModel?> getUpcomingBooking(String userId);
  Future<BookingModel> getBookingById(String bookingId);

  Future<BookingModel> updateBooking({
    required String bookingId,
    required DateTime bookingDate,
    required String tripType,
    String? pickupStationId,
    String? dropoffStationId,
    String? departureTime,
    String? returnTime,
    required double totalPrice,
    BookingSelectionType selectionType = BookingSelectionType.seat,
    int passengerCount = 1,
    bool splitPreference = true,
    bool isLadies = false,
  });

  Future<BookingModel> transferBooking({
    required String bookingId,
    String? targetUserId,
    String? targetPhoneNumber,
  });
}

class BookingDataSourceImpl implements BookingDataSource {
  SupabaseClient get _client => SupabaseConfig.client;

  @override
  Future<BookingModel> createBooking({
    required String userId,
    required String scheduleId,
    required DateTime bookingDate,
    required String tripType,
    String? pickupStationId,
    String? dropoffStationId,
    String? departureTime,
    String? returnTime,
    String? paymentProofImage,
    String? transferNumber,
    required double totalPrice,
    BookingSelectionType selectionType = BookingSelectionType.seat,
    int passengerCount = 1,
    bool splitPreference = true,
    bool isLadies = false,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _client
          .from('bookings')
          .insert({
            'user_id': userId,
            'schedule_id': scheduleId,
            'booking_date': bookingDate.toIso8601String(),
            'trip_type': tripType,
            'pickup_station_id': pickupStationId,
            'dropoff_station_id': dropoffStationId,
            'departure_time': departureTime,
            'return_time': returnTime,
            'payment_proof_image': paymentProofImage,
            'transfer_number': transferNumber,
            'status': 'pending',
            'payment_status': 'unpaid',
            'selection_type': selectionType.toJson(),
            'passenger_count': passengerCount,
            'split_preference': splitPreference,
            'total_price': totalPrice,
            'is_ladies': isLadies,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .single();

      return BookingModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Log detailed error for debugging
      AppLogger.error('❌ Database error creating booking:');
      AppLogger.error('   Code: ${e.code}');
      AppLogger.error('   Message: ${e.message}');
      AppLogger.error('   Details: ${e.details}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Unexpected error creating booking: $e');
      throw Exception('Unexpected error during booking creation: $e');
    }
  }

  @override
  Future<BookingModel> createSubscriptionBooking({
    required String userId,
    required String subscriptionId,
    required String scheduleId,
    required DateTime bookingDate,
    required String tripType,
    String? pickupStationId,
    String? dropoffStationId,
    String? departureTime,
    String? returnTime,
    required double totalPrice,
    bool isLadies = false,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _client
          .from('bookings')
          .insert({
            'user_id': userId,
            'subscription_id': subscriptionId,
            'schedule_id': scheduleId,
            'booking_date': bookingDate.toIso8601String(),
            'trip_type': tripType,
            'pickup_station_id': pickupStationId,
            'dropoff_station_id': dropoffStationId,
            'departure_time': departureTime,
            'return_time': returnTime,
            'payment_proof_image':
                null, // No payment proof for subscription bookings
            'transfer_number':
                null, // No transfer number for subscription bookings
            'status': 'pending', // Pending until admin approval
            'payment_status': 'paid', // Already paid via subscription
            'total_price': totalPrice,
            'is_ladies': isLadies,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .single();

      return BookingModel.fromJson(response);
    } on PostgrestException catch (e) {
      AppLogger.error('❌ Database error creating subscription booking:');
      AppLogger.error('   Code: ${e.code}');
      AppLogger.error('   Message: ${e.message}');
      AppLogger.error('   Details: ${e.details}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Unexpected error creating subscription booking: $e');
      throw Exception(
        'Unexpected error during subscription booking creation: $e',
      );
    }
  }

  @override
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('booking_date', ascending: false);

      return (response as List).map((e) => BookingModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching bookings: $e');
    }
  }

  @override
  Future<BookingModel?> getUpcomingBooking(String userId) async {
    try {
      final now = DateTime.now();
      // Use start of day to include trips scheduled for today
      final today = DateTime(now.year, now.month, now.day);

      final response = await _client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .gte('booking_date', today.toIso8601String())
          .inFilter('status', ['pending', 'confirmed'])
          .order('booking_date', ascending: true);

      if (response.isEmpty) {
        return null;
      }

      // Convert all bookings to models
      final bookings = (response as List)
          .map((e) => BookingModel.fromJson(e))
          .toList();

      AppLogger.info('📋 Found ${bookings.length} upcoming bookings');

      // Filter and sort by date + time
      final upcomingBookings = bookings.where((booking) {
        // Check if booking is today or in the future
        final bookingDateTime = _parseBookingDateTime(
          booking.bookingDate,
          booking.departureTime,
        );

        AppLogger.info('🔍 Checking booking:');
        AppLogger.info('   Date: ${booking.bookingDate}');
        AppLogger.info('   Time: ${booking.departureTime}');
        AppLogger.info('   Parsed DateTime: $bookingDateTime');
        AppLogger.info('   Is after now? ${bookingDateTime?.isAfter(now)}');

        // If we can't parse the time, include it (fallback)
        if (bookingDateTime == null) {
          return booking.bookingDate.isAfter(now) ||
              booking.bookingDate.isAtSameMomentAs(
                DateTime(now.year, now.month, now.day),
              );
        }

        // Only include if the booking time is in the future
        return bookingDateTime.isAfter(now);
      }).toList();

      AppLogger.info('✅ ${upcomingBookings.length} bookings are upcoming');

      if (upcomingBookings.isEmpty) {
        return null;
      }

      // Sort by date + time
      upcomingBookings.sort((a, b) {
        final aDateTime = _parseBookingDateTime(a.bookingDate, a.departureTime);
        final bDateTime = _parseBookingDateTime(b.bookingDate, b.departureTime);

        AppLogger.info('🔀 Comparing:');
        AppLogger.info('   A: ${a.departureTime} -> $aDateTime');
        AppLogger.info('   B: ${b.departureTime} -> $bDateTime');

        // If we can't parse times, fallback to date comparison
        if (aDateTime == null || bDateTime == null) {
          return a.bookingDate.compareTo(b.bookingDate);
        }

        final comparison = aDateTime.compareTo(bDateTime);
        AppLogger.info('   Result: $comparison');
        return comparison;
      });

      AppLogger.info(
        '🎯 Selected booking: ${upcomingBookings.first.departureTime} on ${upcomingBookings.first.bookingDate}',
      );
      return upcomingBookings.first;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching upcoming booking: $e');
    }
  }

  /// Parse booking date + time into a DateTime object
  /// Returns null if time cannot be parsed
  DateTime? _parseBookingDateTime(DateTime date, String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return date;
    }

    try {
      // Parse time string in 24-hour format like "07:00:00" or "16:00:00"
      final timeParts = timeString.trim().split(':');
      if (timeParts.isEmpty) return date;

      final hour = int.parse(timeParts[0]);
      final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      return DateTime(date.year, date.month, date.day, hour, minute, second);
    } catch (e) {
      AppLogger.warning('⚠️ Could not parse time: $timeString - Error: $e');
      return date;
    }
  }

  @override
  Future<BookingModel> getBookingById(String bookingId) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      return BookingModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching booking: $e');
    }
  }

  @override
  Future<BookingModel> updateBooking({
    required String bookingId,
    required DateTime bookingDate,
    required String tripType,
    String? pickupStationId,
    String? dropoffStationId,
    String? departureTime,
    String? returnTime,
    required double totalPrice,
    BookingSelectionType selectionType = BookingSelectionType.seat,
    int passengerCount = 1,
    bool splitPreference = true,
    bool isLadies = false,
  }) async {
    try {
      final now = DateTime.now();
      AppLogger.info('🔄 Updating booking $bookingId...');
      AppLogger.info('   Trip Type: $tripType');
      AppLogger.info('   Total Price: $totalPrice');

      final response = await _client
          .from('bookings')
          .update({
            'booking_date': bookingDate.toIso8601String(),
            'departure_time': departureTime,
            'return_time': returnTime,
            'selection_type': selectionType.toJson(),
            'passenger_count': passengerCount,
            'split_preference': splitPreference,
            'total_price': totalPrice,
            'is_ladies': isLadies,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', bookingId)
          .select()
          .single();

      AppLogger.info('✅ Booking updated successfully');
      return BookingModel.fromJson(response);
    } on PostgrestException catch (e) {
      AppLogger.error('❌ Database error updating booking:');
      AppLogger.error('   Code: ${e.code}');
      AppLogger.error('   Message: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Unexpected error updating booking: $e');
      throw Exception('Unexpected error during booking update: $e');
    }
  }

  @override
  Future<BookingModel> transferBooking({
    required String bookingId,
    String? targetUserId,
    String? targetPhoneNumber,
  }) async {
    try {
      final now = DateTime.now();
      final updates = {
        'updated_at': now.toIso8601String(),
      };

      if (targetUserId != null) {
        updates['user_id'] = targetUserId;
      } else if (targetPhoneNumber != null) {
        // Handle pending transfer by phone number if needed
        // For now, we'll just update the user_id if we have it
        // In a real app, you might have a 'pending_transfers' table
      }

      final response = await _client
          .from('bookings')
          .update(updates)
          .eq('id', bookingId)
          .select()
          .single();

      return BookingModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Database error transferring booking: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during booking transfer: $e');
    }
  }
}
