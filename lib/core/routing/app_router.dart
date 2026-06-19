import 'package:find_my_stuff/features/home/presentation/pages/home_page.dart';
import 'package:find_my_stuff/features/splash/presentation/pages/splash_page.dart';
import 'package:go_router/go_router.dart';

import '../../features/archive/presentation/pages/archived_items_page.dart';
import '../../features/room/presentation/pages/room_details_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/storage_tree/presentation/pages/storage_node_details_page.dart';

class RAppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
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
    ],
  );
}
