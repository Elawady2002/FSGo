import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../config/supabase_config.dart';
import '../services/logger_service.dart';

/// Provider that handles all app-wide initialization synchronously
/// but is consumed asynchronously to avoid blocking the main thread.
final appStartupProvider = FutureProvider<void>((ref) async {
  LoggerService.info('Starting App Initialization...');

  // 1. Initialize date formatting
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('ar_EG', null);
  await initializeDateFormatting('en', null);
  LoggerService.info('Date formatting initialized');

  // 2. Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    LoggerService.info('Environment variables loaded');
  } catch (e) {
    LoggerService.error('Failed to load .env file', error: e);
    throw Exception('Failed to load configuration: $e');
  }

  // 3. Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    LoggerService.info('Supabase initialized');
  } catch (e) {
    LoggerService.error('Failed to initialize Supabase', error: e);
    throw Exception('Failed to initialize backend services: $e');
  }

  LoggerService.info('App Initialization Complete');
});
