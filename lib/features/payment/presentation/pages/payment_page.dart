import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/ios_components.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tracking/presentation/pages/confirmation_page.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../widgets/payment_proof_sheet.dart';
import '../../../subscription/presentation/pages/subscription_confirmation_page.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final String planName;
  final String amount;
  final bool isSubscription;
  final bool isInstallment;
  final SubscriptionScheduleParams? scheduleParams;

  const PaymentPage({
    super.key,
    required this.planName,
    required this.amount,
    this.isSubscription = false,
    this.isInstallment = false,
    this.scheduleParams,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.backgroundColor,
        border: null,
        middle: Text(
          'الدفع',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Order Summary
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.planName,
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isSubscription
                            ? 'اشتراك باقات الطلاب'
                            : 'حجز رحلة',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.amount} ج.م',
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Payment Methods Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                tabs: const [
                  SizedBox(width: 120, child: Tab(text: 'InstaPay')),
                  SizedBox(width: 150, child: Tab(text: 'Vodafone Cash')),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPaymentMethod(
                    title: 'تحويل انستا باي',
                    imagePath: 'lib/assets/image/launcher_icons/instapay.png',
                    accountName: 'Fi El Sekka',
                    accountNumber: 'user@instapay',
                    instructions:
                        'انسخ عنوان الدفع وحول المبلغ، وبعدين ابعت سكرين شوت للتحويل.',
                  ),
                  _buildPaymentMethod(
                    title: 'فودافون كاش',
                    imagePath:
                        'lib/assets/image/launcher_icons/vodafone_cash.png',
                    accountName: 'Fi El Sekka Wallet',
                    accountNumber: '01012345678',
                    instructions:
                        'حول المبلغ على الرقم ده، وبعدين ابعت سكرين شوت لرسالة التأكيد.',
                  ),
                ],
              ),
            ),

            // Confirm Button
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
                text: 'الدفع',
                onPressed: () async {
                  final result = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    isDismissible: false,
                    enableDrag: false,
                    builder: (sheetContext) => PaymentProofSheet(
                      onConfirm: (imagePath, accountNumber) async {
                        final storageService = ref.read(storageServiceProvider);
                        final user = ref.read(authProvider);

                        if (user == null) {
                          throw Exception('المستخدم غير مسجل الدخول');
                        }

                        String? imageUrl;

                        // Upload image to Supabase Storage if provided
                        if (imagePath != null && imagePath.isNotEmpty) {
                          AppLogger.info(
                            '📤 Uploading payment proof to Supabase Storage...',
                          );
                          try {
                            imageUrl = await storageService.uploadPaymentProof(
                              File(imagePath),
                              user.id,
                            );
                            AppLogger.info(
                              '✅ Image uploaded successfully: $imageUrl',
                            );
                          } catch (e) {
                            AppLogger.error('❌ Failed to upload image: $e');
                            throw Exception('فشل رفع صورة الإثبات: $e');
                          }
                        }

                        // Handle subscription or booking based on type
                        if (widget.isSubscription) {
                          // Create subscription
                          AppLogger.info('📝 Creating subscription...');
                          final subscriptionRepository = ref.read(
                            subscriptionRepositoryProvider,
                          );

                          // Parse plan type from plan name
                          SubscriptionPlanType planType;
                          if (widget.planName.contains('شهر')) {
                            planType = SubscriptionPlanType.monthly;
                          } else {
                            planType = SubscriptionPlanType.semester;
                          }

                          final result = await subscriptionRepository
                              .createSubscription(
                                userId: user.id,
                                planType: planType,
                                paymentProofUrl: imageUrl,
                                transferNumber: accountNumber,
                                isInstallment: widget.isInstallment,
                                scheduleParams: widget.scheduleParams,
                              );

                          result.fold(
                            (failure) {
                              AppLogger.error(
                                '❌ Subscription creation failed: ${failure.message}',
                              );
                              throw Exception(failure.message);
                            },
                            (_) {
                              AppLogger.info(
                                '✅ Subscription created successfully!',
                              );
                            },
                          );
                        } else {
                          // Create booking in database
                          AppLogger.info(
                            '📝 Creating booking with payment details...',
                          );
                          AppLogger.info('   Image URL: $imageUrl');
                          AppLogger.info('   Transfer number: $accountNumber');

                          final bookingRepository = ref.read(
                            bookingRepositoryProvider,
                          );
                          final bookingNotifier = ref.read(
                            bookingStateProvider.notifier,
                          );

                          final error = await bookingNotifier.createBooking(
                            bookingRepository,
                            paymentProofImage: imageUrl,
                            transferNumber: accountNumber,
                          );

                          if (error != null) {
                            // Show error
                            AppLogger.error(
                              '❌ Booking creation failed: $error',
                            );
                            if (!mounted) return;
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                            throw Exception(error); // Throw to stop the flow
                          }

                          AppLogger.info('✅ Booking created successfully!');
                        }

                        // Success! Do not navigate here.
                        // PaymentProofSheet will pop with true.
                      },
                    ),
                  );

                  // Navigate to appropriate confirmation page based on payment type
                  AppLogger.info('📱 Payment sheet result: $result');
                  if (result == true) {
                    AppLogger.info('✅ Navigating to confirmation page...');
                    if (!mounted) return;
                    if (!context.mounted) return;

                    if (widget.isSubscription) {
                      // Navigate to subscription confirmation page
                      final now = DateTime.now();
                      final planType = widget.planName.contains('شهر')
                          ? SubscriptionPlanType.monthly
                          : SubscriptionPlanType.semester;
                      final endDate = now.add(
                        Duration(days: planType.durationDays),
                      );

                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => SubscriptionConfirmationPage(
                            planName: widget.planName,
                            price: widget.amount,
                            startDate: now,
                            endDate: endDate,
                          ),
                        ),
                      );
                    } else {
                      // Navigate to booking confirmation page
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const ConfirmationPage(),
                        ),
                      );
                    }
                  } else {
                    AppLogger.warning('❌ Payment was not confirmed');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod({
    required String title,
    required String imagePath,
    required String accountName,
    required String accountNumber,
    required String instructions,
  }) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildCopyableField('اسم الحساب', accountName),
            const SizedBox(height: 16),
            _buildCopyableField('رقم الحساب / العنوان', accountNumber),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.info_circle_fill,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    instructions,
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ $label'),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_on_doc,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
