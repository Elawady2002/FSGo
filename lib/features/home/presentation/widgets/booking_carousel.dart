import 'package:flutter/material.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import 'booking_card.dart';

class BookingCarousel extends StatelessWidget {
  final List<BookingEntity> bookings;

  const BookingCarousel({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    // Sort bookings by date (ascending)
    final sortedBookings = List<BookingEntity>.from(bookings)
      ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    // Show only the nearest (first) booking as a single card, same as subscription card
    final booking = sortedBookings.first;

    return BookingCard(booking: booking);
  }
}
