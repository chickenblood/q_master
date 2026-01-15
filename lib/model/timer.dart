import 'dart:async' as async;
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:q_master/utils/shared_app_prefs.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'timer.freezed.dart';
part 'timer.g.dart';

enum TimerType { stopwatch, tabata }

enum TimerState { preparing, working, resting }

enum ExecutionState { playing, paused }

@freezed
abstract class TimerDisplay with _$TimerDisplay {
  const factory TimerDisplay({
    required Duration elapsedTime,
    required TimerType timerType,
    required Duration prepareInterval,
    required Duration workInterval,
    required Duration restInterval,
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

  void _stop() {
    _stopWatch.stop();
    if (_countdownPlayer.playing) _countdownPlayer.pause();
    WakelockPlus.disable();
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
    final totalStopWatchSeconds = _stopWatch.elapsed.inSeconds;
    state = state.copyWith(elapsedTime: _stopWatch.elapsed);

    if (!_stopWatch.isRunning) return;
    if (state.timerType == .stopwatch && elapsedTime > Duration.zero) return;

    final runningTimeSeconds = _calculateElapsedTime();

    // Play sounds based on timer state transitions.
    final totalRoundTime = state.workInterval + state.restInterval;
    final currentRoundElapsedSeconds =
        runningTimeSeconds.inSeconds % totalRoundTime.inSeconds;

    var allRoundsCompleted = false;
    if (runningTimeSeconds.inSeconds >=
        state.rounds * totalRoundTime.inSeconds) {
      // Timer complete, no more sounds to play.
      allRoundsCompleted = true;
      _stop();
    }

    // Play "PREPARE" sound at the start of the timer.
    if (totalStopWatchSeconds == 0) {
      _prepareSound.play().then((_) {
        _prepareSound.seek(Duration.zero);
        _prepareSound.pause();
      });
    }

    // An index to start the countdown audio from, if applicable.
    int? countdownAudioIndex;
    if (!_countdownPlayer.playing) {
      if (totalStopWatchSeconds >
              (state.prepareInterval.inSeconds - countdownDelaySeconds) &&
          totalStopWatchSeconds < state.prepareInterval.inSeconds) {
        countdownAudioIndex =
            countdownDelaySeconds - remainingPrepareTime.inSeconds - 1;
      } else if (currentRoundElapsedSeconds >
              (state.workInterval.inSeconds - countdownDelaySeconds) &&
          currentRoundElapsedSeconds < state.workInterval.inSeconds) {
        countdownAudioIndex =
            countdownDelaySeconds - remainingWorkTime.inSeconds - 1;
      } else if (currentRoundElapsedSeconds >
              (totalRoundTime.inSeconds - countdownDelaySeconds) &&
          currentRoundElapsedSeconds < totalRoundTime.inSeconds) {
        countdownAudioIndex =
            countdownDelaySeconds - remainingRestTime.inSeconds - 1;
      }
    }

    if (countdownAudioIndex != null &&
        countdownAudioIndex >= 0 &&
        !allRoundsCompleted) {
      // Skip to the appropriate second in the countdown audio.
      await _countdownPlayer.seek(Duration(seconds: countdownAudioIndex));
      await _countdownPlayer.play();
      await _countdownPlayer.seek(Duration.zero);
      await _countdownPlayer.pause();
    }

    if (totalStopWatchSeconds < state.prepareInterval.inSeconds) return;
    if (allRoundsCompleted) return;

    if (currentRoundElapsedSeconds % totalRoundTime.inSeconds == 0) {
      _workSound.play().then((_) {
        _workSound.seek(Duration.zero);
        _workSound.pause();
      });
    } else if (currentRoundElapsedSeconds == workInterval.inSeconds) {
      _restSound.play().then((_) {
        _restSound.seek(Duration.zero);
        _restSound.pause();
      });
    }
  }

  TimerType get timerType => state.timerType;

  Duration _calculateElapsedTime() => state.elapsedTime > state.prepareInterval
      ? state.elapsedTime - state.prepareInterval
      : Duration.zero;

  TimerState get timerState {
    if (state.elapsedTime <= state.prepareInterval) {
      return TimerState.preparing;
    }

    final totalRoundSeconds = state.workInterval + state.restInterval;
    final runningTime = _calculateElapsedTime();
    final completedRounds = runningTime.inSeconds / totalRoundSeconds.inSeconds;
    final currentRoundElapsedSeconds =
        runningTime.inSeconds % totalRoundSeconds.inSeconds;

    if (completedRounds >= state.rounds) {
      return timerType == TimerType.tabata
          ? TimerState.resting
          : TimerState.working;
    }

    if (currentRoundElapsedSeconds <= state.workInterval.inSeconds) {
      return TimerState.working;
    } else {
      return timerType == TimerType.tabata
          ? TimerState.resting
          : TimerState.working;
    }
  }

  ExecutionState get executionState =>
      _stopWatch.isRunning ? ExecutionState.playing : ExecutionState.paused;

  Duration get remainingRestTime {
    final totalRoundSeconds = state.workInterval + state.restInterval;
    final runningTime = _calculateElapsedTime();
    final completedRounds = runningTime.inSeconds / totalRoundSeconds.inSeconds;
    final currentRoundElapsedSeconds = Duration(
      seconds: runningTime.inSeconds % totalRoundSeconds.inSeconds,
    );

    if (completedRounds >= state.rounds) {
      return Duration.zero;
    }

    final restElapsedTime = currentRoundElapsedSeconds > state.workInterval
        ? currentRoundElapsedSeconds - state.workInterval
        : Duration.zero;
    return state.restInterval - restElapsedTime;
  }

  Duration get remainingWorkTime {
    final totalRoundTime = state.workInterval + state.restInterval;
    final runningTime = _calculateElapsedTime();
    final completedRounds = runningTime.inSeconds / totalRoundTime.inSeconds;
    final currentRoundElapsedSeconds =
        runningTime.inSeconds % totalRoundTime.inSeconds;

    if (completedRounds >= state.rounds) {
      return Duration.zero;
    }

    return state.workInterval.inSeconds > currentRoundElapsedSeconds
        ? state.workInterval - Duration(seconds: currentRoundElapsedSeconds)
        : Duration.zero;
  }

  Duration get workInterval => state.workInterval;

  Duration get elapsedTime => _calculateElapsedTime();

  Duration get remainingPrepareTime => state.prepareInterval > state.elapsedTime
      ? state.prepareInterval - state.elapsedTime
      : Duration.zero;

  int get remainingRounds {
    final totalRoundSeconds = state.workInterval + state.restInterval;
    final completedRounds =
        _calculateElapsedTime().inSeconds / totalRoundSeconds.inSeconds;

    return max(state.rounds - completedRounds, 0).toInt();
  }

  @override
  TimerDisplay build() {
    final prefs = SharedAppPrefs.instance;
    final timer = async.Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => _tick(),
    );
    ref.onDispose(() {
      timer.cancel();
      _stopWatch.stop();
    });
    return TimerDisplay(
      elapsedTime: Duration.zero,
      timerType: TimerType.values[prefs.timerType.value],
      prepareInterval: Duration(seconds: prefs.prepareIntervalSeconds.value),
      workInterval: Duration(seconds: prefs.workIntervalSeconds.value),
      restInterval: Duration(seconds: prefs.restIntervalSeconds.value),
      rounds: prefs.rounds.value,
    );
  }
}
