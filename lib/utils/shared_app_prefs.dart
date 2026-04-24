import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharePreferences wrapper that provides typed accessors and change notifiers
/// for application settings.
///
/// Listen to the object itself if you don't care what specific setting changed.
final class SharedAppPrefs extends ChangeNotifier {
  static const maxExercisesPerPage = 20;
  static late final SharedAppPrefs _instance;
  final SharedPreferences _prefs;

  /// Initializes the SharedAppPrefs singleton. This must be called once
  /// before accessing the [instance].
  static Future<void> ensureInitialized() async {
    _instance = SharedAppPrefs._(await SharedPreferences.getInstance());
  }

  static SharedAppPrefs get instance => _instance;

  /// Exercises per page in the beatdown browser
  /// (defaults to 1 if not set)
  late final ValueNotifier<int> exercisesPerPage;

  late final ValueNotifier<int> timerType;
  late final ValueNotifier<int> prepareIntervalSeconds;
  late final ValueNotifier<int> workIntervalSeconds;
  late final ValueNotifier<int> restIntervalSeconds;
  late final ValueNotifier<int> rounds;
  late final ValueNotifier<int> cycles;

  late final ValueNotifier<int> theme;
  late final ValueNotifier<bool> motorboatSoundEnabled;

  late final ValueNotifier<List<String>> selectedCategoryFilters;
  late final ValueNotifier<bool> exerciseVideoFilter;

  SharedAppPrefs._(this._prefs) {
    exercisesPerPage = _valueSetup<int>('exercises_per_page', 8);

    timerType = _valueSetup<int>('timer_type', 1);
    prepareIntervalSeconds = _valueSetup<int>('prepare_interval_seconds', 10);
    workIntervalSeconds = _valueSetup<int>('work_interval_seconds', 30);
    restIntervalSeconds = _valueSetup<int>('rest_interval_seconds', 10);
    rounds = _valueSetup<int>('rounds', 8);
    cycles = _valueSetup<int>('cycles', 1);

    theme = _valueSetup<int>('theme', ThemeMode.system.index);
    motorboatSoundEnabled = _valueSetup<bool>('motorboat_sound', true);

    selectedCategoryFilters =
        _valueSetup<List<String>>('selected_category_filters', const []);
    exerciseVideoFilter =
        _valueSetup<bool>('exercise_video_filter', false);
  }

  ValueNotifier<T> _valueSetup<T>(String key, T defaultValue) {
    late final Function(String, T) setter;
    late final T? Function(String) getter;
    final type = T.toString();
    if (type == 'int') {
      getter = _prefs.getInt as T? Function(String);
      setter = _prefs.setInt as Function(String, T);
    } else if (type == 'double') {
      getter = _prefs.getDouble as T? Function(String);
      setter = _prefs.setDouble as Function(String, T);
    } else if (type == 'bool') {
      getter = _prefs.getBool as T? Function(String);
      setter = _prefs.setBool as Function(String, T);
    } else if (type == 'String') {
      getter = _prefs.getString as T? Function(String);
      setter = _prefs.setString as Function(String, T);
    } else if (type == 'List<String>') {
      getter = _prefs.getStringList as T? Function(String);
      setter = _prefs.setStringList as Function(String, T);
    } else {
      throw UnsupportedError('Unsupported type for SharedAppPrefs: $T');
    }
    final notifier = ValueNotifier<T>(getter(key) ?? defaultValue);
    notifier.addListener(() {
      setter(key, notifier.value);
      notifyListeners();
    });
    return notifier;
  }
}
