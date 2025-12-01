import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../booking/domain/entities/booking_entity.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final BookingEntity booking;

  const TransactionDetailsSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
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
            'تفاصيل المعاملة',
            textAlign: TextAlign.center,
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          // Status Badge
          Center(child: _buildStatusBadge(booking.status)),
          const SizedBox(height: 24),

          // Details
          _buildDetailRow('التاريخ', _formatDate(booking.bookingDate)),
          _buildDetailRow('نوع الرحلة', _getTripTypeLabel(booking.tripType)),
          _buildDetailRow('المبلغ', '${booking.totalPrice} ج.م'),

          if (booking.transferNumber != null &&
              booking.transferNumber!.isNotEmpty)
            _buildDetailRow('رقم التحويل', booking.transferNumber!),

          const SizedBox(height: 24),

          // Payment Proof Image
          if (booking.paymentProofImage != null &&
              booking.paymentProofImage!.isNotEmpty) ...[
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
              child: _buildImage(booking.paymentProofImage!),
            ),
            const SizedBox(height: 24),
          ],

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'إغلاق',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
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

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case BookingStatus.confirmed:
        color = AppTheme.successColor;
        label = 'تمت الموافقة';
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case BookingStatus.pending:
        color = Colors.orange;
        label = 'قيد المراجعة';
        icon = CupertinoIcons.time_solid;
        break;
      case BookingStatus.cancelled:
        color = AppTheme.errorColor;
        label = 'مرفوضة / ملغية';
        icon = CupertinoIcons.xmark_circle_fill;
        break;
      case BookingStatus.completed:
        color = Colors.grey;
        label = 'مكتملة';
        icon = CupertinoIcons.check_mark_circled_solid;
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

  Widget _buildImage(String path) {
    print('🖼️ Loading payment proof image from: $path');

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, error, __) {
          print('❌ Error loading network image: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                const SizedBox(height: 8),
                Text(
                  'فشل تحميل الصورة',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      final file = File(path);
      print('📁 File exists: ${file.existsSync()}');

      if (!file.existsSync()) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'الصورة غير موجودة',
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, error, __) {
          print('❌ Error loading file image: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                const SizedBox(height: 8),
                Text(
                  'فشل تحميل الصورة',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}
