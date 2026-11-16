import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/theme/adaptive_app.dart';
import 'package:q_master/theme/material_theme.dart' as gloom;
import 'package:q_master/ui/adaptive_accessory_action_item.dart';
import 'package:q_master/ui/adaptive_app_bar.dart';
import 'package:q_master/ui/adaptive_scaffold.dart';
import 'package:q_master/ui/adaptive_tab_bar.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('scaffold chrome follows theme and responds on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final mode = ValueNotifier(material.ThemeMode.light);
      final selected = ValueNotifier(0);
      addTearDown(mode.dispose);
      addTearDown(selected.dispose);
      var actions = 0;
      var accessories = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => ValueListenableBuilder<int>(
              valueListenable: selected,
              builder: (_, index, _) {
                final accessory = AdaptiveAccessoryActionItem(
                  icon: const Icon(material.Icons.add),
                  onPressed: (_) => accessories++,
                );
                return AdaptiveScaffold(
                  appBar: AdaptiveAppBar(
                    title: const Text('Title'),
                    actions: [
                      AdaptiveAppBarItem(
                        icon: const Icon(material.Icons.edit),
                        onPressed: () => actions++,
                      ),
                    ],
                  ),
                  body: const Center(child: Text('Body')),
                  bottomBar: AdaptiveTabBar(
                    selectedIndex: index,
                    onTabSelected: (value) => selected.value = value,
                    trailingButton: accessory,
                    items: const [
                      AdaptiveTabItem(
                        label: 'First',
                        icon: Icon(material.Icons.home),
                      ),
                      AdaptiveTabItem(
                        label: 'Second',
                        icon: Icon(material.Icons.timer),
                      ),
                    ],
                  ),
                  floatingActionButton: accessory,
                );
              },
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: ValueListenableBuilder<material.ThemeMode>(
            valueListenable: mode,
            builder: (_, themeMode, _) =>
                AdaptiveApp(routerConfig: router, themeMode: themeMode),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);
      if (platform == TargetPlatform.android) {
        expect(find.byType(material.Scaffold), findsOneWidget);
        expect(find.byType(material.AppBar), findsOneWidget);
        expect(find.byType(material.BottomNavigationBar), findsOneWidget);
      } else {
        expect(find.byType(glass.GlassScaffold), findsOneWidget);
        expect(find.byType(glass.GlassTabBar), findsOneWidget);
        expect(
          tester
              .widget<glass.GlassAppBar>(find.byType(glass.GlassAppBar))
              .backgroundColor,
          gloom.lightTheme().appBarTheme.backgroundColor,
        );
      }

      await tester.tap(find.byIcon(material.Icons.edit));
      await tester.tap(find.text('Second').hitTestable().first);
      await tester.pumpAndSettle();
      expect(actions, 1);
      expect(selected.value, 1);
      await tester.tap(find.byIcon(material.Icons.add));
      await tester.pumpAndSettle();
      expect(accessories, 1);

      mode.value = material.ThemeMode.dark;
      await tester.pumpAndSettle();
      if (platform == TargetPlatform.iOS) {
        expect(
          tester
              .widget<glass.GlassAppBar>(find.byType(glass.GlassAppBar))
              .backgroundColor,
          gloom.darkTheme().appBarTheme.backgroundColor,
        );
      } else {
        expect(
          material.Theme.of(tester.element(find.byType(material.Scaffold)))
              .brightness,
          Brightness.dark,
        );
      }
    });
  }
}
