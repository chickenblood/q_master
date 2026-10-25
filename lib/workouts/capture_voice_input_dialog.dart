import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../l10n/l10n.dart';
import '../ui/action_button.dart';
import '../ui/adaptive_app_bar.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_scaffold.dart';
import '../utils/audio_session_coordinator.dart';

const _waveformBarCount = 14;
const _waveformMinLevel = 0.12;
const _minVisibleWaveformRings = 3;
const _maxRecordDuration = Duration(minutes: 2);
// iOS workaround: recognizer can briefly remain busy between sessions.
const _busyRetryDelay = Duration(milliseconds: 180);

enum _CaptureLifecycle { idle, starting, listening, finishing }

final class CaptureVoiceInputDialog extends StatefulWidget {
  const CaptureVoiceInputDialog({super.key});

  @override
  State<CaptureVoiceInputDialog> createState() =>
      _CaptureVoiceInputDialogState();
}

final class _CaptureVoiceInputDialogState
    extends State<CaptureVoiceInputDialog> {
  static final _logger = Logger();

  late final SpeechToText _speechToText;
  final _startCuePlayer = AudioPlayer();
  final _stopCuePlayer = AudioPlayer();
  final _soundLevels = List<double>.filled(
    _waveformBarCount,
    _waveformMinLevel,
    growable: true,
  );

  var _lifecycle = _CaptureLifecycle.idle;
  int _waveformPhase = 0;
  double _amplitudeLevel = _waveformMinLevel;
  String _recognizedText = '';
  Timer? _waveformTicker;

  bool get _isBusy => _lifecycle == .starting || _lifecycle == .finishing;
  bool get _isFinishing => _lifecycle == .finishing;
  bool get _isListening => _lifecycle == .listening;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _waveformTicker?.cancel();
    unawaited(_shutdownSpeechToText());
    unawaited(_startCuePlayer.dispose());
    unawaited(_stopCuePlayer.dispose());
    super.dispose();
  }

  Future<void> _shutdownSpeechToText() async {
    await _stopSpeechSafely();
  }

  Future<void> _stopSpeechSafely() async {
    try {
      await _speechToText.stop();
    } catch (error, stackTrace) {
      _logger.w(
        'Voice capture stop failed during shutdown: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _initSpeech() async {
    _speechToText = SpeechToText();
    await _prepareMicBeeps();

    final ready = await _speechToText.initialize(
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );
    if (!ready) {
      _logger.w(
        'Voice capture: speech recognition unavailable or not authorized',
      );
      return;
    }

    if (!mounted) return;
    await _startListening(resetTranscript: true, playStartBeep: true);
  }

  Future<void> _prepareMicBeeps() async {
    await _startCuePlayer.setAsset('assets/sounds/mic-beep-start.wav');
    await _startCuePlayer.setVolume(6.0);
    await _stopCuePlayer.setAsset('assets/sounds/mic-beep-end.wav');
    await _stopCuePlayer.setVolume(6.0);
  }

  Future<void> _playCue(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
      AudioSessionCoordinator.instance.markPlaybackStarted();
      try {
        await player.play();
      } finally {
        await AudioSessionCoordinator.instance.markPlaybackEnded();
      }
    } catch (_) {
      // Non-critical UX cue: ignore playback failures.
    }
  }

  Future<void> _handleSpeechResult(SpeechRecognitionResult result) async {
    if (!mounted) return;
    setState(() => _recognizedText = result.recognizedWords);
    if (result.finalResult) {
      _logger.i('Voice capture final transcript: "${result.recognizedWords}"');
      await _dismissOnRecordingStopped();
    } else {
      _logger.d(
        'Voice capture interim transcript: "${result.recognizedWords}"',
      );
    }
  }

  void _handleSpeechStatus(String status) {
    _logger.i('Voice capture speech status changed: $status');

    if (!mounted || _isFinishing) return;
    if (status == SpeechToText.listeningStatus && _lifecycle != .listening) {
      setState(() => _lifecycle = .listening);
      _startWaveformTicker();
      return;
    }

    if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      _resetRecordingState();
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    _logger.e(
      'Voice capture speech error: ${error.errorMsg} '
      '(permanent: ${error.permanent})',
    );

    if (!mounted || _isFinishing) return;

    unawaited(_dismissOnSpeechError());
  }

  void _handleSoundLevelChange(double level) {
    if (!mounted || _isFinishing) return;
    _amplitudeLevel = _normalizeSoundLevel(level);
  }

  void _resetRecordingState() {
    _stopWaveformTicker();
    _resetWaveform();
    _amplitudeLevel = _waveformMinLevel;
    setState(() => _lifecycle = .idle);
  }

  Future<void> _dismissOnRecordingStopped() async {
    if (_isFinishing) return;

    _lifecycle = .finishing;
    final transcript = _recognizedText.trim();
    await _stopSpeechSafely();
    await _playCue(_stopCuePlayer);
    if (!mounted) return;
    Navigator.of(context).pop(transcript.isEmpty ? null : transcript);
  }

  Future<void> _dismissOnSpeechError() async {
    if (_isFinishing) return;

    _lifecycle = .finishing;
    _stopWaveformTicker();
    await _stopSpeechSafely();
    if (!mounted) return;
    Navigator.of(context).pop(null);
  }

  Future<void> _startListening({
    required bool resetTranscript,
    required bool playStartBeep,
  }) async {
    if (_isBusy) return;

    _lifecycle = .starting;
    try {
      if (resetTranscript) {
        _recognizedText = '';
      }
      _resetWaveform();

      if (playStartBeep) {
        await _playCue(_startCuePlayer);
      }
      if (!mounted || _isFinishing) return;

      final started = await _listenWithBusyRetry();
      if (!started) return;

      if (!mounted || _isFinishing) return;
      setState(() => _lifecycle = .listening);
      _startWaveformTicker();
    } finally {
      if (_lifecycle == .starting) {
        _lifecycle = .idle;
      }
    }
  }

  Future<bool> _listenWithBusyRetry() async {
    try {
      await _speechToText.listen(
        onResult: _handleSpeechResult,
        onSoundLevelChange: _handleSoundLevelChange,
        listenOptions: SpeechListenOptions(
          listenFor: _maxRecordDuration,
          pauseFor: const Duration(seconds: 2),
        ),
      );
      return true;
    } on ListenFailedException catch (error, stackTrace) {
      final lowerMessage = (error.message ?? '').toLowerCase();
      final lowerDetails = (error.details ?? '').toLowerCase();
      final isBusy =
          lowerMessage.contains('busy') ||
          lowerMessage.contains('recognizer') ||
          lowerDetails.contains('busy') ||
          lowerDetails.contains('recognizer');
      if (!isBusy) {
        _logger.e(
          'Voice capture listen failed: ${error.message} (${error.details})',
          error: error,
          stackTrace: stackTrace,
        );
        return false;
      }

      _logger.w('Voice capture recognizer busy, retrying listen once.');
      // iOS workaround: force a stop and a short backoff before one retry.
      await _stopSpeechSafely();
      await Future<void>.delayed(_busyRetryDelay);

      try {
        await _speechToText.listen(
          onResult: _handleSpeechResult,
          onSoundLevelChange: _handleSoundLevelChange,
          listenOptions: SpeechListenOptions(
            listenFor: _maxRecordDuration,
            pauseFor: const Duration(seconds: 2),
          ),
        );
        return true;
      } on ListenFailedException catch (retryError, retryStackTrace) {
        _logger.e(
          'Voice capture retry failed: ${retryError.message} (${retryError.details})',
          error: retryError,
          stackTrace: retryStackTrace,
        );
        return false;
      }
    }
  }

  void _startWaveformTicker() {
    _waveformTicker?.cancel();
    _waveformPhase = 0;
    _waveformTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || !_isListening) return;

      _waveformPhase += 1;
      _amplitudeLevel = (_amplitudeLevel * 0.9).clamp(_waveformMinLevel, 1.0);
      final pulse = (0.22 + 0.12 * math.sin(_waveformPhase * 0.15)).clamp(
        _waveformMinLevel,
        1.0,
      );
      final level = math.max(pulse, _amplitudeLevel);
      setState(() {
        _soundLevels.removeAt(0);
        _soundLevels.add(level);
      });
    });
  }

  void _stopWaveformTicker() {
    _waveformTicker?.cancel();
    _waveformTicker = null;
    _waveformPhase = 0;
    _amplitudeLevel = _waveformMinLevel;
  }

  void _resetWaveform() {
    _waveformPhase = 0;
    _amplitudeLevel = _waveformMinLevel;
    for (var index = 0; index < _soundLevels.length; index += 1) {
      _soundLevels[index] = _waveformMinLevel;
    }
  }

  double _normalizeSoundLevel(double level) {
    final shiftedLevel = level < 0 ? level + 60 : level;
    final clampedLevel = shiftedLevel.clamp(0.0, 60.0).toDouble();
    return _waveformMinLevel + (clampedLevel / 60.0) * (1 - _waveformMinLevel);
  }

  Future<void> _cancelAndClose() async {
    if (_isFinishing) return;

    final shouldPlayStopBeep = _isListening || _isBusy;
    _lifecycle = .finishing;
    _stopWaveformTicker();
    await _stopSpeechSafely();
    if (shouldPlayStopBeep) {
      await _playCue(_stopCuePlayer);
    }
    if (!mounted) return;
    Navigator.of(context).pop(null);
  }

  Future<void> _finishAndClose() async {
    if (_isFinishing) return;

    _lifecycle = .finishing;
    _stopWaveformTicker();
    await _stopSpeechSafely();
    await _playCue(_stopCuePlayer);

    final transcript = _recognizedText.trim();
    if (!mounted) return;
    Navigator.of(context).pop(transcript);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: PlatformText(
          l10n.captureVoiceInputPrompt,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        leading: [
          AdaptiveAppBarItem(
            icon: Icon(AdaptiveIcons.close),
            onPressed: _cancelAndClose,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          //fit: StackFit.expand,
          children: [
            Hero(
              tag: 'voiceInputButton',
              child: _SpeechWaveform(levels: _soundLevels),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: PlatformText(
                _recognizedText,
                textAlign: .center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            if (_isListening)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ActionButton(
                  outlined: true,
                  label: l10n.captureVoiceInputStopButton,
                  onPressed: _isFinishing ? null : _finishAndClose,
                ),
              ),
          ],
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
      child: CustomPaint(
        painter: _RadialWaveformPainter(
          levels: levels,
          latestLevel: latestLevel,
          baseColor: scheme.onSurface,
          accentColor: scheme.error,
        ),
        child: const SizedBox.expand(),
      ),
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
    final minRadius = shortestSide * 0.05;
    final maxRadius = shortestSide * 0.78 * expansionFactor;

    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color.lerp(
        baseColor,
        accentColor,
        latestLevel,
      )!.withValues(alpha: 0.35);
    canvas.drawCircle(center, minRadius + (latestLevel * 6), corePaint);

    final ringCount = levels.length;
    final visibleRingCount =
        (_minVisibleWaveformRings +
                ((ringCount - _minVisibleWaveformRings) * latestLevel))
            .round()
            .clamp(_minVisibleWaveformRings, ringCount);
    final firstVisibleIndex = ringCount - visibleRingCount;

    for (var index = firstVisibleIndex; index < ringCount; index += 1) {
      final visibleIndex = index - firstVisibleIndex;
      final t = visibleRingCount == 1
          ? 0.0
          : visibleIndex / (visibleRingCount - 1);
      final level = levels[index].clamp(_waveformMinLevel, 1.0);

      final radius = minRadius + ((maxRadius - minRadius) * t * t);
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
    return oldDelegate.latestLevel != latestLevel ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor ||
        !listEquals(oldDelegate.levels, levels);
  }
}
