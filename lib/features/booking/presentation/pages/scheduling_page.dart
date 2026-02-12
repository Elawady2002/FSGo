import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/booking_provider.dart';
import '../widgets/time_grid_selector.dart';

class SchedulingPage extends ConsumerStatefulWidget {
  const SchedulingPage({super.key});

  @override
  ConsumerState<SchedulingPage> createState() => _SchedulingPageState();
}

class _SchedulingPageState extends ConsumerState<SchedulingPage> {
  final List<String> _departureTimes = [
    '07:30 AM',
    '08:00 AM',
    '08:30 AM',
    '09:00 AM',
  ];
  final List<String> _returnTimes = [
    '02:30 PM',
    '03:30 PM',
    '04:30 PM',
    '05:30 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingStateProvider);
    final isSameDayBookingAllowed = ref
        .read(bookingStateProvider.notifier)
        .isSameDayBookingAllowed;
    final isSameDay = ref
        .read(bookingStateProvider.notifier)
        .isSameDay(DateTime.now(), bookingState.selectedDate);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "تحديد المواعيد",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "اختار التاريخ",
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CalendarDatePicker(
                  initialDate: bookingState.selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  onDateChanged: (date) {
                    ref.read(bookingStateProvider.notifier).selectDate(date);
                  },
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              if (!isSameDayBookingAllowed && isSameDay)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            "الحجز في نفس اليوم متاح بس قبل الساعة 7 الصبح.",
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: 32),
              Text(
                "ميعاد الذهاب",
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 300.ms).slideX(),
              const SizedBox(height: 16),
              TimeGridSelector(
                times: _departureTimes,
                selectedTime: bookingState.selectedDepartureTime,
                onSelect: (time) {
                  ref
                      .read(bookingStateProvider.notifier)
                      .selectDepartureTime(time);
                },
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),
              Text(
                "ميعاد العودة",
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 500.ms).slideX(),
              const SizedBox(height: 16),
              TimeGridSelector(
                times: _returnTimes,
                selectedTime: bookingState.selectedReturnTime,
                onSelect: (time) {
                  ref
                      .read(bookingStateProvider.notifier)
                      .selectReturnTime(time);
                },
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 48),
              CustomButton(
                text: "تأكيد الحجز",
                onPressed:
                    (isSameDayBookingAllowed || !isSameDay) &&
                        bookingState.selectedDepartureTime != null &&
                        bookingState.selectedReturnTime != null
                    ? () {
                        // Go back to home
                        Navigator.popUntil(context, (route) => route.isFirst);

                        // Show success notification
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                const Text('تم تحديد المواعيد بنجاح'),
                              ],
                            ),
                            backgroundColor: AppTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      }
                    : null, // Disable if invalid
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
