import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/theme/adaptive_app.dart';
import 'package:q_master/ui/adaptive_draggable_sheet.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('draggable sheet opens on root navigator on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const sheetColor = Color(0xff123456);
      final rootKey = GlobalKey<NavigatorState>();
      final branchKey = GlobalKey<NavigatorState>();
      String? result;
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
                      builder: (context) => GestureDetector(
                        onTap: () async {
                          result = await showAdaptiveDraggableSheet<String>(
                            context: context,
                            builder: (_) => GestureDetector(
                              onTap: () =>
                                  rootKey.currentState!.pop('selected'),
                              child: const Center(child: Text('Close sheet')),
                            ),
                          );
                        },
                        child: const Center(child: Text('Open sheet')),
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
          child: AdaptiveApp(
            routerConfig: router,
            themeMode: material.ThemeMode.dark,
            builder: (_, child) => Builder(
              builder: (context) {
                final theme = material.Theme.of(context);
                return material.Theme(
                  data: theme.copyWith(scaffoldBackgroundColor: sheetColor),
                  child: child!,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Navigator.of(tester.element(find.text('Open sheet'))),
        same(branchKey.currentState),
      );
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      final sheet = find.text('Close sheet');
      expect(sheet, findsOneWidget);
      expect(Navigator.of(tester.element(sheet)), same(rootKey.currentState));
      if (platform == TargetPlatform.android) {
        expect(
          tester
              .widget<SheetBackground>(find.byType(SheetBackground))
              .backgroundColor,
          sheetColor,
        );
      }
      await tester.tap(sheet);
      await tester.pumpAndSettle();
      expect(result, 'selected');
      expect(sheet, findsNothing);
    });
  }
}
