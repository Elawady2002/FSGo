import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../providers/coordinator_provider.dart';

const _kBg = Colors.white;
const _kCard = Color(0xFFF5F5F5);
const _kLime = Color(0xFF1A1A1A);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);

/// Bottom sheet to pick and assign a driver to an approved schedule
class DriverAssignerSheet extends ConsumerStatefulWidget {
  final CoordinatorScheduleEntity schedule;
  final UserEntity coordinator;

  const DriverAssignerSheet({
    super.key,
    required this.schedule,
    required this.coordinator,
  });

  @override
  ConsumerState<DriverAssignerSheet> createState() =>
      _DriverAssignerSheetState();
}

class _DriverAssignerSheetState extends ConsumerState<DriverAssignerSheet> {
  String? _selectedDriverId;
  String? _selectedDriverName;
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    final driversAsync =
        ref.watch(coordinatorDriversProvider(widget.coordinator.id));

    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'تعيين سائق',
            style: GoogleFonts.cairo(
              color: _kText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.schedule.routeLabel,
            style:
                GoogleFonts.cairo(color: _kSubText, fontSize: 13),
          ),
          const SizedBox(height: 20),
          driversAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _kLime),
            ),
            error: (e, _) => Text(
              'خطأ في تحميل السائقين: $e',
              style: GoogleFonts.cairo(color: Colors.redAccent),
            ),
            data: (drivers) {
              if (drivers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.person_crop_circle,
                          color: _kSubText, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'لا يوجد سائقون متاحون',
                        style: GoogleFonts.cairo(color: _kSubText),
                      ),
                    ],
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: drivers.length,
                  separatorBuilder: (_, _) => const Divider(
                    color: Colors.black12,
                    height: 1,
                  ),
                  itemBuilder: (_, i) {
                    final driver = drivers[i];
                    final isSelected = _selectedDriverId == driver.id;
                    return ListTile(
                      onTap: () => setState(() {
                        _selectedDriverId = driver.id;
                        _selectedDriverName = driver.fullName;
                      }),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? _kLime.withValues(alpha: 0.2)
                            : Colors.black.withOpacity(0.05),
                        child: Text(
                          driver.fullName.isNotEmpty
                              ? driver.fullName[0]
                              : '?',
                          style: GoogleFonts.cairo(
                            color: isSelected ? _kLime : _kText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        driver.fullName,
                        style: GoogleFonts.cairo(
                          color: _kText,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        driver.phone,
                        style:
                            GoogleFonts.cairo(color: _kSubText, fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(CupertinoIcons.checkmark_circle_fill,
                              color: _kLime)
                          : null,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _selectedDriverId != null ? _kLime : Colors.black12,
                foregroundColor: _kBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _selectedDriverId == null || _isAssigning
                  ? null
                  : _assign,
              child: _isAssigning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: _kBg, strokeWidth: 2),
                    )
                  : Text(
                      'تأكيد التعيين',
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _assign() async {
    if (_selectedDriverId == null) return;
    setState(() => _isAssigning = true);

    final error = await ref
        .read(coordinatorScheduleProvider(widget.coordinator.id).notifier)
        .assignDriver(
          widget.schedule.id,
          _selectedDriverId!,
          _selectedDriverName!,
        );

    setState(() => _isAssigning = false);
    if (!mounted) return;

    Navigator.pop(context);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('فشل التعيين: $error', style: GoogleFonts.cairo()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تعيين ${_selectedDriverName ?? "السائق"} بنجاح',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
