import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import 'personal_data_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'saved_places_page.dart';
import 'wallet_page.dart';
import 'payment_methods_page.dart';
import 'ride_history_page.dart';
import 'statistics_page.dart';
import 'help_center_page.dart';
import '../../../subscription/presentation/pages/my_subscription_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using a soft off-white background for a cleaner, easier-on-the-eyes look
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
          'الملف الشخصي',
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Profile Header
            const _ProfileHeader(),
            const SizedBox(height: 32),

            // Account & Settings
            _buildSectionTitle('الحساب والإعدادات'),
            _buildSection([
              _MenuItem(
                icon: CupertinoIcons.ticket,
                title: 'اشتراكي',
                subtitle: 'إدارة اشتراكك الحالي',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const MySubscriptionPage(),
                  ),
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.person,
                title: 'البيانات الشخصية',
                subtitle: 'الاسم، رقم الهاتف، البريد الإلكتروني',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const PersonalDataPage()),
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.location,
                title: 'الأماكن المحفوظة',
                subtitle: 'المنزل، العمل، الجامعة',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const SavedPlacesPage()),
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.globe,
                title: 'اللغة',
                trailingText: 'العربية',
                onTap: () => _showLanguageSheet(context),
              ),
              _MenuItem(
                icon: CupertinoIcons.bell,
                title: 'الإشعارات',
                isSwitch: true,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),

            // Wallet & Payments
            _buildSectionTitle('المحفظة والدفع'),
            _buildSection([
              _MenuItem(
                icon: CupertinoIcons.money_dollar_circle,
                title: 'رصيد المحفظة',
                trailingText: '150 ج.م',
                trailingTextColor: AppTheme.primaryDark,
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const WalletPage()),
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.creditcard,
                title: 'طرق الدفع',
                subtitle: 'إدارة البطاقات والمحافظ الإلكترونية',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const PaymentMethodsPage(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Activity
            _buildSectionTitle('النشاط'),
            _buildSection([
              _MenuItem(
                icon: CupertinoIcons.ticket,
                title: 'سجل الرحلات',
                subtitle: 'عرض الرحلات السابقة والقادمة',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const RideHistoryPage()),
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.chart_bar,
                title: 'إحصائياتي',
                subtitle: 'عدد الرحلات، التوفير',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const StatisticsPage()),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Support & Legal
            _buildSectionTitle('الدعم والمساعدة'),
            _buildSection([
              _MenuItem(
                icon: CupertinoIcons.question_circle,
                title: 'مركز المساعدة',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const HelpCenterPage()),
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.phone,
                title: 'تواصل معنا',
                onTap: () {
                  _showContactDialog(context);
                },
              ),
              _MenuItem(
                icon: CupertinoIcons.doc_text,
                title: 'الشروط والأحكام',
                onTap: () {
                  _showTermsDialog(context);
                },
              ),
            ]),
            const SizedBox(height: 32),

            // Logout
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // No shadow, just a clean flat look
              ),
              child: TextButton(
                onPressed: () => _showLogoutDialog(context, ref),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'تسجيل الخروج',
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFFF3B30),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'الإصدار 1.0.0',
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'اختر اللغة',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('العربية'),
              trailing: const Icon(Icons.check, color: AppTheme.primaryColor),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تواصل معنا'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Text('يمكنك التواصل معنا عبر:'),
            SizedBox(height: 12),
            Text(
              'البريد الإلكتروني:\nsupport@fielsekka.com',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'الهاتف:\n01000000000',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('حسناً'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('الشروط والأحكام'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text(
                '1. استخدام الخدمة مخصص للطلاب فقط\n\n'
                '2. يجب الالتزام بمواعيد الرحلات\n\n'
                '3. الدفع مقدماً قبل الحجز\n\n'
                '4. يمكن إلغاء الحجز قبل 24 ساعة\n\n'
                '5. الحفاظ على النظافة داخل الباص',
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('حسناً'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('خروج'),
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              // Call logout from auth provider
              final error = await ref.read(authProvider.notifier).logout();

              if (error == null && context.mounted) {
                // Logout successful, navigate to login
                Navigator.of(context).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              } else if (context.mounted) {
                // Show error if logout failed
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('خطأ'),
                    content: Text(error ?? 'حدث خطأ أثناء تسجيل الخروج'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('حسناً'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Removed shadow for a flatter, cleaner look
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (index != children.length - 1)
                Padding(
                  padding: const EdgeInsets.only(right: 52), // Indent divider
                  child: Divider(
                    height: 1,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerStatefulWidget {
  const _ProfileHeader();

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });

      final file = File(pickedFile.path);
      final error = await ref
          .read(authProvider.notifier)
          .uploadProfileImage(file);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث الصورة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeImage() async {
    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل تريد حذف صورة الملف الشخصي؟'),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('حذف'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isUploading = true;
      });

      final error = await ref.read(authProvider.notifier).removeProfileImage();

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الصورة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final userName = user?.fullName ?? 'مستخدم';
    final university = user?.universityId ?? 'غير محدد';
    final avatarUrl = user?.avatarUrl;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Avatar image - always opens image picker when tapped
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: AssetImage(
                            'assets/images/avatar_placeholder.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : null,
              ),
            ),
            // Icon button - uploads if no image, deletes if image exists
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploading
                    ? null
                    : (avatarUrl != null ? _removeImage : _pickImage),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: avatarUrl != null
                        ? const Color(0xFFFF3B30)
                        : AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF5F5F7),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    avatarUrl != null
                        ? CupertinoIcons.trash_fill
                        : CupertinoIcons.camera_fill,
                    size: 14,
                    color: avatarUrl != null ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userName,
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          university,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Color? trailingTextColor;
  final bool isSwitch;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingTextColor,
    this.isSwitch = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSwitch ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Simple Icon without background container
              Icon(icon, color: Colors.black87, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: trailingTextColor ?? AppTheme.textSecondary,
                  ),
                ),
              if (isSwitch)
                CupertinoSwitch(
                  value: true,
                  activeTrackColor: AppTheme.primaryColor,
                  onChanged: (val) {},
                )
              else ...[
                if (trailingText != null) const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_left,
                  size: 16,
                  color: Color(0xFFC7C7CC),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
