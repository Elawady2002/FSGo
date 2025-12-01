import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
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
  });

  Future<List<BookingModel>> getUserBookings(String userId);
  Future<BookingModel?> getUpcomingBooking(String userId);
  Future<BookingModel> getBookingById(String bookingId);
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
            'total_price': totalPrice,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .single();

      return BookingModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Log detailed error for debugging
      print('❌ Database error creating booking:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error creating booking: $e');
      throw Exception('Unexpected error during booking creation: $e');
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

      print('📋 Found ${bookings.length} upcoming bookings');

      // Filter and sort by date + time
      final upcomingBookings = bookings.where((booking) {
        // Check if booking is today or in the future
        final bookingDateTime = _parseBookingDateTime(
          booking.bookingDate,
          booking.departureTime,
        );

        print('🔍 Checking booking:');
        print('   Date: ${booking.bookingDate}');
        print('   Time: ${booking.departureTime}');
        print('   Parsed DateTime: $bookingDateTime');
        print('   Is after now? ${bookingDateTime?.isAfter(now)}');

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

      print('✅ ${upcomingBookings.length} bookings are upcoming');

      if (upcomingBookings.isEmpty) {
        return null;
      }

      // Sort by date + time
      upcomingBookings.sort((a, b) {
        final aDateTime = _parseBookingDateTime(a.bookingDate, a.departureTime);
        final bDateTime = _parseBookingDateTime(b.bookingDate, b.departureTime);

        print('🔀 Comparing:');
        print('   A: ${a.departureTime} -> $aDateTime');
        print('   B: ${b.departureTime} -> $bDateTime');

        // If we can't parse times, fallback to date comparison
        if (aDateTime == null || bDateTime == null) {
          return a.bookingDate.compareTo(b.bookingDate);
        }

        final comparison = aDateTime.compareTo(bDateTime);
        print('   Result: $comparison');
        return comparison;
      });

      print(
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
      print('⚠️ Could not parse time: $timeString - Error: $e');
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
}
