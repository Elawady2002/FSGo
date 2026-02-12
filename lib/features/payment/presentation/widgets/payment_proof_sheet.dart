import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ios_components.dart';
import '../../../../core/widgets/custom_input.dart';
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
      );

      if (pickedFile != null) {
        // Compress the image before using it
        final compressedFile = await _compressImage(File(pickedFile.path));

        setState(() {
          _imageFile = compressedFile;
        });
      }
    } catch (e) {
      // Handle permission or other errors
      debugPrint('Error picking image: $e');
    }
  }

  /// Compress image to JPEG format with 85% quality
  Future<File> _compressImage(File file) async {
    try {
      final String targetPath = path.join(
        path.dirname(file.path),
        '${path.basenameWithoutExtension(file.path)}_compressed.jpg',
      );

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 85,
            format: CompressFormat.jpeg,
          );

      if (compressedFile != null) {
        debugPrint(
          '✅ Image compressed: ${file.lengthSync()} → ${File(compressedFile.path).lengthSync()} bytes',
        );
        return File(compressedFile.path);
      }

      // If compression fails, return original file
      debugPrint('⚠️ Compression failed, using original image');
      return file;
    } catch (e) {
      debugPrint('⚠️ Error compressing image: $e, using original');
      return file;
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext viewContext) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(viewContext).viewInsets.bottom + 24,
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
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _imageFile != null
                      ? AppTheme.primaryColor
                      : const Color(0xFFEEEEEE),
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            CupertinoIcons.camera_fill,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'اضغط لرفع صورة التحويل',
                          style: AppTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
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
              CustomInput(
                controller: _accountController,
                hintText: '010xxxxxxxx',
                keyboardType: TextInputType.number,
                // inputFormatters could be added here if needed
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Confirm Button
          IOSButton(
            text: 'تأكيد الطلب',
            isLoading: _isLoading,
            onPressed: () async {
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
                debugPrint(
                  '🔄 PaymentProofSheet: Calling onConfirm callback...',
                );

                // Call the onConfirm callback which will save the booking
                await widget.onConfirm(
                  _imageFile?.path,
                  _accountController.text,
                );

                debugPrint(
                  '✅ PaymentProofSheet: onConfirm completed successfully!',
                );
                debugPrint(
                  '✅ PaymentProofSheet: Closing sheet with result=true',
                );

                // Close sheet only if still mounted
                if (mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e, stackTrace) {
                debugPrint('❌ PaymentProofSheet: Error in onConfirm: $e');
                debugPrint('❌ Stack trace: $stackTrace');

                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });

                  // Show error to user
                  showTopNotification(context, 'حدث خطأ: ${e.toString()}');
                }
              }
            },
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
