import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/models/permission_result.dart';
import 'package:find_my_stuff/shared/services/permission_service.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

enum AppPermissionType {
  camera,
  gallery,
  microphone,
}

class PermissionDialog extends StatelessWidget {
  final AppPermissionType type;
  final bool isPermanentlyDenied;

  const PermissionDialog({
    super.key,
    required this.type,
    required this.isPermanentlyDenied,
  });

  IconData _getIcon() {
    if (isPermanentlyDenied) {
      return Icons.settings_outlined;
    }
    switch (type) {
      case AppPermissionType.camera:
        return Icons.camera_alt_outlined;
      case AppPermissionType.gallery:
        return Icons.photo_library_outlined;
      case AppPermissionType.microphone:
        return Icons.mic_none;
    }
  }

  String _getTitle() {
    final name = _getPermissionName();
    return isPermanentlyDenied ? '$name Permission Disabled' : '$name Permission Required';
  }

  String _getDescription() {
    if (isPermanentlyDenied) {
      final name = _getPermissionName();
      return '$name access has been permanently denied. Please enable it from your device Settings.';
    }
    switch (type) {
      case AppPermissionType.camera:
        return 'Find My Stuff needs camera access to capture photos of your belongings.';
      case AppPermissionType.gallery:
        return 'Find My Stuff needs photo gallery access to let you select photos of your belongings.';
      case AppPermissionType.microphone:
        return 'Find My Stuff needs microphone access for voice search.';
    }
  }

  String _getPermissionName() {
    switch (type) {
      case AppPermissionType.camera:
        return 'Camera';
      case AppPermissionType.gallery:
        return 'Gallery';
      case AppPermissionType.microphone:
        return 'Microphone';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(_getIcon(), size: 36, color: theme.colorScheme.primary),
      title: Text(_getTitle(), textAlign: TextAlign.center),
      content: Text(
        _getDescription(),
        style: context.bodyStyle,
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(isPermanentlyDenied ? 'Open Settings' : 'Allow'),
        ),
      ],
    );
  }
}

class PermissionRequestHelper {
  static Future<bool> request({
    required BuildContext context,
    required PermissionService service,
    required AppPermissionType type,
    VoidCallback? onGranted,
  }) async {
    Future<PermissionResult> runRequest() {
      switch (type) {
        case AppPermissionType.camera:
          return service.requestCameraPermission();
        case AppPermissionType.gallery:
          return service.requestGalleryPermission();
        case AppPermissionType.microphone:
          return service.requestMicrophonePermission();
      }
    }

    final result = await runRequest();

    if (result.isGranted) {
      onGranted?.call();
      return true;
    }

    if (result.shouldOpenSettings) {
      if (context.mounted) {
        final openSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PermissionDialog(type: type, isPermanentlyDenied: true),
        );
        if (openSettings == true) {
          await service.openSettings();
        }
      }
      return false;
    }

    if (context.mounted) {
      final allow = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PermissionDialog(type: type, isPermanentlyDenied: false),
      );

      if (allow == true) {
        final retryResult = await runRequest();
        if (retryResult.isGranted) {
          onGranted?.call();
          return true;
        } else if (retryResult.shouldOpenSettings) {
          if (context.mounted) {
            final openSettings = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => PermissionDialog(type: type, isPermanentlyDenied: true),
            );
            if (openSettings == true) {
              await service.openSettings();
            }
          }
        }
      }
    }

    return false;
  }
}
