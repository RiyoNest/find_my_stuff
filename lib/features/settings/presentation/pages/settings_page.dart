import 'package:find_my_stuff/core/services/backup_service.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Backup'),
            subtitle: const Text(
              'Save all rooms and items',
            ),
            onTap: () async {
              await BackupService.exportBackup();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup exported'),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Backup'),
            onTap: () async {
              await BackupService.importBackup();
              ref.read(roomRefreshProvider.notifier).state++;
              ref.read(storageRefreshProvider.notifier).state++;

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup imported')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}