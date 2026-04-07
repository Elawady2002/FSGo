import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';

import '../../../booking/domain/entities/booking_entity.dart';
import '../../../payment/presentation/pages/top_up_amount_page.dart';

import '../providers/wallet_provider.dart';
import '../widgets/transaction_details_sheet.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final walletTransactionsAsync = ref.watch(walletTransactionsProvider);

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
          // Force a complete rebuild of the providers to bypass any caching
          ref.invalidate(walletProvider);
          ref.invalidate(walletTransactionsProvider);
          
          // Wait for both to finish loading
          await Future.wait([
            ref.read(walletProvider.notifier).refresh(),
            ref.read(walletTransactionsProvider.future),
          ]);
        },
        color: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Wallet Card Design
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Stack(
                        children: [
                          const Positioned(top: 0, left: 0, child: _Rivet()),
                          const Positioned(top: 0, right: 0, child: _Rivet()),
                          const Positioned(bottom: 0, left: 0, child: _Rivet()),
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: _Rivet(),
                          ),

                          Center(
                            child: Column(
                              children: [
                                walletState.isLoading
                                    ? const CupertinoActivityIndicator()
                                    : Text(
                                        '${walletState.balance.toStringAsFixed(2)} EGP',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF003300),
                                          letterSpacing: -1,
                                        ),
                                      ),
                                const SizedBox(height: 8),
                                Text(
                                  'الرصيد الحالي',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF003300)
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Black Section (Action: Top-Up Only)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const TopUpAmountPage(),
                              ),
                            );
                          },
                          icon: const Icon(
                            CupertinoIcons.add,
                            color: Color(0xFF1A1A1A),
                          ),
                          label: Text(
                            'شحن رصيد',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

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

              walletTransactionsAsync.when(
                data: (walletTransactions) {
                  if (walletTransactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(
                          'لا توجد عمليات سابقة',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: walletTransactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = walletTransactions[index];
                      final isCredit = tx['type'] == 'credit';
                      final amount = (tx['amount'] as num).toDouble();
                      final reason = tx['reason'] as String;
                      final createdAt = DateTime.parse(tx['created_at']);

                      return _buildTransactionItem(
                        context,
                        reason,
                        _formatDate(createdAt),
                        amount.toStringAsFixed(2),
                        isCredit,
                        null,
                      );
                    },
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
    final iconBgColor = isCredit
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFEECEB);
    final iconColor = isCredit
        ? const Color(0xFF4CAF50)
        : const Color(0xFFF56356);
    final iconData = isCredit
        ? CupertinoIcons.arrow_down_left
        : CupertinoIcons.arrow_up_right;

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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
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
