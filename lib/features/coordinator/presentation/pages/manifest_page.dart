import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/coordinator_schedule_entity.dart';
import '../../domain/entities/passenger_entity.dart';
import '../providers/driver_duty_provider.dart';

const _kBg = Color(0xFF1A1A1A);
const _kCard = Color(0xFF242424);
const _kLime = Color(0xFFC9D420);
const _kText = Colors.white;
const _kSubText = Color(0xFF9E9E9E);

class ManifestPage extends ConsumerStatefulWidget {
  final CoordinatorScheduleEntity schedule;
  final DateTime date;

  const ManifestPage({
    super.key,
    required this.schedule,
    required this.date,
  });

  @override
  ConsumerState<ManifestPage> createState() => _ManifestPageState();
}

class _ManifestPageState extends ConsumerState<ManifestPage> {
  late final ManifestKey _key;

  @override
  void initState() {
    super.initState();
    _key = ManifestKey(widget.schedule.id, widget.date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(manifestProvider(_key).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manifestProvider(_key));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Column(
          children: [
            Text(
              widget.schedule.routeLabel,
              style: GoogleFonts.cairo(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.schedule.departureTime,
              style: GoogleFonts.cairo(color: _kLime, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kText),
      ),
      body: Builder(builder: (_) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator(color: _kLime));
        }
        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(state.error!,
                    style: GoogleFonts.cairo(color: _kSubText),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.read(manifestProvider(_key).notifier).load(),
                  child: Text('إعادة المحاولة',
                      style: GoogleFonts.cairo(color: _kLime)),
                ),
              ],
            ),
          );
        }
        if (state.passengers.isEmpty) {
          return _EmptyManifest();
        }
        return Column(
          children: [
            _ManifestSummaryBar(state: state),
            Expanded(
              child: RefreshIndicator(
                color: _kLime,
                backgroundColor: _kCard,
                onRefresh: () =>
                    ref.read(manifestProvider(_key).notifier).load(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.passengers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    return _PassengerRow(
                      passenger: state.passengers[i],
                      onCheckIn: () => _checkIn(state.passengers[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _checkIn(PassengerEntity passenger) async {
    if (passenger.isBoarded) return;
    await ref
        .read(manifestProvider(_key).notifier)
        .checkIn(passenger.bookingId);
  }
}

// ── Summary Bar ────────────────────────────────────────────────

class _ManifestSummaryBar extends StatelessWidget {
  final ManifestState state;
  const _ManifestSummaryBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.passengers.length;
    final boarded = state.boardedCount;
    final subscribers =
        state.passengers.where((p) => p.isSubscriber).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatChip(
            label: 'إجمالي',
            value: '$total',
            color: _kText,
          ),
          _Divider(),
          _StatChip(
            label: 'ركبوا',
            value: '$boarded',
            color: Colors.greenAccent,
          ),
          _Divider(),
          _StatChip(
            label: 'في الانتظار',
            value: '${total - boarded}',
            color: _kLime,
          ),
          _Divider(),
          _StatChip(
            label: 'مشتركون',
            value: '$subscribers',
            color: Colors.cyanAccent,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
              color: color, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(label,
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 11)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white12);
  }
}

// ── Passenger Row ──────────────────────────────────────────────

class _PassengerRow extends StatelessWidget {
  final PassengerEntity passenger;
  final VoidCallback onCheckIn;

  const _PassengerRow({required this.passenger, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    final isBoarded = passenger.isBoarded;
    final isSubscriber = passenger.isSubscriber;

    return Container(
      decoration: BoxDecoration(
        color: isBoarded
            ? Colors.greenAccent.withValues(alpha: 0.06)
            : _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscriber
              ? Colors.cyanAccent.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isBoarded
              ? Colors.greenAccent.withValues(alpha: 0.15)
              : _kLime.withValues(alpha: 0.12),
          child: Text(
            passenger.fullName.isNotEmpty ? passenger.fullName[0] : '?',
            style: GoogleFonts.cairo(
              color: isBoarded ? Colors.greenAccent : _kLime,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                passenger.fullName,
                style: GoogleFonts.cairo(
                  color: _kText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: isBoarded
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: Colors.greenAccent,
                ),
              ),
            ),
            if (isSubscriber)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'مشترك',
                  style: GoogleFonts.cairo(
                      color: Colors.cyanAccent, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              passenger.phone,
              style: GoogleFonts.cairo(color: _kSubText, fontSize: 12),
            ),
            if (passenger.passengerCount > 1) ...[
              const SizedBox(width: 8),
              Text(
                '× ${passenger.passengerCount}',
                style: GoogleFonts.cairo(color: _kSubText, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: isBoarded
            ? const Icon(CupertinoIcons.checkmark_circle_fill,
                color: Colors.greenAccent, size: 28)
            : GestureDetector(
                onTap: onCheckIn,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kLime,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ركب',
                    style: GoogleFonts.cairo(
                      color: _kBg,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────

class _EmptyManifest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.person_2, size: 64, color: _kLime),
          const SizedBox(height: 16),
          Text(
            'لا يوجد ركاب بعد',
            style: GoogleFonts.cairo(
              color: _kText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يحجز أحد في هذه الرحلة لهذا اليوم',
            style: GoogleFonts.cairo(color: _kSubText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
