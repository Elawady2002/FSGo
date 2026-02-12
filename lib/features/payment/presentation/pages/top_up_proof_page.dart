import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../../core/providers/storage_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/wallet_provider.dart';

class TopUpProofPage extends ConsumerStatefulWidget {
  final String amount;
  final String method;
  final bool isWithdraw;

  const TopUpProofPage({
    super.key,
    required this.amount,
    required this.method,
    this.isWithdraw = false,
  });

  @override
  ConsumerState<TopUpProofPage> createState() => _TopUpProofPageState();
}

class _TopUpProofPageState extends ConsumerState<TopUpProofPage>
    with TickerProviderStateMixin {
  final TextEditingController _senderPhoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  File? _proofImage;
  bool _isLoading = false;
  bool _copied = false;

  // Account details
  final String _vodafoneNumber = "01012345678";
  final String _instaPayAddress = "user@instapay";

  // Staggered entrance animations
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim1;
  late Animation<double> _fadeAnim2;
  late Animation<double> _fadeAnim3;
  late Animation<Offset> _slideAnim1;
  late Animation<Offset> _slideAnim2;
  late Animation<Offset> _slideAnim3;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Staggered fade-in animations
    _fadeAnim1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _fadeAnim2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _fadeAnim3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    // Staggered slide-up animations
    _slideAnim1 = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));
    _slideAnim2 = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));
    _slideAnim3 = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _senderPhoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _submitRequest() async {
    if (_proofImage == null || _senderPhoneController.text.isEmpty) {
      _showErrorSnackBar('يرجى رفع صورة الإثبات وإدخال رقم المحول منه');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).value;
      if (user == null) throw Exception('User not logged in');

      final storageService = ref.read(storageServiceProvider);
      final imageUrl =
          await storageService.uploadPaymentProof(_proofImage!, user.id);

      final walletNotifier = ref.read(walletProvider.notifier);
      await walletNotifier.requestTopUp(
        amount: double.parse(widget.amount),
        method: widget.method,
        proofUrl: imageUrl!,
        senderPhone: _senderPhoneController.text,
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      _showErrorSnackBar('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle_fill,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (context, _, _) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: AppTheme.primaryColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تم استلام الطلب',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isWithdraw
                    ? 'سيتم مراجعة طلب السحب وتحويل المبلغ إلى حسابك في أقرب وقت.'
                    : 'سيتم مراجعة الطلب واضافة الرصيد إلى محفظتك في أقرب وقت.',
                textAlign: TextAlign.center,
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'العودة للرئيسية',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transferTarget =
        widget.method == 'Vodafone Cash' ? _vodafoneNumber : _instaPayAddress;
    final bool isReady =
        _proofImage != null && _senderPhoneController.text.isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_right,
                color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.isWithdraw ? 'تأكيد السحب' : 'تأكيد الدفع',
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Step 1: Amount & Transfer Info ───
                    SlideTransition(
                      position: _slideAnim1,
                      child: FadeTransition(
                        opacity: _fadeAnim1,
                        child: _buildTransferCard(transferTarget),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Step 2: Upload Proof ───
                    SlideTransition(
                      position: _slideAnim2,
                      child: FadeTransition(
                        opacity: _fadeAnim2,
                        child: _buildProofUploadSection(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Step 3: Sender Phone ───
                    SlideTransition(
                      position: _slideAnim3,
                      child: FadeTransition(
                        opacity: _fadeAnim3,
                        child: _buildPhoneInputSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Submit Button ───
            _buildSubmitButton(isReady),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Transfer Info Card
  // ──────────────────────────────────────────────────
  Widget _buildTransferCard(String transferTarget) {
    final isVodafone = widget.method == 'Vodafone Cash';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Amount badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isWithdraw ? 'سحب' : 'تحويل',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.amount} ج.م',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Divider with label
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'إلى',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade200)),
            ],
          ),

          const SizedBox(height: 16),

          // Destination info
          Row(
            children: [
              // Method icon
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  isVodafone
                      ? 'lib/assets/image/launcher_icons/vodafone_cash.png'
                      : 'lib/assets/image/launcher_icons/instapay.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    CupertinoIcons.money_dollar_circle,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Method name & number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVodafone ? 'فودافون كاش' : 'انستا باي',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transferTarget,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Copy button
              GestureDetector(
                onTap: () => _copyToClipboard(transferTarget),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _copied
                        ? AppTheme.primaryColor.withValues(alpha: 0.15)
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.doc_on_doc_fill,
                        size: 15,
                        color: _copied
                            ? AppTheme.primaryDark
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _copied ? 'تم' : 'نسخ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _copied
                              ? AppTheme.primaryDark
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Proof Upload Section
  // ──────────────────────────────────────────────────
  Widget _buildProofUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          icon: CupertinoIcons.camera_fill,
          label: 'إثبات الدفع',
          step: '1',
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _proofImage != null ? 220 : 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _proofImage != null
                  ? Colors.transparent
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _proofImage != null
                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                    : Colors.grey.shade200,
                width: _proofImage != null ? 2 : 1.5,
              ),
              boxShadow: _proofImage != null
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: _proofImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.file(_proofImage!, fit: BoxFit.cover),
                        ),
                      ),
                      // Change image button
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.arrow_2_circlepath,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'تغيير',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Success badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          CupertinoIcons.cloud_upload_fill,
                          size: 24,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'اضغط لرفع سكرين شوت التحويل',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────
  // Phone Input Section
  // ──────────────────────────────────────────────────
  Widget _buildPhoneInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          icon: CupertinoIcons.phone_fill,
          label: 'رقم المحول منه',
          step: '2',
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _senderPhoneController,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'أدخل رقم التليفون',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 14, left: 8),
                child: Icon(
                  CupertinoIcons.phone,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 0),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────
  // Section Label with Step Number
  // ──────────────────────────────────────────────────
  Widget _buildSectionLabel({
    required IconData icon,
    required String label,
    required String step,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────
  // Submit Button
  // ──────────────────────────────────────────────────
  Widget _buildSubmitButton(bool isReady) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 8
            : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            : AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isReady
                      ? AppTheme.primaryColor
                      : Colors.grey.shade200,
                  boxShadow: isReady
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isReady ? _submitRequest : null,
                    child: Center(
                      child: Text(
                        'تأكيد الطلب',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isReady
                              ? Colors.black
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
