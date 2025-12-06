import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'core/widgets/auth_wrapper.dart';
import 'dart:async';
import 'dart:developer';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Initialize date formatting for Arabic
      await initializeDateFormatting('ar', null);

      try {
        // Load environment variables
        await dotenv.load(fileName: '.env');
        log('Environment variables loaded successfully', name: 'AppLaunch');

        // Initialize Supabase
        await SupabaseConfig.initialize();
        log('Supabase initialized successfully', name: 'AppLaunch');
      } catch (error, stack) {
        log(
          'CRITICAL ERROR during initialization',
          error: error,
          stackTrace: stack,
          name: 'AppLaunch',
        );
        // You might want to show an error screen here
        // For now, we'll continue to allow the app to run
      }

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      log(
        'CRITICAL ERROR: Caught error in runZonedGuarded',
        error: error,
        stackTrace: stack,
        name: 'AppLaunch',
      );
    },
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Fi El Sekka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Localization Configuration
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'EG'), // Egyptian Arabic
      ],
      locale: const Locale('ar', 'EG'), // Force Arabic
      home: const AuthWrapper(),
    );
  }
}
