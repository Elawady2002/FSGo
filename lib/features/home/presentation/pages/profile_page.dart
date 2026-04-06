import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _kBg = Color(0xFF1A1A1A);
const _kCard = Color(0xFF242424);
const _kLime = Color(0xFFC9D420);
const _kText = Colors.white;
const _kSubText = Color(0xFF9E9E9E);

/// Profile page for drivers to view and edit their information
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          'الملف الشخصي',
          style: GoogleFonts.cairo(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(CupertinoIcons.pencil, color: _kLime),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(CupertinoIcons.checkmark, color: _kLime),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: user == null
          ? const _NotLoggedInView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar
                    _buildAvatar(user),
                    const SizedBox(height: 24),
                    // Info Cards
                    _buildInfoSection(user),
                    const SizedBox(height: 24),
                    // Role Badge
                    _buildRoleBadge(user.userType),
                    if (_isEditing) ...[
                      const SizedBox(height: 32),
                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kSubText),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'إلغاء',
                            style: GoogleFonts.cairo(
                              color: _kText,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar(UserEntity user) {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kCard,
            border: Border.all(color: _kLime, width: 3),
            image: hasAvatar
                ? DecorationImage(
                    image: NetworkImage(user.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasAvatar
              ? Icon(CupertinoIcons.person, color: _kLime, size: 60)
              : null,
        ),
        if (_isEditing)
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kLime,
                shape: BoxShape.circle,
                border: Border.all(color: _kBg, width: 3),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_kBg),
                      ),
                    )
                  : const Icon(CupertinoIcons.camera, color: _kBg, size: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection(UserEntity user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'الاسم الكامل',
            controller: _nameController,
            icon: CupertinoIcons.person,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال الاسم';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'رقم الهاتف',
            controller: _phoneController,
            icon: CupertinoIcons.phone,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال رقم الهاتف';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'البريد الإلكتروني',
            controller: _emailController,
            icon: CupertinoIcons.envelope,
            enabled: false, // Email cannot be changed
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.cairo(color: _kText, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: _kSubText),
        prefixIcon: Icon(icon, color: enabled ? _kLime : _kSubText),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kLime),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: enabled
            ? Colors.transparent
            : Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildRoleBadge(UserType userType) {
    final roleName = userType == UserType.driver ? 'سائق' : 'مسؤول';
    final roleColor = userType == UserType.driver ? _kLime : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            userType == UserType.driver
                ? CupertinoIcons.car_detailed
                : CupertinoIcons.briefcase,
            color: roleColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            roleName,
            style: GoogleFonts.cairo(
              color: roleColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    final error = await ref
        .read(authProvider.notifier)
        .uploadProfileImage(File(pickedFile.path));

    setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await ref
        .read(authProvider.notifier)
        .updateProfile(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث الملف الشخصي بنجاح',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            color: Colors.redAccent,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'المستخدم غير مسجل الدخول',
            style: GoogleFonts.cairo(color: _kText, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'الرجاء تسجيل الدخول أولاً',
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
