import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/utils/shared_app_prefs.dart';
import 'package:q_master/workouts/beatdown_browser_screen.dart';
import 'package:q_master/workouts/create_workout_sheet.dart';
import 'package:q_master/workouts/workouts_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedAppPrefs.ensureInitialized();
  });

  for (final (platform, tablet) in [
    (TargetPlatform.android, false),
    (TargetPlatform.iOS, false),
    (TargetPlatform.android, true),
    (TargetPlatform.iOS, true),
  ]) {
    testWidgets(
      'editor is modal and opens beatdown on $platform tablet=$tablet',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          if (tablet) {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(1200, 900);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
          }
          const channel =
              'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          messenger.setMockMessageHandler(
            channel,
            (_) async => const StandardMessageCodec().encodeMessage([null]),
          );
          addTearDown(() => messenger.setMockMessageHandler(channel, null));

          final rootKey = GlobalKey<NavigatorState>();
          final branchKey = GlobalKey<NavigatorState>();
          final router = GoRouter(
            navigatorKey: rootKey,
            initialLocation: '/workouts',
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (_, _, shell) => Scaffold(
                  body: shell,
                  bottomNavigationBar: const Text('Tab bar'),
                ),
                branches: [
                  StatefulShellBranch(
                    navigatorKey: branchKey,
                    routes: [
                      GoRoute(
                        path: '/workouts',
                        builder: (_, _) =>
                            const Center(child: Text('Workouts')),
                        routes: WorkoutsTab.routes,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
          addTearDown(router.dispose);

          final workout = Workout(
            name: 'Test workout',
            date: DateTime(2025),
            sections: [
              WorkoutSection(name: 'Warm up', exercises: ['Push-ups']),
            ],
          );
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp.router(
                theme: ThemeData(
                  platform: platform,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.transparent,
                  ),
                ),
                localizationsDelegates: L10n.localizationsDelegates,
                supportedLocales: L10n.supportedLocales,
                routerConfig: router,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final workoutsContext = tester.element(find.text('Workouts'));
          WorkoutsTab.invokeWorkoutEditor(workoutsContext, workout: workout);
          await tester.pumpAndSettle();

          final editorFinder = find.byType(CreateWorkoutSheet);
          final editorContext = tester.element(editorFinder);
          expect(Navigator.of(editorContext), same(rootKey.currentState));
          final editorRoute = ModalRoute.of(editorContext)!;
          if (tablet) {
            expect(editorRoute, isA<PopupRoute<Object?>>());
          } else {
            expect(editorRoute.fullscreenDialog, isTrue);
            if (platform == TargetPlatform.iOS) {
              expect(editorRoute, isA<CupertinoPageRoute<Object?>>());
            } else {
              expect(editorRoute, isA<MaterialPageRoute<Object?>>());
            }
          }

          final editor = tester.widget<CreateWorkoutSheet>(editorFinder);
          editor.onShowBeatdownBrowser!(editorContext, workout);
          await tester.pumpAndSettle();

          expect(find.byType(CreateWorkoutSheet), findsNothing);
          final browserContext = tester.element(find.byType(BeatdownBrowser));
          expect(Navigator.of(browserContext), same(branchKey.currentState));
          expect(find.text('Tab bar'), findsOneWidget);

          Navigator.of(browserContext).pop();
          await tester.pumpAndSettle();
          expect(find.text('Workouts'), findsOneWidget);
          expect(find.byType(CreateWorkoutSheet), findsNothing);

          WorkoutsTab.invokeWorkoutEditor(workoutsContext, workout: workout);
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(EditableText), 'Unsaved workout');
          await tester.pumpAndSettle();

          if (tablet && platform == TargetPlatform.android) {
            await tester.tapAt(const Offset(20, 20));
          } else {
            await tester.binding.handlePopRoute();
          }
          await tester.pumpAndSettle();
          expect(find.text('Discard?'), findsOneWidget);

          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(find.byType(CreateWorkoutSheet), findsOneWidget);
          expect(find.text('Unsaved workout'), findsOneWidget);

          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Discard?'), findsOneWidget);
          await tester.tap(find.text('Discard Changes'));
          await tester.pumpAndSettle();
          expect(find.byType(CreateWorkoutSheet), findsNothing);
          expect(find.text('Workouts'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }
}
