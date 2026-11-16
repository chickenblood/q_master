import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/slack/slackblast_search_field.dart';
import 'package:q_master/theme/theme.dart' as gloom;
import 'package:q_master/theme/transition_theme.dart';
import 'package:q_master/ui/adaptive_activity_indicator.dart';
import 'package:q_master/ui/adaptive_text_field.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('activity indicator uses split widgets on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        legacy.MaterialApp(
          theme: gloom.darkTheme().copyWith(platform: platform),
          builder: (_, child) => TransitionTheme(child: child!),
          home: const legacy.Scaffold(body: AdaptiveActivityIndicator()),
        ),
      );
      expect(
        platform == TargetPlatform.android
            ? find.byType(material.CircularProgressIndicator)
            : find.byType(cupertino.CupertinoActivityIndicator),
        findsOneWidget,
      );
    });

    testWidgets('multiline field forwards editing callbacks on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var completed = 0;
      String? submitted;

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
            body: AdaptiveTextField(
              controller: controller,
              minLines: 2,
              maxLines: 3,
              onEditingComplete: () => completed++,
              onSubmitted: (value) => submitted = value,
            ),
          ),
        ),
      );
      final field = platform == TargetPlatform.android
          ? find.byType(material.TextField)
          : find.byType(cupertino.CupertinoTextField);
      await tester.enterText(field, 'Burpees');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(completed, 1);
      expect(submitted, 'Burpees');
    });

    testWidgets('search field keeps clear and theme behavior on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final mode = ValueNotifier(legacy.ThemeMode.light);
      final controller = TextEditingController();
      final focusNode = FocusNode();
      final changes = <String>[];
      addTearDown(mode.dispose);
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

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
            supportedLocales: L10n.supportedLocales,
            builder: (_, child) => TransitionTheme(child: child!),
            home: legacy.Scaffold(
              body: SlackblastSearchField(
                controller: controller,
                focusNode: focusNode,
                hintText: 'Search',
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      );
      final field = platform == TargetPlatform.android
          ? find.byType(material.TextField)
          : find.byType(cupertino.CupertinoTextField);
      await tester.enterText(field, 'Merkin');
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
      expect(changes.last, 'Merkin');

      mode.value = legacy.ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(controller.text, 'Merkin');
      expect(focusNode.hasFocus, isTrue);
      if (platform == TargetPlatform.android) {
        final decoration = tester.widget<material.TextField>(field).decoration!;
        expect(
          decoration.focusedBorder!.borderSide.color,
          gloom.darkTheme().colorScheme.primary,
        );
        await tester.tap(find.byIcon(material.Icons.clear));
      } else {
        final context = tester.element(field);
        expect(
          cupertino.CupertinoTheme.of(context).brightness,
          Brightness.dark,
        );
        await tester.tap(
          find.byIcon(cupertino.CupertinoIcons.clear_thick_circled),
        );
      }
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(changes.last, isEmpty);
    });
  }
}
