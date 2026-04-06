import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Provides bi-modal feedback (haptic + audio) for scan results.
class FeedbackService {
  const FeedbackService();

  /// Play success feedback — short double vibration + system click.
  Future<void> playSuccess() async {
    await _vibrate(pattern: [0, 80, 60, 80]);
    await SystemSound.play(SystemSoundType.click);
  }

  /// Play error feedback — long single vibration.
  Future<void> playError() async {
    await _vibrate(pattern: [0, 300]);
  }

  Future<void> _vibrate({required List<int> pattern}) async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) {
      HapticFeedback.vibrate();
      return;
    }
    Vibration.vibrate(pattern: pattern);
  }
}
