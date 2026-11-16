import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/model/exicon.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/services/exicon_fetcher.dart';
import 'package:q_master/theme/adaptive_app.dart';
import 'package:q_master/utils/shared_app_prefs.dart';
import 'package:q_master/workouts/create_workout_sheet.dart';
import 'package:q_master/workouts/exercise_picker_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedAppPrefs.ensureInitialized();
  });

  testWidgets('section edit button works in the iOS editor', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final workout = Workout(
      name: 'Morning beatdown',
      date: DateTime(2025),
      sections: [
        WorkoutSection(name: 'Warm up', exercises: ['Merkin']),
      ],
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => CreateWorkoutSheet(originalWorkout: workout),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: AdaptiveApp(
          routerConfig: router,
          themeMode: material.ThemeMode.dark,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit section'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Edit section name'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('exercise picker selects and adds on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final added = <String>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => GestureDetector(
              onTap: () =>
                  showExercisePicker(context, onExerciseAdded: added.add),
              child: const Center(child: Text('Open picker')),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exiconFetcherProvider.overrideWithBuild(
              (_, _) async => [
                const ExiconEntry(name: 'Merkin', description: 'A push-up.'),
              ],
            ),
          ],
          child: AdaptiveApp(
            routerConfig: router,
            themeMode: material.ThemeMode.dark,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      expect(find.text('Merkin'), findsOneWidget);
      final addButton = find.widgetWithText(material.ElevatedButton, 'Add');
      expect(addButton, findsOneWidget);
      expect(
        tester.widget<material.ElevatedButton>(addButton).onPressed,
        isNull,
      );
      final pickerContext = tester.element(addButton);
      expect(
        tester
            .widget<material.ElevatedButton>(addButton)
            .style!
            .backgroundColor!
            .resolve({}),
        material.Theme.of(pickerContext).colorScheme.primary,
      );

      await tester.tap(find.text('Merkin'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<material.ElevatedButton>(addButton).onPressed,
        isNotNull,
      );
      await tester.tap(addButton);
      await tester.pump();
      expect(added, ['Merkin']);
    });
  }
}
