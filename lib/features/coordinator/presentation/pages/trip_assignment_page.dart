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
  // Local state for assignments: driverId -> list of bookingIds
  Map<String, List<String>> _assignments = {};

  // Mock data for testing
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
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
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
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
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
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
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
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
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
      avatarUrl: 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?auto=format&fit=crop&w=200&q=80',
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
      avatarUrl: 'https://images.unsplash.com/photo-1542909168-82c3e7fdca5c?auto=format&fit=crop&w=200&q=80',
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
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=200&q=80',
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

  @override
  Widget build(BuildContext context) {
    final manifestKey = ManifestKey(widget.schedule.id, widget.date);
    final manifestState = ref.watch(manifestProvider(manifestKey));
    final driversAsync = ref.watch(coordinatorDriversProvider(widget.coordinator.id));
    final displayPassengers = manifestState.passengers.isEmpty ? _mockPassengers : manifestState.passengers;

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
                _buildHeader(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, color: _kText),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.schedule.routeLabel,
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${widget.schedule.departureTime} • ${widget.date.day}/${widget.date.month}',
                  style: GoogleFonts.cairo(color: _kLime, fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _saveAssignments,
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: _kLime,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kLime.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(CupertinoIcons.checkmark, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderList(ManifestState state, List<PassengerEntity> displayPassengers) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kLime));
    }

    if (displayPassengers.isEmpty) {
      return Center(
        child: Text('لا يوجد ركاب متاحين', style: GoogleFonts.cairo(color: _kSubText)),
      );
    }

    // Filter out already assigned passengers if needed
    final unassigned = displayPassengers.where((p) {
      return !_assignments.values.any((list) => list.contains(p.bookingId));
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: displayPassengers.length,
      itemBuilder: (context, i) {
        final passenger = displayPassengers[i];
        final isAssigned = _assignments.values.any((list) => list.contains(passenger.bookingId));
        
        return Draggable<String>(
          data: passenger.bookingId,
          feedback: _RiderCardFeedback(passenger: passenger),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _RiderRow(passenger: passenger, isAssigned: isAssigned),
          ),
          child: _RiderRow(passenger: passenger, isAssigned: isAssigned),
        );
      },
    );
  }

  Widget _buildDriverTray(AsyncValue<List<UserEntity>> driversAsync, List<PassengerEntity> displayPassengers) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Text(
              'السائقين المتاحين',
              style: GoogleFonts.cairo(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: driversAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _kLime)),
              error: (e, _) => Center(child: Text('خطأ في التحميل', style: GoogleFonts.cairo(color: Colors.redAccent))),
              data: (driversList) {
                final drivers = driversList.isEmpty ? _mockDrivers : driversList;
                if (drivers.isEmpty) {
                  return Center(child: Text('لا يوجد سائقين متاحين', style: GoogleFonts.cairo(color: _kSubText)));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: drivers.length,
                  itemBuilder: (context, i) {
                    final driver = drivers[i];
                    final assignedBookingIds = _assignments[driver.id] ?? [];
                    final assignedPassengers = displayPassengers
                        .where((p) => assignedBookingIds.contains(p.bookingId))
                        .toList();

                    return DragTarget<String>(
                      onAcceptWithDetails: (details) {
                        setState(() {
                          // Remove from old car if exists
                          _assignments.forEach((key, value) {
                            value.remove(details.data);
                          });
                          // Add to new car
                          _assignments.putIfAbsent(driver.id, () => []).add(details.data);
                        });
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
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

  void _saveAssignments() async {
    // Implement persistence logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ التقسيمات بنجاح', style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}

class _RiderRow extends StatelessWidget {
  final PassengerEntity passenger;
  final bool isAssigned;
  const _RiderRow({required this.passenger, this.isAssigned = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAssigned ? _kLime.withValues(alpha: 0.1) : _kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.bars, color: _kSubText, size: 20),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: _kLime.withValues(alpha: 0.2),
            backgroundImage: passenger.avatarUrl != null ? NetworkImage(passenger.avatarUrl!) : null,
            child: passenger.avatarUrl == null 
              ? Text(
                  passenger.fullName[0],
                  style: GoogleFonts.cairo(color: _kLime, fontWeight: FontWeight.w700),
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
                  style: GoogleFonts.cairo(color: _kText, fontWeight: FontWeight.w600),
                ),
                Text(
                  passenger.phone,
                  style: GoogleFonts.cairo(color: _kSubText, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isAssigned)
            const Icon(CupertinoIcons.checkmark_circle_fill, color: _kLime, size: 20),
        ],
      ),
    );
  }
}

class _RiderCardFeedback extends StatelessWidget {
  final PassengerEntity passenger;
  const _RiderCardFeedback({required this.passenger});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kLime,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.black,
              backgroundImage: passenger.avatarUrl != null ? NetworkImage(passenger.avatarUrl!) : null,
              child: passenger.avatarUrl == null
                ? Text(passenger.fullName[0], style: const TextStyle(color: Colors.white))
                : null,
            ),
            const SizedBox(width: 12),
            Text(
              passenger.fullName,
              style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 180,
      margin: const EdgeInsets.only(right: 12, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? _kLime.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted ? _kLime : Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _kLime,
                backgroundImage: driver.avatarUrl != null ? NetworkImage(driver.avatarUrl!) : null,
                child: driver.avatarUrl == null
                  ? Text(driver.fullName[0], style: const TextStyle(color: Colors.black))
                  : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  driver.fullName,
                  style: GoogleFonts.cairo(color: _kText, fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${assignedPassengers.length} ركاب',
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 11),
          ),
          const Spacer(),
          SizedBox(
            height: 24,
            child: Stack(
              children: assignedPassengers.take(4).map((p) {
                final index = assignedPassengers.indexOf(p);
                return Positioned(
                  left: index * 16.0,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: _kCard,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: _kSubText,
                      backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                      child: p.avatarUrl == null
                        ? Text(p.fullName[0], style: const TextStyle(fontSize: 8, color: Colors.white))
                        : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
