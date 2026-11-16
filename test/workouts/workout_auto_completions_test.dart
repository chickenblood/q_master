import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/exicon.dart';
import 'package:q_master/services/exicon_fetcher.dart';
import 'package:q_master/theme/theme.dart' as gloom;
import 'package:q_master/theme/transition_theme.dart';
import 'package:q_master/workouts/workout_auto_completions.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('autocomplete selects an exercise on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exiconFetcherProvider.overrideWithBuild(
              (_, _) async => [
                const ExiconEntry(name: 'Merkin'),
                const ExiconEntry(name: 'Squat'),
              ],
            ),
          ],
          child: legacy.MaterialApp(
            theme: gloom.darkTheme().copyWith(platform: platform),
            localizationsDelegates: [
              ...L10n.localizationsDelegates,
              material.GlobalMaterialLocalizations.delegate,
              cupertino.GlobalCupertinoLocalizations.delegate,
            ],
            builder: (_, child) => TransitionTheme(child: child!),
            home: legacy.Scaffold(
              body: WorkoutAutocompleteTextField(
                textEditingController: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Mer');
      await tester.pumpAndSettle();
      expect(find.byType(material.Autocomplete<String>), findsOneWidget);
      final option = find.text('Merkin', findRichText: true);
      expect(option, findsOneWidget);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(controller.text, 'Merkin');
      expect(controller.selection.baseOffset, 'Merkin'.length);
    });
  }
}
