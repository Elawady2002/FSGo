import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/trip_management_provider.dart';
import '../../../coordinator/presentation/providers/driver_duty_provider.dart';
import '../../data/models/trip_session_model.dart';

const _kLime = Color(0xFFC9D420);
const _kText = Color(0xFF1A1A1A);
const _kSubText = Color(0xFF666666);

/// "Start Trip" button with confirmation dialog and live seat counter.
///
/// Place this inside [ManifestPage] or any trip-detail screen.
class StartTripButton extends ConsumerWidget {
  final ManifestKey manifestKey;
  final String driverId;

  const StartTripButton({
    super.key,
    required this.manifestKey,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (key: manifestKey, driverId: driverId);
    final state = ref.watch(tripSessionProvider(args));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live seat counter chip
        _SeatCounterChip(counter: state.seatCounter),
        const SizedBox(height: 12),

        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              state.error!,
              style: GoogleFonts.cairo(
                  color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

        // Action button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: _buildButton(context, ref, state, args),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref,
    TripSessionState state,
    ({ManifestKey key, String driverId}) args,
  ) {
    switch (state.status) {
      case TripStatus.scheduled:
        return ElevatedButton.icon(
          onPressed: state.isStarting
              ? null
              : () => _confirmStart(context, ref, args),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kText,
            foregroundColor: _kLime,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          icon: state.isStarting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: _kLime),
                )
              : const Icon(CupertinoIcons.play_fill, size: 18),
          label: Text(
            state.isStarting ? 'جارٍ التشغيل...' : 'تشغيل الرحلة',
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
        );

      case TripStatus.in_progress:
        return OutlinedButton.icon(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: _kLime,
            side: const BorderSide(color: _kLime),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(CupertinoIcons.checkmark_circle, size: 18),
          label: Text(
            'الرحلة جارية',
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirmStart(
    BuildContext context,
    WidgetRef ref,
    ({ManifestKey key, String driverId}) args,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'تشغيل الرحلة؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'سيتم إغلاق نافذة الحجز وإعادة أجرة من لم يصل إلى محافظهم تلقائياً.',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text('تشغيل',
                style: GoogleFonts.cairo(color: _kLime)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tripSessionProvider(args).notifier).startTrip();
    }
  }
}

// ── Seat Counter Chip ──────────────────────────────────────────

class _SeatCounterChip extends StatelessWidget {
  final SeatCounter counter;
  const _SeatCounterChip({required this.counter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.person_2, size: 16, color: _kSubText),
          const SizedBox(width: 8),
          Text(
            'ركبوا: ${counter.label}',
            style: GoogleFonts.cairo(
              color: _kText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: counter.fraction,
              backgroundColor: Colors.grey.shade300,
              color: _kLime,
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
