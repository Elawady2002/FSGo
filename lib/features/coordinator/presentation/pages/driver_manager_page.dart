import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../providers/coordinator_provider.dart';

const _kBg = Colors.white;
const _kCard = Color(0xFFF5F5F5);
const _kLime = Color(0xFFC9D420);
const _kDark = Color(0xFF1A1A1A);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);

/// صفحة إدارة السائقين - تشمل نظام الدعوات وقائمة السائقين الحاليين
class DriverManagerPage extends ConsumerStatefulWidget {
  final UserEntity coordinator;
  const DriverManagerPage({super.key, required this.coordinator});

  @override
  ConsumerState<DriverManagerPage> createState() => _DriverManagerPageState();
}

class _DriverManagerPageState extends ConsumerState<DriverManagerPage> {
  final _emailCtrl = TextEditingController();
  bool _isInviting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(coordinatorDriversProvider(widget.coordinator.id));
    final invitesAsync = ref.watch(pendingInvitesProvider(widget.coordinator.id));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_right, color: _kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'إدارة السائقين',
          style: GoogleFonts.cairo(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Invitation Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: _kBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دعوة سائق جديد',
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                // Email field + invite button
                Container(
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    style: GoogleFonts.cairo(fontSize: 15, color: _kText),
                    decoration: InputDecoration(
                      hintText: 'البريد الإلكتروني',
                      hintStyle: GoogleFonts.cairo(color: _kSubText, fontSize: 13),
                      hintTextDirection: TextDirection.rtl,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton(
                          onPressed: _isInviting ? null : _handleInvite,
                          style: TextButton.styleFrom(
                            backgroundColor: _kDark,
                            foregroundColor: _kLime,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isInviting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _kLime))
                              : Text('دعوة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Drivers List ──
          Expanded(
            child: driversAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _kDark)),
              error: (e, s) => Center(child: Text('خطأ في تحميل القائمة', style: GoogleFonts.cairo())),
              data: (drivers) {
                return RefreshIndicator(
                  color: _kDark,
                  onRefresh: () async {
                    ref.invalidate(coordinatorDriversProvider(widget.coordinator.id));
                    ref.invalidate(pendingInvitesProvider(widget.coordinator.id));
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      // Section Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          'طاقم العمل',
                          style: GoogleFonts.cairo(
                            color: _kSubText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      // Owner Row
                      _buildDriverRow(
                        name: widget.coordinator.fullName,
                        status: 'مالك',
                        statusColor: _kSubText,
                        isOwner: true,
                      ),

                      if (drivers.isEmpty) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'لا يوجد سائقين مضافين حالياً',
                            style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
                          ),
                        ),
                      ] else
                        ...drivers.map((d) => _buildDriverRow(
                              name: d.fullName,
                              status: 'نشط',
                              statusColor: Colors.green,
                            )),

                      // Section Header for Invites
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          'دعوات معلقة',
                          style: GoogleFonts.cairo(
                            color: _kSubText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      // Real pending invites from DB
                      invitesAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: _kDark)),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (invites) {
                          if (invites.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Text(
                                'لا توجد دعوات معلقة',
                                style: GoogleFonts.cairo(color: _kSubText, fontSize: 13),
                              ),
                            );
                          }
                          return Column(
                            children: invites.map((inv) => _buildDriverRow(
                              name: inv.driverName ?? inv.driverEmail,
                              status: 'بانتظار الموافقة',
                              statusColor: Colors.orange,
                              subtitle: inv.driverName != null ? inv.driverEmail : null,
                            )).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRow({
    required String name,
    required String status,
    required Color statusColor,
    bool isOwner = false,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCard, width: 1.5),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOwner ? _kDark : _kCard,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isOwner
                  ? const Icon(CupertinoIcons.person_fill, color: _kLime, size: 22)
                  : Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        color: _kSubText,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Name and Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwner ? '$name (أنا)' : name,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: isOwner ? FontWeight.w800 : FontWeight.w700,
                    color: _kText,
                  ),
                ),
                Text(
                  subtitle ?? (isOwner ? 'مسؤول المحطة' : 'سائق معتمد'),
                  style: GoogleFonts.cairo(fontSize: 11, color: _kSubText),
                ),
              ],
            ),
          ),

          // Status Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleInvite() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('من فضلك أدخل البريد الإلكتروني', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isInviting = true);

    final error = await ref
        .read(coordinatorScheduleProvider(widget.coordinator.id).notifier)
        .inviteDriver(
          coordinatorId: widget.coordinator.id,
          driverEmail: email,
        );

    if (!mounted) return;
    setState(() => _isInviting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $error', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    _emailCtrl.clear();
    // Refresh pending invites list
    ref.invalidate(pendingInvitesProvider(widget.coordinator.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال الدعوة بنجاح', style: GoogleFonts.cairo()),
        backgroundColor: _kDark,
      ),
    );
  }
}
