import 'dart:async' as async;
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../utils/shared_app_prefs.dart';

part 'timer.freezed.dart';
part 'timer.g.dart';

enum TimerType {
  stopwatch,
  tabata,
  countdown;

  static TimerType fromIndex(int index) => TimerType.values[index];
}

enum ExercisePhase { preparing, working, resting }

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
    required int cycles,
  }) = _TimerDisplay;
}

@riverpod
final class Timer extends _$Timer {
  final _prepareSound = AudioPlayer()
    ..setAsset('assets/sounds/prepare.m4a')
    ..setVolume(6.0);
  final _workSound = AudioPlayer()
    ..setAsset('assets/sounds/work.m4a')
    ..setVolume(6.0);
  final _restSound = AudioPlayer()
    ..setAsset('assets/sounds/recover.m4a')
    ..setVolume(6.0);
  final _countdownChimePlayer = AudioPlayer()
    ..setAsset('assets/sounds/countdown.m4a')
    ..setVolume(6.0);
  late final allChimePlayers = [_countdownChimePlayer];
  final _stopWatch = Stopwatch();

  // Track countdown chimes per phase to ensure each plays only once
  final _countdownTrackers = <ExercisePhase, int?>{};

  // Track phase start sounds
  int _lastPrepareStart = -1;
  int _lastWorkStart = -1;
  int _lastRestStart = -1;

  void start() {
    // Call tick to guarantee an immediate update, rather than waiting for up
    // to one second for the first timer tick.
    _tick();
    _stopWatch.start();
    // Keep the screen awake while the timer is running.
    WakelockPlus.enable();
  }

  void pause() {
    _stopWatch.stop();
    for (final player in allChimePlayers) {
      if (player.playing) player.pause();
    }
    // Allow the screen to sleep when the timer is paused.
    WakelockPlus.disable();

    // Update state one last time on pause.
    _tick();
  }

  void _stop() {
    _stopWatch.stop();
    for (final player in allChimePlayers) {
      if (player.playing) player.pause();
    }
    WakelockPlus.disable();
  }

  Future<void> _resetAudioPlayer(AudioPlayer player) async {
    await player.pause();
    await player.seek(Duration.zero);
  }

  Future<void> reset() async {
    _stopWatch.stop();
    _stopWatch.reset();
    _countdownTrackers.clear();
    _lastPrepareStart = -1;
    _lastWorkStart = -1;
    _lastRestStart = -1;

    await Future.wait([
      _resetAudioPlayer(_prepareSound),
      _resetAudioPlayer(_workSound),
      _resetAudioPlayer(_restSound),
      ...allChimePlayers.map(_resetAudioPlayer),
    ]);

    if (ref.mounted) {
      ref.invalidateSelf();
    }
  }

  Future<void> _tick() async {
    final totalStopWatchTime = _stopWatch.elapsed;
    state = state.copyWith(elapsedTime: totalStopWatchTime);

    if (!_stopWatch.isRunning) return;
    if (state.timerType == .stopwatch && elapsedTime > Duration.zero) return;

    final runningTime = calculateElapsedTime();
    final totalRoundTime = state.workInterval + state.restInterval;

    // Avoid division by zero
    if (totalRoundTime.inSeconds == 0) return;

    final currentRoundElapsedSeconds =
        runningTime.inSeconds % totalRoundTime.inSeconds;

    final currentSecond = totalStopWatchTime.inSeconds;

    // Check if all rounds are completed
    final allRoundsCompleted = switch (state.timerType) {
      // There is only one round for stopwatch and countdown timers,
      // so they are complete when the running time exceeds the work interval.
      .stopwatch || .countdown => runningTime > workInterval,
      .tabata => runningTime > (totalRoundTime * state.rounds * state.cycles),
    };

    if (!allRoundsCompleted) {
      // Play phase sounds at the start of each phase
      if (currentSecond == 0 && _lastPrepareStart != 0) {
        _lastPrepareStart = 0;
        await _playSound(_prepareSound);
      } else if (currentRoundElapsedSeconds == 0 &&
          runningTime > Duration.zero &&
          _lastWorkStart != currentSecond) {
        _lastWorkStart = currentSecond;
        await _playSound(_workSound);
      } else if (currentRoundElapsedSeconds == state.workInterval.inSeconds &&
          currentRoundElapsedSeconds > 0 &&
          _lastRestStart != currentSecond) {
        _lastRestStart = currentSecond;
        await _playSound(_restSound);
      }
    }

    // Play countdown chimes at exact times during the last 3 seconds of each phase
    final prepareRemaining = remainingPrepareTime.inSeconds;
    if (prepareRemaining > 0) {
      await _playCountdownChimes(ExercisePhase.preparing, prepareRemaining);
    } else {
      final workRemaining = remainingWorkTime.inSeconds;
      await _playCountdownChimes(ExercisePhase.working, workRemaining);

      final restRemaining = remainingRestTime.inSeconds;
      await _playCountdownChimes(ExercisePhase.resting, restRemaining);
    }
    if (allRoundsCompleted) _stop();
  }

  Future<void> _playSound(AudioPlayer player) async {
    await player.seek(Duration.zero);
    player.play();
  }

  /// Play countdown chimes (3, 2, 1) and final chime based on remaining time.
  /// Seeks to different positions in the countdown sound file for each chime.
  /// i values: 3=first chime, 2=second, 1=third, 0=final chime
  /// Works with remaining time in the current phase, so chimes play when 3, 2, 1, 0 seconds remain.
  Future<void> _playCountdownChimes(
    ExercisePhase phase,
    int remainingSeconds,
  ) async {
    for (int i = 3; i >= 0; i--) {
      if (remainingSeconds == i && _countdownTrackers[phase] != i) {
        // Seek positions: 0=first chime, 1=second, 2=third, 3=final chime
        await _countdownChimePlayer.seek(Duration(seconds: 3 - i));
        await _countdownChimePlayer.play();
        _countdownTrackers[phase] = i;
      }
    }
  }

  TimerType get timerType => state.timerType;

  Duration calculateElapsedTime() => state.elapsedTime > state.prepareInterval
      ? state.elapsedTime - state.prepareInterval
      : Duration.zero;

  ExercisePhase get timerState {
    if (state.elapsedTime <= state.prepareInterval) {
      return ExercisePhase.preparing;
    }

    final totalRoundSeconds = state.workInterval + state.restInterval;
    final runningTime = calculateElapsedTime();
    final completedRounds = runningTime.inSeconds / totalRoundSeconds.inSeconds;
    final currentRoundElapsedSeconds =
        runningTime.inSeconds % totalRoundSeconds.inSeconds;

    if (completedRounds >= (state.rounds * state.cycles)) {
      return timerType == TimerType.tabata
          ? ExercisePhase.resting
          : ExercisePhase.working;
    }

    if (currentRoundElapsedSeconds <= state.workInterval.inSeconds) {
      return ExercisePhase.working;
    } else {
      return timerType == TimerType.tabata
          ? ExercisePhase.resting
          : ExercisePhase.working;
    }
  }

  ExecutionState get executionState =>
      _stopWatch.isRunning ? ExecutionState.playing : ExecutionState.paused;

  Duration get remainingRestTime {
    final totalRoundSeconds = state.workInterval + state.restInterval;
    final runningTime = calculateElapsedTime();
    final completedRounds = runningTime.inSeconds / totalRoundSeconds.inSeconds;
    final currentRoundElapsedTime = Duration(
      seconds: runningTime.inSeconds % totalRoundSeconds.inSeconds,
    );

    if (completedRounds >= (state.rounds * state.cycles)) {
      return Duration.zero;
    }

    final restElapsedTime = currentRoundElapsedTime > state.workInterval
        ? currentRoundElapsedTime - state.workInterval
        : Duration.zero;
    return state.restInterval - restElapsedTime;
  }

  Duration get remainingWorkTime {
    final totalRoundTime = state.workInterval + state.restInterval;
    final runningTime = calculateElapsedTime();
    final completedRounds = runningTime.inSeconds / totalRoundTime.inSeconds;
    final currentRoundElapsedSeconds =
        runningTime.inSeconds % totalRoundTime.inSeconds;

    if (completedRounds >= (state.rounds * state.cycles)) {
      return Duration.zero;
    }

    return state.workInterval.inSeconds > currentRoundElapsedSeconds
        ? state.workInterval - Duration(seconds: currentRoundElapsedSeconds)
        : Duration.zero;
  }

  Duration get workInterval => state.workInterval;

  Duration get elapsedTime => calculateElapsedTime();

  /// For countdown timer.
  Duration get remainingCountdownTime {
    var remaining = calculateElapsedTime();
    return workInterval > remaining ? workInterval - remaining : Duration.zero;
  }

  Duration get remainingPrepareTime => state.prepareInterval > state.elapsedTime
      ? state.prepareInterval - state.elapsedTime
      : Duration.zero;

  /// The number of rounds left in the current cycle.
  int get remainingRounds {
    final totalRoundTime = state.workInterval + state.restInterval;
    final completedRounds =
        calculateElapsedTime().inSeconds ~/ totalRoundTime.inSeconds;

    return max(state.rounds - completedRounds, 0).toInt();
  }

  int get remainingCycles {
    final totalRoundTime = state.workInterval + state.restInterval;
    final totalCycleTime = totalRoundTime * state.rounds;
    final completedCycles =
        calculateElapsedTime().inSeconds / totalCycleTime.inSeconds;

    return max(state.cycles - completedCycles, 0).toInt();
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
      cycles: prefs.cycles.value,
    );
  }
}
