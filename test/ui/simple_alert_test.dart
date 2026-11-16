import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/theme/theme.dart' as gloom;
import 'package:q_master/theme/transition_theme.dart';
import 'package:q_master/ui/simple_alert.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('HTML alert follows theme changes on $platform', (
      tester,
    ) async {
      const lightText = Color(0xff123456);
      const darkText = Color(0xffabcdef);
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final mode = ValueNotifier(legacy.ThemeMode.light);
      addTearDown(mode.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<legacy.ThemeMode>(
          valueListenable: mode,
          builder: (_, themeMode, _) => legacy.MaterialApp(
            theme: gloom.lightTheme().copyWith(platform: platform),
            darkTheme: gloom.darkTheme().copyWith(platform: platform),
            themeMode: themeMode,
            localizationsDelegates: [
              ...L10n.localizationsDelegates,
              material.GlobalMaterialLocalizations.delegate,
              cupertino.GlobalCupertinoLocalizations.delegate,
            ],
            builder: (_, child) => TransitionTheme(
              child: Builder(
                builder: (context) {
                  final theme = material.Theme.of(context);
                  return material.Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        onSurface: themeMode == legacy.ThemeMode.light
                            ? lightText
                            : darkText,
                      ),
                    ),
                    child: child!,
                  );
                },
              ),
            ),
            home: legacy.Scaffold(
              body: Builder(
                builder: (context) => legacy.TextButton(
                  onPressed: () => showSimpleAlert(
                    context,
                    title: 'Exercise',
                    message: '<p>Do a merkin</p>',
                  ),
                  child: const Text('Open alert'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open alert'));
      await tester.pumpAndSettle();

      Color? textColor() =>
          tester.widget<HtmlWidget>(find.byType(HtmlWidget)).textStyle?.color;
      expect(textColor(), lightText);
      mode.value = legacy.ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(textColor(), darkText);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(HtmlWidget), findsNothing);
    });
  }
}
