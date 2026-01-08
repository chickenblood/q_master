import 'dart:async' as async;
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:q_master/utils/shared_app_prefs.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timer.freezed.dart';
part 'timer.g.dart';

enum TimerState { preparing, working, resting }

enum ExecutionState { playing, paused }

@freezed
abstract class TimerDisplay with _$TimerDisplay {
  const factory TimerDisplay({
    required Duration elapsedTime,
    required int prepareIntervalSeconds,
    required int workIntervalSeconds,
    required int restIntervalSeconds,
    required int rounds,
  }) = _TimerDisplay;
}

@riverpod
final class Timer extends _$Timer {
  static const countdownDelaySeconds = 4;
  final _prepareSound = AudioPlayer()
    ..setAsset('assets/sounds/prepare.wav')
    ..setVolume(6.0);
  final _workSound = AudioPlayer()
    ..setAsset('assets/sounds/work.wav')
    ..setVolume(6.0);
  final _restSound = AudioPlayer()
    ..setAsset('assets/sounds/recover.wav')
    ..setVolume(6.0);
  final _chime1Sound = AudioPlayer()
    ..setAsset('assets/sounds/chime_1.wav')
    ..setVolume(6.0);
  final _chime2Sound = AudioPlayer()
    ..setAsset('assets/sounds/chime_2.wav')
    ..setVolume(6.0);
  final _stopWatch = Stopwatch();

  void start() {
    // Call tick to guarantee an immediate update, rather than waiting for up
    // to one second for the first timer tick.
    _tick();
    _stopWatch.start();
  }

  void pause() {
    _stopWatch.stop();
    // Update state one last time on pause.
    _tick();
  }

  void reset() {
    _stopWatch.stop();
    _stopWatch.reset();
    // Force a rebuild to re-read the prefs.
    ref.invalidateSelf();
  }

  void _tick() {
    state = state.copyWith(elapsedTime: _stopWatch.elapsed);

    if (!_stopWatch.isRunning) return;
    if (remainingRounds == 0) return;

    // Play sounds based on timer state transitions.
    final totalRoundSeconds =
        state.workIntervalSeconds + state.restIntervalSeconds;
    final currentRoundElapsedSeconds = _runningTimeSeconds % totalRoundSeconds;
    final preparationEnding =
        _stopWatch.elapsed.inSeconds >
            (state.prepareIntervalSeconds - countdownDelaySeconds) &&
        _stopWatch.elapsed.inSeconds < state.prepareIntervalSeconds;
    final workoutEnding =
        (currentRoundElapsedSeconds >
            (workIntervalSeconds - countdownDelaySeconds) &&
        (currentRoundElapsedSeconds <= workIntervalSeconds));
    final restEnding =
        currentRoundElapsedSeconds >
        (totalRoundSeconds - countdownDelaySeconds);

    if (_stopWatch.elapsed.inSeconds == 0) {
      _prepareSound.play().then((_) {
        _prepareSound.seek(Duration.zero);
        _prepareSound.pause();
      });
    }

    if (preparationEnding || workoutEnding || restEnding) {
      _chime1Sound.play().then((_) {
        _chime1Sound.seek(Duration.zero);
        _chime1Sound.pause();
      });
    }

    if (_stopWatch.elapsed.inSeconds < state.prepareIntervalSeconds) return;

    void playFinalChime() {
      _chime2Sound.play().then((_) {
        _chime2Sound.seek(Duration.zero);
        _chime2Sound.pause();
      });
    }

    if (currentRoundElapsedSeconds % totalRoundSeconds == 0) {
      _workSound.play().then((_) {
        _workSound.seek(Duration.zero);
        _workSound.pause();
      });
      playFinalChime();
    } else if (currentRoundElapsedSeconds == workIntervalSeconds) {
      _restSound.play().then((_) {
        _restSound.seek(Duration.zero);
        _restSound.pause();
      });
      playFinalChime();
    }
  }

  int get _runningTimeSeconds => max(
    0,
    state.elapsedTime.inSeconds - state.prepareIntervalSeconds,
  ).toInt();

  TimerState get timerState {
    if (state.elapsedTime.inSeconds < state.prepareIntervalSeconds) {
      return TimerState.preparing;
    }

    final totalRoundSeconds =
        state.workIntervalSeconds + state.restIntervalSeconds;
    final completedRounds = _runningTimeSeconds ~/ totalRoundSeconds;
    final currentRoundElapsedSeconds = _runningTimeSeconds % totalRoundSeconds;

    if (completedRounds >= state.rounds) {
      return TimerState.resting;
    }

    if (currentRoundElapsedSeconds < state.workIntervalSeconds) {
      return TimerState.working;
    } else {
      return TimerState.resting;
    }
  }

  ExecutionState get executionState =>
      _stopWatch.isRunning ? ExecutionState.playing : ExecutionState.paused;

  int get remainingRestSeconds {
    final totalRoundSeconds =
        state.workIntervalSeconds + state.restIntervalSeconds;
    final completedRounds = _runningTimeSeconds ~/ totalRoundSeconds;
    final currentRoundElapsedSeconds = _runningTimeSeconds % totalRoundSeconds;

    if (completedRounds >= state.rounds) {
      return 0;
    }

    final restElapsedSeconds = max(
      currentRoundElapsedSeconds - state.workIntervalSeconds,
      0,
    );
    return state.restIntervalSeconds - restElapsedSeconds;
  }

  int get remainingWorkSeconds {
    final totalRoundSeconds =
        state.workIntervalSeconds + state.restIntervalSeconds;
    final completedRounds = _runningTimeSeconds ~/ totalRoundSeconds;
    final currentRoundElapsedSeconds = _runningTimeSeconds % totalRoundSeconds;

    if (completedRounds >= state.rounds) {
      return 0;
    }

    return state.workIntervalSeconds - currentRoundElapsedSeconds;
  }

  int get workIntervalSeconds => state.workIntervalSeconds;

  int get elapsedSeconds => state.elapsedTime.inSeconds;

  int get remainingPrepareSeconds =>
      max(state.prepareIntervalSeconds - state.elapsedTime.inSeconds, 0);

  int get remainingRounds {
    final totalRoundSeconds =
        state.workIntervalSeconds + state.restIntervalSeconds;
    final completedRounds = _runningTimeSeconds ~/ totalRoundSeconds;

    return max(state.rounds - completedRounds, 0);
  }

  @override
  TimerDisplay build() {
    final timer = async.Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
    ref.onDispose(() {
      timer.cancel();
      _stopWatch.stop();
    });
    final prefs = SharedAppPrefs.instance;
    return TimerDisplay(
      elapsedTime: Duration.zero,
      prepareIntervalSeconds: prefs.prepareIntervalSeconds.value,
      workIntervalSeconds: prefs.workIntervalSeconds.value,
      restIntervalSeconds: prefs.restIntervalSeconds.value,
      rounds: prefs.rounds.value,
    );
  }
}

String formatSeconds(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final minutesStr = minutes.toString().padLeft(2, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');
  return '$minutesStr:$secondsStr';
}
