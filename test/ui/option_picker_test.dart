import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/theme/adaptive_app.dart';
import 'package:q_master/theme/theme.dart' as gloom;
import 'package:q_master/ui/option_picker.dart';

void main() {
  for (final (platform, anchored) in [
    (TargetPlatform.android, false),
    (TargetPlatform.iOS, false),
    (TargetPlatform.iOS, true),
  ]) {
    testWidgets('option picker follows theme on $platform anchored=$anchored', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      int? result;
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
                  GoRoute(
                    path: '/',
                    builder: (_, _) => Builder(
                      builder: (context) {
                        Widget trigger(glass.GlassMorphAnchor? anchor) =>
                            GestureDetector(
                              onTap: () async {
                                result = await showOptionPicker<int>(
                                  context: context,
                                  title: 'Choose',
                                  anchor: anchor,
                                  options: const [
                                    PickerOption(
                                      value: 7,
                                      icon: material.Icons.check,
                                      title: 'Select',
                                      subtitle: 'Choose this option',
                                    ),
                                  ],
                                );
                              },
                              child: const Center(child: Text('Open picker')),
                            );
                        return anchored
                            ? glass.GlassMorphTrigger(
                                builder: (_, anchor) => trigger(anchor),
                              )
                            : trigger(null);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      final mode = ValueNotifier(material.ThemeMode.light);
      addTearDown(mode.dispose);
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
      expect(
        Navigator.of(tester.element(find.text('Open picker'))),
        same(branchKey.currentState),
      );

      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();
      final option = find.text('Select');
      expect(option, findsOneWidget);
      expect(Navigator.of(tester.element(option)), same(rootKey.currentState));
      if (!anchored) expect(find.byType(material.BottomSheet), findsOneWidget);
      expect(
        tester.widget<Text>(option).style!.color,
        gloom.lightTheme().colorScheme.onSurface,
      );
      mode.value = material.ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(option).style!.color,
        gloom.darkTheme().colorScheme.onSurface,
      );
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(result, 7);
      expect(option, findsNothing);
    });
  }
}
