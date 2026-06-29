enum PermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

class PermissionResult {
  final PermissionState state;
  final bool isGranted;
  final bool shouldOpenSettings;
  final String message;

  const PermissionResult({
    required this.state,
    required this.isGranted,
    required this.shouldOpenSettings,
    required this.message,
  });

  PermissionResult copyWith({
    PermissionState? state,
    bool? isGranted,
    bool? shouldOpenSettings,
    String? message,
  }) {
    return PermissionResult(
      state: state ?? this.state,
      isGranted: isGranted ?? this.isGranted,
      shouldOpenSettings: shouldOpenSettings ?? this.shouldOpenSettings,
      message: message ?? this.message,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PermissionResult &&
        other.state == state &&
        other.isGranted == isGranted &&
        other.shouldOpenSettings == shouldOpenSettings &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(state, isGranted, shouldOpenSettings, message);
}
