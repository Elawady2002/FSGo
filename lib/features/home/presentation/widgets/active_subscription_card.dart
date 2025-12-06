import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../booking/domain/entities/booking_entity.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../../../subscription/domain/entities/subscription_schedule_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
    with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  // String? _selectedDepartureTime; // Removed as unused in new design
  // String? _selectedReturnTime;    // Removed as unused in new design
  // String _selectedTripType = 'round_trip'; // Removed unused field
  String? _universityName;
  Map<String, SubscriptionScheduleEntity> _schedules = {};
  double _dragOffsetY = 0.0;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    // Default to today, but will be updated by _fetchSchedules
    _selectedDate = DateTime.now();
    _fetchSchedules();
    _fetchUniversityName();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(ActiveSubscriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh calendar when regularBookings list changes
    if (oldWidget.regularBookings.length != widget.regularBookings.length) {
      _fetchSchedules();
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  Future<void> _fetchUniversityName() async {
    final user = ref.read(authProvider);
    if (user?.universityId != null) {
      try {
        final response = await Supabase.instance.client
            .from('universities')
            .select('name')
            .eq('id', user!.universityId!)
            .single();
        if (mounted) {
          setState(() {
            _universityName = response['name'] as String;
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

      // 1. Fetch subscription bookings from bookings table
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
          subscriptionId: booking['subscription_id'] as String,
          tripDate: bookingDate,
          tripType: booking['trip_type'] as String,
          departureTime: booking['departure_time'] as String?,
          returnTime: booking['return_time'] as String?,
          createdAt: DateTime.parse(booking['created_at'] as String),
          updatedAt: booking['updated_at'] != null
              ? DateTime.parse(booking['updated_at'] as String)
              : DateTime.parse(booking['created_at'] as String),
        );
      }

      // 2. Add regular bookings from widget.regularBookings
      for (var booking in widget.regularBookings) {
        final dateKey = booking.bookingDate.toIso8601String().split('T')[0];

        // Convert BookingEntity to SubscriptionScheduleEntity
        schedulesMap[dateKey] = SubscriptionScheduleEntity(
          id: booking.id,
          subscriptionId: '', // Empty for regular bookings
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
    // Sort dates
    final sortedDates = _schedules.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    // Find first date after now (or today if not passed yet)
    String? nearestDateKey;
    for (var dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      // If date is today or future
      if (date.isAfter(now.subtract(const Duration(days: 1)))) {
        nearestDateKey = dateKey;
        break;
      }
    }

    // If found, select it
    if (nearestDateKey != null) {
      final date = DateTime.parse(nearestDateKey);
      final schedule = _schedules[nearestDateKey];
      setState(() {
        _selectedDate = date;
        if (schedule != null) {
          // _selectedTripType = schedule.tripType;
          // _selectedDepartureTime = schedule.departureTime;
          // _selectedReturnTime = schedule.returnTime;
        }
      });
    }
  }

  void _playSound() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  void _openFullScreenView() {
    _playSound();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenBookingView(
            initialDate: _selectedDate ?? DateTime.now(),
            schedules: _schedules,
            subscription: widget.subscription,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
                final dateKey = date.toIso8601String().split('T')[0];
                final schedule = _schedules[dateKey];
                if (schedule != null) {
                  // _selectedTripType = schedule.tripType;
                  // _selectedDepartureTime = schedule.departureTime;
                  // _selectedReturnTime = schedule.returnTime;
                }
              });
            },
            onBookingTap: (booking) {
              Navigator.of(context).pop();
              // Just update the displayed details on the card
              setState(() {
                _selectedDate = booking.tripDate;
                // _selectedTripType = booking.tripType;
                // _selectedDepartureTime = booking.departureTime;
                // _selectedReturnTime = booking.returnTime;
              });
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Custom curve for realistic expansion
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          // Scale from card size to full screen
          final scaleAnimation = Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(curvedAnimation);

          // Slide up slightly for natural feel
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (_) => _playSound(),
      onVerticalDragUpdate: (details) {
        setState(() {
          // Add resistance and allow dragging down (positive delta)
          _dragOffsetY += details.primaryDelta! * 0.6;
        });
      },
      onVerticalDragEnd: (details) {
        // Trigger on Drag Down (positive offset/velocity)
        if (_dragOffsetY > 80 || details.primaryVelocity! > 300) {
          _openFullScreenView();
          _runSpringBack();
        } else {
          _runSpringBack();
        }
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffsetY),
        child: Container(
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
        ),
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
          // Top Row: Badge (Right) and Back Arrow (Left) in RTL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge (First -> Right in RTL)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFF00), // Lime green
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'قريباً',
                  style: AppTheme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
              // Back Arrow (Second -> Left in RTL)
            ],
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),

          const SizedBox(height: 40), // Fixed spacing instead of Spacer
          // Dates Row
          // In RTL: First child is Right, Second child is Left.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // Center the columns
            children: [
              // Start Date (Right side in RTL)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    'تاريخ البداية',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 14, // Increased from 12
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateSafe(widget.subscription.startDate),
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20, // Increased size
                    ),
                  ),
                ],
              ),

              // End Date (Left side in RTL)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    'نوع الرحلة',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTripTypeLabel(widget.subscription.tripType),
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
          // In RTL: First child is Right, Second is Left.
          Row(
            children: [
              Icon(
                CupertinoIcons.location_fill,
                color: const Color(0xFFCCFF00), // Lime green
                size: 18,
              ),
              const SizedBox(width: 12),
              // Text (Left of dot)
              Expanded(
                child: Text(
                  'من منطقتك إلى ${_universityName ?? "الجامعة"}',
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

  String _getTripTypeLabel(String tripType) {
    switch (tripType) {
      case 'departure_only':
        return 'ذهاب فقط';
      case 'return_only':
        return 'عودة فقط';
      case 'round_trip':
        return 'ذهاب وعودة';
      default:
        return tripType;
    }
  }

  String _formatDateSafe(DateTime date) {
    try {
      return DateFormat('d MMMM', 'ar').format(date);
    } catch (e) {
      // Fallback if locale data is missing
      return "${date.day}/${date.month}";
    }
  }
}
