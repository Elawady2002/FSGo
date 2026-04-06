import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../config/supabase_config.dart';
import '../config/env.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';

/// Provider that handles all app-wide initialization synchronously
/// but is consumed asynchronously to avoid blocking the main thread.
final appStartupProvider = FutureProvider<void>((ref) async {
  LoggerService.info('Starting App Initialization...');

  // 1. Initialize date formatting
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('ar_EG', null);
  await initializeDateFormatting('en', null);
  LoggerService.info('Date formatting initialized');

  // 2. Validate compile-time environment variables
  if (!Env.isValid) {
    throw Exception(Env.validationError);
  }
  LoggerService.info('Environment variables validated');

  // 3. Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    LoggerService.info('Supabase initialized');
  } catch (e) {
    LoggerService.error('Failed to initialize Supabase', error: e);
    throw Exception('Failed to initialize backend services: $e');
  }

  // 4. Initialize Push Notifications (graceful — won't crash if Firebase not configured)
  await NotificationService.instance.initialize();
  LoggerService.info('App Initialization Complete');
});
