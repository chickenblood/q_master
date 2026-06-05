import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'workout.dart';

part 'workout_list.g.dart';

@riverpod
final class WorkoutList extends _$WorkoutList {
  static final _logger = Logger();
  final _watch = WatchConnectivity();
  String? _filename;
  AppLifecycleListener? _appLifecycleListener;
  Future<void>? _initialLoad;

  @override
  List<Workout> build() {
    ref.onDispose(() => _appLifecycleListener?.dispose());
    unawaited(_ensureInitialized());
    return [];
  }

  Future<void> _ensureInitialized() => _initialLoad ??= _initialize();

  Future<void> _initialize() async {
    _appLifecycleListener ??= AppLifecycleListener(onPause: _syncToWatch);

    try {
      final filename = await _ensureFilename();
      final file = File(filename);
      if (!await file.exists()) {
        return;
      }

      final json = await file.readAsString();
      final newWorkouts = (jsonDecode(json) as List)
          .map((e) => Workout.fromJson(_migrateJson(e as Map<String, Object?>)))
          .toList();

      state = newWorkouts;
      await _syncToWatch();
    } on Object catch (error, stackTrace) {
      _logger.e(
        'Failed to initialize workouts from disk.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String> _ensureFilename() async {
    if (_filename != null) {
      return _filename!;
    }

    final directory = await getApplicationDocumentsDirectory();
    _filename = '${directory.path}/workouts.json';
    return _filename!;
  }

  Future<void> _syncToWatch() async {
    final workoutsArray = state.map((e) => e.toJson()).toList();
    final isPaired = await _watch.isPaired;
    final isReachable = await _watch.isReachable;
    if (isPaired) {
      try {
        final payload = {
          'workouts': workoutsArray,
          'date': DateTime.now().toIso8601String(),
        };

        if (Platform.isAndroid) {
          // Realtime push when connected; fall back to context sync when not
          // reachable.
          if (isReachable) {
            await _watch.sendMessage(payload);
          } else {
            await _watch.updateApplicationContext(payload);
          }
        } else {
          // Standard sync for iOS/watchOS
          await _watch.updateApplicationContext(payload);
        }
      } on PlatformException catch (e) {
        _logger.e('Sync failure. Reachable: $isReachable', error: e);
      }
    }
  }

  Future<void> _save({required List<Workout> updatedWorkouts}) async {
    final filename = await _ensureFilename();
    final file = File(filename);
    await file.create(recursive: true);
    final json = jsonEncode(updatedWorkouts);
    await file.writeAsString(json);
    state = updatedWorkouts;

    await _syncToWatch();
  }

  Future<void> _runAfterInitialLoad(Future<void> Function() action) async {
    await _ensureInitialized();
    await action();
  }

  void _mutateAndSave(bool Function(List<Workout>) mutate) {
    unawaited(
      _runAfterInitialLoad(() async {
        final updatedWorkouts = List.of(state);
        final didMutate = mutate(updatedWorkouts);
        if (!didMutate) {
          return;
        }
        await _save(updatedWorkouts: updatedWorkouts);
      }),
    );
  }

  void add(Workout workout) {
    _mutateAndSave((updatedWorkouts) {
      // New items go to the front of the list.
      updatedWorkouts.insert(0, workout);
      // Save updated list to disk.
      return true;
    });
  }

  void remove(Workout workout) {
    _mutateAndSave((updatedWorkouts) {
      final removed = updatedWorkouts.remove(workout);
      if (!removed) {
        debugPrint('Unable to remove workout');
      }
      return removed;
    });
  }

  void replace(Workout existingWorkout, Workout newWorkout) {
    _mutateAndSave((updatedWorkouts) {
      final index = updatedWorkouts.indexOf(existingWorkout);
      assert(index != -1);
      if (index == -1) {
        debugPrint('Unable to replace workout');
        return false;
      }
      updatedWorkouts[index] = newWorkout;
      return true;
    });
  }

  void move(int fromIndex, int toIndex) {
    _mutateAndSave((updatedWorkouts) {
      final workout = updatedWorkouts.removeAt(fromIndex);
      updatedWorkouts.insert(toIndex, workout);
      return true;
    });
  }

  void duplicate(Workout workout) {
    _mutateAndSave((updatedWorkouts) {
      // Copy workout, but give the copy the current time and date.
      final newWorkout = workout.copyWith(date: DateTime.now());
      updatedWorkouts.insert(0, newWorkout);
      return true;
    });
  }
}

/// Migrates a workout JSON map from older formats to the current format
/// (sections as an ordered list of section objects).
///
/// Handles:
/// - v1 (legacy): warmup/thang/mary as top-level keys
/// - v2 (current): ordered section list under 'sections'
Map<String, Object?> _migrateJson(Map<String, Object?> json) {
  // V1: flat keys warmup/thang/mary at top level
  if (json.containsKey('warmup') ||
      json.containsKey('thang') ||
      json.containsKey('mary')) {
    return {
      'name': json['name'],
      'date': json['date'],
      'sections': [
        {'name': 'warmup', 'exercises': _migrateExerciseList(json['warmup'])},
        {'name': 'thang', 'exercises': _migrateExerciseList(json['thang'])},
        {'name': 'mary', 'exercises': _migrateExerciseList(json['mary'])},
      ],
    };
  }

  final result = Map<String, Object?>.of(json);

  // Current format: sanitize exercise entries within each section
  if (result['sections'] is List) {
    final sectionsList = result['sections'] as List;
    result['sections'] = [
      for (final section in sectionsList)
        if (section is Map)
          {
            'name': section['name'] as String,
            'exercises': _migrateExerciseList(section['exercises']),
          },
    ];
  }

  return result;
}

/// Converts a list of exercises — either plain strings or `{ name: '...' }` maps
/// — into a plain `List<String>`.
List<String> _migrateExerciseList(Object? exercises) {
  if (exercises == null) return [];
  return (exercises as List)
      .map((e) {
        if (e is String) return e;
        if (e is Map) return (e['name'] as String?) ?? '';
        return '';
      })
      .where((e) => e.isNotEmpty)
      .toList();
}
