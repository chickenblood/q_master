import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timer.freezed.dart';
part 'timer.g.dart';

enum TimerState { preparing, working, resting }

enum ExecutionState { playing, paused }

@riverpod
final class Timer extends _$Timer {
  void reset() {
    state = build();
  }

  @override
  TimerDisplay build() {
    return TimerDisplay(
      prepareSeconds: 5,
      expiredSeconds: 0,
      restSeconds: 15,
      roundsLeft: 0,
      cyclesLeft: 0,
    );
  }
}

@freezed
abstract class TimerDisplay with _$TimerDisplay {
  const factory TimerDisplay({
    required int prepareSeconds,
    required int expiredSeconds,
    required int restSeconds,
    required int roundsLeft,
    required int cyclesLeft,
  }) = _TimerDisplay;
}
