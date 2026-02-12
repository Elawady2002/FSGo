import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../subscription/domain/entities/subscription_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SubscriptionDetailsSheet extends StatelessWidget {
  final SubscriptionEntity subscription;

  const SubscriptionDetailsSheet({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Text(
              'تفاصيل الاشتراك',
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Status Badge
            Center(child: _buildStatusBadge(subscription.status)),
            const SizedBox(height: 24),

            // Details
            _buildDetailRow('التاريخ', _formatDate(subscription.createdAt)),
            _buildDetailRow('نوع الباقة', subscription.planType.displayName),
            _buildDetailRow(
              'المبلغ',
              '${subscription.amount.toStringAsFixed(0)} ج.م',
            ),
            _buildDetailRow(
              'تاريخ البداية',
              _formatDate(subscription.startDate),
            ),
            _buildDetailRow('تاريخ النهاية', _formatDate(subscription.endDate)),

            if (subscription.transferNumber != null &&
                subscription.transferNumber!.isNotEmpty)
              _buildDetailRow('رقم التحويل', subscription.transferNumber!),

            const SizedBox(height: 24),

            // Payment Proof Image
            if (subscription.paymentProofUrl != null &&
                subscription.paymentProofUrl!.isNotEmpty) ...[
              Text(
                'صورة الإثبات',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImage(subscription.paymentProofUrl!),
              ),
              const SizedBox(height: 24),
            ],

            // Close Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'إغلاق',
                onPressed: () => Navigator.pop(context),
                backgroundColor: AppTheme.primaryColor,
                textColor: Colors.black,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTheme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SubscriptionStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case SubscriptionStatus.active:
        color = AppTheme.successColor;
        label = 'نشط';
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case SubscriptionStatus.pending:
        color = Colors.orange;
        label = 'قيد المراجعة';
        icon = CupertinoIcons.time_solid;
        break;
      case SubscriptionStatus.expired:
        color = Colors.grey;
        label = 'منتهي';
        icon = CupertinoIcons.xmark_circle_fill;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      errorWidget: (context, url, error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.grey, size: 48),
            const SizedBox(height: 8),
            Text(
              'فشل تحميل الصورة',
              style: AppTheme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
