import 'dart:async' as async;
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:q_master/utils/shared_app_prefs.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
    ..setAsset('assets/sounds/prepare.m4a')
    ..setVolume(6.0);
  final _workSound = AudioPlayer()
    ..setAsset('assets/sounds/work.m4a')
    ..setVolume(6.0);
  final _restSound = AudioPlayer()
    ..setAsset('assets/sounds/recover.m4a')
    ..setVolume(6.0);
  final _countdownPlayer = AudioPlayer()
    ..setAsset('assets/sounds/countdown.m4a')
    ..setVolume(6.0);
  final _stopWatch = Stopwatch();

  void start() {
    // Call tick to guarantee an immediate update, rather than waiting for up
    // to one second for the first timer tick.
    _tick();
    _stopWatch.start();
    if (_countdownPlayer.position > Duration.zero) _countdownPlayer.play();
    // Keep the screen awake while the timer is running.
    WakelockPlus.enable();
  }

  void pause() {
    _stopWatch.stop();
    if (_countdownPlayer.playing) _countdownPlayer.pause();
    // Allow the screen to sleep when the timer is paused.
    WakelockPlus.disable();

    // Update state one last time on pause.
    _tick();
  }

  Future<void> reset() async {
    _stopWatch.stop();
    _stopWatch.reset();
    await _workSound.seek(Duration.zero);
    await _workSound.pause();
    await _restSound.seek(Duration.zero);
    await _restSound.pause();
    await _prepareSound.seek(Duration.zero);
    await _prepareSound.pause();
    await _countdownPlayer.seek(Duration.zero);
    await _countdownPlayer.pause();
    // Force a rebuild to re-read the prefs.
    ref.invalidateSelf();
  }

  Future<void> _tick() async {
    final elapsedSeconds = _stopWatch.elapsed.inSeconds;
    state = state.copyWith(elapsedTime: Duration(seconds: elapsedSeconds));

    if (!_stopWatch.isRunning) return;
    if (remainingRounds == 0) return;
    final runningTimeSeconds = calculateRunningTime();

    // Play "PREPARE" sound at the start of the timer.
    if (elapsedSeconds == 0) {
      _prepareSound.play().then((_) {
        _prepareSound.seek(Duration.zero);
        _prepareSound.pause();
      });
    }

    // Play sounds based on timer state transitions.
    final totalRoundSeconds =
        state.workIntervalSeconds + state.restIntervalSeconds;
    final currentRoundElapsedSeconds = runningTimeSeconds % totalRoundSeconds;

    // An index to start the countdown audio from, if applicable.
    int? countdownAudioIndex;
    if (!_countdownPlayer.playing) {
      if (elapsedSeconds >
              (state.prepareIntervalSeconds - countdownDelaySeconds) &&
          elapsedSeconds < state.prepareIntervalSeconds) {
        countdownAudioIndex =
            countdownDelaySeconds - remainingPrepareSeconds - 1;
      } else if (currentRoundElapsedSeconds >
              (state.workIntervalSeconds - countdownDelaySeconds) &&
          currentRoundElapsedSeconds < state.workIntervalSeconds) {
        countdownAudioIndex = countdownDelaySeconds - remainingWorkSeconds - 1;
      } else if (currentRoundElapsedSeconds >
              (totalRoundSeconds - countdownDelaySeconds) &&
          currentRoundElapsedSeconds < totalRoundSeconds) {
        countdownAudioIndex = countdownDelaySeconds - remainingRestSeconds - 1;
      }
    }

    if (countdownAudioIndex != null && countdownAudioIndex >= 0) {
      // Skip to the appropriate second in the countdown audio.
      await _countdownPlayer.seek(Duration(seconds: countdownAudioIndex));
      await _countdownPlayer.play();
      await _countdownPlayer.seek(Duration.zero);
      await _countdownPlayer.pause();
    }

    if (elapsedSeconds < state.prepareIntervalSeconds) return;

    if (currentRoundElapsedSeconds % totalRoundSeconds == 0) {
      _workSound.play().then((_) {
        _workSound.seek(Duration.zero);
        _workSound.pause();
      });
    } else if (currentRoundElapsedSeconds == workIntervalSeconds) {
      _restSound.play().then((_) {
        _restSound.seek(Duration.zero);
        _restSound.pause();
      });
    }
  }

  int calculateRunningTime() => max(
    0,
    state.elapsedTime.inSeconds - state.prepareIntervalSeconds,
  ).toInt();

  TimerState get timerState {
    if (state.elapsedTime.inSeconds <= state.prepareIntervalSeconds) {
      return TimerState.preparing;
    }

    final totalRoundSeconds =
        state.workIntervalSeconds + state.restIntervalSeconds;
    final runningTimeSeconds = calculateRunningTime();
    final completedRounds = runningTimeSeconds / totalRoundSeconds;
    final currentRoundElapsedSeconds = runningTimeSeconds % totalRoundSeconds;

    if (completedRounds >= state.rounds) {
      return TimerState.resting;
    }

    if (currentRoundElapsedSeconds <= state.workIntervalSeconds) {
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
    final runningTimeSeconds = calculateRunningTime();
    final completedRounds = runningTimeSeconds / totalRoundSeconds;
    final currentRoundElapsedSeconds = runningTimeSeconds % totalRoundSeconds;

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
    final runningTimeSeconds = calculateRunningTime();
    final completedRounds = runningTimeSeconds / totalRoundSeconds;
    final currentRoundElapsedSeconds = runningTimeSeconds % totalRoundSeconds;

    if (completedRounds >= state.rounds) {
      return 0;
    }

    return max(
      state.workIntervalSeconds - currentRoundElapsedSeconds,
      0,
    ).toInt();
  }

  int get workIntervalSeconds => state.workIntervalSeconds;

  int get elapsedSeconds => state.elapsedTime.inSeconds;

  int get remainingPrepareSeconds =>
      max(state.prepareIntervalSeconds - state.elapsedTime.inSeconds, 0);

  int get remainingRounds {
    final totalRoundSeconds =
        state.workIntervalSeconds + state.restIntervalSeconds;
    final completedRounds = calculateRunningTime() / totalRoundSeconds;

    return max(state.rounds - completedRounds, 0).toInt();
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
