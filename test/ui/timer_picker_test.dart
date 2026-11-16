import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as modern;
import 'package:q_master/theme/adaptive_app.dart';
import 'package:q_master/theme/theme.dart' as gloom;
import 'package:q_master/timer/timer_screen.dart';
import 'package:q_master/timer/timer_setup_tab.dart';
import 'package:q_master/utils/shared_app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedAppPrefs.ensureInitialized();
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('timer pickers retain their navigation on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final rootKey = GlobalKey<NavigatorState>();
      final branchKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: rootKey,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => shell,
            branches: [
              StatefulShellBranch(
                navigatorKey: branchKey,
                routes: [
                  GoRoute(path: '/', builder: (_, _) => const TimerSetupTab()),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: AdaptiveApp(
            routerConfig: router,
            themeMode: modern.ThemeMode.dark,
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final (label, pickerType) in [
        ('Prepare', cupertino.CupertinoTimerPicker),
        ('Rounds', cupertino.CupertinoPicker),
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        final picker = find.byType(pickerType);
        expect(picker, findsOneWidget);
        final pickerContext = tester.element(picker);
        final navigator = Navigator.of(pickerContext);
        expect(
          navigator,
          same(
            platform == TargetPlatform.android
                ? branchKey.currentState
                : rootKey.currentState,
          ),
        );
        expect(material.Theme.of(pickerContext).brightness, Brightness.dark);
        expect(
          pickerType == cupertino.CupertinoTimerPicker
              ? tester
                    .widget<cupertino.CupertinoTimerPicker>(picker)
                    .backgroundColor
              : tester
                    .widget<cupertino.CupertinoPicker>(picker)
                    .backgroundColor,
          gloom.darkTheme().scaffoldBackgroundColor,
        );
        if (platform == TargetPlatform.android) {
          expect(find.byType(modern.BottomSheet), findsOneWidget);
        }
        expect(
          cupertino.CupertinoTheme.of(pickerContext).brightness,
          Brightness.dark,
        );
        navigator.pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('timer screen follows theme on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final mode = ValueNotifier(modern.ThemeMode.light);
      addTearDown(mode.dispose);
      final branchKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => shell,
            branches: [
              StatefulShellBranch(
                navigatorKey: branchKey,
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => const TimerSetupTab(),
                    routes: TimerSetupTab.routes,
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
      await tester.tap(find.text('Start Timer'));
      await tester.pumpAndSettle();
      expect(find.byType(TimerScreen), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(TimerScreen))),
        same(branchKey.currentState),
      );
      final label = find.text('PREPARE');
      expect(label, findsOneWidget);
      final context = tester.element(label);
      expect(
        tester.widget<Text>(label).style!.color,
        gloom.TimerColors.prepareLabel(context),
      );
      final lightColor = tester.widget<Text>(label).style!.color;
      mode.value = modern.ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(label).style!.color,
        gloom.TimerColors.prepareLabel(context),
      );
      expect(tester.widget<Text>(label).style!.color, isNot(lightColor));
      branchKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Start Timer'), findsOneWidget);
    });
  }
}
