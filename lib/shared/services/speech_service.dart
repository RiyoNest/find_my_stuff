import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;

  Future<bool> initialize({
    required Function(String status) onStatus,
    required Function(dynamic error) onError,
  }) async {
    if (_isInitialized) {
      return _speech.isAvailable;
    }
    try {
      final available = await _speech.initialize(
        onStatus: onStatus,
        onError: onError,
      );
      _isInitialized = available;
      return available;
    } catch (e) {
      debugPrint('SpeechService initialize error: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> listen({
    required Function(dynamic result) onResult,
    required Function(dynamic error) onError,
    required Function(String status) onStatus,
    String? localeId,
  }) async {
    final hasInit = await initialize(onStatus: onStatus, onError: onError);
    if (!hasInit) {
      throw Exception('Speech recognition is not available');
    }

    if (_speech.isListening) {
      return;
    }

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.search,
        localeId: localeId,
      ),
      onResult: onResult,
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  void dispose() {
    _speech.cancel();
  }
}
