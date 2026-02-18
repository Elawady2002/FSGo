import 'dart:math' show pi;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/utils/digit_converter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/features/booking/domain/entities/booking_entity.dart';
import 'package:my_app/features/subscription/domain/entities/subscription_entity.dart';
import 'package:my_app/features/subscription/domain/entities/subscription_schedule_entity.dart';
import 'package:my_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_app/core/providers/locale_provider.dart';
import 'package:my_app/l10n/app_localizations.dart';
import 'full_screen_booking_view.dart';

class ActiveSubscriptionCard extends ConsumerStatefulWidget {
  final SubscriptionEntity subscription;
  final List<BookingEntity> regularBookings;

  const ActiveSubscriptionCard({
    super.key,
    required this.subscription,
    this.regularBookings = const [],
  });

  @override
  ConsumerState<ActiveSubscriptionCard> createState() =>
      _ActiveSubscriptionCardState();
}

class _ActiveSubscriptionCardState extends ConsumerState<ActiveSubscriptionCard>
    with TickerProviderStateMixin {
  DateTime? _selectedDate;
  String? _universityName;
  Map<String, SubscriptionScheduleEntity> _schedules = {};
  double _dragOffsetY = 0.0;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  // ── Flip Animation ──────────────────────────────────────────────────────────
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;
  double _dragStartX = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchSchedules();
    _fetchUniversityName();

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ActiveSubscriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.regularBookings.length != widget.regularBookings.length) {
      _fetchSchedules();
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  // ── Flip Handlers ───────────────────────────────────────────────────────────
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

  // ── Data Fetching ───────────────────────────────────────────────────────────
  Future<void> _fetchUniversityName() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user?.universityId != null) {
      try {
        final response = await Supabase.instance.client
            .from('universities')
            .select('name')
            .eq('id', user!.universityId!)
            .single();
        if (mounted) {
          setState(() {
            _universityName = response['name'] as String?;
          });
        }
      } catch (e) {
        debugPrint('Error fetching university name: $e');
      }
    }
  }

  Future<void> _fetchSchedules() async {
    if (widget.subscription.id == null) return;

    try {
      final Map<String, SubscriptionScheduleEntity> schedulesMap = {};

      final response = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('subscription_id', widget.subscription.id!)
          .order('booking_date');

      for (var booking in response) {
        final bookingDate = DateTime.parse(booking['booking_date'] as String);
        final dateKey = bookingDate.toIso8601String().split('T')[0];

        schedulesMap[dateKey] = SubscriptionScheduleEntity(
          id: booking['id'] as String,
          subscriptionId: (booking['subscription_id'] as String?) ?? '',
          tripDate: bookingDate,
          tripType: (booking['trip_type'] as String?) ?? 'round_trip',
          departureTime: booking['departure_time'] as String?,
          returnTime: booking['return_time'] as String?,
          createdAt: DateTime.parse(booking['created_at'] as String),
          updatedAt: booking['updated_at'] != null
              ? DateTime.parse(booking['updated_at'] as String)
              : DateTime.parse(booking['created_at'] as String),
        );
      }

      for (var booking in widget.regularBookings) {
        final dateKey = booking.bookingDate.toIso8601String().split('T')[0];
        schedulesMap[dateKey] = SubscriptionScheduleEntity(
          id: booking.id,
          subscriptionId: '',
          tripDate: booking.bookingDate,
          tripType: booking.tripType,
          departureTime: booking.departureTime,
          returnTime: booking.returnTime,
          createdAt: booking.createdAt,
          updatedAt: booking.updatedAt,
        );
      }

      if (mounted) {
        setState(() {
          _schedules = schedulesMap;
        });
        _selectNearestTrip();
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    }
  }

  void _selectNearestTrip() {
    final now = DateTime.now();
    final sortedDates = _schedules.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    String? nearestDateKey;
    for (var dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      if (date.isAfter(now.subtract(const Duration(days: 1)))) {
        nearestDateKey = dateKey;
        break;
      }
    }

    if (nearestDateKey != null) {
      final date = DateTime.parse(nearestDateKey);
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _playSound() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  void _openFullScreenView() {
    _playSound();
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return FullScreenBookingView(
                initialDate: _selectedDate ?? DateTime.now(),
                schedules: _schedules,
                subscription: widget.subscription,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                onBookingTap: (booking) {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedDate = booking.tripDate;
                  });
                },
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final curvedAnimation = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  final scaleAnimation = Tween<double>(
                    begin: 0.85,
                    end: 1.0,
                  ).animate(curvedAnimation);
                  final slideAnimation = Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(curvedAnimation);
                  return SlideTransition(
                    position: slideAnimation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      alignment: Alignment.center,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
            opaque: false,
            barrierColor: Colors.black87,
          ),
        )
        .then((_) {
          debugPrint('🔄 Refreshing schedules after booking view closed...');
          _fetchSchedules();
        });
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Vertical drag → open full screen (original behaviour)
      onVerticalDragStart: (_) => _playSound(),
      onVerticalDragUpdate: (details) {
        if (_isFlipped) return; // don't allow vertical drag while flipped
        setState(() {
          _dragOffsetY += details.primaryDelta! * 0.6;
        });
      },
      onVerticalDragEnd: (details) {
        if (_isFlipped) return;
        if (_dragOffsetY > 80 || details.primaryVelocity! > 300) {
          _openFullScreenView();
          _runSpringBack();
        } else {
          _runSpringBack();
        }
      },
      // Horizontal drag → flip card
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Transform.translate(
        offset: Offset(0, _dragOffsetY),
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
                      child: _buildBack(),
                    )
                  : _buildFront(),
            );
          },
        ),
      ),
    );
  }

  // ── Front Face (original card, untouched) ───────────────────────────────────
  Widget _buildFront() {
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
        child: _buildDetailsContent(),
      ),
    );
  }

  Widget _buildDetailsContent() {
    return Padding(
      key: const ValueKey('details'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFF00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.soon,
                  style: AppTheme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),

          const SizedBox(height: 40),

          // Dates Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.startDate,
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateSafe(context, widget.subscription.startDate),
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
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
                    AppLocalizations.of(context)!.tripType,
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTripTypeLabel(context, widget.subscription.tripType),
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
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

          // Route Info
          Row(
            children: [
              const Icon(
                CupertinoIcons.location_fill,
                color: Color(0xFFCCFF00),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.fromYourAreaTo(
                    _universityName ??
                        (ref.read(localeProvider).languageCode == 'ar'
                            ? "الجامعة"
                            : "University"),
                  ),
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  // ── Back Face (QR Code, same black design) ──────────────────────────────────
  Widget _buildBack() {
    final subscriptionId = widget.subscription.id ?? 'NO-ID';
    final shortId = '#${subscriptionId.substring(0, 8).toUpperCase()}';

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
          child: Row(
            children: [
              // QR Code on white background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: subscriptionId,
                  version: QrVersions.auto,
                  size: 120,
                  foregroundColor: Colors.black,
                ),
              ),

              const SizedBox(width: 20),

              // Info beside QR
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFF00),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'تذكرة الاشتراك',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subscription ID
                    Text(
                      shortId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Start Date
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.calendar,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateSafe(
                            context,
                            widget.subscription.startDate,
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Route
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location_fill,
                          color: Color(0xFFCCFF00),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.fromYourAreaTo(
                              _universityName ??
                                  (ref.read(localeProvider).languageCode == 'ar'
                                      ? "الجامعة"
                                      : "University"),
                            ),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Hint
                    Row(
                      children: const [
                        Icon(
                          CupertinoIcons.arrow_left_right,
                          color: Colors.white24,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'اسحب للرجوع',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                          ),
                        ),
                      ],
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

  // ── Helpers ─────────────────────────────────────────────────────────────────
  void _runSpringBack() {
    _springAnimation = Tween<double>(begin: _dragOffsetY, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
    _springController.reset();
    _springController.forward();
    _springController.addListener(() {
      setState(() {
        _dragOffsetY = _springAnimation.value;
      });
    });
  }

  String _getTripTypeLabel(BuildContext context, String tripType) {
    final l10n = AppLocalizations.of(context)!;
    switch (tripType) {
      case 'departure_only':
        return l10n.departureOnly;
      case 'return_only':
        return l10n.returnOnly;
      case 'round_trip':
        return l10n.roundTrip;
      default:
        return tripType;
    }
  }

  String _formatDateSafe(BuildContext context, DateTime date) {
    try {
      return DateFormat('d MMMM', 'ar_EG').format(date).w;
    } catch (e) {
      return "${date.day}/${date.month}";
    }
  }
}
