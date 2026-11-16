import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/theme/adaptive_app.dart';
import 'package:q_master/theme/material_theme.dart' as gloom;
import 'package:q_master/ui/adaptive_tab_bar.dart';
import 'package:q_master/ui/app_shell.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('shell switches branches and adapts its chrome on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final router = GoRouter(
        initialLocation: '/workouts',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, state, shell) => AppShell(
              navigationShell: shell,
              routerState: state,
              workoutsScrollController: scrollController,
            ),
            branches: [
              for (final (path, label) in [
                ('/workouts', 'Workouts content'),
                ('/games', 'Games content'),
                ('/timer', 'Timer content'),
                ('/location', 'Location content'),
              ])
                StatefulShellBranch(
                  routes: [GoRoute(path: path, builder: (_, _) => Text(label))],
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

      AdaptiveTabBar tabBar() =>
          tester.widget<AdaptiveTabBar>(find.byType(AdaptiveTabBar));
      expect(find.text('Workouts content'), findsOneWidget);
      expect(tabBar().selectedIconColor, gloom.darkTheme().colorScheme.primary);
      expect(tabBar().trailingButton, isNotNull);
      if (platform == TargetPlatform.android) {
        expect(find.byType(material.FloatingActionButton), findsOneWidget);
      }

      await tester.tap(find.text('Games').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.text('Games content'), findsOneWidget);
      expect(tabBar().selectedIndex, 1);
      expect(tabBar().trailingButton, isNull);
      expect(find.byType(material.FloatingActionButton), findsNothing);

      await tester.tap(find.text('Timer').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.text('Timer content'), findsOneWidget);
      expect(tabBar().selectedIndex, 2);
      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpAndSettle();
      expect(tabBar().visible, isFalse);
    });
  }
}
