import 'full_screen_booking_view.dart';
import '../../../subscription/domain/entities/subscription_schedule_entity.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import 'qr_details_sheet.dart';
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../providers/home_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UnifiedTripCard extends ConsumerStatefulWidget {
  final BookingEntity? widgetBooking;
  final SubscriptionEntity? widgetSubscription;
  final bool isLadies;

  const UnifiedTripCard({
    super.key,
    BookingEntity? booking,
    SubscriptionEntity? subscription,
    this.isLadies = false,
  }) : widgetBooking = booking,
       widgetSubscription = subscription;

  @override
  ConsumerState<UnifiedTripCard> createState() => _UnifiedTripCardState();
}

class _UnifiedTripCardState extends ConsumerState<UnifiedTripCard> with SingleTickerProviderStateMixin {
  double _dragOffsetY = 0;
  late AnimationController _springController;

  void _openQRSheet() {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => QRDetailsSheet(
        booking: widget.widgetBooking,
        subscription: widget.widgetSubscription,
      ),
    );
  }

  Future<void> _handlePullDown() async {
    HapticFeedback.heavyImpact();
    
    // 1. Check if provided directly
    SubscriptionEntity? subscription = widget.widgetSubscription;
    
    // 2. Search for subscription associated with the booking
    if (subscription == null && widget.widgetBooking?.subscriptionId != null) {
      final allSubs = await ref.read(userSubscriptionsProvider.future);
      subscription = allSubs.where((s) => s.id == widget.widgetBooking!.subscriptionId).firstOrNull;
    }
    
    // 3. Fallback to current active/pending subscription
    subscription ??= await ref.read(activeSubscriptionProvider.future);

    // 4. Final fallback: pick the most recent subscription if none are strictly "active"
    if (subscription == null) {
      final allSubs = await ref.read(userSubscriptionsProvider.future);
      if (allSubs.isNotEmpty) {
        subscription = allSubs.first;
      }
    }

    // 5. Emergency fallback for Station/Mawkaf trips: Create a placeholder subscription
    if (subscription == null) {
      final user = ref.read(authProvider).value;
      if (user != null) {
        final now = DateTime.now();
        subscription = SubscriptionEntity(
          id: 'placeholder_${widget.widgetBooking?.id ?? 'generic'}',
          userId: user.id,
          planType: SubscriptionPlanType.monthly,
          amount: 0,
          status: SubscriptionStatus.active,
          startDate: widget.widgetBooking?.bookingDate.subtract(const Duration(days: 30)) ?? now.subtract(const Duration(days: 30)),
          endDate: widget.widgetBooking?.bookingDate.add(const Duration(days: 30)) ?? now.add(const Duration(days: 30)),
          createdAt: now,
          tripType: widget.widgetBooking?.tripType ?? 'round_trip',
          pickupStationId: widget.widgetBooking?.pickupStationId,
          dropoffStationId: widget.widgetBooking?.dropoffStationId,
        );
      }
    }
    
    if (subscription != null) {
      final now = DateTime.now();
      // Fetch bookings for this subscription
      final bookings = await ref.read(userBookingsProvider.future);
      
      final Map<String, SubscriptionScheduleEntity> schedules = {};
      for (final b in bookings) {
        if (b.subscriptionId == subscription.id) {
          final dateKey = b.bookingDate.toIso8601String().split('T')[0];
          schedules[dateKey] = SubscriptionScheduleEntity.fromBooking(b);
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (context) => FullScreenBookingView(
              initialDate: widget.widgetBooking?.bookingDate ?? now,
              schedules: schedules,
              subscription: subscription!,
              onDateSelected: (date) {},
              onBookingTap: (schedule) {},
            ),
          ),
        );
      }
    } else {
      HapticFeedback.lightImpact();
      debugPrint('No subscription found for pull-down navigation');
    }
  }

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _springController.addListener(() {
      setState(() {
        _dragOffsetY = _dragOffsetY * (1 - _springController.value);
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isLadies ? const Color(0xFFFF2D55) : const Color(0xFFCCFF00);
    final l10n = AppLocalizations.of(context)!;
    
    // Determine what to display
    final isSubscription = widget.widgetBooking == null;
    
    String? formattedTime;
    if (!isSubscription && widget.widgetBooking!.departureTime != null) {
      try {
        final timeParts = widget.widgetBooking!.departureTime!.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final period = hour < 12 ? 'ص' : 'م';
          final displayHour = hour % 12 == 0 ? 12 : hour % 12;
          formattedTime = '$displayHour:${minute.toString().padLeft(2, '0')} $period';
        }
      } catch (e) {
        formattedTime = widget.widgetBooking!.departureTime;
      }
    }

    // Route logic
    final boardingStations = ref.watch(allBoardingStationsProvider).valueOrNull ?? [];
    final arrivalStations = ref.watch(allArrivalStationsProvider).valueOrNull ?? [];
    final universities = ref.watch(allUniversitiesProvider).valueOrNull ?? [];
    final lang = ref.watch(localeProvider).languageCode;
    
    final pickupId = isSubscription ? widget.widgetSubscription!.pickupStationId : widget.widgetBooking!.pickupStationId;
    final dropoffId = isSubscription ? widget.widgetSubscription!.dropoffStationId : widget.widgetBooking!.dropoffStationId;
    final tripType = isSubscription ? widget.widgetSubscription!.tripType : widget.widgetBooking!.tripType;

    final pickupStation = boardingStations.where((s) => s.id == pickupId).firstOrNull;
    final dropoffStation = arrivalStations.where((s) => s.id == dropoffId).firstOrNull;

    final universityName = universities.isNotEmpty
        ? universities.first.getLocalizedName(lang)
        : 'الجامعة';

    String routeFrom = '';
    String routeTo = '';

    if (tripType == 'departure_only') {
      routeFrom = pickupStation?.getLocalizedName(lang) ?? l10n.madinaty;
      if (dropoffId != null && dropoffStation != null) {
        routeTo = dropoffStation.getLocalizedName(lang);
      } else {
        routeTo = universityName;
      }
    } else if (tripType == 'return_only') {
      routeFrom = universityName;
      routeTo = dropoffStation?.getLocalizedName(lang) ??
          pickupStation?.getLocalizedName(lang) ??
          l10n.madinaty;
    } else {
      routeFrom = pickupStation?.getLocalizedName(lang) ?? l10n.madinaty;
      routeTo = universityName;
    }

    // Trip Label
    String tripLabel;
    if (dropoffId != null) {
      tripLabel = l10n.stationToStation;
    } else {
      switch (tripType) {
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

    String formattedDate = '';
    if (isSubscription) {
      formattedDate = '${widget.widgetSubscription!.startDate.day} ${DateFormat('MMMM', 'ar_EG').format(widget.widgetSubscription!.startDate)}';
    } else {
      formattedDate = '${widget.widgetBooking!.bookingDate.day} ${DateFormat('MMMM', 'ar_EG').format(widget.widgetBooking!.bookingDate)}';
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(0.0, 160.0);
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffsetY > 80) {
          _handlePullDown();
        }
        _springController.forward(from: 0);
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffsetY),
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10), // Keep shadow static for cleaner movement
              ),
            ],
          ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                              !isSubscription 
                                  ? (widget.widgetBooking!.status == BookingStatus.confirmed ? l10n.confirmed : l10n.soon)
                                  : 'تذكرة الاشتراك',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _openQRSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isSubscription && (widget.widgetBooking?.passengerCount ?? 1) > 1) ...[
                                    Text(
                                      '${widget.widgetBooking!.passengerCount}',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 14,
                                      color: Colors.white24,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const Icon(
                                    CupertinoIcons.qrcode,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSubscription ? l10n.startDate : l10n.date,
                                style: GoogleFonts.cairo(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.tripType,
                                style: GoogleFonts.cairo(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tripLabel,
                                style: GoogleFonts.cairo(
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
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
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
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          textDirection: ui.TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
