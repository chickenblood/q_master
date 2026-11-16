import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as legacy_cupertino;
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/theme/theme.dart' as gloom;
import 'package:q_master/theme/transition_theme.dart';
import 'package:q_master/ui/adaptive_list_tile.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('list tile preserves layout and tap behavior on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final mode = ValueNotifier(legacy.ThemeMode.light);
      addTearDown(mode.dispose);
      var presses = 0;
      const padding = EdgeInsets.only(left: 0, right: 8);

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
                  SizedBox(
                    key: const ValueKey('old tile'),
                    width: 300,
                    child: platform == TargetPlatform.android
                        ? legacy.ListTile(
                            title: const Text(
                              'Exercise',
                              key: ValueKey('old title'),
                            ),
                            trailing: const Icon(legacy.Icons.check),
                            onTap: () => presses++,
                            contentPadding: padding,
                          )
                        : legacy_cupertino.CupertinoListTile(
                            title: const Text(
                              'Exercise',
                              key: ValueKey('old title'),
                            ),
                            trailing: const Icon(legacy.Icons.check),
                            onTap: () => presses++,
                            padding: padding,
                          ),
                  ),
                  SizedBox(
                    key: const ValueKey('new tile'),
                    width: 300,
                    child: AdaptiveListTile(
                      title: const Text('Exercise', key: ValueKey('new title')),
                      trailing: const Icon(legacy.Icons.check),
                      padding: padding,
                      onTap: () => presses++,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      void expectParity() {
        expect(
          tester.getSize(find.byKey(const ValueKey('new tile'))),
          tester.getSize(find.byKey(const ValueKey('old tile'))),
        );
        final oldContext = tester.element(
          find.byKey(const ValueKey('old title')),
        );
        final newContext = tester.element(
          find.byKey(const ValueKey('new title')),
        );
        final oldStyle = DefaultTextStyle.of(oldContext).style;
        final newStyle = DefaultTextStyle.of(newContext).style;
        expect(newStyle.fontFamily, oldStyle.fontFamily);
        expect(newStyle.fontSize, oldStyle.fontSize);
        expect(newStyle.fontWeight, oldStyle.fontWeight);
        expect(newStyle.letterSpacing, oldStyle.letterSpacing);
        if (platform == TargetPlatform.android) {
          expect(newStyle.color, oldStyle.color);
          expect(
            material.Theme.of(newContext).brightness,
            mode.value == legacy.ThemeMode.dark
                ? Brightness.dark
                : Brightness.light,
          );
        } else {
          expect(
            cupertino.CupertinoDynamicColor.resolve(
              newStyle.color!,
              newContext,
            ).toARGB32(),
            legacy_cupertino.CupertinoDynamicColor.resolve(
              oldStyle.color!,
              oldContext,
            ).toARGB32(),
          );
          expect(
            cupertino.CupertinoTheme.of(newContext).brightness,
            mode.value == legacy.ThemeMode.dark
                ? Brightness.dark
                : Brightness.light,
          );
        }
      }

      expectParity();
      await tester.tap(find.byKey(const ValueKey('new tile')));
      await tester.pumpAndSettle();
      expect(presses, 1);
      mode.value = legacy.ThemeMode.dark;
      await tester.pumpAndSettle();
      expectParity();
    });
  }
}
