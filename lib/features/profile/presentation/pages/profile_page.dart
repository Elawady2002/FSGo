import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../home/presentation/widgets/global_drawer.dart';

const _kBg = Color(0xFFF5F5F7);
const _kCard = Colors.white;
const _kLime = Color(0xFFC9D420);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);
const _kDanger = Color(0xFFFF3B30);

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: _kBg,
      drawer: GlobalDrawer(user: user, selectedIndex: 0),
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(CupertinoIcons.bars, color: _kText),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'الملف الشخصي',
          style: GoogleFonts.cairo(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: _kLime))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Profile Header
                  _buildHeader(user),
                  const SizedBox(height: 24),

                  // Driver Stats Row
                  _buildStatsRow(),
                  const SizedBox(height: 32),

                  // Account Section
                  _buildSectionTitle('حسابي'),
                  _buildSection([
                    _MenuItem(
                      icon: CupertinoIcons.person,
                      title: 'البيانات الشخصية',
                      subtitle: 'تعديل الاسم ورقم الهاتف',
                      onTap: () => _navigateToPersonalData(),
                    ),
                    _MenuItem(
                      icon: CupertinoIcons.money_dollar_circle,
                      title: 'المحفظة الرقمية',
                      subtitle: 'رصيدك الحالي والمعاملات',
                      onTap: () => _navigateToWallet(),
                    ),
                    _MenuItem(
                      icon: CupertinoIcons.time,
                      title: 'سجل الرحلات',
                      subtitle: 'عرض الرحلات السابقة والمنجزة',
                      onTap: () => _navigateToRideHistory(),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Support Section
                  _buildSectionTitle('الدعم والخصوصية'),
                  _buildSection([
                    _MenuItem(
                      icon: CupertinoIcons.question_circle,
                      title: 'مركز المساعدة',
                      onTap: () => _navigateToHelp(),
                    ),
                    _MenuItem(
                      icon: CupertinoIcons.phone,
                      title: 'تواصل معنا',
                      onTap: () => _showContactOptions(),
                    ),
                    _MenuItem(
                      icon: CupertinoIcons.doc_text,
                      title: 'الشروط والأحكام',
                      onTap: () => _showTerms(),
                    ),
                  ]),
                  const SizedBox(height: 40),

                  // Version Info
                  Text(
                    'الإصدار 1.0.0',
                    style: GoogleFonts.cairo(
                      color: _kSubText.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(UserEntity user) {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBg,
                  border: Border.all(color: _kLime.withValues(alpha: 0.3), width: 3),
                  image: hasAvatar
                      ? DecorationImage(
                          image: NetworkImage(user.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasAvatar
                    ? const Icon(CupertinoIcons.person, color: _kLime, size: 48)
                    : null,
              ),
              // Camera button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: _kLime,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kLime.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: GoogleFonts.cairo(
              color: _kText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            user.phone,
            style: GoogleFonts.cairo(
              color: _kSubText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '4.9',
            'التقييم',
            CupertinoIcons.star_fill,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '124',
            'رحلة',
            CupertinoIcons.car_detailed,
            _kLime,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            '85',
            'ساعة',
            CupertinoIcons.time,
            Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: _kText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: _kSubText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: GoogleFonts.cairo(
            color: _kText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index != items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(right: 56),
                  child: Divider(color: _kBg, height: 1),
                ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    final error = await ref.read(authProvider.notifier).uploadProfileImage(File(pickedFile.path));
    setState(() => _isUploading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, style: GoogleFonts.cairo())),
      );
    }
  }

  // Navigation Placeholders (to be implemented/linked)
  void _navigateToPersonalData() {}
  void _navigateToWallet() {}
  void _navigateToRideHistory() {}
  void _navigateToHelp() {}
  void _showContactOptions() {}
  void _showTerms() {}
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _kLime, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          color: _kText,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.cairo(
                color: _kSubText,
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(CupertinoIcons.chevron_left, color: _kSubText, size: 14),
    );
  }
}
