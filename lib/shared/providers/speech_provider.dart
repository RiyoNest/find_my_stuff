import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:find_my_stuff/shared/models/speech_state.dart';
import 'package:find_my_stuff/shared/services/speech_service.dart';
import 'package:find_my_stuff/shared/services/permission_service.dart';
import 'package:find_my_stuff/shared/widgets/permission_dialog.dart';
import 'package:find_my_stuff/shared/providers/permission_provider.dart';
import 'package:flutter/foundation.dart';

class SpeechNotifier extends StateNotifier<SpeechState> {
  final SpeechService _service;
  final PermissionService _permissionService;

  SpeechNotifier(this._service, this._permissionService)
      : super(const SpeechState(status: SpeechStatus.idle));

  Future<void> startListening(
    BuildContext context, {
    String? localeId,
  }) async {
    // Prevent duplicate listening sessions
    if (state.status == SpeechStatus.listening || state.status == SpeechStatus.initializing) {
      if (kDebugMode) {
        debugPrint('SpeechNotifier: startListening called while already listening/initializing');
      }
      return;
    }

    state = state.copyWith(status: SpeechStatus.requestingPermission);
    if (kDebugMode) {
      debugPrint('SpeechNotifier: Checking microphone permission');
    }

    final granted = await PermissionRequestHelper.request(
      context: context,
      service: _permissionService,
      type: AppPermissionType.microphone,
    );

    if (!granted) {
      state = state.copyWith(
        status: SpeechStatus.error,
        errorMessage: 'Microphone permission is required.',
        permissionGranted: false,
      );
      return;
    }

    state = state.copyWith(
      status: SpeechStatus.initializing,
      permissionGranted: true,
      errorMessage: null,
      recognizedText: '',
      partialText: '',
    );
    if (kDebugMode) {
      debugPrint('SpeechNotifier: Initializing speech engine');
    }

    try {
      final hasInit = await _service.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );

      if (!hasInit) {
        state = state.copyWith(
          status: SpeechStatus.error,
          errorMessage: 'Speech recognition engine is unavailable.',
        );
        return;
      }

      state = state.copyWith(status: SpeechStatus.listening);
      if (kDebugMode) {
        debugPrint('SpeechNotifier: Listening started');
      }

      await _service.listen(
        localeId: localeId ?? "en_IN",
        onResult: (result) {
          final words = (result.recognizedWords as String).trim();
          final isFinal = result.finalResult as bool;
          
          if (kDebugMode) {
            debugPrint('SpeechNotifier: Result words = "$words", isFinal = $isFinal');
          }

          if (isFinal) {
            if (words.isNotEmpty) {
              state = state.copyWith(
                status: SpeechStatus.completed,
                recognizedText: words,
                partialText: words,
              );
              if (kDebugMode) {
                debugPrint('SpeechNotifier: Completed with final text = "$words"');
              }
            } else {
              state = state.copyWith(status: SpeechStatus.idle);
            }
          } else {
            state = state.copyWith(
              status: SpeechStatus.listening,
              partialText: words,
            );
          }
        },
        onError: _handleError,
        onStatus: _handleStatus,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SpeechNotifier: startListening exception = $e');
      }
      state = state.copyWith(
        status: SpeechStatus.error,
        errorMessage: 'Error initializing speech service: $e',
      );
    }
  }

  void _handleStatus(String status) {
    if (kDebugMode) {
      debugPrint('SpeechNotifier status callback: $status');
    }
    if (status == 'done' || status == 'notListening') {
      if (state.status == SpeechStatus.listening) {
        state = state.copyWith(status: SpeechStatus.processing);
        // Add a small delay to finalize state transition
        Future.delayed(const Duration(milliseconds: 300), () {
          if (state.status == SpeechStatus.processing) {
            final finalWords = state.partialText;
            if (finalWords.isNotEmpty) {
              state = state.copyWith(
                status: SpeechStatus.completed,
                recognizedText: finalWords,
              );
            } else {
              state = state.copyWith(status: SpeechStatus.idle);
            }
          }
        });
      }
    }
  }

  void _handleError(dynamic error) {
    if (kDebugMode) {
      debugPrint('SpeechNotifier error callback: $error');
    }
    
    // Check if error is no match but we have partial text
    final String errorMsg = error.errorMsg ?? '';
    if (errorMsg == 'error_no_match' && state.partialText.isNotEmpty) {
      state = state.copyWith(
        status: SpeechStatus.completed,
        recognizedText: state.partialText,
      );
      return;
    }

    state = state.copyWith(
      status: SpeechStatus.error,
      errorMessage: errorMsg.isNotEmpty ? errorMsg : 'Speech recognition failed.',
    );
  }

  Future<void> stopListening() async {
    if (kDebugMode) {
      debugPrint('SpeechNotifier: Stopping listening');
    }
    await _service.stop();
    if (state.status == SpeechStatus.listening) {
      state = state.copyWith(status: SpeechStatus.processing);
    }
  }

  Future<void> cancelListening() async {
    if (kDebugMode) {
      debugPrint('SpeechNotifier: Cancelling listening');
    }
    await _service.cancel();
    state = state.copyWith(status: SpeechStatus.cancelled);
  }

  void reset() {
    state = const SpeechState(status: SpeechStatus.idle);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

final speechProvider = StateNotifierProvider<SpeechNotifier, SpeechState>((ref) {
  final service = ref.watch(speechServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  return SpeechNotifier(service, permissionService);
});
