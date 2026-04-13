import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../services/logger_service.dart';

/// Provider that monitors app lifecycle and verifies user session validity
/// when the app returns to the foreground.
final userSessionValidatorProvider = Provider<void>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  
  // Create a listener for lifecycle changes
  final observer = _AppLifecycleObserver(
    onResumed: () async {
      final user = authNotifier.currentUser;
      if (user != null) {
        LoggerService.info('SessionValidator: App resumed, verifying user existence for ${user.id}');
        // authProvider.build() or authStateChanges will naturally trigger 
        // because we call getCurrentUser (which now has the logout logic) 
        // to refresh the state if needed.
        
        // We can explicitly trigger a check by calling a "refresh" or just 
        // letting the auth subscription handle it if we trigger a dummy fetch.
        // In our case, the easiest way is to call authNotifier.logout() if 
        // a dedicated check fails.
        
        // Actually, the authProvider matches authRepository.authStateChanges().
        // If we want to force a check, we can call refresh on the provider.
        ref.invalidate(authProvider);
      }
    },
  );

  WidgetsBinding.instance.addObserver(observer);
  
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
  });
});

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResumed;

  _AppLifecycleObserver({required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
