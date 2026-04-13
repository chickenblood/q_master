import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
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
  static SpeechToText? _speechToText;
  static final _logger = Logger();

  final _micBeepPlayer = AudioPlayer();
  final _soundLevels = List<double>.filled(
    _waveformBarCount,
    _waveformMinLevel,
    growable: true,
  );

  var _speechReady = false;
  var _isBusy = false;
  var _isFinishing = false;
  var _isListening = false;
  double _latestVisualLevel = _waveformMinLevel;
  String? _recognizedText;
  Timer? _waveformTicker;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _waveformTicker?.cancel();
    unawaited(_speechToText!.stop());
    unawaited(_micBeepPlayer.dispose());
    super.dispose();
  }

  Future<void> _initSpeech() async {
    await _prepareMicBeep();

    _speechToText ??= SpeechToText();
    final ready = await _speechToText!.initialize(
      onError: _handleSpeechError,
      onStatus: _handleSpeechStatus,
    );
    if (!mounted) return;
    setState(() => _speechReady = ready);
    await _startListeningOnOpen();
  }

  Future<void> _prepareMicBeep() async {
    await _micBeepPlayer.setAsset('assets/sounds/mic-beep.wav');
    await _micBeepPlayer.setVolume(6.0);
  }

  Future<void> _playMicBeep() async {
    try {
      await _micBeepPlayer.seek(Duration.zero);
      await _micBeepPlayer.play();
    } catch (_) {
      // Non-critical UX cue: ignore playback failures.
    }
  }

  void _handleSpeechStatus(String status) {
    _logger.i('Voice capture speech status changed: $status');

    if (!mounted || _isFinishing) return;

    if (status == SpeechToText.listeningStatus) {
      _startWaveformTicker();
      setState(() => _isListening = true);
      return;
    }

    if (status == SpeechToText.doneStatus) {
      _stopWaveformTicker();
      _resetWaveform();
      setState(() => _isListening = false);
      return;
    }

    if (status != SpeechToText.notListeningStatus) {
      return;
    }

    _stopWaveformTicker();
    _resetWaveform();
    setState(() => _isListening = false);
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    _logger.e(
      'Voice capture speech error: ${error.errorMsg} '
      '(permanent: ${error.permanent})',
    );

    if (!mounted || _isFinishing) return;

    _stopWaveformTicker();
    _resetWaveform();
    setState(() => _isListening = false);
  }

  Future<void> _startListeningOnOpen() async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      _recognizedText = null;
      _resetWaveform();

      if (!_speechReady) return;

      await _playMicBeep();
      if (!mounted || _isFinishing) return;

      await _speechToText!.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _recognizedText = result.recognizedWords);
        },
        onSoundLevelChange: _handleSoundLevelChange,
        listenFor: _maxRecordDuration,
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(
          listenMode: .dictation,
          onDevice: true,
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

    _latestVisualLevel = _normalizeSoundLevel(level);
  }

  void _startWaveformTicker() {
    _waveformTicker?.cancel();
    _waveformTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || !_isListening) return;

      final nextLevel = (_waveformMinLevel + (_latestVisualLevel * 0.92)).clamp(
        _waveformMinLevel,
        1.0,
      );
      _latestVisualLevel = nextLevel;

      setState(() {
        _soundLevels.removeAt(0);
        _soundLevels.add(nextLevel);
      });
    });
  }

  void _stopWaveformTicker() {
    _waveformTicker?.cancel();
    _waveformTicker = null;
    _latestVisualLevel = _waveformMinLevel;
  }

  double _normalizeSoundLevel(double level) {
    final shiftedLevel = level < 0 ? level + 60 : level;
    final clampedLevel = shiftedLevel.clamp(0.0, 60.0).toDouble();
    return _waveformMinLevel + (clampedLevel / 60.0) * (1 - _waveformMinLevel);
  }

  void _resetWaveform() {
    _latestVisualLevel = _waveformMinLevel;
    for (var index = 0; index < _soundLevels.length; index += 1) {
      _soundLevels[index] = _waveformMinLevel;
    }
  }

  Future<void> _cancelAndClose() async {
    if (_isFinishing) return;

    final shouldPlayStopBeep = _isListening || _isBusy;
    _isFinishing = true;
    _stopWaveformTicker();
    await _speechToText!.cancel();
    if (shouldPlayStopBeep) {
      await _playMicBeep();
    }
    if (!mounted) return;
    Navigator.of(context).pop(null);
  }

  Future<void> _finishAndClose() async {
    if (_isFinishing) return;

    _isFinishing = true;
    setState(() => _isBusy = true);
    try {
      _stopWaveformTicker();
      await _speechToText!.stop();
      await _playMicBeep();

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
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                            child: _SpeechWaveform(levels: _soundLevels),
                          ),
                        ),
                      ),
                      if (_isListening) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: PlatformElevatedButton(
                            onPressed: _isFinishing ? null : _finishAndClose,
                            child: PlatformText('Stop'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: PlatformText(
                    _recognizedText ?? '',
                    style: Theme.of(context).textTheme.displaySmall!,
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
  const _SpeechWaveform({required this.levels});

  final List<double> levels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latestLevel = levels.isEmpty ? _waveformMinLevel : levels.last;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final side = math.min(constraints.maxWidth, 220.0);
            return SizedBox.square(
              dimension: side,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
                ),
                child: CustomPaint(
                  painter: _RadialWaveformPainter(
                    levels: levels,
                    latestLevel: latestLevel,
                    baseColor: scheme.onSurface,
                    accentColor: scheme.error,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

final class _RadialWaveformPainter extends CustomPainter {
  const _RadialWaveformPainter({
    required this.levels,
    required this.latestLevel,
    required this.baseColor,
    required this.accentColor,
  });

  final List<double> levels;
  final double latestLevel;
  final Color baseColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;

    final center = size.center(Offset.zero);
    final shortestSide = math.min(size.width, size.height);
    final expansionFactor = (0.65 + (latestLevel * 0.75)).clamp(0.5, 1.35);
    final minRadius = shortestSide * 0.08;
    final maxRadius = shortestSide * 0.68 * expansionFactor;

    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color.lerp(
        baseColor,
        accentColor,
        latestLevel,
      )!.withValues(alpha: 0.35);
    canvas.drawCircle(center, minRadius + (latestLevel * 6), corePaint);

    final ringCount = levels.length;
    for (var index = 0; index < ringCount; index += 1) {
      final age = ringCount - 1 - index;
      final t = ringCount == 1 ? 0.0 : age / (ringCount - 1);
      final level = levels[index].clamp(_waveformMinLevel, 1.0);

      final radius = minRadius + ((maxRadius - minRadius) * t);
      final opacity = (0.08 + ((1 - t) * 0.7)).clamp(0.08, 0.8);

      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + (level * 2.0)
        ..color = Color.lerp(
          baseColor,
          accentColor,
          level,
        )!.withValues(alpha: opacity);

      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialWaveformPainter oldDelegate) {
    if (oldDelegate.levels.length != levels.length) return true;
    if (oldDelegate.latestLevel != latestLevel) return true;
    for (var index = 0; index < levels.length; index += 1) {
      if (oldDelegate.levels[index] != levels[index]) return true;
    }
    return false;
  }
}
