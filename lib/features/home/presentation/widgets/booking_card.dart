import 'dart:math' show pi;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../booking/domain/entities/trip_type.dart';
import '../../../../core/utils/digit_converter.dart';

class BookingCard extends StatefulWidget {
  final BookingEntity booking;
  final bool isLadies;

  const BookingCard({
    super.key,
    required this.booking,
    this.isLadies = false,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;
  double _dragStartX = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final dx = details.globalPosition.dx - _dragStartX;
    final velocity = details.primaryVelocity ?? 0;
    if (dx.abs() > 60 || velocity.abs() > 400) {
      _flip();
    }
  }

  void _flip() {
    HapticFeedback.mediumImpact();
    if (_isFlipped) {
      _flipController.reverse().then((_) {
        if (mounted) setState(() => _isFlipped = false);
      });
    } else {
      _flipController.forward().then((_) {
        if (mounted) setState(() => _isFlipped = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.isLadies ? const Color(0xFFFF2D55) : const Color(0xFFCCFF00);

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, _) {
          final angle = _flipAnimation.value * pi;
          final showBack = _flipAnimation.value >= 0.5;

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: showBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBack(primaryColor),
                  )
                : _buildFront(context, primaryColor),
          );
        },
      ),
    );
  }

  // ── Front Face: same design as ActiveSubscriptionCard ──────────────────────
  Widget _buildFront(BuildContext context, Color primaryColor) {
    final l10n = AppLocalizations.of(context)!;

    // Trip type label — matches subscription card labels
    String tripLabel;
    switch (widget.booking.tripType) {
      case 'departure_only':
        tripLabel = l10n.departureOnly;
        break;
      case 'return_only':
        tripLabel = l10n.returnOnly;
        break;
      default:
        tripLabel = l10n.roundTrip;
    }

    // Route: from/to based on trip type
    final String from = widget.booking.tripType == 'return_only'
        ? l10n.guc
        : l10n.madinaty;
    final String to = widget.booking.tripType == 'return_only'
        ? l10n.madinaty
        : l10n.guc;

    // Real date from booking
    final formattedDate =
        DateFormat('d MMMM', 'ar_EG').format(widget.booking.bookingDate).w;

    // Status badge text
    final statusText = widget.booking.status == BookingStatus.confirmed
        ? l10n.confirmed
        : l10n.soon;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Status Badge (same as subscription "قريباً" badge)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(begin: -0.2, end: 0),

              const SizedBox(height: 40),

              // Date & Trip Type Row (same layout as subscription card)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.startDate,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  // Trip type column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tripType,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tripLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),

              // Route row: "من [from] إلى [to]" with departure time
              Row(
                children: [
                  Icon(
                    CupertinoIcons.location_fill,
                    color: primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.booking.departureTime != null
                          ? '${widget.booking.departureTime} · $from → $to'
                          : '$from → $to',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  // ── Back Face: QR Code, same black design ──────────────────────────────────
  Widget _buildBack(Color primaryColor) {
    final shortId = '#${widget.booking.id.substring(0, 8).toUpperCase()}';
    final formattedDate =
        DateFormat('d MMMM', 'ar_EG').format(widget.booking.bookingDate).w;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge top center
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'تذكرة الركوب',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Main row: info + QR
              Expanded(
                child: Row(
                  children: [
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            shortId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.calendar,
                                  color: Colors.white54, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (widget.booking.departureTime != null)
                            Row(
                              children: [
                                const Icon(CupertinoIcons.clock,
                                    color: Colors.white54, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  widget.booking.departureTime!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: widget.booking.id,
                        version: QrVersions.auto,
                        size: 110,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Hint
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(CupertinoIcons.arrow_left_right,
                      color: Colors.white24, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'اسحب للرجوع',
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
