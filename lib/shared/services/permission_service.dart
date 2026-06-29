import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:find_my_stuff/shared/models/permission_result.dart';

class PermissionService {
  final Map<ph.Permission, bool> _requestingMap = {};

  Future<PermissionResult> requestCameraPermission() async {
    return _requestPermission(ph.Permission.camera, 'Camera');
  }

  Future<PermissionResult> requestGalleryPermission() async {
    final results = await [
      ph.Permission.photos,
      ph.Permission.storage,
    ].request();

    final photosStatus = results[ph.Permission.photos] ?? ph.PermissionStatus.denied;
    final storageStatus = results[ph.Permission.storage] ?? ph.PermissionStatus.denied;

    final granted = photosStatus.isGranted ||
        photosStatus.isLimited ||
        storageStatus.isGranted ||
        storageStatus.isLimited;

    final permanentlyDenied = photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied;

    return PermissionResult(
      state: granted
          ? PermissionState.granted
          : (permanentlyDenied ? PermissionState.permanentlyDenied : PermissionState.denied),
      isGranted: granted,
      shouldOpenSettings: permanentlyDenied,
      message: 'Gallery permission request completed.',
    );
  }

  Future<PermissionResult> requestMicrophonePermission() async {
    return _requestPermission(ph.Permission.microphone, 'Microphone');
  }

  Future<PermissionResult> checkCameraPermission() async {
    return _checkPermission(ph.Permission.camera, 'Camera');
  }

  Future<PermissionResult> checkGalleryPermission() async {
    final photosStatus = await ph.Permission.photos.status;
    final storageStatus = await ph.Permission.storage.status;

    final granted = photosStatus.isGranted ||
        photosStatus.isLimited ||
        storageStatus.isGranted ||
        storageStatus.isLimited;

    final permanentlyDenied = photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied;

    return PermissionResult(
      state: granted
          ? PermissionState.granted
          : (permanentlyDenied ? PermissionState.permanentlyDenied : PermissionState.denied),
      isGranted: granted,
      shouldOpenSettings: permanentlyDenied,
      message: 'Gallery permission status checked.',
    );
  }

  Future<PermissionResult> checkMicrophonePermission() async {
    return _checkPermission(ph.Permission.microphone, 'Microphone');
  }

  Future<PermissionResult> _checkPermission(ph.Permission permission, String typeName) async {
    final status = await permission.status;
    final isGranted = status.isGranted || status.isLimited;
    final shouldOpenSettings = status.isPermanentlyDenied;
    return PermissionResult(
      state: _mapStatus(status),
      isGranted: isGranted,
      shouldOpenSettings: shouldOpenSettings,
      message: '$typeName permission status is ${status.name}.',
    );
  }

  Future<void> openSettings() async {
    await ph.openAppSettings();
  }

  Future<PermissionResult> _requestPermission(ph.Permission permission, String typeName) async {
    if (_requestingMap[permission] == true) {
      return PermissionResult(
        state: PermissionState.denied,
        isGranted: false,
        shouldOpenSettings: false,
        message: 'Already requesting $typeName permission.',
      );
    }

    _requestingMap[permission] = true;
    try {
      final status = await permission.status;
      if (status.isGranted) {
        return PermissionResult(
          state: PermissionState.granted,
          isGranted: true,
          shouldOpenSettings: false,
          message: '$typeName permission is granted.',
        );
      }
      if (status.isLimited) {
        return PermissionResult(
          state: PermissionState.limited,
          isGranted: true,
          shouldOpenSettings: false,
          message: '$typeName permission is limited.',
        );
      }
      if (status.isRestricted) {
        return PermissionResult(
          state: PermissionState.restricted,
          isGranted: false,
          shouldOpenSettings: false,
          message: '$typeName permission is restricted.',
        );
      }
      if (status.isPermanentlyDenied) {
        return PermissionResult(
          state: PermissionState.permanentlyDenied,
          isGranted: false,
          shouldOpenSettings: true,
          message: '$typeName permission is permanently denied.',
        );
      }

      // If not granted/denied, request it
      final result = await permission.request();
      final isGranted = result.isGranted || result.isLimited;
      final shouldOpenSettings = result.isPermanentlyDenied;

      return PermissionResult(
        state: _mapStatus(result),
        isGranted: isGranted,
        shouldOpenSettings: shouldOpenSettings,
        message: isGranted
            ? '$typeName permission was granted.'
            : '$typeName permission was denied.',
      );
    } finally {
      _requestingMap[permission] = false;
    }
  }

  PermissionState _mapStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionState.granted;
      case ph.PermissionStatus.denied:
        return PermissionState.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionState.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionState.restricted;
      case ph.PermissionStatus.limited:
        return PermissionState.limited;
      case ph.PermissionStatus.provisional:
        return PermissionState.granted;
    }
  }
}
