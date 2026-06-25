// File: lib/main.dart
//
// CHANGE from your version: FindMyStuffApp is now a ConsumerWidget that
// watches themeModeProvider, so the theme selection in AppDrawer actually
// changes the live app instead of being local-only state.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/database/database_seed.dart';
import 'core/database/objectbox_service.dart';
import 'core/routing/app_router.dart';
import 'core/services/crashlytics_service.dart';
import 'firebase_options.dart';
import 'shared/providers/theme_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'core/services/photo_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await CrashlyticsService.initialize();

  final appDir = await getApplicationDocumentsDirectory();
  PhotoStorageService.initialize(appDir.path);

  await ObjectBoxService.initialize();
  await DatabaseSeed.seed();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FindMyStuffApp(),
    ),
  );
}

class FindMyStuffApp extends ConsumerWidget {
  const FindMyStuffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FindMyStuff',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,

      theme: RAppTheme.lightTheme,
      darkTheme: RAppTheme.darkTheme,

      routerConfig: RAppRouter.router,
    );
  }
}