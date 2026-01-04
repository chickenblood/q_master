import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'workout.dart';

part 'workout_list.g.dart';

@riverpod
final class WorkoutList extends _$WorkoutList {
  String? _filename;

  @override
  List<Workout> build() {
    getApplicationDocumentsDirectory().then((directory) {
      _filename = '${directory.path}/workouts.json';
      final file = File(_filename!);
      if (!file.existsSync()) {
        return;
      }
      final json = file.readAsStringSync();
      final newWorkouts = (jsonDecode(json) as List)
          .map((e) => Workout.fromJson(e))
          .toList();
      state = newWorkouts;
    });
    return [];
  }

  Future<void> _save({required List<Workout> updatedWorkouts}) async {
    final file = File(_filename!)..createSync();
    final json = jsonEncode(updatedWorkouts);
    file.writeAsStringSync(json);
    state = updatedWorkouts;
  }

  void add(Workout workout) {
    final updatedWorkouts = List.of(state);
    // New items go to the front of the list.
    updatedWorkouts.insert(0, workout);
    // Save updated list to disk.
    _save(updatedWorkouts: updatedWorkouts);
  }

  void remove(Workout workout) {
    final updatedWorkouts = List.of(state);
    if (updatedWorkouts.remove(workout)) {
      _save(updatedWorkouts: updatedWorkouts);
    } else {
      debugPrint('Unable to remove workout');
    }
  }

  void replace(Workout existingWorkout, Workout newWorkout) {
    final index = state.indexOf(existingWorkout);
    assert(index != -1);
    if (index == -1) {
      debugPrint('Unable to replace workout');
      return;
    }
    final updatedWorkouts = List.of(state);
    updatedWorkouts[index] = newWorkout;
    _save(updatedWorkouts: updatedWorkouts);
  }

  void duplicate(Workout workout) {
    final updatedWorkouts = List.of(state);
    // Copy workout, but give the copy the current time and date.
    final newWorkout = workout.copyWith(date: DateTime.now());
    updatedWorkouts.insert(0, newWorkout);
    _save(updatedWorkouts: updatedWorkouts);
  }
}
