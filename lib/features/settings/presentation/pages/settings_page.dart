import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/services/backup_service.dart';
import 'package:find_my_stuff/shared/providers/room_providers.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<bool> _showConfirmImportDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: ctx.borderRadiusL,
        ),
        title: Text('Replace Existing Data?', style: ctx.titleStyle),
        content: Text(
          'Importing a backup will overwrite your current local database. This action cannot be undone. Do you want to continue?',
          style: ctx.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: ctx.buttonStyle),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: RAppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Import Backup', style: ctx.buttonStyle),
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
            leading: Icon(Icons.download, size: context.iconMedium),
            title: Text('Export Backup', style: context.titleStyle),
            subtitle: Text(
              'Save all rooms and items',
              style: context.bodyMediumStyle,
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
            leading: Icon(Icons.download, size: context.iconMedium),
            title: Text('Import Backup', style: context.titleStyle),
            subtitle: Text(
              'Restore database from a backup file',
              style: context.bodyMediumStyle,
            ),
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