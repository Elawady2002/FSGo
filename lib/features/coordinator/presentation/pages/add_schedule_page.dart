import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../providers/coordinator_provider.dart';

// ── Design tokens ──────────────────────────────────────────────
const _kBg = Colors.white;
const _kCard = Color(0xFFF5F5F5);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);
const _kLime = Color(0xFFC9D420);
// Both schedule types use the same primary color scheme
const _kUniversity = Color(0xFF1A1A1A);
const _kStation = Color(0xFF1A1A1A);

class AddSchedulePage extends ConsumerStatefulWidget {
  final UserEntity coordinator;
  const AddSchedulePage({super.key, required this.coordinator});

  @override
  ConsumerState<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends ConsumerState<AddSchedulePage> {
  // Step 0 = type selector, Step 1 = form
  int _step = 0;
  ScheduleType? _selectedType;

  final _formKey = GlobalKey<FormState>();
  final _destCtrl = TextEditingController();
  final _fareCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  TimeOfDay _departureTime = const TimeOfDay(hour: 7, minute: 0);
  final Set<String> _selectedDays = {};
  String _subscriptionType = 'monthly'; // 'monthly' | 'semester'
  bool _isSaving = false;

  static const _days = [
    ('sunday', 'الأحد'),
    ('monday', 'الاثنين'),
    ('tuesday', 'الثلاثاء'),
    ('wednesday', 'الأربعاء'),
    ('thursday', 'الخميس'),
    ('friday', 'الجمعة'),
    ('saturday', 'السبت'),
  ];

  @override
  void dispose() {
    _destCtrl.dispose();
    _fareCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          _step == 0 ? 'نوع الموعد' : 'تفاصيل الموعد',
          style: GoogleFonts.cairo(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: _kText),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _step == 0
            ? _TypeSelectorStep(
                key: const ValueKey('step-0'),
                selectedType: _selectedType,
                onTypeSelected: (t) => setState(() => _selectedType = t),
                onContinue: () => setState(() => _step = 1),
              )
            : _FormStep(
                key: const ValueKey('step-1'),
                scheduleType: _selectedType!,
                formKey: _formKey,
                destCtrl: _destCtrl,
                fareCtrl: _fareCtrl,
                durationCtrl: _durationCtrl,
                departureTime: _departureTime,
                selectedDays: _selectedDays,
                subscriptionType: _subscriptionType,
                isSaving: _isSaving,
                onPickTime: _pickTime,
                onDayToggle: (day) => setState(() {
                  if (_selectedDays.contains(day)) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                }),
                onSubscriptionTypeChange: (v) =>
                    setState(() => _subscriptionType = v),
                onSubmit: _submit,
                days: _days,
              ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: _selectedType == ScheduleType.university
                ? _kUniversity
                : _kStation,
            onPrimary: Colors.white,
            onSurface: _kText,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: _selectedType == ScheduleType.university
                  ? _kUniversity
                  : _kStation,
              textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteColor: _kCard,
            hourMinuteTextColor: _kText,
            dayPeriodColor: _kCard,
            dayPeriodTextColor: _kText,
            dialHandColor: _selectedType == ScheduleType.university
                ? _kUniversity
                : _kStation,
            dialBackgroundColor: _kCard,
            dialTextColor: _kText,
            entryModeIconColor: _selectedType == ScheduleType.university
                ? _kUniversity
                : _kStation,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _departureTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('اختر يوماً واحداً على الأقل',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final timeStr =
        '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';

    final error = await ref
        .read(coordinatorScheduleProvider(widget.coordinator.id).notifier)
        .createSchedule(
          origin: widget.coordinator.entityName,
          destination: _destCtrl.text.trim(),
          departureTime: timeStr,
          availableDays: _selectedDays.toList(),
          baseFare: double.parse(_fareCtrl.text.trim()),
          scheduleType: _selectedType!,
          subscriptionType: _selectedType == ScheduleType.university
              ? _subscriptionType
              : null,
          durationDays: _selectedType == ScheduleType.university &&
                  _durationCtrl.text.trim().isNotEmpty
              ? int.tryParse(_durationCtrl.text.trim())
              : null,
        );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $error', style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال الموعد — في انتظار الموافقة',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}

// ── Step 0: Type Selector ──────────────────────────────────────

class _TypeSelectorStep extends StatelessWidget {
  final ScheduleType? selectedType;
  final ValueChanged<ScheduleType> onTypeSelected;
  final VoidCallback onContinue;

  const _TypeSelectorStep({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ما نوع الموعد الذي تريد إضافته؟',
            style: GoogleFonts.cairo(
              color: _kSubText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _TypeCard(
            type: ScheduleType.university,
            icon: CupertinoIcons.building_2_fill,
            title: 'موعد جامعة',
            subtitle: 'اشتراكات شهرية أو فصل دراسي مع مدة محددة',
            accentColor: _kUniversity,
            isSelected: selectedType == ScheduleType.university,
            onTap: () => onTypeSelected(ScheduleType.university),
          ),
          const SizedBox(height: 16),
          _TypeCard(
            type: ScheduleType.station,
            icon: CupertinoIcons.bus,
            title: 'موعد موقف',
            subtitle: 'مواعيد يومية متكررة بدون اشتراكات',
            accentColor: _kStation,
            isSelected: selectedType == ScheduleType.station,
            onTap: () => onTypeSelected(ScheduleType.station),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedType == null
                    ? const Color(0xFFCCCCCC)
                    : _kText,
                foregroundColor: selectedType == null ? Colors.white : _kLime,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: selectedType == null ? null : onContinue,
              child: Text(
                'متابعة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final ScheduleType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? _kText : _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kText : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? _kLime.withValues(alpha: 0.15)
                    : accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? _kLime : _kSubText,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : _kText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : _kSubText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: _kLime, size: 22)
            else
              const Icon(CupertinoIcons.circle,
                  color: Colors.black12, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Form ───────────────────────────────────────────────

class _FormStep extends StatelessWidget {
  final ScheduleType scheduleType;
  final GlobalKey<FormState> formKey;
  final TextEditingController destCtrl;
  final TextEditingController fareCtrl;
  final TextEditingController durationCtrl;
  final TimeOfDay departureTime;
  final Set<String> selectedDays;
  final String subscriptionType;
  final bool isSaving;
  final VoidCallback onPickTime;
  final ValueChanged<String> onDayToggle;
  final ValueChanged<String> onSubscriptionTypeChange;
  final VoidCallback onSubmit;
  final List<(String, String)> days;

  const _FormStep({
    super.key,
    required this.scheduleType,
    required this.formKey,
    required this.destCtrl,
    required this.fareCtrl,
    required this.durationCtrl,
    required this.departureTime,
    required this.selectedDays,
    required this.subscriptionType,
    required this.isSaving,
    required this.onPickTime,
    required this.onDayToggle,
    required this.onSubscriptionTypeChange,
    required this.onSubmit,
    required this.days,
  });

  Color get _accentColor =>
      scheduleType == ScheduleType.university ? _kUniversity : _kStation;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // University-specific: Subscription type + duration
            if (scheduleType == ScheduleType.university) ...[
              _SectionLabel('نوع الاشتراك'),
              const SizedBox(height: 8),
              _SubscriptionTypeToggle(
                value: subscriptionType,
                accentColor: _accentColor,
                onChanged: onSubscriptionTypeChange,
              ),
              const SizedBox(height: 16),
              _SectionLabel('مدة الاشتراك (بالأيام)'),
              const SizedBox(height: 8),
              _DarkField(
                controller: durationCtrl,
                hint: subscriptionType == 'semester' ? '120 يوم' : '30 يوم',
                keyboardType: TextInputType.number,
                accentColor: _accentColor,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'مطلوب';
                  if (int.tryParse(v) == null) return 'رقم صحيح فقط';
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],

            _SectionLabel('الوجهة'),
            const SizedBox(height: 8),
            _DarkField(
              controller: destCtrl,
              hint: scheduleType == ScheduleType.university
                  ? 'اسم الجامعة / الوجهة'
                  : 'الوجهة',
              accentColor: _accentColor,
              validator: (v) =>
                  v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 20),

            _SectionLabel('وقت الانطلاق'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onPickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.clock,
                        color: _accentColor, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      departureTime.format(context),
                      style: GoogleFonts.cairo(
                          color: _kText, fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right,
                        color: _kSubText, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _SectionLabel('أيام التشغيل'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: days.map((day) {
                final isSelected = selectedDays.contains(day.$1);
                return GestureDetector(
                  onTap: () => onDayToggle(day.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _accentColor.withValues(alpha: 0.12)
                          : _kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _accentColor
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      day.$2,
                      style: GoogleFonts.cairo(
                        color:
                            isSelected ? _accentColor : _kSubText,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _SectionLabel('السعر (جنيه)'),
            const SizedBox(height: 8),
            _DarkField(
              controller: fareCtrl,
              hint: '0',
              keyboardType: TextInputType.number,
              accentColor: _accentColor,
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (double.tryParse(v) == null) return 'رقم فقط';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _accentColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info_circle,
                      color: _accentColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إرسال الموعد للمراجعة. بعد موافقة الإدارة يمكنك تعيين سائق.',
                      style: GoogleFonts.cairo(
                          color: _accentColor.withValues(alpha: 0.85),
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kText,
                  foregroundColor: _kLime,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: isSaving ? null : onSubmit,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: _kLime,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'إرسال للموافقة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Subscription Type Toggle ───────────────────────────────────

class _SubscriptionTypeToggle extends StatelessWidget {
  final String value;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  const _SubscriptionTypeToggle({
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'شهري',
            isSelected: value == 'monthly',
            accentColor: accentColor,
            onTap: () => onChanged('monthly'),
          ),
          _ToggleOption(
            label: 'فصل دراسي',
            isSelected: value == 'semester',
            accentColor: accentColor,
            onTap: () => onChanged('semester'),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: isSelected ? Colors.white : _kSubText,
              fontSize: 14,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        color: _kSubText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final Color accentColor;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.accentColor,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.cairo(color: _kText, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: _kSubText, fontSize: 15),
        filled: true,
        fillColor: _kCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
