import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout.freezed.dart';
part 'workout.g.dart';

/// Model class representing a workout.
@freezed
abstract class Workout with _$Workout {
  const factory Workout({
    required String name,
    required DateTime date,
    required List<Exercise> warmup,
    required List<Exercise> thang,
    required List<Exercise> mary,
  }) = _Workout;

  factory Workout.fromJson(Map<String, Object?> json) =>
      _$WorkoutFromJson(json);
}

/// Model class representing a specific exercise within a workout.
@freezed
abstract class Exercise with _$Exercise {
  const factory Exercise({required String name}) = _Exercise;

  factory Exercise.fromJson(Map<String, Object?> json) =>
      _$ExerciseFromJson(json);
}
