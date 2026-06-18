import 'package:find_my_stuff/features/home/presentation/pages/home_page.dart';
import 'package:find_my_stuff/features/splash/presentation/pages/splash_page.dart';
import 'package:go_router/go_router.dart';

class RAppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}