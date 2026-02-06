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
  tabata;

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

  // Track last played sound to avoid replaying
  int _lastPrepareSecond = -1;
  int _lastWorkSecond = -1;
  int _lastRestSecond = -1;

  // Track countdown chimes per phase to ensure each plays only once
  int _lastPrepareCountdown = -1;
  int _lastWorkCountdown = -1;
  int _lastRestCountdown = -1;

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
    _lastPrepareSecond = -1;
    _lastWorkSecond = -1;
    _lastRestSecond = -1;
    _lastPrepareCountdown = -1;
    _lastWorkCountdown = -1;
    _lastRestCountdown = -1;
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

    // Play final chime at the end of each phase (when phase completes)
    if (totalStopWatchTime == state.prepareInterval &&
        _lastPrepareSecond != totalStopWatchTime.inSeconds) {
      _lastPrepareSecond = totalStopWatchTime.inSeconds;
      _playFinalChime();
    } else if (currentRoundElapsedSeconds == state.workInterval.inSeconds &&
        currentRoundElapsedSeconds > 0 &&
        _lastWorkSecond != currentSecond) {
      _lastWorkSecond = currentSecond;
      _playFinalChime();
    } else if (currentRoundElapsedSeconds == totalRoundTime.inSeconds &&
        currentRoundElapsedSeconds > 0 &&
        _lastRestSecond != currentSecond) {
      _lastRestSecond = currentSecond;
      _playFinalChime();
    }
    // Check if all rounds are completed
    final allRoundsCompleted =
        runningTime >= (totalRoundTime * state.rounds * state.cycles);
    if (allRoundsCompleted) {
      _stop();
      return;
    }

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

    // Play countdown chimes at exact times during the last 3 seconds of each phase
    final prepareEndSeconds = state.prepareInterval.inSeconds;
    if (currentSecond == prepareEndSeconds - 3 && _lastPrepareCountdown != 3) {
      await _countdownChimePlayer.seek(Duration(seconds: 0));
      await _countdownChimePlayer.play();
      _lastPrepareCountdown = 3;
    } else if (currentSecond == prepareEndSeconds - 2 &&
        _lastPrepareCountdown != 2) {
      await _countdownChimePlayer.seek(Duration(seconds: 1));
      await _countdownChimePlayer.play();
      _lastPrepareCountdown = 2;
    } else if (currentSecond == prepareEndSeconds - 1 &&
        _lastPrepareCountdown != 1) {
      await _countdownChimePlayer.seek(Duration(seconds: 2));
      await _countdownChimePlayer.play();
      _lastPrepareCountdown = 1;
    }

    final totalRoundSeconds = totalRoundTime.inSeconds;
    final completedRounds = runningTime.inSeconds ~/ totalRoundSeconds;
    final currentWorkEndSeconds =
        state.prepareInterval.inSeconds +
        completedRounds * totalRoundSeconds +
        state.workInterval.inSeconds;
    if (currentSecond == currentWorkEndSeconds - 3 && _lastWorkCountdown != 3) {
      await _countdownChimePlayer.seek(Duration(seconds: 0));
      await _countdownChimePlayer.play();
      _lastWorkCountdown = 3;
    } else if (currentSecond == currentWorkEndSeconds - 2 &&
        _lastWorkCountdown != 2) {
      await _countdownChimePlayer.seek(Duration(seconds: 1));
      await _countdownChimePlayer.play();
      _lastWorkCountdown = 2;
    } else if (currentSecond == currentWorkEndSeconds - 1 &&
        _lastWorkCountdown != 1) {
      await _countdownChimePlayer.seek(Duration(seconds: 2));
      await _countdownChimePlayer.play();
      _lastWorkCountdown = 1;
    }

    final currentRestEndSeconds =
        currentWorkEndSeconds + state.restInterval.inSeconds;
    if (currentSecond == currentRestEndSeconds - 3 && _lastRestCountdown != 3) {
      await _countdownChimePlayer.seek(Duration(seconds: 0));
      await _countdownChimePlayer.play();
      _lastRestCountdown = 3;
    } else if (currentSecond == currentRestEndSeconds - 2 &&
        _lastRestCountdown != 2) {
      await _countdownChimePlayer.seek(Duration(seconds: 1));
      await _countdownChimePlayer.play();
      _lastRestCountdown = 2;
    } else if (currentSecond == currentRestEndSeconds - 1 &&
        _lastRestCountdown != 1) {
      await _countdownChimePlayer.seek(Duration(seconds: 2));
      await _countdownChimePlayer.play();
      _lastRestCountdown = 1;
    }
  }

  Future<void> _playSound(AudioPlayer player) async {
    await player.seek(Duration.zero);
    player.play();
  }

  Future<void> _playFinalChime() async {
    await _countdownChimePlayer.seek(Duration(seconds: 3));
    await _countdownChimePlayer.play();
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
    ref
      // Needed on Android for some reason to ensure the timer keeps running
      // when the tab is not selected.
      ..keepAlive()
      ..onDispose(() {
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
