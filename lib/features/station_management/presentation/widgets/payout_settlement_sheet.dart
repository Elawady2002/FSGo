import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/payout_provider.dart';
import '../../domain/entities/payout_settle_entity.dart';

const _kBg = Colors.white;
const _kCard = Color(0xFFF5F5F5);
const _kLime = Color(0xFFC9D420);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);

/// Bottom sheet that lists pending payouts and lets the manager
/// upload a settlement screenshot.
///
/// Usage:
/// ```dart
/// PayoutSettlementSheet.show(context, managerId: user.id);
/// ```
class PayoutSettlementSheet extends ConsumerWidget {
  final String managerId;
  const PayoutSettlementSheet({super.key, required this.managerId});

  static Future<void> show(
    BuildContext context, {
    required String managerId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => PayoutSettlementSheet(
          managerId: managerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(pendingPayoutsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  'تسوية المدفوعات',
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(CupertinoIcons.money_dollar_circle,
                    color: _kLime, size: 24),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: payoutsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kLime)),
              error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: GoogleFonts.cairo(color: Colors.redAccent)),
              ),
              data: (payouts) => payouts.isEmpty
                  ? _EmptyPayouts()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: payouts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) => _PayoutCard(
                        payout: payouts[i],
                        managerId: managerId,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payout Card ────────────────────────────────────────────────

class _PayoutCard extends ConsumerStatefulWidget {
  final PayoutSettleEntity payout;
  final String managerId;
  const _PayoutCard({required this.payout, required this.managerId});

  @override
  ConsumerState<_PayoutCard> createState() => _PayoutCardState();
}

class _PayoutCardState extends ConsumerState<_PayoutCard> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _settle() async {
    if (_selectedImage == null) return;
    await ref.read(settlementProvider.notifier).settle(
          payoutId: widget.payout.payoutId,
          managerId: widget.managerId,
          proofImage: _selectedImage!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final settlementState = ref.watch(settlementProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _kLime.withValues(alpha: 0.12),
                child: Text(
                  widget.payout.driverName.isNotEmpty
                      ? widget.payout.driverName[0]
                      : '؟',
                  style: GoogleFonts.cairo(
                      color: _kLime, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.payout.driverName,
                      style: GoogleFonts.cairo(
                        color: _kText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.payout.status.label,
                      style: GoogleFonts.cairo(
                          color: _kSubText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Amount badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kLime,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.payout.amount.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Image preview or pick button
          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _selectedImage!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Error message
          if (settlementState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                settlementState.error!,
                style: GoogleFonts.cairo(
                    color: Colors.redAccent, fontSize: 12),
              ),
            ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kText,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(CupertinoIcons.photo, size: 16),
                  label: Text(
                    _selectedImage == null
                        ? 'إرفاق الإيصال'
                        : 'تغيير الصورة',
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_selectedImage == null ||
                          settlementState.isLoading)
                      ? null
                      : _settle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kLime,
                    foregroundColor: _kText,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: settlementState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kText),
                        )
                      : const Icon(CupertinoIcons.checkmark_alt, size: 16),
                  label: Text(
                    settlementState.isLoading ? 'جارٍ...' : 'تسوية',
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────

class _EmptyPayouts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.checkmark_seal,
              size: 64, color: _kLime),
          const SizedBox(height: 16),
          Text(
            'لا توجد مدفوعات معلقة',
            style: GoogleFonts.cairo(
              color: _kText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تمت تسوية جميع المدفوعات',
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
