import 'package:shared_preferences/shared_preferences.dart';

extension Utils on SharedPreferences {
  static const _kDodecahedronImpulseKey = 'dodecahedron_impulse';
  static const _kDodecahedronDampingKey = 'dodecahedron_damping';

  /// Stored default impulse strength for the dodecahedron control.
  double? get dodecahedronImpulse => getDouble(_kDodecahedronImpulseKey);
  Future<bool> setDodecahedronImpulse(double value) =>
      setDouble(_kDodecahedronImpulseKey, value);

  /// Stored default damping for the dodecahedron control.
  double? get dodecahedronDamping => getDouble(_kDodecahedronDampingKey);
  Future<bool> setDodecahedronDamping(double value) =>
      setDouble(_kDodecahedronDampingKey, value);

  /// Exercises per page in the beatdown browser
  /// (defaults to 1 if not set)
  int get exercisesPerPage => getInt('exercises_per_page') ?? 1;
  Future<bool> setExercisesPerPage(int value) =>
      setInt('exercises_per_page', value);
}
