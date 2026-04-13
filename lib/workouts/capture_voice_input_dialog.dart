import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../l10n/l10n.dart';
import '../ui/adaptive_icons.dart';

const _maxRecordDuration = Duration(minutes: 2);
const _waveformBarCount = 28;
const _waveformMinLevel = 0.12;

final class CaptureVoiceInputDialog extends StatefulWidget {
  const CaptureVoiceInputDialog({super.key});

  @override
  State<CaptureVoiceInputDialog> createState() =>
      _CaptureVoiceInputDialogState();
}

final class _CaptureVoiceInputDialogState
    extends State<CaptureVoiceInputDialog> {
  final _speechToText = SpeechToText();
  final _soundLevels = List<double>.filled(
    _waveformBarCount,
    _waveformMinLevel,
  );

  var _speechReady = false;
  var _isBusy = false;
  var _isFinishing = false;
  var _isListening = false;
  String? _recognizedText;
  Duration _elapsed = Duration.zero;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ready = await _speechToText.initialize(onStatus: _handleSpeechStatus);
    if (!mounted) return;
    setState(() => _speechReady = ready);
    await _startListeningOnOpen();
  }

  void _handleSpeechStatus(String status) {
    if (!mounted || _isFinishing) return;

    if (status == SpeechToText.listeningStatus) {
      _startElapsedTimer();
      setState(() => _isListening = true);
      return;
    }

    if (status != SpeechToText.notListeningStatus &&
        status != SpeechToText.doneStatus) {
      return;
    }

    final shouldFinish = _isListening;
    _stopElapsedTimer();
    _resetWaveform();
    setState(() => _isListening = false);

    if (shouldFinish) {
      unawaited(_finishAndClose());
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _startListeningOnOpen() async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      _recognizedText = null;
      _elapsed = Duration.zero;
      _resetWaveform();

      if (!_speechReady) return;

      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _recognizedText = result.recognizedWords);
        },
        onSoundLevelChange: _handleSoundLevelChange,
        listenFor: _maxRecordDuration,
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _handleSoundLevelChange(double level) {
    if (!mounted) return;

    final visualLevel = _normalizeSoundLevel(level);
    setState(() {
      _soundLevels.removeAt(0);
      _soundLevels.add(visualLevel);
    });
  }

  double _normalizeSoundLevel(double level) {
    final shiftedLevel = level < 0 ? level + 60 : level;
    final clampedLevel = shiftedLevel.clamp(0.0, 60.0).toDouble();
    return _waveformMinLevel + (clampedLevel / 60.0) * (1 - _waveformMinLevel);
  }

  void _resetWaveform() {
    for (var index = 0; index < _soundLevels.length; index += 1) {
      _soundLevels[index] = _waveformMinLevel;
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed += const Duration(milliseconds: 200);
      });
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  Future<void> _cancelAndClose() async {
    if (_isFinishing) return;

    _isFinishing = true;
    _stopElapsedTimer();
    await _speechToText.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(null);
  }

  Future<void> _finishAndClose() async {
    if (_isBusy || _isFinishing) return;

    _isFinishing = true;
    setState(() => _isBusy = true);
    try {
      _stopElapsedTimer();
      await _speechToText.stop();

      final transcript = _recognizedText?.trim();
      if (!mounted) return;
      Navigator.of(context).pop(transcript);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return PlatformScaffold(
      appBar: PlatformAppBar(
        cupertino: (appBarContext, _) => CupertinoNavigationBarData(
          backgroundColor: Colors.transparent,
          leading: PlatformIconButton(
            padding: const EdgeInsets.only(right: 22),
            icon: Icon(AdaptiveIcons.close),
            onPressed: _cancelAndClose,
          ),
          title: PlatformText(l10n.captureVoiceInputPrompt),
        ),
        material: (appBarContext, _) => MaterialAppBarData(
          leading: PlatformIconButton(
            icon: Icon(AdaptiveIcons.close),
            onPressed: _cancelAndClose,
          ),
          title: PlatformText(l10n.captureVoiceInputPrompt),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Hero(
                tag: 'voiceInputButton',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _SpeechWaveform(
                      levels: _soundLevels,
                      elapsed: _elapsed,
                      maxDuration: _maxRecordDuration,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isListening || _isBusy)
                PlatformText(l10n.captureVoiceInputRecordingHint),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: PlatformText(
                    (_recognizedText == null || _recognizedText!.isEmpty)
                        ? (_speechReady
                              ? l10n.captureVoiceInputTranscriptPlaceholder
                              : l10n.captureVoiceInputSpeechUnavailable)
                        : _recognizedText!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SpeechWaveform extends StatelessWidget {
  const _SpeechWaveform({
    required this.levels,
    required this.elapsed,
    required this.maxDuration,
  });

  final List<double> levels;
  final Duration elapsed;
  final Duration maxDuration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final level in levels)
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      width: 4,
                      height: 20 + (76 * level),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          scheme.onSurface.withValues(alpha: 0.3),
                          scheme.error,
                          level,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PlatformText(_formatDuration(elapsed)),
            PlatformText(_formatDuration(maxDuration)),
          ],
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
