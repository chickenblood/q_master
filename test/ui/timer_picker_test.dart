// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:q_master/theme/adaptive_app.dart';
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
            themeMode: material.ThemeMode.dark,
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
        navigator.pop();
        await tester.pumpAndSettle();
      }
    });
  }
}
