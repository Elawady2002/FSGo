import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fielsekkia_driver/l10n/app_localizations.dart';
import 'package:fielsekkia_driver/core/theme/app_theme.dart';
import 'package:fielsekkia_driver/features/booking/presentation/providers/booking_provider.dart';
import 'package:fielsekkia_driver/features/booking/domain/entities/booking_entity.dart';
import 'package:fielsekkia_driver/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fielsekkia_driver/features/subscription/domain/entities/subscription_entity.dart';

class RideHistoryPage extends ConsumerStatefulWidget {
  const RideHistoryPage({super.key});

  @override
  ConsumerState<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends ConsumerState<RideHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.rideHistory,
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: const Color(0xFFC9D420),
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: l10n.upcoming),
                Tab(text: l10n.past),
                Tab(text: l10n.subscriptions),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingRides(),
          _buildPastRides(),
          _buildSubscriptions(),
        ],
      ),
    );
  }

  Widget _buildUpcomingRides() {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final upcomingBookings = bookings
            .where(
              (b) =>
                  b.bookingDate.isAfter(
                    DateTime.now().subtract(const Duration(days: 1)),
                  ) &&
                  (b.status == BookingStatus.pending ||
                      b.status == BookingStatus.confirmed),
            )
            .toList();

        if (upcomingBookings.isEmpty) {
          return _buildEmptyState(
            AppLocalizations.of(context)!.noUpcomingRides,
          );
        }

        return _buildAnimatedList(
          itemCount: upcomingBookings.length,
          itemBuilder: (context, index) =>
              _buildRideCard(upcomingBookings[index]),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildPastRides() {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final pastBookings = bookings
            .where(
              (b) =>
                  b.bookingDate.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)),
                  ) ||
                  b.status == BookingStatus.cancelled ||
                  b.status == BookingStatus.completed,
            )
            .toList();

        if (pastBookings.isEmpty) {
          return _buildEmptyState(AppLocalizations.of(context)!.noPastRides);
        }

        return _buildAnimatedList(
          itemCount: pastBookings.length,
          itemBuilder: (context, index) => _buildRideCard(pastBookings[index]),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildSubscriptions() {
    final subscriptionsAsync = ref.watch(userSubscriptionsProvider);

    return subscriptionsAsync.when(
      data: (subscriptions) {
        if (subscriptions.isEmpty) {
          return _buildEmptyState(
            AppLocalizations.of(context)!.noSubscriptions,
          );
        }

        return _buildAnimatedList(
          itemCount: subscriptions.length,
          itemBuilder: (context, index) =>
              _buildSubscriptionCard(subscriptions[index]),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildAnimatedList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: itemBuilder(context, index),
        );
      },
    );
  }

  Widget _buildSubscriptionCard(SubscriptionEntity subscription) {
    final statusInfo = _getSubscriptionStatusInfo(subscription.status);
    final totalDays = subscription.endDate
        .difference(subscription.startDate)
        .inDays;
    final remainingDays = subscription.endDate
        .difference(DateTime.now())
        .inDays;
    final progress = (totalDays - remainingDays) / totalDays;
    final progressClamped = progress.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                        color: statusInfo['color'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusInfo['label'],
                        style: TextStyle(
                          color: statusInfo['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${subscription.amount.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSubInfoItem(
                      icon: CupertinoIcons.calendar,
                      label: AppLocalizations.of(context)!.plan,
                      value: subscription.planType.displayName,
                    ),
                    const Spacer(),
                    _buildSubInfoItem(
                      icon: CupertinoIcons.time,
                      label: AppLocalizations.of(context)!.daysRemaining,
                      value:
                          '${remainingDays > 0 ? remainingDays : 0} ${AppLocalizations.of(context)!.day}',
                      isEnd: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressClamped,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      remainingDays > 5 ? AppTheme.primaryColor : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.from}: ${subscription.startDate.day}/${subscription.startDate.month}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${AppLocalizations.of(context)!.to}: ${subscription.endDate.day}/${subscription.endDate.month}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isEnd = false,
  }) {
    return Column(
      crossAxisAlignment: isEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEnd) Icon(icon, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            if (isEnd) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: Colors.grey.shade400),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(BookingEntity booking) {
    final statusInfo = _getStatusInfo(booking.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      CupertinoIcons.ticket_fill,
                      color: AppTheme.primaryDark,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTripTypeLabel(booking.tripType),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${booking.totalPrice.toStringAsFixed(0)} ${AppLocalizations.of(context)!.egp}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo['color'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusInfo['label'],
                          style: TextStyle(
                            color: statusInfo['color'],
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildTicketDashedLine(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  if (booking.tripType != 'university_request' || booking.departureTime != null)
                    _buildTripDetailRow(
                      icon: CupertinoIcons.time,
                      title: AppLocalizations.of(context)!.departureTime,
                      value: booking.departureTime ?? '7:00 AM',
                    ),
                  const Spacer(),
                  if (booking.tripType == 'round_trip' || (booking.tripType == 'university_request' && booking.returnTime != null))
                    _buildTripDetailRow(
                      icon: CupertinoIcons.arrow_2_squarepath,
                      title: AppLocalizations.of(context)!.returnTime,
                      value: booking.returnTime ?? '4:00 PM',
                      isEnd: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketDashedLine() {
    return Row(
      children: [
        SizedBox(
          width: 10,
          height: 20,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  (constraints.constrainWidth() / 10).floor(),
                  (index) => SizedBox(
                    width: 5,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: 10,
          height: 20,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetailRow({
    required IconData icon,
    required String title,
    required String value,
    bool isEnd = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isEnd) Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: isEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        if (isEnd) ...[
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: Colors.grey.shade400),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.ticket,
                size: 80,
                color: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.errorLoadingData,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(BookingStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case BookingStatus.confirmed:
        return {'label': l10n.confirmed, 'color': AppTheme.successColor};
      case BookingStatus.pending:
        return {'label': l10n.pending, 'color': Colors.orange};
      case BookingStatus.cancelled:
        return {'label': l10n.cancelled, 'color': AppTheme.errorColor};
      case BookingStatus.completed:
        return {'label': l10n.completed, 'color': Colors.grey};
    }
  }

  String _getTripTypeLabel(String tripType) {
    final l10n = AppLocalizations.of(context)!;
    switch (tripType) {
      case 'departure_only':
        return l10n.departure;
      case 'return_only':
        return l10n.returnText;
      case 'round_trip':
        return l10n.roundTrip;
      case 'university_request':
        return 'طلب خط جامعة';
      default:
        return tripType;
    }
  }

  Map<String, dynamic> _getSubscriptionStatusInfo(SubscriptionStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case SubscriptionStatus.active:
        return {'label': l10n.active, 'color': AppTheme.successColor};
      case SubscriptionStatus.pending:
        return {'label': l10n.underReview, 'color': Colors.orange};
      case SubscriptionStatus.expired:
        return {'label': l10n.expired, 'color': Colors.grey};
    }
  }
}
