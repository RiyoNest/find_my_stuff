import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/routing/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FindMyStuffApp(),
    ),
  );
}

class FindMyStuffApp extends StatelessWidget {
  const FindMyStuffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FindMyStuff',
      debugShowCheckedModeBanner: false,
      theme: RAppTheme.lightTheme,
      routerConfig: RAppRouter.router,
    );
  }
}