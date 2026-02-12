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
import '../../../payment/presentation/pages/top_up_amount_page.dart';

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
          await ref.read(walletProvider.notifier).refresh();
          ref.invalidate(userBookingsProvider);
          ref.invalidate(userSubscriptionsProvider);
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
            children: [
              // New Wallet Card Design
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Green Section (Balance)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor, // Brand Yellow
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Stack(
                        children: [
                          // Rivets (Decorative dots)
                          const Positioned(top: 0, left: 0, child: _Rivet()),
                          const Positioned(top: 0, right: 0, child: _Rivet()),
                          const Positioned(bottom: 0, left: 0, child: _Rivet()),
                          const Positioned(bottom: 0, right: 0, child: _Rivet()),

                          // Content
                          Center(
                            child: Column(
                              children: [
                                // Balance
                                walletState.isLoading
                                    ? const CupertinoActivityIndicator()
                                    : Text(
                                        '${walletState.balance.toStringAsFixed(2)} EGP',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF003300), // Dark Green
                                          letterSpacing: -1,
                                        ),
                                      ),
                                const SizedBox(height: 8),
                                Text(
                                  'الرصيد الحالي',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF003300).withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Bottom Black Section (Actions)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Row(
                        children: [
                          // Top Up Button
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) => const TopUpAmountPage(isWithdraw: false),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.arrow_down_left, color: Colors.white, size: 24),
                                    SizedBox(height: 8),
                                    Text(
                                      'شحن',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Divider
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          
                          // Widthdraw Button
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) => const TopUpAmountPage(isWithdraw: true),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.arrow_up_right, color: Colors.white, size: 24), // Swap icon usually means exchange, but using up-right for withdraw
                                    SizedBox(height: 8),
                                    Text(
                                      'سحب',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
             
              // Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سجل العمليات',
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'عرض الكل',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                            title: 'حجز رحلة',
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

                      transactions.sort((a, b) => b.date.compareTo(a.date));

                      if (transactions.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text('لا توجد عمليات سابقة', style: TextStyle(color: Colors.grey)),
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
                          // Determine style based on type
                          // Booking -> Debit (Red arrow up-right)
                          // Subscription -> Debit (Red arrow up-right)
                          
                          // If we had TopUp -> Credit (Green arrow down-left)
                          // If we had Withdraw -> Debit (Red arrow up-right or different icon)
                          
                          final isCredit = false; // Currently all are debits (bookings/subs)
                          
                          return _buildTransactionItem(
                             context,
                             transaction.title,
                             _formatDate(transaction.date), // Custom format to match "8:18 10/2" if possible
                             transaction.amount.toStringAsFixed(2),
                             isCredit,
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
    // Colors from image
    final iconBgColor = isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFEECEB); // Pale Green / Pale Red
    final iconColor = isCredit ? const Color(0xFF4CAF50) : const Color(0xFFF56356); // Green / Salmon Red
    final iconData = isCredit ? CupertinoIcons.arrow_down_left : CupertinoIcons.arrow_up_right;

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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon (Right in RTL)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Title & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Amount (Left in RTL)
            Text(
              '${isCredit ? '+' : '-'}$amount',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black, 
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format: 18:44 9/2
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}';
  }
}

class _Rivet extends StatelessWidget {
  const _Rivet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFF003300),
        shape: BoxShape.circle,
      ),
    );
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
