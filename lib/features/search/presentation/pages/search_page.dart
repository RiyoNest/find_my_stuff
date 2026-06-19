import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/search_result_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('Search Items')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),

            const SizedBox(height: 16),

            Expanded(
              child: resultsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (items) {
                  if (query.isEmpty) {
                    return const Center(child: Text('Start typing to search'));
                  }

                  if (items.isEmpty) {
                    return const Center(child: Text('No results found'));
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];

                      return SearchResultTile(item: item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
