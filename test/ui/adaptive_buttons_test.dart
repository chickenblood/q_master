import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as legacy_cupertino;
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/theme/theme.dart' as gloom;
import 'package:q_master/theme/transition_theme.dart';
import 'package:q_master/ui/action_button.dart';
import 'package:q_master/ui/adaptive_buttons.dart';
import 'package:q_master/ui/adaptive_menu.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('buttons preserve platform sizing and callbacks on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var presses = 0;
      void pressed() => presses++;
      const color = Color(0xffc25135);

      await tester.pumpWidget(
        legacy.MaterialApp(
          theme: gloom.lightTheme().copyWith(platform: platform),
          localizationsDelegates: [
            ...L10n.localizationsDelegates,
            material.GlobalMaterialLocalizations.delegate,
            cupertino.GlobalCupertinoLocalizations.delegate,
          ],
          builder: (_, child) => TransitionTheme(child: child!),
          home: legacy.Scaffold(
            body: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const ValueKey('old icon'),
                      child: platform == TargetPlatform.android
                          ? legacy.IconButton(
                              icon: const Icon(legacy.Icons.add),
                              onPressed: pressed,
                              padding: const EdgeInsets.all(8),
                            )
                          : legacy_cupertino.CupertinoButton(
                              onPressed: pressed,
                              borderRadius: BorderRadius.circular(8),
                              pressedOpacity: 0.4,
                              disabledColor: legacy_cupertino
                                  .CupertinoColors
                                  .quaternarySystemFill,
                              child: const Icon(legacy.Icons.add),
                            ),
                    ),
                    AdaptiveIconButton(
                      key: const ValueKey('new icon'),
                      icon: const Icon(legacy.Icons.add),
                      onPressed: pressed,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const ValueKey('old custom icon'),
                      child: platform == TargetPlatform.android
                          ? legacy.IconButton(
                              icon: const Icon(legacy.Icons.add, size: 80),
                              onPressed: pressed,
                              padding: const EdgeInsets.all(8),
                            )
                          : legacy_cupertino.CupertinoButton(
                              onPressed: pressed,
                              padding: const EdgeInsets.only(right: 8),
                              borderRadius: BorderRadius.circular(8),
                              pressedOpacity: 0.4,
                              disabledColor: legacy_cupertino
                                  .CupertinoColors
                                  .quaternarySystemFill,
                              child: const Icon(legacy.Icons.add, size: 80),
                            ),
                    ),
                    AdaptiveIconButton(
                      key: const ValueKey('new custom icon'),
                      icon: const Icon(legacy.Icons.add, size: 80),
                      cupertinoPadding: const EdgeInsets.only(right: 8),
                      onPressed: pressed,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const ValueKey('old text'),
                      child: platform == TargetPlatform.android
                          ? legacy.TextButton(
                              style: legacy.TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: pressed,
                              child: const Text('Button'),
                            )
                          : legacy_cupertino.CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: pressed,
                              borderRadius: BorderRadius.circular(8),
                              pressedOpacity: 0.4,
                              disabledColor: legacy_cupertino
                                  .CupertinoColors
                                  .quaternarySystemFill,
                              child: const Text('Button'),
                            ),
                    ),
                    AdaptiveTextButton(
                      key: const ValueKey('new text'),
                      padding: EdgeInsets.zero,
                      onPressed: pressed,
                      child: const Text('Button'),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const ValueKey('old elevated'),
                      child: platform == TargetPlatform.android
                          ? legacy.ElevatedButton(
                              style: legacy.ElevatedButton.styleFrom(
                                backgroundColor: color,
                              ),
                              onPressed: pressed,
                              child: const Text('Next'),
                            )
                          : legacy_cupertino.CupertinoTheme(
                              data: const legacy_cupertino.CupertinoThemeData(
                                primaryColor: color,
                              ),
                              child: legacy_cupertino.CupertinoButton.filled(
                                color: color,
                                onPressed: pressed,
                                borderRadius: BorderRadius.circular(8),
                                pressedOpacity: 0.4,
                                disabledColor: legacy_cupertino
                                    .CupertinoColors
                                    .quaternarySystemFill,
                                child: const Text('Next'),
                              ),
                            ),
                    ),
                    AdaptiveElevatedButton(
                      key: const ValueKey('new elevated'),
                      color: color,
                      onPressed: pressed,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      for (final kind in ['icon', 'custom icon', 'text', 'elevated']) {
        expect(
          tester.getSize(find.byKey(ValueKey('new $kind'))),
          tester.getSize(find.byKey(ValueKey('old $kind'))),
        );
        await tester.tap(find.byKey(ValueKey('new $kind')));
        await tester.pumpAndSettle();
      }
      expect(presses, 4);

      if (platform == TargetPlatform.android) {
        final button = tester.widget<material.ElevatedButton>(
          find.descendant(
            of: find.byKey(const ValueKey('new elevated')),
            matching: find.byType(material.ElevatedButton),
          ),
        );
        expect(button.style!.backgroundColor!.resolve({}), color);
      } else {
        final button = tester.widget<cupertino.CupertinoButton>(
          find.descendant(
            of: find.byKey(const ValueKey('new elevated')),
            matching: find.byType(cupertino.CupertinoButton),
          ),
        );
        expect(button.color, color);
      }
    });

    testWidgets('action button follows theme and disabled state on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final mode = ValueNotifier(legacy.ThemeMode.light);
      addTearDown(mode.dispose);
      var presses = 0;
      await tester.pumpWidget(
        ValueListenableBuilder<legacy.ThemeMode>(
          valueListenable: mode,
          builder: (_, themeMode, _) => legacy.MaterialApp(
            theme: gloom.lightTheme().copyWith(platform: platform),
            darkTheme: gloom.darkTheme().copyWith(platform: platform),
            themeMode: themeMode,
            builder: (_, child) => TransitionTheme(child: child!),
            home: legacy.Scaffold(
              body: Column(
                children: [
                  ActionButton(label: 'Enabled', onPressed: () => presses++),
                  const ActionButton(label: 'Disabled', onPressed: null),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Enabled'));
      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();
      expect(presses, 1);
      Color? backgroundColor() {
        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Enabled'),
                matching: find.byType(Container),
              )
              .first,
        );
        return (container.decoration! as BoxDecoration).color;
      }

      expect(backgroundColor(), gloom.lightTheme().colorScheme.primary);
      mode.value = legacy.ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(backgroundColor(), gloom.darkTheme().colorScheme.primary);
      expect(
        tester.widget<Text>(find.text('Enabled')).style!.color,
        gloom.darkTheme().colorScheme.onPrimary,
      );
      expect(
        tester.widget<Text>(find.text('Disabled')).style!.color,
        gloom.darkTheme().colorScheme.onSurface.withValues(alpha: 0.38),
      );
    });
  }

  testWidgets('adaptive menu still opens and invokes its action', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final mode = ValueNotifier(legacy.ThemeMode.light);
    addTearDown(mode.dispose);
    var presses = 0;
    await tester.pumpWidget(
      ValueListenableBuilder<legacy.ThemeMode>(
        valueListenable: mode,
        builder: (_, themeMode, _) => legacy.MaterialApp(
          theme: gloom.lightTheme().copyWith(platform: TargetPlatform.android),
          darkTheme: gloom.darkTheme().copyWith(
            platform: TargetPlatform.android,
          ),
          themeMode: themeMode,
          builder: (_, child) => TransitionTheme(child: child!),
          home: legacy.Scaffold(
            body: AdaptiveMenu(
              icon: const Icon(legacy.Icons.more_vert),
              menuChildren: [
                AdaptiveMenuItem(
                  icon: const Icon(legacy.Icons.edit),
                  title: 'Edit',
                  onPressed: () => presses++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(legacy.Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.byType(material.MenuItemButton), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Edit')).style!.color,
      gloom.lightTheme().textTheme.titleLarge!.color,
    );
    mode.value = legacy.ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Edit')).style!.color,
      gloom.darkTheme().textTheme.titleLarge!.color,
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(presses, 1);
  });
}
