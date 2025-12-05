import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import '../../../booking/presentation/pages/booking_page.dart';
import '../../../../core/widgets/ios_components.dart';
import '../../../../core/widgets/animated_progress_slider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../providers/home_provider.dart';
import '../../../booking/domain/entities/city_entity.dart';
import '../../../booking/domain/entities/university_entity.dart';
import '../../../booking/domain/entities/station_entity.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/trip_map_sheet.dart';
import '../widgets/active_subscription_card.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/presentation/widgets/subscription_plans_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    AppLogger.debug('HomePage build called');
    // Get screen size for responsive layout
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صباح الخير،',
                        style: AppTheme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final user = ref.watch(authProvider);
                          final firstName =
                              user?.fullName.split(' ').first ?? 'يا صديقي';
                          return Text(
                            firstName,
                            style: AppTheme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                    child: Consumer(
                      builder: (context, ref, child) {
                        final user = ref.watch(authProvider);
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: user?.avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(user!.avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: user?.avatarUrl == null
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    CupertinoIcons.person_fill,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Invalidate providers to trigger refresh
                  ref.invalidate(upcomingBookingProvider);
                  ref.invalidate(userBookingsProvider);
                  ref.invalidate(userSubscriptionsProvider);
                  ref.invalidate(activeSubscriptionProvider);
                  // Wait for the providers to refresh
                  await Future.wait([
                    ref.read(upcomingBookingProvider.future),
                    ref.read(userBookingsProvider.future),
                    ref.read(userSubscriptionsProvider.future),
                    ref.read(activeSubscriptionProvider.future),
                  ]);
                },
                color: AppTheme.primaryColor,
                backgroundColor: Colors.white,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Check for active subscription first
                    Consumer(
                      builder: (context, ref, child) {
                        final activeSubAsync = ref.watch(
                          activeSubscriptionProvider,
                        );
                        final userBookingsAsync = ref.watch(
                          userBookingsProvider,
                        );

                        return activeSubAsync.when(
                          data: (subscription) {
                            if (subscription != null) {
                              // Get upcoming regular bookings (not from subscription)
                              final upcomingBookings =
                                  userBookingsAsync.value
                                      ?.where(
                                        (b) =>
                                            b.bookingDate.isAfter(
                                              DateTime.now(),
                                            ) &&
                                            b.subscriptionId == null,
                                      )
                                      .toList() ??
                                  [];

                              // User has active subscription
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('اشتراكك النشط'),
                                  const SizedBox(height: 16),
                                  ActiveSubscriptionCard(
                                    subscription: subscription,
                                    regularBookings: upcomingBookings,
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              );
                            }
                            // No active subscription, show upcoming trip
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('رحلتك الجاية'),
                                const SizedBox(height: 16),
                                _buildUpcomingTripCard(),
                              ],
                            );
                          },
                          loading: () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('رحلتك الجاية'),
                              const SizedBox(height: 16),
                              _buildUpcomingTripCard(),
                            ],
                          ),
                          error: (_, __) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('رحلتك الجاية'),
                              const SizedBox(height: 16),
                              _buildUpcomingTripCard(),
                            ],
                          ),
                        );
                      },
                    ),

                    // Route Info - Only show if there is an upcoming booking
                    Consumer(
                      builder: (context, ref, child) {
                        final upcomingBookingAsync = ref.watch(
                          upcomingBookingProvider,
                        );
                        return upcomingBookingAsync.when(
                          data: (booking) {
                            if (booking == null) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 32),
                                _buildSectionTitle('مسار الرحلة'),
                                const SizedBox(height: 16),
                                _buildRouteInfoCard(booking),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Button
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'جاهز لحجز رحلتك الجديدة؟',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  IOSButton(
                    text: 'احجز رحلتك',
                    onPressed: () => _showLocationDrawer(context),
                    icon: CupertinoIcons.ticket_fill,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildUpcomingTripCard() {
    final upcomingBookingAsync = ref.watch(upcomingBookingProvider);

    return upcomingBookingAsync.when(
      data: (booking) {
        if (booking == null) {
          // Empty state - no bookings - centered without container
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.calendar_badge_minus,
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    size: 120,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'لا توجد رحلات محجوزة',
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'احجز رحلتك الجاية دلوقتي عشان تضمن مكانك',
                      textAlign: TextAlign.center,
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Has booking - display trip card
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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.status == BookingStatus.confirmed
                                ? 'مؤكد'
                                : 'قريباً',
                            style: AppTheme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.arrow_right_circle_fill,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'التاريخ',
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${booking.bookingDate.day} ${_getMonthName(booking.bookingDate.month)}',
                                style: AppTheme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نوع الرحلة',
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTripTypeLabel(booking.tripType),
                                style: AppTheme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.money_dollar_circle,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'السعر: ${booking.totalPrice.toStringAsFixed(0)} ج.م',
                            style: AppTheme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppTheme.errorColor,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل الرحلات',
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
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

  Widget _buildRouteInfoCard(BookingEntity booking) {
    // Determine route based on trip type
    String from = 'مدينتي';
    String to = 'الجامعة الألمانية (GUC)';

    if (booking.tripType == 'return_only') {
      from = 'الجامعة الألمانية (GUC)';
      to = 'مدينتي';
    }

    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => TripMapSheet(booking: booking),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          children: [
            _buildLocationRow(
              icon: CupertinoIcons.circle_fill,
              iconColor: AppTheme.primaryColor,
              label: 'من',
              value: from,
              isLast: false,
            ),
            _buildLocationRow(
              icon: CupertinoIcons.location_solid,
              iconColor: Colors.black,
              label: 'إلى',
              value: to,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Icon(icon, color: iconColor, size: 16),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.dividerColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isLast) const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDrawer(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const LocationSelectionDrawer(),
    );
  }
}

// Location Selection Drawer
class LocationSelectionDrawer extends ConsumerStatefulWidget {
  final bool navigateToSubscription;

  const LocationSelectionDrawer({
    super.key,
    this.navigateToSubscription = false,
  });

  @override
  ConsumerState<LocationSelectionDrawer> createState() =>
      _LocationSelectionDrawerState();
}

class _LocationSelectionDrawerState
    extends ConsumerState<LocationSelectionDrawer> {
  CityEntity? selectedCity;
  UniversityEntity? selectedUniversity;
  StationEntity? selectedStation;

  Widget _buildSelectionCard({
    required String title,
    required String? value,
    required String placeholder,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    final isSelected = value != null;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? placeholder,
                    style: isSelected
                        ? AppTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )
                        : AppTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.chevron_left,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    // Removed empty check - every city now has universities and stations
    int selectedIndex = 0;
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
                      'إلغاء',
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
                    onTap: () {
                      onSelected(items[selectedIndex]);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'تم',
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
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                onSelectedItemChanged: (int index) => selectedIndex = index,
                childCount: items.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    onSelected(items[index]);
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Text(
                      labelBuilder(items[index]),
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesProvider);
    final universitiesAsync = selectedCity != null
        ? ref.watch(universitiesProvider(selectedCity!.id))
        : const AsyncValue.data(<UniversityEntity>[]);
    final stationsAsync =
        selectedCity !=
            null // Changed from selectedUniversity to selectedCity
        ? ref.watch(
            stationsProvider(selectedCity!.id),
          ) // Changed from selectedUniversity!.id to selectedCity!.id
        : const AsyncValue.data(<StationEntity>[]);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final user = ref.watch(authProvider);
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          image: user?.avatarUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(user!.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user?.avatarUrl == null
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  CupertinoIcons.person_fill,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختار موقعك',
                        style: AppTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'حدد المدينة، الجامعة، والمحطة',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: AnimatedProgressSlider(
              currentStep: selectedStation != null
                  ? 2 // Final step (Station)
                  : (selectedUniversity != null
                        ? 1 // University step
                        : (selectedCity != null
                              ? 0
                              : -1)), // City step or initial (-1)
              totalSteps: 3,
              labels: const ['المدينة', 'الجامعة', 'المحطة'],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // City Selection
                citiesAsync.when(
                  data: (cities) => _buildSelectionCard(
                    title: 'المدينة',
                    value: selectedCity?.nameAr,
                    placeholder: 'اختار المدينة',
                    icon: CupertinoIcons.building_2_fill,
                    onTap: () => _showPicker<CityEntity>(
                      title: 'اختار المدينة',
                      items: cities,
                      labelBuilder: (city) => city.nameAr,
                      onSelected: (city) {
                        setState(() {
                          selectedCity = city;
                          selectedUniversity = null;
                          selectedStation = null;
                        });
                      },
                    ),
                  ),
                  loading: () => _buildSelectionCard(
                    title: 'المدينة',
                    value: null,
                    placeholder: 'جاري التحميل...',
                    icon: CupertinoIcons.building_2_fill,
                    onTap: () {},
                    isLoading: true,
                    isEnabled: false,
                  ),
                  error: (err, stack) => Text('Error: $err'),
                ),

                if (selectedCity != null) ...[
                  const SizedBox(height: 12),
                  // University Selection
                  universitiesAsync.when(
                    data: (universities) => _buildSelectionCard(
                      title: 'الجامعة',
                      value: selectedUniversity?.nameAr,
                      placeholder: 'اختار الجامعة',
                      icon: CupertinoIcons.book_fill,
                      onTap: () => _showPicker<UniversityEntity>(
                        title: 'اختار الجامعة',
                        items: universities,
                        labelBuilder: (uni) => uni.nameAr,
                        onSelected: (uni) {
                          setState(() {
                            selectedUniversity = uni;
                            selectedStation = null;
                          });
                        },
                      ),
                    ),
                    loading: () => _buildSelectionCard(
                      title: 'الجامعة',
                      value: null,
                      placeholder: 'جاري التحميل...',
                      icon: CupertinoIcons.book_fill,
                      onTap: () {},
                      isLoading: true,
                      isEnabled: false,
                    ),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ],

                if (selectedUniversity != null) ...[
                  const SizedBox(height: 12),
                  // Station Selection
                  stationsAsync.when(
                    data: (stations) => _buildSelectionCard(
                      title: 'المحطة',
                      value: selectedStation?.nameAr,
                      placeholder: 'اختار المحطة',
                      icon: CupertinoIcons.location_fill,
                      onTap: () => _showPicker<StationEntity>(
                        title: 'اختار المحطة',
                        items: stations,
                        labelBuilder: (station) => station.nameAr,
                        onSelected: (station) {
                          setState(() {
                            selectedStation = station;
                          });
                        },
                      ),
                    ),
                    loading: () => _buildSelectionCard(
                      title: 'المحطة',
                      value: null,
                      placeholder: 'جاري التحميل...',
                      icon: CupertinoIcons.location_fill,
                      onTap: () {},
                      isLoading: true,
                      isEnabled: false,
                    ),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: IOSButton(
              text: 'متابعة',
              onPressed: selectedStation != null
                  ? () {
                      // Set location data in Booking Provider
                      ref
                          .read(bookingStateProvider.notifier)
                          .setLocationData(
                            city: selectedCity!,
                            university: selectedUniversity!,
                            station: selectedStation!,
                          );

                      Navigator.pop(context);

                      // Navigate based on mode
                      if (widget.navigateToSubscription) {
                        // Show subscription plans sheet
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => const SubscriptionPlansSheet(),
                        );
                      } else {
                        // Navigate to booking page
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const BookingPage(),
                          ),
                        );
                      }
                    }
                  : null,
              color: selectedStation != null
                  ? AppTheme.primaryColor
                  : AppTheme.dividerColor,
            ),
          ),
        ],
      ),
    );
  }
}
