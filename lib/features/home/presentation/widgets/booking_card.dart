import 'dart:math' show pi;
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../providers/home_provider.dart';

class BookingCard extends ConsumerStatefulWidget {
  final BookingEntity booking;
  final bool isLadies;

  const BookingCard({
    super.key,
    required this.booking,
    this.isLadies = false,
  });

  @override
  ConsumerState<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<BookingCard>
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

    // Common time formatting (Manual to force English digits)
    String? formattedTime;
    if (widget.booking.departureTime != null) {
      try {
        final timeParts = widget.booking.departureTime!.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final period = hour < 12 ? 'ص' : 'م';
          final displayHour = hour % 12 == 0 ? 12 : hour % 12;
          formattedTime = '$displayHour:${minute.toString().padLeft(2, '0')} $period';
        }
      } catch (e) {
        formattedTime = widget.booking.departureTime;
      }
    }

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
                    child: _buildBack(primaryColor, formattedTime),
                  )
                : _buildFront(context, primaryColor, formattedTime),
          );
        },
      ),
    );
  }

  // ── Front Face: same design as ActiveSubscriptionCard ──────────────────────
  Widget _buildFront(BuildContext context, Color primaryColor, String? formattedTime) {
    final l10n = AppLocalizations.of(context)!;

    // Trip type label — matches subscription card labels
    String tripLabel;
    final isStationToStation = widget.booking.dropoffStationId != null;

    if (isStationToStation) {
      tripLabel = l10n.stationToStation;
    } else {
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
    }

    // Route: from/to based on real data
    final stations = ref.watch(allStationsProvider).valueOrNull ?? [];
    final universities = ref.watch(allUniversitiesProvider).valueOrNull ?? [];
    final lang = ref.watch(localeProvider).languageCode;

    final pickupStation = stations.where((s) => s.id == widget.booking.pickupStationId).firstOrNull;
    final dropoffStation = stations.where((s) => s.id == widget.booking.dropoffStationId).firstOrNull;

    final universityName = universities.isNotEmpty
        ? universities.first.getLocalizedName(lang)
        : 'الجامعة';

    String routeFrom = '';
    String routeTo = '';

    if (widget.booking.tripType == 'departure_only') {
      routeFrom = pickupStation?.getLocalizedName(lang) ?? l10n.madinaty;
      if (widget.booking.dropoffStationId != null && dropoffStation != null) {
        routeTo = dropoffStation.getLocalizedName(lang);
      } else {
        routeTo = universityName;
      }
    } else if (widget.booking.tripType == 'return_only') {
      routeFrom = universityName;
      routeTo = dropoffStation?.getLocalizedName(lang) ??
          pickupStation?.getLocalizedName(lang) ??
          l10n.madinaty;
    } else {
      routeFrom = pickupStation?.getLocalizedName(lang) ?? l10n.madinaty;
      routeTo = universityName;
    }

    // Real date from booking (Forcing English digits for day)
    final formattedDate =
        '${widget.booking.bookingDate.day} ${DateFormat('MMMM', 'ar_EG').format(widget.booking.bookingDate)}';

    // Status badge text
    final statusText = widget.booking.status == BookingStatus.confirmed
        ? l10n.confirmed
        : l10n.soon;

    return Container(
      height: 280, // Fixed height to match back face and prevent jumping
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
              // Top Content
              Expanded(
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

                    const SizedBox(height: 32),

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
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),

              // Route row: "من [from] إلى [to]" with departure time
              SizedBox(
                height: 24,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_fill,
                      color: primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formattedTime != null
                            ? '$formattedTime · $routeFrom ← $routeTo'
                            : '$routeFrom ← $routeTo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        textDirection: ui.TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  // ── Back Face: QR Code, same black design ──────────────────────────────────
  Widget _buildBack(Color primaryColor, String? formattedTime) {
    final shortId = '#${widget.booking.id.substring(0, 8).toUpperCase()}';
    final formattedDate =
        '${widget.booking.bookingDate.day} ${DateFormat('MMMM', 'ar_EG').format(widget.booking.bookingDate)}';

    return Container(
      height: 280, // Same fixed height as front face
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
            children: [
              // Info + QR
              Expanded(
                child: Row(
                  children: [
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Badge Aligned with elements below
                          Container(
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
                          const SizedBox(height: 16),
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
                          if (formattedTime != null)
                            Row(
                              children: [
                                const Icon(CupertinoIcons.clock,
                                    color: Colors.white54, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  formattedTime,
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
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),

              // Hint
              SizedBox(
                height: 24,
                child: Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
