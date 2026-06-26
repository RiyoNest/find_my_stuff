// File: lib/core/routing/app_router.dart
//
// CHANGE from your version: added routes for /quick-add, /dashboard-items,
// and /photos. Previously these three pages were only reachable via
// Navigator.push(MaterialPageRoute(...)) from the Home page, while
// everything else used context.push() (go_router) — inconsistent
// back-stack and deep-link behavior. Now everything goes through
// go_router. Pages needing a list (DashboardItemsPage, PhotoGalleryPage)
// receive it via `extra` since URLs can't carry full object lists.

import 'package:find_my_stuff/features/dashboard/presentation/pages/dashboard_items_page.dart';
import 'package:find_my_stuff/features/gallery/presentation/pages/photo_gallery_page.dart';
import 'package:find_my_stuff/features/home/presentation/pages/home_page.dart';
import 'package:find_my_stuff/features/storage_tree/presentation/pages/quick_add_item_page.dart';
import 'package:go_router/go_router.dart';

import '../../features/archive/presentation/pages/archived_items_page.dart';
import '../../features/room/presentation/pages/room_details_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/storage_tree/presentation/pages/storage_node_details_page.dart';

class RAppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      // GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      // GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/room/:roomUuid',
        builder: (context, state) {
          return RoomDetailsPage(roomUuid: state.pathParameters['roomUuid']!);
        },
      ),
      GoRoute(
        path: '/node/:nodeUuid',
        builder: (context, state) {
          return StorageNodeDetailsPage(
            nodeUuid: state.pathParameters['nodeUuid']!,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          return const SearchPage();
        },
      ),
      GoRoute(
        path: '/archived',
        builder: (context, state) => const ArchivedItemsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/quick-add',
        builder: (context, state) => const QuickAddItemPage(),
      ),
      GoRoute(
        path: '/dashboard/:type',
        builder: (context, state) {
          return DashboardItemsPage(
            type: state.pathParameters['type']!,
          );
        },
      ),
      GoRoute(
        path: '/photos',
        builder: (context, state) {
          return const PhotoGalleryPage();
        },
      ),
    ],
  );
}