enum SpeechStatus {
  idle,
  requestingPermission,
  initializing,
  listening,
  processing,
  completed,
  cancelled,
  error,
}

class SpeechState {
  final SpeechStatus status;
  final String recognizedText;
  final String partialText;
  final String? errorMessage;
  final bool permissionGranted;

  const SpeechState({
    required this.status,
    this.recognizedText = '',
    this.partialText = '',
    this.errorMessage,
    this.permissionGranted = false,
  });

  SpeechState copyWith({
    SpeechStatus? status,
    String? recognizedText,
    String? partialText,
    String? errorMessage,
    bool? permissionGranted,
  }) {
    return SpeechState(
      status: status ?? this.status,
      recognizedText: recognizedText ?? this.recognizedText,
      partialText: partialText ?? this.partialText,
      errorMessage: errorMessage ?? this.errorMessage,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}
