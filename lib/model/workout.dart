import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

part 'workout.freezed.dart';
part 'workout.g.dart';

/// Provider for the WorkoutList
final workoutListProvider = FutureProvider((ref) async {
  final directory = await getApplicationDocumentsDirectory();
  final filename = '${directory.path}/workouts.json';
  return WorkoutList(filename: filename, onUpdate: ref.invalidateSelf);
});

final class WorkoutList {
  final String filename;
  final workouts = <Workout>[];
  final void Function() onUpdate;

  WorkoutList({required this.filename, required this.onUpdate}) {
    final file = File(filename);
    if (!file.existsSync()) {
      return;
    }
    final json = file.readAsStringSync();
    final newWorkouts = (jsonDecode(json) as List)
        .map((e) => Workout.fromJson(e))
        .toList();
    workouts.addAll(newWorkouts);
  }

  Future<void> _save({required List<Workout> updatedWorkouts}) async {
    final file = File(filename)..createSync();
    final json = jsonEncode(updatedWorkouts);
    file.writeAsStringSync(json);
    onUpdate();
  }

  void add(Workout workout) {
    final updatedWorkouts = workouts.toList();
    // New items go to the front of the list.
    updatedWorkouts.insert(0, workout);
    // Save updated list to disk.
    _save(updatedWorkouts: updatedWorkouts);
  }

  void remove(Workout workout) {
    final updatedWorkouts = workouts.toList();
    if (updatedWorkouts.remove(workout)) {
      _save(updatedWorkouts: updatedWorkouts);
    } else {
      debugPrint('Unable to remove workout');
    }
  }

  void replace(Workout existingWorkout, Workout newWorkout) {
    final index = workouts.indexOf(existingWorkout);
    assert(index != -1);
    if (index == -1) {
      debugPrint('Unable to replace workout');
      return;
    }
    final updatedWorkouts = workouts.toList();
    updatedWorkouts[index] = newWorkout;
    _save(updatedWorkouts: updatedWorkouts);
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
