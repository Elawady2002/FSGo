import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';

import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../payment/presentation/pages/payment_page.dart';

import '../providers/wallet_provider.dart';
import '../widgets/digital_ticket.dart';
import '../widgets/top_up_sheet.dart';
import '../widgets/transaction_details_sheet.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final bookingsAsync = ref.watch(userBookingsProvider);
    final subscriptionsAsync = ref.watch(userSubscriptionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_right, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'المحفظة',
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate providers to trigger refresh
          await ref.read(walletProvider.notifier).refresh();
          ref.invalidate(userBookingsProvider);
          ref.invalidate(userSubscriptionsProvider);
          // Wait for the providers to refresh
          await Future.wait([
            ref.read(userBookingsProvider.future),
            ref.read(userSubscriptionsProvider.future),
          ]);
        },
        color: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الرصيد الحالي',
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    walletState.isLoading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                walletState.balance.toStringAsFixed(2),
                                style: AppTheme.textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ج.م',
                                style: AppTheme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'شحن الرصيد',
                      onPressed: () async {
                        final result = await showModalBottomSheet<Map<String, String>>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const TopUpSheet(),
                        );

                        if (result != null && context.mounted) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => PaymentPage(
                                planName: 'شحن الرصيد',
                                amount: result['amount']!,
                                isSubscription: false,
                                selectedMethod: result['method'],
                              ),
                            ),
                          );
                        }
                      },
                      backgroundColor: AppTheme.primaryColor,
                      textColor: Colors.black,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Transactions
              Text(
                'آخر العمليات',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Transactions List
              bookingsAsync.when(
                data: (bookings) {
                  return subscriptionsAsync.when(
                    data: (subscriptions) {
                      // Combine and sort transactions
                      final transactions = <_TransactionItem>[];

                      for (final booking in bookings) {
                        transactions.add(
                          _TransactionItem(
                            title: 'دفع رحلة',
                            date: booking.createdAt,
                            amount: booking.totalPrice,
                            originalObject: booking,
                            type: _TransactionType.booking,
                          ),
                        );
                      }

                      for (final subscription in subscriptions) {
                        transactions.add(
                          _TransactionItem(
                            title:
                                'اشتراك ${subscription.planType.displayName}',
                            date: subscription.createdAt,
                            amount: subscription.amount,
                            originalObject: subscription,
                            type: _TransactionType.subscription,
                          ),
                        );
                      }

                      // Sort by date (newest first)
                      transactions.sort((a, b) => b.date.compareTo(a.date));

                      if (transactions.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('لا توجد عمليات سابقة'),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return DigitalTicket(
                            title: transaction.title,
                            date: transaction.date,
                            amount: transaction.amount,
                            status: 'مدفوع',
                            type: transaction.type == _TransactionType.booking
                                ? 'booking'
                                : 'subscription',
                            onTap: () {
                              if (transaction.originalObject is BookingEntity) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => TransactionDetailsSheet(
                                    booking: transaction.originalObject,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    String title,
    String date,
    String amount,
    bool isCredit,
    dynamic originalObject,
  ) {
    return GestureDetector(
      onTap: () {
        if (originalObject is BookingEntity) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                TransactionDetailsSheet(booking: originalObject),
          );
        }
        // NOTE: Add subscription details sheet if needed
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCredit
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit
                    ? CupertinoIcons.arrow_down_left
                    : CupertinoIcons.arrow_up_right,
                color: isCredit ? AppTheme.successColor : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCredit ? AppTheme.successColor : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple date formatting, you might want to use intl package
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

enum _TransactionType { booking, subscription }

class _TransactionItem {
  final String title;
  final DateTime date;
  final double amount;
  final dynamic originalObject;
  final _TransactionType type;

  _TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.originalObject,
    required this.type,
  });
}
