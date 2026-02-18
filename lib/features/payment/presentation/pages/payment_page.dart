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
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import '../widgets/payment_proof_sheet.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final String planName;
  final String amount;
  final bool isSubscription;
  final bool isInstallment;
  final SubscriptionScheduleParams? scheduleParams;
  final String? selectedMethod;

  const PaymentPage({
    super.key,
    required this.planName,
    required this.amount,
    this.isSubscription = false,
    this.isInstallment = false,
    this.scheduleParams,
    this.selectedMethod,
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
    // Pre-select tab based on selectedMethod
    final initialIndex = widget.selectedMethod == 'Vodafone Cash' ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Softer background
      appBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF5F5F7),
        border: null,
        middle: Text(
          'الدفع',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.chevron_right, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Payment Methods Selector
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.black,
                      unselectedLabelColor: AppTheme.textTertiary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      tabs: const [
                        Tab(text: 'InstaPay'),
                        Tab(text: 'Vodafone Cash'),
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
                          imagePath:
                              'lib/assets/image/launcher_icons/instapay.png',
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
                ],
              ),
            ),
          ),

          // Confirm Button Bottom Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom + 8
                  : 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
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
                      final user = ref.read(authProvider).value;
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

                        AppLogger.info('📋 Subscription details:');
                        AppLogger.info('   Plan type: ${planType.name}');
                        AppLogger.info(
                          '   Has scheduleParams: ${widget.scheduleParams != null}',
                        );
                        if (widget.scheduleParams != null) {
                          AppLogger.info(
                            '   Start date: ${widget.scheduleParams!.startDate}',
                          );
                          AppLogger.info(
                            '   Trip type: ${widget.scheduleParams!.tripType}',
                          );
                          AppLogger.info(
                            '   Schedule ID: ${widget.scheduleParams!.scheduleId}',
                          );
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
                          AppLogger.error('❌ Booking creation failed: $error');
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

                  // Invalidate providers to refresh home page
                  ref.invalidate(userBookingsProvider);
                  ref.invalidate(upcomingBookingProvider);
                  if (widget.isSubscription) {
                    ref.invalidate(activeSubscriptionProvider);
                  }

                  // Go back to home
                  Navigator.popUntil(context, (route) => route.isFirst);

                  // Show success notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.isSubscription
                                ? 'تم تفعيل الاشتراك بنجاح'
                                : 'تم الحجز بنجاح',
                          ),
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
                } else {
                  AppLogger.warning('❌ Payment was not confirmed');
                }
              },
            ),
          ),
        ],
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
      physics: const BouncingScrollPhysics(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(12),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 32),
            _buildCopyableField(
              'اسم الحساب',
              accountName,
              CupertinoIcons.person_fill,
            ),
            const SizedBox(height: 20),
            _buildCopyableField(
              'رقم الحساب / العنوان',
              accountNumber,
              CupertinoIcons.tag_fill,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.info_circle_fill,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      instructions,
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            label,
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text('تم نسخ $label بنجاح'),
                        ],
                      ),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_on_doc_fill,
                    size: 16,
                    color: AppTheme.primaryColor,
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
