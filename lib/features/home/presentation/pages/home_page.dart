import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/utils/logger.dart';
import 'package:my_app/l10n/app_localizations.dart';
import 'package:my_app/core/providers/locale_provider.dart';
import 'package:my_app/features/booking/presentation/pages/booking_page.dart';
import 'package:my_app/core/widgets/ios_components.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../providers/home_provider.dart';
import '../../../booking/domain/entities/city_entity.dart';
import '../../../booking/domain/entities/university_entity.dart';
import '../../../booking/domain/entities/boarding_station_entity.dart';
import '../../../booking/domain/entities/arrival_station_entity.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/trip_map_sheet.dart';
import '../widgets/unified_trip_card.dart';
import '../widgets/wallet_widget.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/presentation/widgets/subscription_plans_sheet.dart';
import '../widgets/empty_bookings_widget.dart';
import '../../../../core/widgets/dashed_rect.dart';
import '../../../../core/widgets/custom_input.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    AppLogger.debug('HomePage build called');
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness:
            Brightness.light, // For iOS (dark icons on light bg)
      ),
      child: Scaffold(
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
                          l10n.goodMorning,
                          style: AppTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final user = ref.watch(authProvider).valueOrNull;
                            final firstName =
                                user?.fullName.split(' ').first ?? l10n.friend;
                            return Text(
                              firstName,
                              style: AppTheme.textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const WalletWidget(),
                        const SizedBox(width: 12),
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
                              final user = ref.watch(authProvider).valueOrNull;
                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
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

                          return userBookingsAsync.when(
                            data: (bookings) {
                              final now = DateTime.now();
                              final upcomingBookings = bookings.where((b) {
                                return !b.isCancelled &&
                                    !b.isCompleted &&
                                    (b.bookingDate.isAfter(
                                          now.subtract(const Duration(days: 1)),
                                        ) ||
                                        b.bookingDate.day == now.day);
                              }).toList();

                              // Sort by date ascending, pick nearest
                              upcomingBookings.sort(
                                (a, b) =>
                                    a.bookingDate.compareTo(b.bookingDate),
                              );
                              final nearestBooking =
                                  upcomingBookings.firstOrNull;

                              return activeSubAsync.when(
                                data: (subscription) {
                                  if (nearestBooking == null &&
                                      subscription == null) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionTitle(
                                          context,
                                          ref,
                                          l10n.nextTrip,
                                        ),
                                        const SizedBox(height: 16),
                                        const EmptyBookingsWidget(),
                                      ],
                                    );
                                  }

                                  String sectionTitle = nearestBooking != null
                                      ? l10n.nextTrip
                                      : l10n.activeSubscription;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionTitle(
                                        context,
                                        ref,
                                        sectionTitle,
                                      ),
                                      const SizedBox(height: 16),
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Bottom layer: Title and Route Info (paints behind)
                                          if (nearestBooking != null)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Spacer to reserve height for physical alignment
                                                const SizedBox(height: 240),
                                                const SizedBox(height: 16),
                                                _buildSectionTitle(
                                                  context,
                                                  ref,
                                                  l10n.tripRoute,
                                                ),
                                                const SizedBox(height: 12),
                                                _buildRouteInfoCard(
                                                  nearestBooking,
                                                ),
                                              ],
                                            ),
                                          // Top layer: The Card (paints on top of everything)
                                          UnifiedTripCard(
                                            booking: nearestBooking,
                                            subscription: nearestBooking == null
                                                ? subscription
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (e, s) => const SizedBox.shrink(),
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, s) => const SizedBox.shrink(),
                          );
                        },
                      ),

                      // Route Info - Removed as per new design
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
                      l10n.readyToBook,
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    IOSButton(
                      text: l10n.bookNow,
                      onPressed: () => _showLocationDrawer(context),
                      icon: CupertinoIcons.ticket_fill,
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

  Widget _buildSectionTitle(BuildContext context, WidgetRef ref, String title) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    return Align(
      alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        title,
        style: AppTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard(BookingEntity booking) {
    final l10n = AppLocalizations.of(context)!;
    final boardingStations = ref.watch(allBoardingStationsProvider).valueOrNull ?? [];
    final arrivalStations = ref.watch(allArrivalStationsProvider).valueOrNull ?? [];
    final universities = ref.watch(allUniversitiesProvider).valueOrNull ?? [];
    final lang = ref.watch(localeProvider).languageCode;

    final pickupStation = boardingStations
        .where((s) => s.id == booking.pickupStationId)
        .firstOrNull;
    final dropoffStation = arrivalStations
        .where((s) => s.id == booking.dropoffStationId)
        .firstOrNull;

    final universityName = universities.isNotEmpty
        ? universities.first.getLocalizedName(lang)
        : 'الجامعة';

    String routeFrom = '';
    String routeTo = '';

    if (booking.tripType == 'departure_only') {
      routeFrom = pickupStation?.getLocalizedName(lang) ?? l10n.madinaty;
      if (booking.dropoffStationId != null && dropoffStation != null) {
        routeTo = dropoffStation.getLocalizedName(lang);
      } else {
        routeTo = universityName;
      }
    } else if (booking.tripType == 'return_only') {
      routeFrom = universityName;
      routeTo =
          dropoffStation?.getLocalizedName(lang) ??
          pickupStation?.getLocalizedName(lang) ??
          l10n.madinaty;
    } else {
      routeFrom = pickupStation?.getLocalizedName(lang) ?? l10n.madinaty;
      routeTo = universityName;
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
              context,
              ref,
              icon: CupertinoIcons.circle_fill,
              iconColor: AppTheme.primaryColor,
              label: l10n.from,
              value: routeFrom,
              isLast: false,
            ),
            _buildLocationRow(
              context,
              ref,
              icon: CupertinoIcons.location_solid,
              iconColor: Colors.black,
              label: l10n.to,
              value: routeTo,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationIconColumn(icon, iconColor, isLast),
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

  Widget _buildLocationIconColumn(IconData icon, Color iconColor, bool isLast) {
    return Column(
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
  BoardingStationEntity? selectedPickupStation;
  ArrivalStationEntity? selectedArrivalStation;
  bool isToUniversity = false;

  Widget _buildSelectionItem(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String? value,
    required String placeholder,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    final isSelected = value != null;
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            _buildSelectionIcon(isSelected, isLoading, icon),
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
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? placeholder,
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? Colors.black : AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
              color: AppTheme.textTertiary.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIcon(bool isSelected, bool isLoading, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
              size: 22,
            ),
    );
  }

  void _showPicker<T>(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
    bool showAddOption = false,
    String? addOptionLabel,
    ValueChanged<String>? onAddSubmit,
    String? emptyMessage,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    bool isAdding = false;
    final addController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.clear,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: items.isEmpty && emptyMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                emptyMessage,
                                style: AppTheme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: items.length + (showAddOption ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        if (showAddOption && index == items.length) {
                          if (isAdding) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomInput(
                                      controller: addController,
                                      hintText: addOptionLabel ?? 'الاسم',
                                      prefixIcon: CupertinoIcons.add,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      final val = addController.text.trim();
                                      if (val.isNotEmpty &&
                                          onAddSubmit != null) {
                                        Navigator.pop(context);
                                        onAddSubmit(val);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.checkmark_alt,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                isAdding = true;
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: DashedRect(
                                color: AppTheme.textTertiary.withValues(
                                  alpha: 0.5,
                                ),
                                strokeWidth: 1.5,
                                gap: 6.0,
                                dashWidth: 6.0,
                                radius: 12.0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.add,
                                        size: 20,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        addOptionLabel ?? 'إضافة',
                                        style: AppTheme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final item = items[index];
                        return GestureDetector(
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(context);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    labelBuilder(item),
                                    style: AppTheme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                Icon(
                                  isAr
                                      ? CupertinoIcons.chevron_left
                                      : CupertinoIcons.chevron_right,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final citiesAsync = ref.watch(citiesProvider);
    final universitiesAsync = (selectedCity != null && isToUniversity)
        ? ref.watch(universitiesProvider(selectedCity!.id))
        : const AsyncValue.data(<UniversityEntity>[]);
    final boardingStationsAsync = selectedCity != null
        ? ref.watch(boardingStationsProvider(selectedCity!.id))
        : const AsyncValue.data(<BoardingStationEntity>[]);

    final arrivalStationsAsync = selectedPickupStation != null
        ? ref.watch(arrivalStationsProvider(selectedPickupStation!.id))
        : const AsyncValue.data(<ArrivalStationEntity>[]);

    final bool isComplete = isToUniversity
        ? (selectedCity != null &&
              selectedUniversity != null &&
              selectedPickupStation != null)
        : (selectedCity != null &&
              selectedPickupStation != null &&
              selectedArrivalStation != null);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectLocation,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      style: AppTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isToUniversity
                          ? l10n.selectLocationSub
                          : l10n.selectLocationSubAlt,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Trip Type Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutQuart,
                    alignment: isAr
                        ? (isToUniversity
                              ? Alignment.centerLeft
                              : Alignment.centerRight)
                        : (isToUniversity
                              ? Alignment.centerRight
                              : Alignment.centerLeft),
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildToggleItem(
                        title: l10n.stationToStation,
                        isSelected: !isToUniversity,
                        onTap: () {
                          setState(() {
                            isToUniversity = false;
                            selectedUniversity = null;
                            selectedPickupStation = null;
                            selectedArrivalStation = null;
                          });
                        },
                      ),
                      _buildToggleItem(
                        title: l10n.forUniversity,
                        isSelected: isToUniversity,
                        onTap: () {
                          setState(() {
                            isToUniversity = true;
                            selectedUniversity = null;
                            selectedPickupStation = null;
                            selectedArrivalStation = null;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),


            // Main Selection Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // City Selection
                        citiesAsync.when(
                          data: (cities) => _buildSelectionItem(
                            context,
                            ref,
                            title: l10n.city,
                            value: selectedCity?.getLocalizedName(
                              ref.read(localeProvider).languageCode,
                            ),
                            placeholder: l10n.selectCity,
                            icon: CupertinoIcons.building_2_fill,
                            onTap: () => _showPicker<CityEntity>(
                              context,
                              ref,
                              title: l10n.selectCity,
                              items: cities,
                              labelBuilder: (city) => city.getLocalizedName(
                                ref.read(localeProvider).languageCode,
                              ),
                              onSelected: (city) {
                                setState(() {
                                  selectedCity = city;
                                  selectedUniversity = null;
                                  selectedPickupStation = null;
                                  selectedArrivalStation = null;
                                });
                              },
                            ),
                          ),
                          loading: () => _buildSelectionItem(
                            context,
                            ref,
                            title: l10n.city,
                            value: null,
                            placeholder: l10n.loading,
                            icon: CupertinoIcons.building_2_fill,
                            onTap: () {},
                            isLoading: true,
                            isEnabled: false,
                          ),
                          error: (err, stack) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('${l10n.error}: $err'),
                          ),
                        ),

                        if (selectedCity != null) ...[
                          Divider(
                            height: 1,
                            color: Colors.grey.shade100,
                            indent: 16,
                            endIndent: 16,
                          ),
                          if (isToUniversity) ...[
                            // University Selection
                            universitiesAsync.when(
                              data: (universities) => _buildSelectionItem(
                                context,
                                ref,
                                title: l10n.university,
                                value: selectedUniversity?.getLocalizedName(
                                  ref.read(localeProvider).languageCode,
                                ),
                                placeholder: l10n.selectUniversity,
                                icon: CupertinoIcons.book_fill,
                                onTap: () => _showPicker<UniversityEntity>(
                                  context,
                                  ref,
                                  title: l10n.selectUniversity,
                                  items: universities,
                                  labelBuilder: (uni) => uni.getLocalizedName(
                                    ref.read(localeProvider).languageCode,
                                  ),
                                  onSelected: (uni) {
                                    setState(() {
                                      selectedUniversity = uni;
                                      selectedPickupStation = null;
                                    });
                                  },
                                  showAddOption: true,
                                  addOptionLabel: 'إضافة جامعة غير موجودة',
                                  onAddSubmit: (String val) {
                                    setState(() {
                                      selectedUniversity = UniversityEntity(
                                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                        nameAr: val,
                                        nameEn: val,
                                        cityId: selectedCity?.id ?? '',
                                        isActive: true,
                                        location: const Location(
                                          latitude: 0,
                                          longitude: 0,
                                          address: '',
                                        ),
                                      );
                                      selectedPickupStation = null;
                                    });
                                  },
                                ),
                              ),
                              loading: () => _buildSelectionItem(
                                context,
                                ref,
                                title: l10n.university,
                                value: null,
                                placeholder: l10n.loading,
                                icon: CupertinoIcons.book_fill,
                                onTap: () {},
                                isLoading: true,
                                isEnabled: false,
                              ),
                              error: (err, stack) =>
                                  Text('${l10n.error}: $err'),
                            ),
                          ] else ...[
                            // Departure Station Selection
                            boardingStationsAsync.when(
                              data: (stations) => _buildSelectionItem(
                                context,
                                ref,
                                title: l10n.pickupStation,
                                value: selectedPickupStation?.getLocalizedName(
                                  ref.read(localeProvider).languageCode,
                                ),
                                placeholder: l10n.selectPickupPoint,
                                icon: CupertinoIcons.location_fill,
                                onTap: () => _showPicker<BoardingStationEntity>(
                                  context,
                                  ref,
                                  title: l10n.selectPickupPoint,
                                  items: stations,
                                  labelBuilder: (station) =>
                                      station.getLocalizedName(
                                        ref.read(localeProvider).languageCode,
                                      ),
                                  onSelected: (station) {
                                    setState(() {
                                      selectedPickupStation = station;
                                      selectedArrivalStation = null;
                                    });
                                  },
                                  emptyMessage: l10n.emptyPickupStation,
                                ),
                              ),
                              loading: () => _buildSelectionItem(
                                context,
                                ref,
                                title: l10n.pickupStation,
                                value: null,
                                placeholder: l10n.loading,
                                icon: CupertinoIcons.location_fill,
                                onTap: () {},
                                isLoading: true,
                                isEnabled: false,
                              ),
                              error: (err, stack) =>
                                  Text('${l10n.error}: $err'),
                            ),
                          ],
                        ],

                        if (selectedCity != null &&
                            (isToUniversity
                                ? selectedUniversity != null
                                : selectedPickupStation != null)) ...[
                          Divider(
                            height: 1,
                            color: Colors.grey.shade100,
                            indent: 16,
                            endIndent: 16,
                          ),
                          if (isToUniversity) ...[
                            // Station Selection (Pickup)
                            boardingStationsAsync.when(
                              data: (stations) => _buildSelectionItem(
                                context,
                                ref,
                                title: l10n.station,
                                value: selectedPickupStation?.getLocalizedName(
                                  ref.read(localeProvider).languageCode,
                                ),
                                placeholder: l10n.selectStation,
                                icon: CupertinoIcons.location_fill,
                                onTap: () => _showPicker<BoardingStationEntity>(
                                  context,
                                  ref,
                                  title: l10n.selectStation,
                                  items: stations,
                                  labelBuilder: (station) =>
                                      station.getLocalizedName(
                                        ref.read(localeProvider).languageCode,
                                      ),
                                  onSelected: (station) {
                                    setState(() {
                                      selectedPickupStation = station;
                                    });
                                  },
                                  emptyMessage: l10n.emptyPickupStation,
                                ),
                              ),
                              loading: () => _buildSelectionItem(
                                context,
                                ref,
                                title: l10n.station,
                                value: null,
                                placeholder: l10n.loading,
                                icon: CupertinoIcons.location_fill,
                                onTap: () {},
                                isLoading: true,
                                isEnabled: false,
                              ),
                              error: (err, stack) =>
                                  Text('${l10n.error}: $err'),
                            ),
                          ] else ...[
                            // Arrival Station Selection
                            arrivalStationsAsync.when(
                              data: (stations) => _buildSelectionItem(
                                context,
                                ref,
                                title: l10n.arrivalStation,
                                value: selectedArrivalStation?.getLocalizedName(
                                  ref.read(localeProvider).languageCode,
                                ),
                                placeholder: l10n.selectArrivalPoint,
                                icon: CupertinoIcons.pin_fill,
                                onTap: () => _showPicker<ArrivalStationEntity>(
                                  context,
                                  ref,
                                  title: l10n.selectArrivalPoint,
                                  items: stations,
                                  labelBuilder: (station) =>
                                      station.getLocalizedName(
                                        ref.read(localeProvider).languageCode,
                                      ),
                                  onSelected: (station) {
                                    setState(() {
                                      selectedArrivalStation = station;
                                    });
                                  },
                                  emptyMessage: l10n.emptyArrivalStation,
                                ),
                              ),
                              loading: () => _buildSelectionItem(
                                context,
                                ref,
                                title: l10n.arrivalStation,
                                value: null,
                                placeholder: l10n.loading,
                                icon: CupertinoIcons.pin_fill,
                                onTap: () {},
                                isLoading: true,
                                isEnabled: false,
                              ),
                              error: (err, stack) =>
                                  Text('${l10n.error}: $err'),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
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
                text: l10n.continueText,
                onPressed: isComplete
                    ? () {
                        ref
                            .read(bookingStateProvider.notifier)
                            .setLocationData(
                              city: selectedCity!,
                              university: selectedUniversity,
                              pickupStation: selectedPickupStation!,
                              arrivalStation: selectedArrivalStation,
                              isToUniversity: isToUniversity,
                            );

                        Navigator.pop(context);

                        if (widget.navigateToSubscription) {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) =>
                                const SubscriptionPlansSheet(),
                          );
                        } else {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => const BookingPage(),
                            ),
                          );
                        }
                      }
                    : null,
                color: isComplete
                    ? AppTheme.primaryColor
                    : AppTheme.dividerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 48,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              style:
                  AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : AppTheme.textSecondary,
                  ) ??
                  const TextStyle(),
              child: Text(title, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
