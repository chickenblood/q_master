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
    required int elapsedSeconds,
    required int prepareIntervalSeconds,
    required int workIntervalSeconds,
    required int restIntervalSeconds,
    required int rounds,
  }) = _TimerDisplay;
}

@riverpod
final class Timer extends _$Timer {
  static const defaultDisplay = TimerDisplay(
    elapsedSeconds: 0,
    prepareIntervalSeconds: 3,
    workIntervalSeconds: 60,
    restIntervalSeconds: 10,
    rounds: 8,
  );
  final _stopWatch = Stopwatch();

  void start() => _stopWatch.start();
  void pause() => _stopWatch.stop();

  void reset() {
    _stopWatch.stop();
    _stopWatch.reset();
  }

  void _tick() {
    state = state.copyWith(elapsedSeconds: _stopWatch.elapsed.inSeconds);
  }

  int get _runningTimeSeconds =>
      (state.elapsedSeconds - state.prepareIntervalSeconds).toInt();

  TimerState get timerState {
    if (state.elapsedSeconds < state.prepareIntervalSeconds) {
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

    final restElapsedSeconds =
        currentRoundElapsedSeconds - state.workIntervalSeconds;
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

  int get remainingPrepareSeconds =>
      max(state.prepareIntervalSeconds - state.elapsedSeconds, 0);

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
