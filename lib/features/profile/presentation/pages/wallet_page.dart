import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

import '../widgets/transaction_details_sheet.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final subscriptionsAsync = ref.watch(userSubscriptionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '150.00',
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'شحن الرصيد',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return _buildTransactionItem(
                            context,
                            transaction.title,
                            _formatDate(transaction.date),
                            '- ${transaction.amount} ج.م',
                            false,
                            transaction.originalObject,
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
        // TODO: Add subscription details sheet if needed
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
