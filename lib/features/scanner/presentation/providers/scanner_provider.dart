import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../coordinator/data/datasources/driver_duty_data_source.dart';
import '../../../coordinator/presentation/providers/driver_duty_provider.dart';
import '../../domain/feedback_service.dart';

// ── Feedback Service ───────────────────────────────────────────

final feedbackServiceProvider = Provider<FeedbackService>(
  (_) => const FeedbackService(),
);

// ── Scan State ─────────────────────────────────────────────────

enum ScanResult { idle, success, alreadyBoarded, notFound, error }

class ScanState {
  final ScanResult result;
  final String? lastScannedId;
  final String? message;
  final bool isProcessing;

  const ScanState({
    this.result = ScanResult.idle,
    this.lastScannedId,
    this.message,
    this.isProcessing = false,
  });

  ScanState copyWith({
    ScanResult? result,
    String? lastScannedId,
    String? message,
    bool? isProcessing,
  }) =>
      ScanState(
        result: result ?? this.result,
        lastScannedId: lastScannedId ?? this.lastScannedId,
        message: message ?? this.message,
        isProcessing: isProcessing ?? this.isProcessing,
      );
}

// ── Scanner Notifier ───────────────────────────────────────────

class ScannerNotifier extends StateNotifier<ScanState> {
  final DriverDutyDataSource _dataSource;
  final FeedbackService _feedback;
  final ManifestKey _manifestKey;

  final Set<String> _processedIds = {};
  DateTime? _lastScanTime;

  ScannerNotifier(this._dataSource, this._feedback, this._manifestKey)
      : super(const ScanState());

  /// Process a raw QR value from the camera.
  Future<void> processQr(String raw) async {
    if (state.isProcessing) return;

    // Debounce: ignore the same code for 2 seconds
    final now = DateTime.now();
    if (_lastScanTime != null &&
        state.lastScannedId == raw &&
        now.difference(_lastScanTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastScanTime = now;

    state = state.copyWith(isProcessing: true, lastScannedId: raw);

    try {
      // The QR payload IS the booking ID (UUID)
      final bookingId = raw.trim();

      if (_processedIds.contains(bookingId)) {
        await _feedback.playError();
        state = state.copyWith(
          result: ScanResult.alreadyBoarded,
          message: 'الراكب ركب مسبقاً',
          isProcessing: false,
        );
        return;
      }

      await _dataSource.checkInPassenger(bookingId);
      _processedIds.add(bookingId);

      await _feedback.playSuccess();
      state = state.copyWith(
        result: ScanResult.success,
        message: 'تم التحقق بنجاح ✓',
        isProcessing: false,
      );
    } catch (e) {
      await _feedback.playError();
      state = state.copyWith(
        result: ScanResult.error,
        message: 'تذكرة غير صالحة',
        isProcessing: false,
      );
    }
  }

  void reset() {
    state = const ScanState();
    _lastScanTime = null;
  }
}

final scannerProvider = StateNotifierProvider.family<
    ScannerNotifier, ScanState, ManifestKey>((ref, key) {
  final ds = ref.watch(driverDutyDataSourceProvider);
  final feedback = ref.watch(feedbackServiceProvider);
  return ScannerNotifier(ds, feedback, key);
});
