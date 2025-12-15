import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

part 'workout.freezed.dart';
part 'workout.g.dart';

final workoutListProvider = Provider((_) async {
  final directory = await getApplicationDocumentsDirectory();
  final filename = '${directory.path}/workouts.json';
  return WorkoutList(filename: filename);
});

final class WorkoutList {
  final String filename;
  final workouts = <Workout>[];

  WorkoutList({required this.filename}) {
    final file = File(filename);
    if (!file.existsSync()) {
      return;
    }
    final json = file.readAsStringSync();
    final storedWorkouts = (jsonDecode(json) as List)
        .map((e) => Workout.fromJson(e))
        .toList();
    workouts.addAll(storedWorkouts);
  }

  void add(Workout workout) {
    // New items go to the front of the list.
    workouts.insert(0, workout);

    // Save updated list to disk.
    final file = File(filename)..createSync();
    final json = jsonEncode(workouts);
    file.writeAsStringSync(json);
  }
}

@freezed
abstract class Exercise with _$Exercise {
  const factory Exercise({required String name}) = _Exercise;

  factory Exercise.fromJson(Map<String, Object?> json) =>
      _$ExerciseFromJson(json);
}

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
