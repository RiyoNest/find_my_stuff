import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/database/database_seed.dart';
import 'core/database/objectbox_service.dart';
import 'core/routing/app_router.dart';
import 'core/services/app_review_service.dart';
import 'core/services/app_update_service.dart';
import 'core/services/crashlytics_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await CrashlyticsService.initialize();

  await ObjectBoxService.initialize();
  await DatabaseSeed.seed();

  runApp(const ProviderScope(child: FindMyStuffApp()));
}

class FindMyStuffApp extends StatelessWidget {
  const FindMyStuffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FindMyStuff',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,

      theme: RAppTheme.lightTheme,
      darkTheme: RAppTheme.darkTheme,

      routerConfig: RAppRouter.router,
    );
  }
}
