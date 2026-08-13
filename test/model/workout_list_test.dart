import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/model/workout_list.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutList persistence', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('workout_list_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Workout makeWorkout(String name) => Workout(
      name: name,
      date: DateTime(2024, 1, 1, 8, 0),
      sections: [
        WorkoutSection(name: 'Thang', exercises: ['Burpee']),
      ],
    );

    test(
      'keeps the last valid state when the persisted file is malformed',
      () async {
        final file = File('${tempDir.path}/workouts.json');
        await file.writeAsString('{"not":"a list"}');

        final container = ProviderContainer(
          overrides: [
            workoutListProvider.overrideWith(
              () => WorkoutList(filenameProvider: () async => file.path),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(workoutListProvider.notifier);
        notifier.state = [makeWorkout('Existing')];
        await notifier.loadFromDisk();

        expect(notifier.state, [makeWorkout('Existing')]);
      },
    );

    test('waits for disk load before mutating stale empty state', () async {
      final file = File('${tempDir.path}/workouts.json');
      final diskWorkout = makeWorkout('FromDisk');
      await file.writeAsString(jsonEncode([diskWorkout.toJson()]));

      final container = ProviderContainer(
        overrides: [
          workoutListProvider.overrideWith(
            () => WorkoutList(
              filenameProvider: () async => file.path,
              beforeDiskLoad: () async =>
                  Future<void>.delayed(const Duration(milliseconds: 25)),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(workoutListProvider.notifier);
      notifier.state = [];

      await notifier.add(makeWorkout('Fresh'));

      expect(notifier.state, [
        isA<Workout>().having((workout) => workout.name, 'name', 'Fresh'),
        isA<Workout>().having((workout) => workout.name, 'name', 'FromDisk'),
      ]);
    });
  });
}
