import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../../domain/entities/passenger_entity.dart';
import '../providers/coordinator_provider.dart';
import '../providers/driver_duty_provider.dart';

const _kBg = Color(0xFF000000);
const _kCard = Color(0xFF1A1A1A);
const _kCard2 = Color(0xFF222222);
const _kLime = Color(0xFFC9D420);
const _kText = Colors.white;
const _kSubText = Color(0xFF999999);

class TripAssignmentPage extends ConsumerStatefulWidget {
  final CoordinatorScheduleEntity schedule;
  final UserEntity coordinator;
  final DateTime date;

  const TripAssignmentPage({
    super.key,
    required this.schedule,
    required this.coordinator,
    required this.date,
  });

  @override
  ConsumerState<TripAssignmentPage> createState() => _TripAssignmentPageState();
}

class _TripAssignmentPageState extends ConsumerState<TripAssignmentPage> {
  Map<String, List<String>> _assignments = {};

  /// Booking IDs currently selected by the user (tap-to-select)
  final Set<String> _selectedPassengers = {};

  static final List<PassengerEntity> _mockPassengers = [
    const PassengerEntity(
      bookingId: 'p1',
      userId: 'u1',
      fullName: 'أحمد محمود العوضي',
      phone: '01012345678',
      paymentType: PassengerPaymentType.cash,
      boardingStatus: PassengerBoardingStatus.booked,
      passengerCount: 1,
      isLadies: false,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
    ),
    const PassengerEntity(
      bookingId: 'p2',
      userId: 'u2',
      fullName: 'سارة محمد علي',
      phone: '01198765432',
      paymentType: PassengerPaymentType.subscriber,
      boardingStatus: PassengerBoardingStatus.booked,
      passengerCount: 1,
      isLadies: true,
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
    ),
    const PassengerEntity(
      bookingId: 'p3',
      userId: 'u3',
      fullName: 'ياسين حسن',
      phone: '01255566677',
      paymentType: PassengerPaymentType.cash,
      boardingStatus: PassengerBoardingStatus.booked,
      passengerCount: 2,
      isLadies: false,
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
    ),
    const PassengerEntity(
      bookingId: 'p4',
      userId: 'u4',
      fullName: 'ليلى إبراهيم',
      phone: '01566677788',
      paymentType: PassengerPaymentType.cash,
      boardingStatus: PassengerBoardingStatus.booked,
      passengerCount: 1,
      isLadies: true,
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    ),
  ];

  static final List<UserEntity> _mockDrivers = [
    UserEntity(
      id: 'd1',
      email: 'driver1@test.com',
      phone: '01000000001',
      fullName: 'كابتن محمد سمير',
      userType: UserType.driver,
      isVerified: true,
      createdAt: DateTime.now(),
      officeName: 'مكتب المنصورة',
      avatarUrl:
          'https://images.unsplash.com/photo-1566492031773-4f4e44671857?auto=format&fit=crop&w=200&q=80',
    ),
    UserEntity(
      id: 'd2',
      email: 'driver2@test.com',
      phone: '01000000002',
      fullName: 'كابتن محمود إبراهيم',
      userType: UserType.driver,
      isVerified: true,
      createdAt: DateTime.now(),
      officeName: 'رابطة سائقي القاهرة',
      avatarUrl:
          'https://images.unsplash.com/photo-1542909168-82c3e7fdca5c?auto=format&fit=crop&w=200&q=80',
    ),
    UserEntity(
      id: 'd3',
      email: 'driver3@test.com',
      phone: '01000000003',
      fullName: 'كابتن علي حسن',
      userType: UserType.driver,
      isVerified: true,
      createdAt: DateTime.now(),
      officeName: 'محطة العاصمة',
      avatarUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=200&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final manifestKey = ManifestKey(widget.schedule.id, widget.date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(manifestProvider(manifestKey).notifier).load();
      ref.read(coordinatorDriversProvider(widget.coordinator.id));
    });
  }

  void _toggleSelect(String bookingId) {
    setState(() {
      if (_selectedPassengers.contains(bookingId)) {
        _selectedPassengers.remove(bookingId);
      } else {
        _selectedPassengers.add(bookingId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final manifestKey = ManifestKey(widget.schedule.id, widget.date);
    final manifestState = ref.watch(manifestProvider(manifestKey));
    final driversAsync =
        ref.watch(coordinatorDriversProvider(widget.coordinator.id));
    final displayPassengers = manifestState.passengers.isEmpty
        ? _mockPassengers
        : manifestState.passengers;

    return Scaffold(
      backgroundColor: _kBg,
      body: Hero(
        tag: 'schedule-card-${widget.schedule.id}',
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, displayPassengers.length),
                Expanded(
                  child: _buildRiderList(manifestState, displayPassengers),
                ),
                _buildDriverTray(driversAsync, displayPassengers),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sign-board Header ────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, int passengerCount) {
    final parts = widget.schedule.routeLabel.split(' → ');
    final origin = parts.isNotEmpty ? parts[0] : widget.schedule.routeLabel;
    final dest = parts.length > 1 ? parts[1] : '';

    final dayNames = {
      'sunday': 'الأحد', 'monday': 'الاثنين', 'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء', 'thursday': 'الخميس',
      'friday': 'الجمعة', 'saturday': 'السبت',
    };
    final weekday = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ][widget.date.weekday - 1];
    final dayLabel = dayNames[weekday] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          // ── Action buttons ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Close
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.xmark,
                      color: _kText, size: 17),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Sign Board ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _kLime.withValues(alpha: 0.22),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kLime.withValues(alpha: 0.07),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Route row ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Origin
                      Flexible(
                        flex: 5,
                        child: Text(
                          origin,
                          style: GoogleFonts.cairo(
                            color: _kText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Dashed arrow
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _RouteArrow(),
                        ),
                      ),

                      // Destination
                      Flexible(
                        flex: 5,
                        child: Text(
                          dest,
                          style: GoogleFonts.cairo(
                            color: _kLime,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Separator ──────────────────────────────────
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: _kLime.withValues(alpha: 0.12),
                ),

                // ── Meta row ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Time
                      _SignDetail(
                        icon: CupertinoIcons.clock_fill,
                        value: widget.schedule.departureTime,
                        isAccent: true,
                      ),
                      _SignDot(),
                      // Date
                      _SignDetail(
                        icon: CupertinoIcons.calendar,
                        value:
                            '$dayLabel ${widget.date.day}/${widget.date.month}',
                      ),
                      _SignDot(),
                      // Count
                      _SignDetail(
                        icon: CupertinoIcons.person_2_fill,
                        value: '$passengerCount ركاب',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ── Rider List (tap-to-select + multi-drag) ──────────────────────
  Widget _buildRiderList(
      ManifestState state, List<PassengerEntity> displayPassengers) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kLime));
    }

    if (displayPassengers.isEmpty) {
      return Center(
        child:
            Text('لا يوجد ركاب متاحين', style: GoogleFonts.cairo(color: _kSubText)),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: displayPassengers.length,
          itemBuilder: (context, i) {
            final passenger = displayPassengers[i];
            final isAssigned = _assignments.values
                .any((list) => list.contains(passenger.bookingId));
            final isSelected =
                _selectedPassengers.contains(passenger.bookingId);

            // Passengers dragged: if this one is selected → send all selected,
            // otherwise send just this one
            final dragData = isSelected
                ? _selectedPassengers.toList()
                : [passenger.bookingId];

            return GestureDetector(
              onTap: () => _toggleSelect(passenger.bookingId),
              child: LongPressDraggable<List<String>>(
                data: dragData,
                delay: const Duration(milliseconds: 250),
                feedback: Material(
                  color: Colors.transparent,
                  child: _RiderCardFeedback(
                    passenger: passenger,
                    count: isSelected ? _selectedPassengers.length : 1,
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _RiderRow(
                    passenger: passenger,
                    isAssigned: isAssigned,
                    isSelected: isSelected,
                  ),
                ),
                child: _RiderRow(
                  passenger: passenger,
                  isAssigned: isAssigned,
                  isSelected: isSelected,
                ),
              ),
            );
          },
        ),

        // Selection hint badge
        if (_selectedPassengers.isNotEmpty)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  color: _kLime,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _kLime.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.hand_draw,
                        color: Colors.black, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedPassengers.length} محدد • اسحب لتعيين',
                      style: GoogleFonts.cairo(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Driver Tray (vertical scroll, full-width cards) ──────────────
  Widget _buildDriverTray(AsyncValue<List<UserEntity>> driversAsync,
      List<PassengerEntity> displayPassengers) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              children: [
                Text(
                  'السائقين المتاحين',
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                driversAsync.maybeWhen(
                  data: (d) {
                    final count =
                        d.isEmpty ? _mockDrivers.length : d.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kLime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count سائق',
                        style: GoogleFonts.cairo(
                            color: _kLime,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: driversAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kLime)),
              error: (e, _) => Center(
                  child: Text('خطأ في التحميل',
                      style: GoogleFonts.cairo(color: Colors.redAccent))),
              data: (driversList) {
                final drivers =
                    driversList.isEmpty ? _mockDrivers : driversList;
                if (drivers.isEmpty) {
                  return Center(
                      child: Text('لا يوجد سائقين متاحين',
                          style: GoogleFonts.cairo(color: _kSubText)));
                }
                return ListView.builder(
                  // ── Vertical scroll ──
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: drivers.length,
                  itemBuilder: (context, i) {
                    final driver = drivers[i];
                    final assignedBookingIds =
                        _assignments[driver.id] ?? [];
                    final assignedPassengers = displayPassengers
                        .where((p) =>
                            assignedBookingIds.contains(p.bookingId))
                        .toList();

                    return DragTarget<List<String>>(
                      onAcceptWithDetails: (details) {
                        setState(() {
                          for (final bookingId in details.data) {
                            _assignments.forEach(
                                (key, value) => value.remove(bookingId));
                            _assignments
                                .putIfAbsent(driver.id, () => [])
                                .add(bookingId);
                          }
                          _selectedPassengers.clear();
                        });
                        // Auto-save
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم تعيين ${details.data.length} راكب لـ ${driver.fullName}',
                              style: GoogleFonts.cairo(),
                            ),
                            backgroundColor: _kLime.withValues(alpha: 0.9),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DriverAssignmentCard(
                            driver: driver,
                            assignedPassengers: assignedPassengers,
                            isHighlighted: candidateData.isNotEmpty,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _saveAssignments() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ التقسيمات بنجاح', style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}

// ── Meta chip for header ─────────────────────────────────────────
// ── Route Arrow (dashed line + arrow icon) ──────────────────────
class _RouteArrow extends StatelessWidget {
  const _RouteArrow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 5.0;
        final gap = 4.0;
        final totalWidth = constraints.maxWidth - 18;
        final count = (totalWidth / (dashWidth + gap)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dashes
            ...List.generate(count, (_) => Container(
              width: dashWidth,
              height: 1.5,
              margin: EdgeInsets.only(right: gap),
              color: _kLime.withValues(alpha: 0.45),
            )),
            // Arrow head
            Icon(CupertinoIcons.arrow_left,
                color: _kLime, size: 14),
          ],
        );
      },
    );
  }
}

// ── Sign Detail item ────────────────────────────────────────────
class _SignDetail extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isAccent;
  const _SignDetail({
    required this.icon,
    required this.value,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAccent ? _kLime : Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: color,
            fontSize: 12,
            fontWeight:
                isAccent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Sign separator dot ───────────────────────────────────────────
class _SignDot extends StatelessWidget {
  const _SignDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Rider Row (with selection state) ────────────────────────────
class _RiderRow extends StatelessWidget {
  final PassengerEntity passenger;
  final bool isAssigned;
  final bool isSelected;
  const _RiderRow({
    required this.passenger,
    this.isAssigned = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? _kLime.withValues(alpha: 0.12)
            : isAssigned
                ? Colors.white.withValues(alpha: 0.05)
                : _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? _kLime.withValues(alpha: 0.6)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Selection indicator / drag handle
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: isSelected
                ? const Icon(CupertinoIcons.checkmark_circle_fill,
                    key: ValueKey('check'), color: _kLime, size: 20)
                : const Icon(CupertinoIcons.bars,
                    key: ValueKey('bars'), color: _kSubText, size: 20),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: _kLime.withValues(alpha: 0.2),
            backgroundImage: passenger.avatarUrl != null
                ? NetworkImage(passenger.avatarUrl!)
                : null,
            child: passenger.avatarUrl == null
                ? Text(
                    passenger.fullName[0],
                    style: GoogleFonts.cairo(
                        color: _kLime, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger.fullName,
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  passenger.phone,
                  style: GoogleFonts.cairo(color: _kSubText, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isAssigned && !isSelected)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'تم التعيين',
                style: GoogleFonts.cairo(
                    color: _kSubText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Drag Feedback ────────────────────────────────────────────────
class _RiderCardFeedback extends StatelessWidget {
  final PassengerEntity passenger;
  final int count;
  const _RiderCardFeedback(
      {required this.passenger, this.count = 1});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kLime,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black,
              backgroundImage: passenger.avatarUrl != null
                  ? NetworkImage(passenger.avatarUrl!)
                  : null,
              child: passenger.avatarUrl == null
                  ? Text(passenger.fullName[0],
                      style: const TextStyle(color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count > 1 ? '$count ركاب' : passenger.fullName,
                  style: GoogleFonts.cairo(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
                if (count > 1)
                  Text(
                    'يُسحبون معاً',
                    style: GoogleFonts.cairo(
                        color: Colors.black54,
                        fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Driver Assignment Card (full-width, horizontal layout) ───────
class _DriverAssignmentCard extends StatelessWidget {
  final UserEntity driver;
  final List<PassengerEntity> assignedPassengers;
  final bool isHighlighted;

  const _DriverAssignmentCard({
    required this.driver,
    required this.assignedPassengers,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPassengers = assignedPassengers.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      height: 138,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlighted ? _kLime.withValues(alpha: 0.15) : _kCard2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted ? _kLime : Colors.white.withValues(alpha: 0.08),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 1st child = RIGHT in RTL: driver avatar ───────────────
          CircleAvatar(
            radius: 22,
            backgroundColor: _kLime,
            backgroundImage: driver.avatarUrl != null
                ? NetworkImage(driver.avatarUrl!)
                : null,
            child: driver.avatarUrl == null
                ? Text(
                    driver.fullName[0],
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // ── Expanded: driver name + count ─────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  driver.fullName,
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasPassengers
                        ? _kLime.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${assignedPassengers.length} ركاب',
                    style: GoogleFonts.cairo(
                      color: hasPassengers ? _kLime : _kSubText,
                      fontSize: 12,
                      fontWeight: hasPassengers
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ── Divider ───────────────────────────────────────────────
          SizedBox(
            height: double.infinity,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          const SizedBox(width: 14),

          // ── Last child = LEFT in RTL: passenger avatars ───────────
          SizedBox(
            width: 72,
            child: hasPassengers
                ? _AssignedAvatarStack(passengers: assignedPassengers)
                : _DropHint(isHighlighted: isHighlighted),
          ),
        ],
      ),
    );
  }
}

// ── Assigned Avatar Stack (left side of driver card) ────────────
class _AssignedAvatarStack extends StatelessWidget {
  final List<PassengerEntity> passengers;
  const _AssignedAvatarStack({required this.passengers});

  @override
  Widget build(BuildContext context) {
    final show = passengers.take(4).toList();
    final extra = passengers.length - 4;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stacked avatars
        SizedBox(
          height: 40,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (int i = 0; i < show.length; i++)
                Positioned(
                  top: 0,
                  left: i * 22.0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: _kCard,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: _kSubText,
                      backgroundImage: show[i].avatarUrl != null
                          ? NetworkImage(show[i].avatarUrl!)
                          : null,
                      child: show[i].avatarUrl == null
                          ? Text(show[i].fullName[0],
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white))
                          : null,
                    ),
                  ),
                ),
              if (extra > 0)
                Positioned(
                  top: 0,
                  left: show.length * 22.0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: _kCard2,
                    child: Text(
                      '+$extra',
                      style: GoogleFonts.cairo(
                          color: _kLime,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${passengers.length} راكب',
          style: GoogleFonts.cairo(
              color: _kLime, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Drop Hint (when driver has no passengers) ────────────────────
class _DropHint extends StatelessWidget {
  final bool isHighlighted;
  const _DropHint({required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isHighlighted
                ? _kLime.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: isHighlighted
                  ? _kLime
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Icon(
            CupertinoIcons.arrow_down,
            color: isHighlighted ? _kLime : _kSubText,
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'أسقط\nهنا',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: isHighlighted ? _kLime : _kSubText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
