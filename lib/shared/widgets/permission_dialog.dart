import 'dart:async';
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

class _LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  bool _wasPaused = false;

  _LifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      onResume();
    }
  }
}

class PermissionRequestHelper {
  static bool _permissionFlowRunning = false;

  static Future<bool> request({
    required BuildContext context,
    required PermissionService service,
    required AppPermissionType type,
    Future<void> Function()? onGranted,
  }) async {
    // Phase 5: Prevent concurrent permission requests
    if (_permissionFlowRunning) {
      return false;
    }
    _permissionFlowRunning = true;

    // Execution guard to ensure callback runs exactly once
    bool onGrantedExecuted = false;
    Future<void> safeExecuteCallback() async {
      if (onGrantedExecuted) return;
      onGrantedExecuted = true;
      if (onGranted != null) {
        // Wait a microtask to allow any pending UI transitions to schedule
        await Future.delayed(Duration.zero);
        // Mounted Safety
        if (context.mounted) {
          await onGranted();
        }
      }
    }

    Future<PermissionResult> runCheck() {
      switch (type) {
        case AppPermissionType.camera:
          return service.checkCameraPermission();
        case AppPermissionType.gallery:
          return service.checkGalleryPermission();
        case AppPermissionType.microphone:
          return service.checkMicrophonePermission();
      }
    }

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

    try {
      // 1. Initial Status Check (checks status without prompting)
      final initialCheck = await runCheck();

      // Already Granted
      if (initialCheck.isGranted) {
        await safeExecuteCallback();
        return true;
      }

      // 2. Permanently Denied Check
      if (initialCheck.shouldOpenSettings) {
        if (!context.mounted) return false;
        final openSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => PermissionDialog(type: type, isPermanentlyDenied: true),
        );

        if (openSettings == true) {
          final completer = Completer<void>();
          final observer = _LifecycleObserver(onResume: () {
            if (!completer.isCompleted) completer.complete();
          });
          WidgetsBinding.instance.addObserver(observer);

          try {
            await service.openSettings();
            await completer.future;
          } finally {
            WidgetsBinding.instance.removeObserver(observer);
          }

          final afterSettingsCheck = await runCheck();
          if (afterSettingsCheck.isGranted) {
            if (context.mounted) {
              await safeExecuteCallback();
              return true;
            }
          }
        }
        return false;
      }

      // 3. Denied / First Time Check (Requestable)
      // Do NOT show a custom explanation dialog. Immediately request permission.
      final result = await runRequest();
      if (result.isGranted) {
        if (context.mounted) {
          await safeExecuteCallback();
          return true;
        }
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('PermissionRequestHelper: Exception occurred: $e\n$stackTrace');
      return false;
    } finally {
      _permissionFlowRunning = false;
    }
  }
}
