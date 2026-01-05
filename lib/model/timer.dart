import 'dart:async' as async;
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
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
  static const defaultDisplay = TimerDisplay(
    elapsedTime: Duration.zero,
    prepareIntervalSeconds: 5,
    workIntervalSeconds: 30,
    restIntervalSeconds: 5,
    rounds: 8,
  );
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
  }

  void _tick() {
    state = state.copyWith(elapsedTime: _stopWatch.elapsed);
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

    return defaultDisplay;
  }
}

String formatSeconds(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final minutesStr = minutes.toString().padLeft(2, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');
  return '$minutesStr:$secondsStr';
}
