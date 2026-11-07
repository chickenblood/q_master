import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:accessing_security_scoped_resource/accessing_security_scoped_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import 'workout.dart';

part 'workout_list_controller.g.dart';

@Riverpod(keepAlive: true)
final class WorkoutListController extends _$WorkoutListController {
  static final _logger = Logger();
  final _watch = WatchConnectivity();
  final Future<String> Function() _filenameProvider;
  final Future<void> Function()? _beforeDiskLoad;
  final Future<void> Function()? _beforeDiskSave;
  var _dataIsLoaded = false;
  Future<void>? _initialLoadFuture;
  String? _cachedFilename;
  AppLifecycleListener? _appLifecycleListener;

  WorkoutListController({
    Future<String> Function()? filenameProvider,
    Future<void> Function()? beforeDiskLoad,
    Future<void> Function()? beforeDiskSave,
  }) : _filenameProvider = filenameProvider ?? _defaultFilename,
       _beforeDiskLoad = beforeDiskLoad,
       _beforeDiskSave = beforeDiskSave;

  static Future<String> _defaultFilename() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/workouts.json';
  }

  @override
  List<Workout> build() {
    // This is just to force a sync on background of the app during testing.
    // It's not really necessary since the app syncs on every save.
    if (_appLifecycleListener == null) {
      _appLifecycleListener = AppLifecycleListener(onPause: _syncToWatch);
      ref.onDispose(() {
        _appLifecycleListener?.dispose();
        _appLifecycleListener = null;
      });
    }
    if (!_dataIsLoaded) {
      // Set initial state while we load from disk.
      state = [];
      loadFromDisk();
    }
    return state;
  }

  Future<void> loadFromDisk() {
    if (_initialLoadFuture != null) {
      return _initialLoadFuture!;
    }
    _initialLoadFuture = _loadFromDisk();
    return _initialLoadFuture!;
  }

  Future<String> _filename() async {
    if (_cachedFilename != null) {
      return _cachedFilename!;
    }
    _cachedFilename = await _filenameProvider();
    return _cachedFilename!;
  }

  Future<List<Workout>?> _decodeWorkoutsFromJsonString(String json) async {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Expected persisted workouts to be a list');
    }

    final newWorkouts = <Workout>[];
    for (final entry in decoded) {
      try {
        if (entry is! Map) {
          _logger.w('Skipping malformed workout entry: expected map.');
          continue;
        }
        final migrated = _migrateJson(Map<String, Object?>.from(entry));
        newWorkouts.add(Workout.fromJson(migrated));
      } on Object catch (error, stackTrace) {
        _logger.w(
          'Skipping malformed workout entry during load.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return newWorkouts;
  }

  Future<void> _loadFromDisk() async {
    try {
      final lastKnownState = List<Workout>.of(state);
      if (_beforeDiskLoad != null) {
        await _beforeDiskLoad();
      }

      final file = File(await _filename());
      if (!(await file.exists())) {
        state = lastKnownState.isNotEmpty ? lastKnownState : const [];
        _dataIsLoaded = true;
        return;
      }

      late final List<Workout>? decodedWorkouts;
      try {
        decodedWorkouts = await _decodeWorkoutsFromJsonString(
          await file.readAsString(),
        );
      } on Object {
        final backupFile = File('${file.path}.bak');
        if (await backupFile.exists()) {
          try {
            decodedWorkouts = await _decodeWorkoutsFromJsonString(
              await backupFile.readAsString(),
            );
            await file.writeAsString(
              jsonEncode(
                decodedWorkouts!.map((workout) => workout.toJson()).toList(),
              ),
            );
          } on Object {
            decodedWorkouts = null;
          }
        } else {
          decodedWorkouts = null;
        }
      }

      if (decodedWorkouts == null) {
        throw const FormatException(
          'No valid persisted workouts were available',
        );
      }

      state = decodedWorkouts;
      _dataIsLoaded = true;
      await _syncToWatch();
    } on Object catch (error, stackTrace) {
      final preservedState = List<Workout>.of(state);
      _logger.e(
        'Failed to initialize workouts from disk.',
        error: error,
        stackTrace: stackTrace,
      );
      state = preservedState.isNotEmpty ? preservedState : const [];
      _dataIsLoaded = true;
    } finally {
      _initialLoadFuture = null;
    }
  }

  Future<void> _syncToWatch() async {
    try {
      final workoutsArray = state.map((e) => e.toJson()).toList();
      final isPaired = await _watch.isPaired;
      final isReachable = await _watch.isReachable;
      if (!isPaired) {
        return;
      }

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
      _logger.e('Sync failure.', error: e);
    } on MissingPluginException catch (e) {
      _logger.w(
        'Watch connectivity plugin unavailable; skipping sync.',
        error: e,
      );
    }
  }

  Future<void> _save({required List<Workout> updatedWorkouts}) async {
    final previousState = state;
    state = updatedWorkouts;

    try {
      final file = File(await _filename());
      await file.create(recursive: true);
      final json = jsonEncode(updatedWorkouts.map((w) => w.toJson()).toList());
      final tempFile = File('${file.path}.tmp');
      final backupFile = File('${file.path}.bak');
      if (_beforeDiskSave != null) {
        await _beforeDiskSave();
      }
      if (await file.exists()) {
        await backupFile.writeAsString(await file.readAsString());
      }
      await tempFile.writeAsString(json);
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);
    } on Object catch (error, stackTrace) {
      state = previousState;
      _logger.e(
        'Failed to persist workouts to disk.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    await _syncToWatch();
  }

  Future<void> _mutateAndSave(bool Function(List<Workout>) mutate) async {
    if (!_dataIsLoaded) {
      await loadFromDisk();
    }

    final updatedWorkouts = List.of(state);
    final didMutate = mutate(updatedWorkouts);
    if (!didMutate) {
      return;
    }
    return _save(updatedWorkouts: updatedWorkouts);
  }

  Future<void> add(Workout workout) {
    return _mutateAndSave((updatedWorkouts) {
      // New items go to the front of the list.
      updatedWorkouts.insert(0, workout);
      // Save updated list to disk.
      return true;
    });
  }

  /// Reads a single workout from a file.
  Future<void> addFromFile(String filename) async {
    // Special handling for iOS secure URLs like those received over AirDrop.
    final isIOSSecureURL = Platform.isIOS && filename.startsWith('/private');

    if (isIOSSecureURL) {
      await AccessingSecurityScopedResource()
          .startAccessingSecurityScopedResourceWithFilePath(filename);
    }
    final file = File(filename);
    if (!file.existsSync()) {
      return;
    }
    final data = file.readAsStringSync();
    final json = jsonDecode(data);
    // Give incoming data the current date.
    // TODO: This may not be in the correct format for a workout. We should
    // catch the error if that is the case.
    final workout = Workout.fromJson(json).copyWith(date: DateTime.now());
    await add(workout);

    if (isIOSSecureURL) {
      await AccessingSecurityScopedResource()
          .stopAccessingSecurityScopedResourceWithFilePath(filename);
    }
  }

  Future<void> remove(Workout workout) {
    return _mutateAndSave((updatedWorkouts) {
      final removed = updatedWorkouts.remove(workout);
      if (!removed) {
        debugPrint('Unable to remove workout');
      }
      return removed;
    });
  }

  Future<void> replace(Workout existingWorkout, Workout newWorkout) {
    return _mutateAndSave((updatedWorkouts) {
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

  Future<void> move(int fromIndex, int toIndex) {
    return _mutateAndSave((updatedWorkouts) {
      if (fromIndex < 0 || fromIndex >= updatedWorkouts.length) {
        debugPrint('Unable to move workout: source index out of range');
        return false;
      }
      if (toIndex < 0 || toIndex > updatedWorkouts.length) {
        debugPrint('Unable to move workout: destination index out of range');
        return false;
      }

      final workout = updatedWorkouts.removeAt(fromIndex);
      final targetIndex = toIndex.clamp(0, updatedWorkouts.length);
      updatedWorkouts.insert(targetIndex, workout);
      return true;
    });
  }

  Future<void> duplicate(Workout workout) {
    return _mutateAndSave((updatedWorkouts) {
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
            'name': (section['name'] as String?) ?? '',
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
  if (exercises is! List) return [];
  return exercises
      .map((e) {
        if (e is String) return e;
        if (e is Map) return (e['name'] as String?) ?? '';
        return '';
      })
      .where((e) => e.isNotEmpty)
      .toList();
}
