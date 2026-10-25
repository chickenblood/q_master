import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/model/workout_list.dart';
import 'package:q_master/workouts/create_workout_sheet.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saving an edited new workout replaces it instead of adding it', (
    tester,
  ) async {
    final tempDir = await Directory.systemTemp.createTemp(
      'create_workout_sheet_test_',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final container = ProviderContainer(
      overrides: [
        workoutListProvider.overrideWith(
          () => WorkoutList(
            filenameProvider: () async => '${tempDir.path}/workouts.json',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(workoutListProvider.notifier).loadFromDisk();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const CreateWorkoutSheet(initialDisplayMode: DisplayMode.edit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final workoutNameField = find.byType(TextField);
    expect(workoutNameField, findsOneWidget);

    await tester.enterText(workoutNameField, 'First version');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(container.read(workoutListProvider), hasLength(1));
    expect(container.read(workoutListProvider).single.name, 'First version');

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(workoutNameField, 'Updated version');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final workouts = container.read(workoutListProvider);
    expect(workouts, hasLength(1));
    expect(workouts.single.name, 'Updated version');
  });
}
