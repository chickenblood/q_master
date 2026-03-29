// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout.freezed.dart';
part 'workout.g.dart';

/// Model class representing a workout.
@freezed
abstract class Workout with _$Workout {
  @JsonSerializable(explicitToJson: true)
  const factory Workout({
    required String name,
    required DateTime date,
    required List<WorkoutSection> sections,
  }) = _Workout;

  factory Workout.fromJson(Map<String, Object?> json) =>
      _$WorkoutFromJson(json);
}

/// An ordered section of a workout (e.g. warmup, thang, mary) with its exercises.
@freezed
abstract class WorkoutSection with _$WorkoutSection {
  const factory WorkoutSection({
    required String name,
    required List<String> exercises,
  }) = _WorkoutSection;

  factory WorkoutSection.fromJson(Map<String, Object?> json) =>
      _$WorkoutSectionFromJson(json);
}
