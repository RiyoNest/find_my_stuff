import 'package:flutter/material.dart';

import '../../../../shared/repositories/place_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PlaceRepository();

    final places = repo.getAll();

    debugPrint('Places Count: ${places.length}');

    if (places.isNotEmpty) {
      debugPrint('First Place: ${places.first.name}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FindMyStuff'),
      ),
      body: Center(
        child: Text(
          places.isEmpty
              ? 'No Places Found'
              : 'Welcome to ${places.first.name}',
        ),
      ),
    );
  }
}