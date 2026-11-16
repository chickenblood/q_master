import 'package:cupertino_ui/cupertino_ui.dart' as modern_cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as legacy_cupertino;
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as modern;
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/settings/settings_sheet.dart';
import 'package:q_master/slack/slackblast_picker_sheet.dart';
import 'package:q_master/slack/slackblast_search_field.dart';
import 'package:q_master/theme/adaptive_app.dart';
import 'package:q_master/theme/material_theme.dart' as modern_gloom;
import 'package:q_master/theme/theme.dart' as legacy_gloom;
import 'package:q_master/theme/transition_theme.dart';
import 'package:q_master/ui/adaptive_modal_sheet.dart';
import 'package:q_master/utils/shared_app_prefs.dart';
import 'package:q_master/workouts/create_workout_sheet.dart';
import 'package:q_master/workouts/workouts_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedAppPrefs.ensureInitialized();
  });

  for (final dark in [false, true]) {
    test('new ${dark ? 'dark' : 'light'} theme preserves component styles', () {
      final oldTheme = dark
          ? legacy_gloom.darkTheme()
          : legacy_gloom.lightTheme();
      final newTheme = dark
          ? modern_gloom.darkTheme()
          : modern_gloom.lightTheme();
      const selected = {WidgetState.selected};

      expect(newTheme.brightness, oldTheme.brightness);
      expect(
        oldTheme.cupertinoOverrideTheme,
        legacy_cupertino.CupertinoThemeData(
          primaryColor: newTheme.cupertinoOverrideTheme!.primaryColor,
        ).noDefault(),
      );
      expect(newTheme.colorScheme.primary, oldTheme.colorScheme.primary);
      expect(newTheme.colorScheme.surface, oldTheme.colorScheme.surface);
      expect(newTheme.colorScheme.onSurface, oldTheme.colorScheme.onSurface);
      expect(newTheme.colorScheme.outline, oldTheme.colorScheme.outline);
      expect(
        newTheme.scaffoldBackgroundColor,
        oldTheme.scaffoldBackgroundColor,
      );
      expect(newTheme.textTheme.titleLarge, oldTheme.textTheme.titleLarge);
      expect(newTheme.textTheme.bodyMedium, oldTheme.textTheme.bodyMedium);
      expect(newTheme.iconTheme, oldTheme.iconTheme);
      expect(
        newTheme.appBarTheme.backgroundColor,
        oldTheme.appBarTheme.backgroundColor,
      );
      expect(
        newTheme.appBarTheme.titleTextStyle,
        oldTheme.appBarTheme.titleTextStyle,
      );
      expect(newTheme.dividerTheme.color, oldTheme.dividerTheme.color);
      expect(newTheme.cardTheme.color, oldTheme.cardTheme.color);
      expect(newTheme.cardTheme.shape, oldTheme.cardTheme.shape);
      expect(
        newTheme.listTileTheme.tileColor,
        oldTheme.listTileTheme.tileColor,
      );
      expect(
        newTheme.navigationBarTheme.backgroundColor,
        oldTheme.navigationBarTheme.backgroundColor,
      );
      expect(
        newTheme.navigationBarTheme.iconTheme?.resolve(selected),
        oldTheme.navigationBarTheme.iconTheme?.resolve(selected),
      );
      expect(
        newTheme.bottomNavigationBarTheme.selectedItemColor,
        oldTheme.bottomNavigationBarTheme.selectedItemColor,
      );
      expect(newTheme.bottomSheetTheme.shape, oldTheme.bottomSheetTheme.shape);
      expect(
        newTheme.filledButtonTheme.style?.backgroundColor?.resolve(selected),
        oldTheme.filledButtonTheme.style?.backgroundColor?.resolve(selected),
      );
      expect(
        newTheme.outlinedButtonTheme.style?.side?.resolve(selected),
        oldTheme.outlinedButtonTheme.style?.side?.resolve(selected),
      );
      expect(
        newTheme.floatingActionButtonTheme.backgroundColor,
        oldTheme.floatingActionButtonTheme.backgroundColor,
      );
      expect(
        newTheme.inputDecorationTheme.fillColor,
        oldTheme.inputDecorationTheme.fillColor,
      );
      expect(
        newTheme.segmentedButtonTheme.style?.backgroundColor?.resolve(selected),
        oldTheme.segmentedButtonTheme.style?.backgroundColor?.resolve(selected),
      );
      expect(newTheme.chipTheme.labelStyle, oldTheme.chipTheme.labelStyle);
      expect(
        newTheme.switchTheme.trackColor?.resolve(selected),
        oldTheme.switchTheme.trackColor?.resolve(selected),
      );
    });

    testWidgets(
      'split modal surfaces match legacy in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        await tester.pumpWidget(
          legacy.MaterialApp(
            theme: dark ? legacy_gloom.darkTheme() : legacy_gloom.lightTheme(),
            builder: (_, child) => TransitionTheme(child: child!),
            home: legacy.Scaffold(
              body: Row(
                children: [
                  Expanded(
                    child: legacy.Dialog(child: const SizedBox(height: 60)),
                  ),
                  Expanded(
                    child: modern.Dialog(child: const SizedBox(height: 60)),
                  ),
                ],
              ),
            ),
          ),
        );
        final oldSurface = tester.widget<legacy.Material>(
          find.descendant(
            of: find.byType(legacy.Dialog),
            matching: find.byType(legacy.Material),
          ),
        );
        final newSurface = tester.widget<modern.Material>(
          find.descendant(
            of: find.byType(modern.Dialog),
            matching: find.byType(modern.Material),
          ),
        );
        expect(newSurface.color, oldSurface.color);
        expect(newSurface.elevation, oldSurface.elevation);
        expect(newSurface.shape, oldSurface.shape);
      },
    );
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final tablet in [false, true]) {
      testWidgets(
        'themes follow preference in root modal on $platform tablet=$tablet',
        (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          addTearDown(() => debugDefaultTargetPlatformOverride = null);
          if (tablet) {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(1200, 900);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
          }

          final mode = ValueNotifier(modern.ThemeMode.light);
          addTearDown(mode.dispose);
          final navigatorKey = GlobalKey<NavigatorState>();
          final router = GoRouter(
            navigatorKey: navigatorKey,
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (_, _, shell) => shell,
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: '/',
                        builder: (context, state) => legacy.Scaffold(
                          body: legacy.TextButton(
                            onPressed: () => showAdaptiveModalSheet<void>(
                              context: navigatorKey.currentContext!,
                              child: const _ThemeProbe(),
                            ),
                            child: const Text('Open'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
          addTearDown(router.dispose);

          await tester.pumpWidget(
            ProviderScope(
              child: ValueListenableBuilder<modern.ThemeMode>(
                valueListenable: mode,
                builder: (_, themeMode, _) =>
                    AdaptiveApp(routerConfig: router, themeMode: themeMode),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(modern_cupertino.CupertinoApp),
            platform == TargetPlatform.iOS ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(legacy.MaterialApp),
            platform == TargetPlatform.android ? findsOneWidget : findsNothing,
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();

          void expectThemes(Finder finder, Brightness brightness) {
            final context = tester.element(finder);
            final oldTheme = legacy.Theme.of(context);
            final newTheme = modern.Theme.of(context);
            final cupertinoTheme = modern_cupertino.CupertinoTheme.of(context);
            final glassTheme = legacy_cupertino.CupertinoTheme.of(context);
            final expectedGlassTheme = legacy.MaterialBasedCupertinoThemeData(
              materialTheme: oldTheme,
            );
            expect(Navigator.of(context), same(navigatorKey.currentState));
            expect(oldTheme.brightness, brightness);
            expect(newTheme.brightness, brightness);
            expect(newTheme.colorScheme.primary, oldTheme.colorScheme.primary);
            expect(
              newTheme.scaffoldBackgroundColor,
              oldTheme.scaffoldBackgroundColor,
            );
            expect(newTheme.platform, platform);
            expect(cupertinoTheme.brightness, brightness);
            expect(
              cupertinoTheme.primaryColor,
              oldTheme.cupertinoOverrideTheme?.primaryColor,
            );
            Color resolveGlassColor(Color color) =>
                legacy_cupertino.CupertinoDynamicColor.resolve(color, context);
            expect(
              resolveGlassColor(glassTheme.barBackgroundColor).toARGB32(),
              resolveGlassColor(expectedGlassTheme.barBackgroundColor)
                  .toARGB32(),
            );
            expect(
              resolveGlassColor(glassTheme.textTheme.textStyle.color!)
                  .toARGB32(),
              resolveGlassColor(expectedGlassTheme.textTheme.textStyle.color!)
                  .toARGB32(),
            );
            expect(glassTheme.brightness, brightness);
            expect(modern.MaterialLocalizations.of(context), isNotNull);
            expect(
              modern_cupertino.CupertinoLocalizations.of(context),
              isNotNull,
            );
          }

          expectThemes(find.byType(_ThemeProbe), Brightness.light);
          mode.value = modern.ThemeMode.dark;
          await tester.pumpAndSettle();
          expectThemes(find.byType(_ThemeProbe), Brightness.dark);
          mode.value = modern.ThemeMode.light;
          await tester.pumpAndSettle();
          expectThemes(find.byType(_ThemeProbe), Brightness.light);

          tester.platformDispatcher.platformBrightnessTestValue =
              Brightness.dark;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          mode.value = modern.ThemeMode.system;
          await tester.pumpAndSettle();
          expectThemes(find.byType(_ThemeProbe), Brightness.dark);
          tester.platformDispatcher.platformBrightnessTestValue =
              Brightness.light;
          await tester.pumpAndSettle();
          expectThemes(find.byType(_ThemeProbe), Brightness.light);

          navigatorKey.currentState!.pop();
          await tester.pumpAndSettle();
          final homeContext = tester.element(find.text('Open'));
          expect(
            Navigator.of(homeContext),
            isNot(same(navigatorKey.currentState)),
          );
          final workout = Workout(
            name: 'Test workout',
            date: DateTime(2025),
            sections: [
              WorkoutSection(name: 'Warm up', exercises: ['Push-ups']),
            ],
          );
          final sheets = <(void Function(), Finder, Finder?)>[
            (
              () => settingsGlassBarItem(
                id: 'settings',
                context: homeContext,
              ).onPressed!(),
              find.text('GENERAL'),
              find.text('GENERAL'),
            ),
            (
              () => WorkoutsTab.invokeWorkoutEditor(
                homeContext,
                workout: workout,
              ),
              find.byType(CreateWorkoutSheet),
              find.text('WARM UP'),
            ),
            (
              () => showSlackblastPicker(homeContext, workout: workout),
              find.byType(SlackblastSearchField),
              null,
            ),
          ];
          for (final (open, finder, accentText) in sheets) {
            mode.value = modern.ThemeMode.light;
            await tester.pumpAndSettle();
            open();
            await tester.pumpAndSettle();
            expect(finder, findsOneWidget);
            expectThemes(finder, Brightness.light);
            if (accentText != null) {
              expect(
                tester.widget<Text>(accentText).style?.color,
                legacy_gloom.lightTheme().colorScheme.primary,
              );
            } else {
              // Exercise the picker offline without initializing Firebase.
              final context = tester.element(finder);
              expect(
                find.text(L10n.of(context)!.slackblastLoadErrorMessage),
                findsOneWidget,
              );
            }
            mode.value = modern.ThemeMode.dark;
            await tester.pumpAndSettle();
            expectThemes(finder, Brightness.dark);
            if (accentText != null) {
              expect(
                tester.widget<Text>(accentText).style?.color,
                legacy_gloom.darkTheme().colorScheme.primary,
              );
            }
            navigatorKey.currentState!.pop();
            await tester.pumpAndSettle();
          }
        },
      );
    }
  }

  testWidgets('Cupertino system chrome follows explicit and system themes', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final styles = <Map<Object?, Object?>>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setSystemUIOverlayStyle') {
        styles.add(call.arguments as Map<Object?, Object?>);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final mode = ValueNotifier(modern.ThemeMode.light);
    addTearDown(mode.dispose);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const Text('Home'))],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<modern.ThemeMode>(
        valueListenable: mode,
        builder: (_, themeMode, _) =>
            AdaptiveApp(routerConfig: router, themeMode: themeMode),
      ),
    );
    await tester.pumpAndSettle();
    expect(styles.last['statusBarIconBrightness'], 'Brightness.dark');
    expect(styles.last['statusBarBrightness'], 'Brightness.light');
    mode.value = modern.ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(styles.last['statusBarIconBrightness'], 'Brightness.light');
    expect(styles.last['statusBarBrightness'], 'Brightness.dark');
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    mode.value = modern.ThemeMode.system;
    await tester.pumpAndSettle();
    expect(styles.last['statusBarIconBrightness'], 'Brightness.dark');
    expect(styles.last['statusBarBrightness'], 'Brightness.light');
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(styles.last['statusBarIconBrightness'], 'Brightness.light');
    expect(styles.last['statusBarBrightness'], 'Brightness.dark');
  });
}

class _ThemeProbe extends StatelessWidget {
  const _ThemeProbe();

  @override
  Widget build(BuildContext context) => modern.Material(
    child: modern.FilledButton(
      onPressed: () {},
      child: const Text('Theme probe'),
    ),
  );
}
