import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/utils/digit_converter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ios_components.dart';
import '../../../../core/widgets/insufficient_balance_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/wallet_provider.dart';
import '../../domain/entities/trip_type.dart';
import '../providers/booking_provider.dart';
// import '../widgets/student_packages_button.dart';
import 'booking_success_page.dart';
import '../widgets/booking_date_card.dart';
import '../widgets/time_selection_card.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../domain/entities/booking_entity.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingStateProvider);
    final bookingNotifier = ref.read(bookingStateProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    AppLocalizations.of(context)!.bookYourTrip,
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // // Student Packages Button
                  // const StudentPackagesButton(),
                  // const SizedBox(height: 24),

                  // Trip Type Selector

                  // Unified Booking Card (all options in one container)
                  _buildUnifiedBookingCard(bookingState, bookingNotifier, ref),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Bottom Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: IOSButton(
                text: bookingState.isToUniversity
                    ? 'اطلب خط الجامعة'
                    : AppLocalizations.of(context)!.bookNow,
                onPressed:
                    bookingNotifier.isBookingComplete &&
                        bookingNotifier.isSameDayBookingAllowed
                    ? () async {
                        final user = ref.read(authProvider).value;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.pleaseLoginFirst,
                              ),
                            ),
                          );
                          return;
                        }

                        final amount = bookingNotifier.totalPrice;
                        final walletState = ref.read(walletProvider);

                        // If it's a university request, we don't deduct money immediately
                        if (bookingState.isToUniversity) {
                          final repository = ref.read(
                            bookingRepositoryProvider,
                          );
                          final errorMessage = await bookingNotifier
                              .createUniversityRequestBooking(repository);

                          if (errorMessage == null) {
                            if (!context.mounted) return;
                            // Navigate to Success Page for Pending Request
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingSuccessPage(
                                  amount: 0,
                                  tripType: 'طلب خط جامعة (قيد المراجعة)',
                                  date: bookingState.selectedDate,
                                ),
                              ),
                              (route) => route.isFirst,
                            );
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        // Standard booking flow (Mawkaf)
                        if (walletState.balance < amount) {
                          showDialog(
                            context: context,
                            builder: (context) => InsufficientBalanceDialog(
                              currentBalance: walletState.balance,
                              requiredAmount: amount,
                            ),
                          );
                          return;
                        }

                        // Deduct from wallet
                        final success = await ref
                            .read(walletProvider.notifier)
                            .deductAmount(
                              amount,
                              '${AppLocalizations.of(context)!.bookNow} - ${_getTripTypeLabel(context, bookingState.tripType)}',
                            );

                        if (!success) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.errorDeductingAmount,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Create booking
                        final repository = ref.read(bookingRepositoryProvider);
                        final errorMessage = await bookingNotifier
                            .createBooking(
                              repository,
                              paymentProofImage: null,
                              transferNumber: null,
                            );

                        if (errorMessage == null) {
                          if (!context.mounted) return;

                          // Navigate to Success Page
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingSuccessPage(
                                amount: amount,
                                tripType: _getTripTypeLabel(
                                  context,
                                  bookingState.tripType,
                                ),
                                date: bookingState.selectedDate,
                              ),
                            ),
                            (route) => route.isFirst,
                          );
                        } else {
                          // RECOVERY: If booking creation failed but we already deducted money, refund it!
                          await ref
                              .read(walletProvider.notifier)
                              .addAmount(
                                amount,
                                'استرداد: فشل إنشاء الحجز - $errorMessage',
                              );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'فشل الحجز: $errorMessage',
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    : null,
                color:
                    bookingNotifier.isBookingComplete &&
                        bookingNotifier.isSameDayBookingAllowed
                    ? AppTheme.primaryColor
                    : AppTheme.dividerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInlineScheduleSection(
    BookingStateModel state,
    BookingState bookingNotifier,
    WidgetRef ref, {
    bool isLadies = false,
  }) {
    if (state.isToUniversity) {
      final universityId = state.selectedUniversity?.id;
      final routesAsync = ref.watch(routesProvider(universityId));

      return routesAsync.when(
        data: (routes) {
          if (routes.isEmpty) {
            return [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noTripsAvailable,
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ];
          }

          final route = routes.first;
          final schedulesAsync = ref.watch(schedulesProvider(route.id));

          return [
            schedulesAsync.when(
              data: (schedules) {
                final allSchedules = schedules;
                final selectedSchedule =
                    state.selectedDepartureSchedule ??
                    state.selectedReturnSchedule;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInlineLabel(
                        AppLocalizations.of(context)!.tripTime,
                        isLadies: isLadies,
                      ),
                      const SizedBox(height: 12),
                      TimeSelectionCard(
                        title: AppLocalizations.of(context)!.selectTripTime,
                        isLadies: isLadies,
                        selectedTime: selectedSchedule != null
                            ? _formatTime(selectedSchedule.departureTime)
                            : null,
                        icon: CupertinoIcons.clock,
                        onTap: () {
                          final items = allSchedules
                              .map((s) => _formatTime(s.departureTime))
                              .toList();
                          _showTimePicker(
                            title: AppLocalizations.of(context)!.tripTime,
                            items: items,
                            onSelect: (time) {
                              if (time != null) {
                                final schedule = allSchedules.firstWhere(
                                  (s) => _formatTime(s.departureTime) == time,
                                );
                                bookingNotifier.selectDepartureSchedule(schedule);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('Error: $err')),
              ),
            ),
          ];
        },
        loading: () => [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CupertinoActivityIndicator()),
          ),
        ],
        error: (err, _) => [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('Error: $err')),
          ),
        ],
      );
    } else {
      // For Point-to-Point: Use schedules from ArrivalStationEntity
      final schedules = state.selectedArrivalStation?.schedules ?? [];
      final selectedTime = state.selectedDepartureTime ?? state.selectedReturnTime;

      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInlineLabel(
                AppLocalizations.of(context)!.tripTime,
                isLadies: isLadies,
              ),
              const SizedBox(height: 12),
              TimeSelectionCard(
                title: AppLocalizations.of(context)!.selectTripTime,
                isLadies: isLadies,
                selectedTime: selectedTime != null ? _formatTime(selectedTime) : null,
                icon: CupertinoIcons.clock,
                onTap: schedules.isEmpty
                    ? null
                    : () {
                        // For Point-to-Point, schedules are already strings like "HH:mm"
                        final formattedSchedules =
                            schedules.map((s) => _formatTime(s)).toList();
                        _showTimePicker(
                          title: AppLocalizations.of(context)!.tripTime,
                          items: formattedSchedules,
                          onSelect: (time) {
                            if (time != null) {
                              // Find original raw time
                              final originalTime = schedules.firstWhere(
                                (s) => _formatTime(s) == time,
                              );
                              bookingNotifier.selectDepartureTime(originalTime);
                            }
                          },
                        );
                      },
              ),
              if (schedules.isEmpty && state.selectedArrivalStation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    AppLocalizations.of(context)!.noTripsAvailable,
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ];
    }
  }

  String _formatTime(String time) {
    // Basic formatting from "HH:mm" to "h:mm a" if needed,
    // but the entity says "departureTime" is String.
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2022, 1, 1, hour, minute);
      return DateFormat(
        'h:mm a',
        'ar_EG',
      ).format(dt).replaceAll('صباحاً', 'ص').replaceAll('مساءً', 'م');
    } catch (e) {
      return time;
    }
  }

  void _showTimePicker({
    required String title,
    required List<String> items,
    required void Function(String?) onSelect,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 340,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Header with Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFFF3B30),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)!.done,
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Picker
            Expanded(
              child: CupertinoPicker.builder(
                itemExtent: 48,
                magnification: 1.1,
                useMagnifier: true,
                backgroundColor: Colors.transparent,
                selectionOverlay: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSelectedItemChanged: (index) {
                  onSelect(items[index]);
                },
                childCount: items.length,
                itemBuilder: (context, index) => Center(
                  child: GestureDetector(
                    onTap: () {
                      onSelect(items[index]);
                      Navigator.pop(context);
                    },
                    child: Text(
                      items[index],
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _showGenericTimePicker({
    required String title,
    required void Function(String?) onSelect,
  }) {
    // Generate times like 07:00 AM, 07:30 AM, ..., 11:30 PM
    final List<String> times = [];
    for (int hour = 6; hour <= 23; hour++) {
      for (int minute in [0, 30]) {
        final dt = DateTime(2022, 1, 1, hour, minute);
        final formatted = DateFormat(
          'h:mm a',
          'ar_EG',
        ).format(dt).replaceAll('صباحاً', 'ص').replaceAll('مساءً', 'م');
        times.add(formatted);
      }
    }

    _showTimePicker(title: title, items: times, onSelect: onSelect);
  }

  Widget _buildHorizontalTicketPath(
    BookingStateModel state, {
    bool isLadies = false,
  }) {
    String destinationName = state.isToUniversity
        ? (state.selectedUniversity?.nameAr ?? 'الجامعة')
        : (state.selectedArrivalStation?.nameAr ?? 'موقف الوصول');

    final Color lineColor = isLadies
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.white24;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPathPoint(
              label: AppLocalizations.of(context)!.pickupStation,
              value: state.selectedStation?.nameAr ?? '-',
              isFirst: true,
              isLadies: isLadies,
            ),
            _buildPathPoint(
              label: state.isToUniversity
                  ? AppLocalizations.of(context)!.university
                  : AppLocalizations.of(context)!.arrivalPoint,
              value: destinationName,
              isLast: true,
              isLadies: isLadies,
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Visual Path Line with Arrow
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: lineColor,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAnimatedDot(isFirst: true, isLadies: isLadies),
                _buildDirectionArrow(isLadies: isLadies),
                _buildAnimatedDot(isLast: true, isLadies: isLadies),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionArrow({bool isLadies = false}) {
    final Color bgColor = isLadies
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black;
    final Color borderColor = isLadies
        ? Colors.white.withValues(alpha: 0.5)
        : AppTheme.primaryColor.withValues(alpha: 0.5);
    final Color arrowColor = isLadies ? Colors.white : AppTheme.primaryColor;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.linear,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Icon(
            CupertinoIcons.arrow_left, // Arabic is RTL, so arrow points left
            color: arrowColor,
            size: 14,
          ),
        );
      },
    );
  }

  Widget _buildPathPoint({
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
    bool isLadies = false,
  }) {
    final Color labelColor = isLadies
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.5);

    return Expanded(
      child: Column(
        crossAxisAlignment: isFirst
            ? CrossAxisAlignment.start
            : isLast
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: labelColor,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: isFirst
                ? TextAlign.start
                : isLast
                ? TextAlign.end
                : TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot({
    bool isFirst = false,
    bool isLast = false,
    bool isLadies = false,
  }) {
    final Color dotColor = isLadies ? Colors.white : AppTheme.primaryColor;

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFirst || isLast
            ? dotColor
            : (isLadies ? Colors.transparent : Colors.black),
        border: Border.all(color: dotColor, width: 2),
      ),
    );
  }

  String _getTripTypeLabel(BuildContext context, TripType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case TripType.departureOnly:
        return l10n.departureOnly;
      case TripType.returnOnly:
        return l10n.returnOnly;
      case TripType.roundTrip:
        return l10n.roundTrip;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  UNIFIED BOOKING CARD — All options in one cohesive container
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildUnifiedBookingCard(
    BookingStateModel state,
    BookingState notifier,
    WidgetRef ref,
  ) {
    bool isLadies = state.isLadiesOnly;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          // ── Dark Base (invisible content just for sizing) ──
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Opacity(
              opacity: 0,
              child: _buildUnifiedCardContent(state, notifier, ref),
            ),
          ),

          // ── Full-Card Pink Circular Reveal ──
          Positioned.directional(
            textDirection: Directionality.of(context),
            end: 46 - 1000,
            bottom: 35 - 1000,
            width: 2000,
            height: 2000,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutExpo,
                width: isLadies ? 2000 : 0,
                height: isLadies ? 2000 : 0,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF2D55),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // ── Visible Content (rendered only ONCE) ──
          _buildUnifiedCardContent(state, notifier, ref),
        ],
      ),
    );
  }

  Widget _buildUnifiedCardContent(
    BookingStateModel state,
    BookingState notifier,
    WidgetRef ref,
  ) {
    final bool isLadies = state.isLadiesOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section 0: Trip Summary (direction + price) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHorizontalTicketPath(state, isLadies: isLadies),
              const SizedBox(height: 20),
              // Dashed divider
              Row(
                children: List.generate(
                  30,
                  (i) => Expanded(
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      color: i.isEven
                          ? Colors.white.withValues(
                              alpha: isLadies ? 0.25 : 0.12,
                            )
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Seat/car info + price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        state.selectionType == BookingSelectionType.seat
                            ? CupertinoIcons.person_2_fill
                            : CupertinoIcons.bus,
                        color: isLadies ? Colors.white : AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.selectionType == BookingSelectionType.seat
                            ? '${AppLocalizations.of(context)!.seats}: ${state.passengerCount}'
                            : AppLocalizations.of(context)!.fullCar,
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'EGP ${notifier.totalPrice.toStringAsFixed(0)}',
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      color: isLadies ? Colors.white : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        _buildThinDivider(isLadies: isLadies),

        // ── Section 1: Booking Type ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInlineLabel(
                AppLocalizations.of(context)!.bookingType,
                isLadies: isLadies,
              ),
              const SizedBox(height: 12),
              _buildInlineSegmentedSelector(
                isLadies: isLadies,
                options: [
                  {
                    'title': AppLocalizations.of(context)!.individualSeat,
                    'icon': CupertinoIcons.person_fill,
                    'value': BookingSelectionType.seat,
                  },
                  {
                    'title': AppLocalizations.of(context)!.fullCar,
                    'icon': CupertinoIcons.bus,
                    'value': BookingSelectionType.fullCar,
                  },
                ],
                currentValue: state.selectionType,
                onChanged: (val) {
                  if (val == BookingSelectionType.fullCar) {
                    notifier.setSelectionType(BookingSelectionType.fullCar);
                    notifier.setPassengerCount(14);
                  } else {
                    notifier.setSelectionType(BookingSelectionType.seat);
                    notifier.setPassengerCount(1);
                  }
                },
              ),
            ],
          ),
        ),

        if (state.selectionType == BookingSelectionType.seat) ...[
          _buildThinDivider(isLadies: isLadies),

          // ── Section 2: Passenger Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInlineLabel(
                  AppLocalizations.of(context)!.passengerCount,
                  isLadies: isLadies,
                ),
                const SizedBox(height: 12),
                _buildInlinePassengerCounter(
                  state,
                  notifier,
                  isLadies: isLadies,
                ),
              ],
            ),
          ),

          // ── Section 3: Distribution (only if >1 passenger) ──
          if (state.passengerCount > 1) ...[
            _buildThinDivider(isLadies: isLadies),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInlineLabel('عايزين تركبو ازاي؟', isLadies: isLadies),
                  const SizedBox(height: 12),
                  _buildInlineSegmentedSelector(
                    isLadies: isLadies,
                    options: [
                      {'title': 'هتركبو مع بعض', 'value': true},
                      {'title': 'مش هتفرق المهم نركب', 'value': false},
                    ],
                    currentValue: state.splitPreference,
                    onChanged: (val) =>
                        notifier.setSplitPreference(val as bool),
                  ),
                ],
              ),
            ),
          ],
        ],

        _buildThinDivider(isLadies: isLadies),

        // ── Date ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInlineLabel(
                AppLocalizations.of(context)!.date,
                isLadies: isLadies,
              ),
              const SizedBox(height: 12),
              BookingDateCard(
                selectedDate: state.selectedDate,
                onDateSelected: notifier.selectDate,
                isLadies: isLadies,
              ),
            ],
          ),
        ),

        _buildThinDivider(isLadies: isLadies),

        // ── Trip Schedule ──
        if (!state.isToUniversity) ...[
          ..._buildInlineScheduleSection(
            state,
            notifier,
            ref,
            isLadies: isLadies,
          ),
          _buildThinDivider(isLadies: isLadies),
        ] else ...[
          // For Universities: Trip Direction (Going / Returning / Both)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInlineLabel('اتجاه الرحلة', isLadies: isLadies),
                const SizedBox(height: 12),
                _buildInlineSegmentedSelector(
                  isLadies: isLadies,
                  options: [
                    {
                      'title': 'ذهاب',
                      'icon': CupertinoIcons.arrow_right,
                      'value': TripType.departureOnly,
                    },
                    {
                      'title': 'عودة',
                      'icon': CupertinoIcons.arrow_left,
                      'value': TripType.returnOnly,
                    },
                    {
                      'title': 'ذهاب وعودة',
                      'icon': CupertinoIcons.arrow_right_arrow_left,
                      'value': TripType.roundTrip,
                    },
                  ],
                  currentValue: state.tripType,
                  onChanged: (val) {
                    notifier.selectTripType(val as TripType);
                    // Clear times when changing direction
                    if (val == TripType.departureOnly)
                      notifier.selectReturnTime(null);
                    if (val == TripType.returnOnly)
                      notifier.selectDepartureTime(null);
                  },
                ),
              ],
            ),
          ),

          _buildThinDivider(isLadies: isLadies),

          // Generic Time Picker(s) based on Direction
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.tripType == TripType.departureOnly ||
                    state.tripType == TripType.roundTrip) ...[
                  _buildInlineLabel('معاد الذهاب', isLadies: isLadies),
                  const SizedBox(height: 12),
                  TimeSelectionCard(
                    title: 'اختر معاد الذهاب',
                    isLadies: isLadies,
                    selectedTime: state.selectedDepartureTime != null
                        ? _formatTime(state.selectedDepartureTime!)
                        : null,
                    icon: CupertinoIcons.clock,
                    onTap: () {
                      _showGenericTimePicker(
                        title: 'معاد الذهاب',
                        onSelect: (time) {
                          if (time != null) {
                            notifier.selectDepartureTime(time);
                          }
                        },
                      );
                    },
                  ),
                ],
                if (state.tripType == TripType.roundTrip)
                  const SizedBox(height: 24),
                if (state.tripType == TripType.returnOnly ||
                    state.tripType == TripType.roundTrip) ...[
                  _buildInlineLabel('معاد العودة', isLadies: isLadies),
                  const SizedBox(height: 12),
                  TimeSelectionCard(
                    title: 'اختر معاد العودة',
                    isLadies: isLadies,
                    selectedTime: state.selectedReturnTime != null
                        ? _formatTime(state.selectedReturnTime!)
                        : null,
                    icon: CupertinoIcons.clock_fill,
                    onTap: () {
                      _showGenericTimePicker(
                        title: 'معاد العودة',
                        onSelect: (time) {
                          if (time != null) {
                            notifier.selectReturnTime(time);
                          }
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          _buildThinDivider(isLadies: isLadies),
        ],

        // ── Ladies Only (always last) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: state.isLadiesOnly
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.person_2_fill,
                  color: state.isLadiesOnly
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'عربية ستات بس',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CupertinoSwitch(
                activeTrackColor: const Color(0xFF9E003A),
                thumbColor: Colors.white,
                value: state.isLadiesOnly,
                onChanged: notifier.setIsLadiesOnly,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Inline Label (small, dim, inside the card) ───
  Widget _buildInlineLabel(String text, {bool isLadies = false}) {
    return Text(
      text,
      style: AppTheme.textTheme.bodySmall?.copyWith(
        color: isLadies
            ? Colors.white.withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.4),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  // ─── Thin Divider (ultra-subtle separator) ───
  Widget _buildThinDivider({bool isLadies = false}) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: isLadies
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.06),
    );
  }

  // ─── Inline Segmented Selector (no outer container) ───
  Widget _buildInlineSegmentedSelector({
    required List<Map<String, dynamic>> options,
    required dynamic currentValue,
    required Function(dynamic) onChanged,
    bool isLadies = false,
  }) {
    final Color selectedBg = isLadies ? Colors.white : AppTheme.primaryColor;
    final Color selectedText = isLadies
        ? const Color(0xFFFF2D55)
        : Colors.black;
    final Color unselectedText = isLadies
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.7);
    final Color unselectedIcon = isLadies
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isLadies ? 0.1 : 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: options.map((opt) {
          bool isSelected = opt['value'] == currentValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt['value']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: selectedBg.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (opt['icon'] != null) ...[
                      Icon(
                        opt['icon'] as IconData,
                        color: isSelected ? selectedText : unselectedIcon,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        opt['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: isSelected ? selectedText : unselectedText,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Inline Passenger Counter (compact, no outer box) ───
  Widget _buildInlinePassengerCounter(
    BookingStateModel state,
    BookingState notifier, {
    bool isLadies = false,
  }) {
    final Color accentColor = isLadies ? Colors.white : AppTheme.primaryColor;
    final Color dimText = isLadies
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isLadies ? 0.1 : 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: state.passengerCount > 1
                ? () => notifier.setPassengerCount(state.passengerCount - 1)
                : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isLadies ? 0.15 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.minus,
                color: state.passengerCount > 1
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                size: 20,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                '${state.passengerCount}',
                style: AppTheme.textTheme.headlineSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.seats,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: dimText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: state.passengerCount < 14
                ? () => notifier.setPassengerCount(state.passengerCount + 1)
                : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isLadies ? 0.15 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.add,
                color: state.passengerCount < 14
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
