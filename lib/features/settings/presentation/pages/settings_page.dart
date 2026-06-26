import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/services/backup_service.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<bool> _showConfirmImportDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RAppRadius.lg),
        ),
        title: const Text('Replace Existing Data?'),
        content: const Text(
          'Importing a backup will overwrite your current local database. This action cannot be undone. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: RAppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import Backup'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

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
              try {
                await BackupService.exportBackup();
                if (context.mounted) {
                  AppSnackBar.success(context, 'Backup exported');
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.error(context, 'Export failed: ${e.toString()}');
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Backup'),
            onTap: () async {
              final confirmed = await _showConfirmImportDialog(context);
              if (!confirmed) return;

              try {
                await BackupService.importBackup();
                ref.read(roomRefreshProvider.notifier).state++;
                ref.read(storageRefreshProvider.notifier).state++;

                if (context.mounted) {
                  AppSnackBar.success(context, 'Backup imported');
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.error(context, 'Import failed: ${e.toString()}');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}