import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ios_components.dart';
import '../../../../core/widgets/top_notification.dart';

class PaymentProofSheet extends StatefulWidget {
  final Future<void> Function(String? imagePath, String accountNumber)
  onConfirm;

  const PaymentProofSheet({super.key, required this.onConfirm});

  @override
  State<PaymentProofSheet> createState() => _PaymentProofSheetState();
}

class _PaymentProofSheetState extends State<PaymentProofSheet> {
  final TextEditingController _accountController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle permission or other errors
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            'إثبات الدفع',
            textAlign: TextAlign.center,
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ارفع صورة التحويل واكتب رقم المحفظة للتأكيد',
            textAlign: TextAlign.center,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Image Upload Area
          GestureDetector(
            onTap: _isLoading ? null : _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _imageFile != null
                      ? AppTheme.primaryColor
                      : AppTheme.dividerColor,
                  width: _imageFile != null ? 2 : 1,
                ),
                image: _imageFile != null
                    ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _imageFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.camera_fill,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'اضغط لرفع صورة التحويل',
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          // Account Number Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رقم المحفظة / الحساب',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: TextField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    hintText: '010xxxxxxxx',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Confirm Button
          IOSButton(
            text: _isLoading ? 'جاري الحفظ...' : 'تأكيد الطلب',
            onPressed: _isLoading
                ? null
                : () async {
                    if (_imageFile == null) {
                      showTopNotification(context, 'من فضلك ارفع صورة التحويل');
                      return;
                    }

                    if (_accountController.text.isEmpty) {
                      showTopNotification(context, 'من فضلك اكتب رقم المحفظة');
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      // Call the onConfirm callback which will save the booking
                      await widget.onConfirm(
                        _imageFile?.path,
                        _accountController.text,
                      );

                      // Close sheet only if still mounted
                      if (mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
            color: _isLoading ? AppTheme.dividerColor : AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
