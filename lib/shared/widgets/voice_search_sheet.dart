import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:find_my_stuff/shared/models/speech_state.dart';
import 'package:find_my_stuff/shared/providers/speech_provider.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class VoiceSearchSheet extends ConsumerStatefulWidget {
  const VoiceSearchSheet({super.key});

  @override
  ConsumerState<VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

class _VoiceSearchSheetState extends ConsumerState<VoiceSearchSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Reset speech state and start listening automatically on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speechProvider.notifier).reset();
      _startListeningFlow();
    });
  }

  void _startListeningFlow() {
    ref.read(speechProvider.notifier).startListening(context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speechState = ref.watch(speechProvider);

    // Start or stop pulse animation based on listening status
    if (speechState.status == SpeechStatus.listening) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
    }

    // React to completion to pop the sheet with result
    ref.listen<SpeechState>(speechProvider, (previous, next) {
      if (next.status == SpeechStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            Navigator.of(context).pop(next.recognizedText);
          }
        });
      }
    });

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Guarantee listening stops/cancels when sheet is dismissed
          ref.read(speechProvider.notifier).cancelListening();
        }
      },
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacingM,
            vertical: context.spacingL,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.radiusL),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Status
              Text(
                _getStatusText(speechState.status),
                style: context.titleStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // Core Visualizer Area
              Container(
                height: 160,
                alignment: Alignment.center,
                child: _buildCentralWidget(speechState, theme),
              ),
              const SizedBox(height: 24),

              // Dynamic Transcript Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: const BoxConstraints(minHeight: 60),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(context.radiusM),
                ),
                child: Center(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _getTranscriptText(speechState),
                      style: context.bodyStyle.copyWith(
                        fontStyle: speechState.partialText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: speechState.partialText.isEmpty
                            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buttons action bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(speechProvider.notifier).cancelListening();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel'),
                  ),
                  if (speechState.status == SpeechStatus.error)
                    FilledButton.icon(
                      onPressed: _startListeningFlow,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: speechState.status == SpeechStatus.listening
                          ? () => ref.read(speechProvider.notifier).stopListening()
                          : null,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(SpeechStatus status) {
    switch (status) {
      case SpeechStatus.idle:
        return 'Idle';
      case SpeechStatus.requestingPermission:
        return 'Requesting Microphone Access...';
      case SpeechStatus.initializing:
        return 'Connecting...';
      case SpeechStatus.listening:
        return 'Listening...';
      case SpeechStatus.processing:
        return 'Processing Speech...';
      case SpeechStatus.completed:
        return 'Search Complete';
      case SpeechStatus.cancelled:
        return 'Cancelled';
      case SpeechStatus.error:
        return 'Speech Error';
    }
  }

  String _getTranscriptText(SpeechState state) {
    if (state.status == SpeechStatus.initializing) {
      return 'Get ready to speak...';
    }
    if (state.status == SpeechStatus.listening) {
      return state.partialText.isNotEmpty ? state.partialText : 'Speak now...';
    }
    if (state.status == SpeechStatus.processing || state.status == SpeechStatus.completed) {
      return state.recognizedText.isNotEmpty ? state.recognizedText : 'Analyzing transcript...';
    }
    if (state.status == SpeechStatus.error) {
      return state.errorMessage ?? 'Speech could not be recognized.';
    }
    return 'Listening...';
  }

  Widget _buildCentralWidget(SpeechState state, ThemeData theme) {
    if (state.status == SpeechStatus.initializing ||
        state.status == SpeechStatus.requestingPermission) {
      return const CircularProgressIndicator();
    }

    if (state.status == SpeechStatus.processing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Analyzing voice input...',
            style: context.bodySmallStyle.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (state.status == SpeechStatus.completed) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.withValues(alpha: 0.15),
        ),
        padding: const EdgeInsets.all(24),
        child: const CircleAvatar(
          radius: 36,
          backgroundColor: Colors.green,
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      );
    }

    if (state.status == SpeechStatus.error) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.error.withValues(alpha: 0.15),
        ),
        padding: const EdgeInsets.all(24),
        child: CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.error,
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      );
    }

    // Default: listening pulse animation
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(
              alpha: 0.05 + (_animationController.value * 0.15),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(
                alpha: 0.1 + (_animationController.value * 0.2),
            ),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        );
      },
    );
  }
}
