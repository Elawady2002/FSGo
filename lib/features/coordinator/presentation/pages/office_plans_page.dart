import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../domain/entities/office_plan_entity.dart';
import '../providers/coordinator_provider.dart';

const _kBg = Colors.white;
const _kCard = Color(0xFFF5F5F5);
const _kLime = Color(0xFFC9D420);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);

class OfficePlansPage extends ConsumerStatefulWidget {
  final UserEntity coordinator;
  const OfficePlansPage({super.key, required this.coordinator});

  @override
  ConsumerState<OfficePlansPage> createState() => _OfficePlansPageState();
}

class _OfficePlansPageState extends ConsumerState<OfficePlansPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(officePlanProvider(widget.coordinator.id).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(officePlanProvider(widget.coordinator.id));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          'خطط الاشتراك',
          style: GoogleFonts.cairo(
              color: _kText, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kText),
      ),
      body: Builder(builder: (_) {
        if (planState.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: _kLime));
        }
        if (planState.error != null) {
          return Center(
            child: Text(planState.error!,
                style: GoogleFonts.cairo(color: Colors.redAccent)),
          );
        }
        return RefreshIndicator(
          color: _kLime,
          backgroundColor: _kCard,
          onRefresh: () =>
              ref.read(officePlanProvider(widget.coordinator.id).notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RevenueHeader(plans: planState.plans),
              const SizedBox(height: 16),
              if (planState.plans.isEmpty)
                _EmptyPlans(onAdd: () => _showAddPlan(context))
              else ...[
                ...planState.plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlanCard(
                      plan: plan,
                      onToggle: (v) => ref
                          .read(officePlanProvider(widget.coordinator.id)
                              .notifier)
                          .togglePlan(plan.id, v),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _AddPlanButton(onTap: () => _showAddPlan(context)),
              ],
            ],
          ),
        );
      }),
      floatingActionButton: planState.plans.isNotEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _kLime,
              foregroundColor: _kBg,
              onPressed: () => _showAddPlan(context),
              icon: const Icon(CupertinoIcons.add),
              label: Text('خطة جديدة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ),
    );
  }

  void _showAddPlan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPlanSheet(coordinator: widget.coordinator),
    );
  }
}

// ── Revenue Header ─────────────────────────────────────────────

class _RevenueHeader extends StatelessWidget {
  final List<OfficePlanEntity> plans;
  const _RevenueHeader({required this.plans});

  @override
  Widget build(BuildContext context) {
    final activePlans = plans.where((p) => p.isActive).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kLime.withValues(alpha: 0.15),
            _kLime.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kLime.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.chart_bar_fill, color: _kLime, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الخطط النشطة',
                style: GoogleFonts.cairo(color: _kSubText, fontSize: 12),
              ),
              Text(
                '$activePlans خطة',
                style: GoogleFonts.cairo(
                    color: _kLime,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Plan Card ──────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final OfficePlanEntity plan;
  final ValueChanged<bool> onToggle;
  const _PlanCard({required this.plan, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isActive
              ? _kLime.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.planName,
                  style: GoogleFonts.cairo(
                    color: _kText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CupertinoSwitch(
                value: plan.isActive,
                onChanged: onToggle,
                activeTrackColor: _kLime,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PlanBadge(label: plan.planType.label),
              const SizedBox(width: 8),
              _PlanBadge(
                  label: '${plan.durationDays} يوم',
                  color: Colors.cyanAccent),
              if (plan.maxStudents != null) ...[
                const SizedBox(width: 8),
                _PlanBadge(
                  label: 'حد ${plan.maxStudents} طالب',
                  color: Colors.orangeAccent,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${plan.price.toStringAsFixed(0)} جنيه',
                style: GoogleFonts.cairo(
                  color: _kLime,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                plan.isActive ? 'نشط' : 'متوقف',
                style: GoogleFonts.cairo(
                  color: plan.isActive ? Colors.greenAccent : _kSubText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PlanBadge({required this.label, this.color = _kLime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(color: color, fontSize: 11),
      ),
    );
  }
}

class _AddPlanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPlanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kLime.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.add_circled, color: _kLime, size: 18),
            const SizedBox(width: 8),
            Text(
              'إضافة خطة جديدة',
              style: GoogleFonts.cairo(
                  color: _kLime, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────

class _EmptyPlans extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPlans({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 48),
          const Icon(CupertinoIcons.creditcard, size: 64, color: _kLime),
          const SizedBox(height: 16),
          Text(
            'لا توجد خطط اشتراك',
            style: GoogleFonts.cairo(
                color: _kText, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'أنشئ خططاً شهرية أو فصلية للطلاب',
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kLime,
              foregroundColor: _kBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: onAdd,
            icon: const Icon(CupertinoIcons.add),
            label: Text('إضافة خطة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Add Plan Sheet ─────────────────────────────────────────────

class _AddPlanSheet extends ConsumerStatefulWidget {
  final UserEntity coordinator;
  const _AddPlanSheet({required this.coordinator});

  @override
  ConsumerState<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends ConsumerState<_AddPlanSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();
  final _maxStudentsCtrl = TextEditingController();
  OfficePlanType _planType = OfficePlanType.monthly;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _daysCtrl.dispose();
    _maxStudentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'خطة اشتراك جديدة',
            style: GoogleFonts.cairo(
                color: _kText, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _DarkField(
              controller: _nameCtrl, hint: 'اسم الخطة (مثال: شهري صيفي)'),
          const SizedBox(height: 10),
          // Plan type selector
          Row(
            children: OfficePlanType.values.map((type) {
              final selected = _planType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _planType = type),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: type == OfficePlanType.monthly ? 6 : 0,
                        left: type == OfficePlanType.semester ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? _kLime.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected ? _kLime : Colors.black12),
                    ),
                    child: Text(
                      type.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: selected ? _kLime : _kSubText,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DarkField(
                  controller: _priceCtrl,
                  hint: 'السعر (جنيه)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DarkField(
                  controller: _daysCtrl,
                  hint: 'عدد الأيام',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DarkField(
            controller: _maxStudentsCtrl,
            hint: 'الحد الأقصى للطلاب (اختياري)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kLime,
                foregroundColor: _kBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: _kBg, strokeWidth: 2),
                    )
                  : Text('حفظ الخطة',
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final days = int.tryParse(_daysCtrl.text.trim());
    final maxStudents = int.tryParse(_maxStudentsCtrl.text.trim());

    if (name.isEmpty || price == null || days == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى تعبئة جميع الحقول المطلوبة',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final error = await ref
        .read(officePlanProvider(widget.coordinator.id).notifier)
        .createPlan(
          planName: name,
          planType: _planType,
          price: price,
          durationDays: days,
          maxStudents: maxStudents,
        );

    setState(() => _isSaving = false);
    if (!mounted) return;

    Navigator.pop(context);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('خطأ: $error', style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة الخطة بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// ── Shared widget ──────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _DarkField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(color: _kText, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kLime, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
