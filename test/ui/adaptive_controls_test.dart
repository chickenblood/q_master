import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/theme/theme.dart' as gloom;
import 'package:q_master/theme/transition_theme.dart';
import 'package:q_master/ui/adaptive_button_bar.dart';
import 'package:q_master/ui/adaptive_nav_text_field.dart';
import 'package:q_master/ui/adaptive_segmented_control.dart';
import 'package:q_master/ui/adaptive_slider.dart';
import 'package:q_master/ui/adaptive_switch.dart';
import 'package:q_master/ui/dismissible_row.dart';
import 'package:q_master/ui/expandable_fab.dart' as fab;

void main() {
  testWidgets('expandable FAB opens and invokes an action', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      legacy.MaterialApp(
        theme: gloom.darkTheme(),
        builder: (_, child) => TransitionTheme(child: child!),
        home: legacy.Scaffold(
          body: SizedBox(
            height: 300,
            width: 300,
            child: fab.ExpandableFab(
              distance: 100,
              children: [
                fab.ActionButton(
                  label: 'Create',
                  icon: const Icon(material.Icons.edit),
                  onPressed: () => presses++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(material.Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(material.Icons.edit));
    await tester.pumpAndSettle();
    expect(presses, 1);
    await tester.tap(find.byIcon(material.Icons.close));
    await tester.pumpAndSettle();
  });

  testWidgets('dismissible row follows the theme and dismisses', (
    tester,
  ) async {
    const lightError = Color(0xff9a1234);
    const darkError = Color(0xffef5678);
    final mode = ValueNotifier(legacy.ThemeMode.light);
    final dismissed = ValueNotifier(false);
    addTearDown(mode.dispose);
    addTearDown(dismissed.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<legacy.ThemeMode>(
        valueListenable: mode,
        builder: (_, themeMode, _) => legacy.MaterialApp(
          theme: gloom.lightTheme(),
          darkTheme: gloom.darkTheme(),
          themeMode: themeMode,
          builder: (_, child) => TransitionTheme(
            child: Builder(
              builder: (context) {
                final theme = material.Theme.of(context);
                return material.Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      error: themeMode == legacy.ThemeMode.light
                          ? lightError
                          : darkError,
                    ),
                  ),
                  child: child!,
                );
              },
            ),
          ),
          home: legacy.Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: dismissed,
              builder: (_, isDismissed, _) => isDismissed
                  ? const SizedBox()
                  : DismissibleRow(
                      key: const ValueKey('row'),
                      onDismissed: (_) => dismissed.value = true,
                      child: const SizedBox(height: 60, child: Text('Workout')),
                    ),
            ),
          ),
        ),
      ),
    );

    Color? backgroundColor() =>
        (tester.widget<Dismissible>(find.byType(Dismissible)).background!
                as Container)
            .color;
    expect(backgroundColor(), lightError);
    mode.value = legacy.ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(backgroundColor(), darkError);
    await tester.drag(find.text('Workout'), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(dismissed.value, isTrue);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'adaptive controls retain interactions and theme on $platform',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final mode = ValueNotifier(legacy.ThemeMode.light);
        final controller = TextEditingController();
        addTearDown(mode.dispose);
        addTearDown(controller.dispose);
        double? sliderValue;
        bool? switchValue;
        int? selected;
        var buttonPresses = 0;

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
              builder: (_, child) => TransitionTheme(child: child!),
              home: legacy.Scaffold(
                body: Column(
                  children: [
                    SizedBox(
                      width: 300,
                      child: AdaptiveSlider(onChanged: (v) => sliderValue = v),
                    ),
                    AdaptiveSwitch(
                      value: false,
                      onChanged: (v) => switchValue = v,
                    ),
                    AdaptiveSegmentedControl(
                      segments: const [
                        AdaptiveSegment(label: 'Light'),
                        AdaptiveSegment(label: 'Dark'),
                      ],
                      onSegmentSelected: (v) => selected = v,
                    ),
                    AdaptiveNavTextField(controller: controller),
                    AdaptiveButtonBar(
                      items: [
                        AdaptiveButtonBarItem(
                          icon: const Icon(material.Icons.play_arrow),
                          onPressed: () => buttonPresses++,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final slider = platform == TargetPlatform.android
            ? find.byType(material.Slider)
            : find.byType(glass.GlassSlider);
        final toggle = platform == TargetPlatform.android
            ? find.byType(material.Switch)
            : find.byType(glass.GlassSwitch);
        final field = platform == TargetPlatform.android
            ? find.byType(material.TextField)
            : find.byType(glass.GlassTextField);
        await tester.drag(slider, const Offset(45, 0));
        await tester.tap(toggle);
        await tester.tap(find.text('Dark'));
        await tester.enterText(field, 'Merkin');
        await tester.tap(find.byIcon(material.Icons.play_arrow));
        await tester.pumpAndSettle();
        expect(sliderValue, isNotNull);
        expect(switchValue, isTrue);
        expect(selected, 1);
        expect(controller.text, 'Merkin');
        expect(buttonPresses, 1);

        mode.value = legacy.ThemeMode.dark;
        await tester.pumpAndSettle();
        if (platform == TargetPlatform.iOS) {
          expect(
            tester.widget<glass.GlassSlider>(slider).activeColor,
            gloom.darkTheme().colorScheme.primary,
          );
          expect(
            tester
                .widget<glass.GlassSegmentedControl>(
                  find.byType(glass.GlassSegmentedControl),
                )
                .indicatorColor,
            gloom.darkTheme().colorScheme.primary,
          );
        } else {
          expect(
            material.Theme.of(tester.element(slider)).brightness,
            Brightness.dark,
          );
        }
        expect(controller.text, 'Merkin');
      },
    );
  }
}
