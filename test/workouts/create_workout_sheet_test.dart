import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/model/workout_list_controller.dart';
import 'package:q_master/workouts/create_workout_sheet.dart';

Future<void> _pumpEditor(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

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
        workoutListControllerProvider.overrideWith(
          () => WorkoutListController(
            filenameProvider: () async => '${tempDir.path}/workouts.json',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(workoutListControllerProvider.notifier).loadFromDisk();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const CreateWorkoutSheet(),
        ),
      ),
    );
    await _pumpEditor(tester);

    final workoutNameField = find.byType(TextField);
    expect(workoutNameField, findsOneWidget);

    await tester.enterText(workoutNameField, 'First version');
    await tester.tap(find.byIcon(Icons.check));
    await _pumpEditor(tester);

    expect(container.read(workoutListControllerProvider), hasLength(1));
    expect(
      container.read(workoutListControllerProvider).single.name,
      'First version',
    );

    await tester.tap(find.byIcon(Icons.edit));
    await _pumpEditor(tester);
    await tester.enterText(workoutNameField, 'Updated version');
    await tester.tap(find.byIcon(Icons.check));
    await _pumpEditor(tester);

    final workouts = container.read(workoutListControllerProvider);
    expect(workouts, hasLength(1));
    expect(workouts.single.name, 'Updated version');
  });

  testWidgets('adding a section with an existing name keeps both sections', (
    tester,
  ) async {
    final tempDir = await Directory.systemTemp.createTemp(
      'create_workout_sheet_test_',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final container = ProviderContainer(
      overrides: [
        workoutListControllerProvider.overrideWith(
          () => WorkoutListController(
            filenameProvider: () async => '${tempDir.path}/workouts.json',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(workoutListControllerProvider.notifier).loadFromDisk();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const CreateWorkoutSheet(),
        ),
      ),
    );
    await _pumpEditor(tester);

    await tester.tap(find.text('Add Section').first);
    await _pumpEditor(tester);
    await tester.enterText(find.byType(TextField).last, 'Warm up');
    await tester.tap(find.text('Add Section').last);
    await _pumpEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'Duplicate sections');
    await tester.tap(find.byIcon(Icons.check));
    await _pumpEditor(tester);

    final sections = container
        .read(workoutListControllerProvider)
        .single
        .sections;
    expect(sections, hasLength(2));
    expect(sections.map((section) => section.name), ['Warm up', 'Warm up']);
  });

  testWidgets('dragging an exercise moves it to another section', (
    tester,
  ) async {
    final workout = Workout(
      name: 'Cross-section move',
      date: DateTime(2025),
      sections: [
        WorkoutSection(name: 'Warm up', exercises: ['Push-ups']),
        WorkoutSection(name: 'Thang', exercises: ['Burpees']),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: CreateWorkoutSheet(originalWorkout: workout),
        ),
      ),
    );
    await _pumpEditor(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Push-ups')),
    );
    await tester.pump(kLongPressTimeout);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('Burpees')));
    await tester.pump();
    await gesture.up();
    await _pumpEditor(tester);

    expect(
      tester.getTopLeft(find.text('Push-ups')).dy,
      greaterThan(tester.getTopLeft(find.text('THANG')).dy),
    );
  });

  testWidgets('dragging an exercise to the edge auto-scrolls the workout', (
    tester,
  ) async {
    final workout = Workout(
      name: 'Auto-scroll',
      date: DateTime(2025),
      sections: [
        for (var index = 0; index < 20; index++)
          WorkoutSection(
            name: 'Section $index',
            exercises: ['Exercise $index'],
          ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: CreateWorkoutSheet(originalWorkout: workout),
        ),
      ),
    );
    await _pumpEditor(tester);

    final scrollableFinder = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    final scrollable = tester.state<ScrollableState>(scrollableFinder.first);
    expect(scrollable.position.pixels, 0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Exercise 0')),
    );
    await tester.pump(kLongPressTimeout);
    await tester.pump();

    final viewport = tester.getRect(find.byType(CustomScrollView));
    await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 8));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(scrollable.position.pixels, greaterThan(0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dropping an exercise scrolls the moved row into view', (
    tester,
  ) async {
    final workout = Workout(
      name: 'Scroll to drop',
      date: DateTime(2025),
      sections: [
        for (var index = 0; index < 20; index++)
          WorkoutSection(
            name: 'Section $index',
            exercises: ['Exercise $index'],
          ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: CreateWorkoutSheet(originalWorkout: workout),
        ),
      ),
    );
    await _pumpEditor(tester);

    final viewport = tester.getRect(find.byType(CustomScrollView));
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Exercise 0')),
    );
    await tester.pump(kLongPressTimeout);
    await tester.pump();
    await gesture.moveTo(Offset(viewport.center.dx, viewport.bottom - 8));
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(scrollable.position.pixels, greaterThan(0));

    // Move away from the edge and let the auto-scroll settle, since the
    // scrollable ignores pointers while it animates.
    await gesture.moveTo(tester.getCenter(find.text('Exercise 3')));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(0, 1));
    await tester.pump();
    final offsetBeforeDrop = scrollable.position.pixels;
    await gesture.up();
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, isNot(offsetBeforeDrop));
    expect(
      tester.getCenter(find.text('Exercise 0')).dy,
      closeTo(viewport.center.dy, 80),
    );
  });
}
