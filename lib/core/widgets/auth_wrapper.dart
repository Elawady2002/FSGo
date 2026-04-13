import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/logger_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/user_session_validator.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

/// Authentication wrapper that routes based on auth state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize session validator (it will listen to lifecycle changes)
    ref.watch(userSessionValidatorProvider);
    
    final authState = ref.watch(authProvider);

    LoggerService.debug('AuthWrapper build called. State: $authState');

    return authState.when(
      data: (user) {
        LoggerService.info(
          'AuthWrapper: Data state, user is ${user?.fullName ?? 'null'}',
        );
        if (user != null) {
          return const HomePage();
        } else {
          return const OnboardingPage();
        }
      },
      loading: () {
        LoggerService.info('AuthWrapper: Loading state');
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stackTrace) {
        LoggerService.error(
          'AuthWrapper error',
          error: error,
          stackTrace: stackTrace,
        );
        return Scaffold(
          body: Center(child: Text('حدث خطأ أثناء تحميل البيانات: $error')),
        );
      },
    );
  }
}
