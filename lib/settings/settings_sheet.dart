import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/timer.dart';
import 'package:q_master/ui/adaptive_icons.dart';
import 'package:q_master/ui/adaptive_modal_sheet.dart';
import 'package:q_master/utils/datetime_utils.dart';
import 'package:q_master/utils/shared_app_prefs.dart';

final class SettingsActionButton extends StatelessWidget {
  const SettingsActionButton({super.key});

  @override
  Widget build(BuildContext context) => PlatformIconButton(
    padding: Theme.of(context).platform == TargetPlatform.iOS
        ? EdgeInsets.only(right: 22)
        : EdgeInsets.zero,
    icon: Icon(context.platformIcons.gearSolid),
    onPressed: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      await showAdaptiveModalSheet(
        context: navigator.context,
        child: const _SettingsSheet(),
      );
    },
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();
  static const _minimumTimePeriodSeconds = 5;

  Future<void> _showAboutDialog(BuildContext context) async {
    final l10n = L10n.of(context)!;
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    return showAdaptiveAboutDialog(
      context: context,
      applicationName: L10n.of(context)!.appBarTitle,
      applicationVersion:
          'Version: ${packageInfo.version}\nBuild:${packageInfo.buildNumber}',
      applicationIcon: Image.asset(
        'assets/icon/app_icon.png',
        width: 48.0,
        height: 48.0,
      ),
      children: [
        SizedBox(height: 180, child: Text(l10n.settingsAboutDialogDescription)),
      ],
    );
  }

  Widget _content(
    BuildContext context, {
    required SharedAppPrefs prefs,
    required WidgetRef ref,
  }) {
    final l10n = L10n.of(context)!;
    final timer = ref.read(timerProvider.notifier);
    final timeIntervalSettings = [
      (
        prefs.prepareIntervalSeconds,
        L10n.of(context)!.timerSettingsPrepareLabel,
      ),
      (prefs.workIntervalSeconds, L10n.of(context)!.timerSettingsWorkLabel),
      (prefs.restIntervalSeconds, L10n.of(context)!.timerSettingsRestLabel),
    ];
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: PlatformText(
              l10n.workoutsSettingsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListenableBuilder(
            listenable: prefs.exercisesPerPage,
            builder: (_, _) => PlatformListTile(
              title: Text(
                L10n.of(context)!.exercisesPerPageSettingsLabel,

                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Slider.adaptive(
                value: prefs.exercisesPerPage.value.toDouble(),
                min: 1,
                max: 30,
                divisions: 30,
                onChanged: (value) =>
                    prefs.exercisesPerPage.value = value.round(),
              ),
              trailing: Text(
                prefs.exercisesPerPage.value.toString(),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(fontSize: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: const Divider(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: PlatformText(
              l10n.timerSettingsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListenableBuilder(
            listenable: prefs.timerType,
            builder: (_, _) => SegmentedButton(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text(l10n.timerTypeStopwatchLabel),
                ),
                ButtonSegment(value: 1, label: Text(l10n.timerTypeTabataLabel)),
              ],
              selected: {prefs.timerType.value},
              onSelectionChanged: (newSelection) {
                prefs.timerType.value = newSelection.single;
                timer.reset();
              },
            ),
          ),
          SizedBox(height: 8),
          for (final (intervalNotifier, label) in timeIntervalSettings)
            ListenableBuilder(
              listenable: intervalNotifier,
              builder: (_, _) => PlatformListTile(
                title: PlatformText(
                  label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                trailing: PlatformText(
                  formatDuration(Duration(seconds: intervalNotifier.value)),
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                onTap: () => _showTimeIntervalPicker(
                  context,
                  timeNotifier: intervalNotifier,
                  timer: timer,
                ),
              ),
            ),
          ListenableBuilder(
            listenable: prefs.rounds,
            builder: (_, _) => PlatformListTile(
              title: PlatformText(
                l10n.timerSettingsRoundsLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: PlatformText(
                prefs.rounds.value.toString(),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              onTap: () => _showRoundsPicker(
                context,
                roundsNotifier: prefs.rounds,
                timer: timer,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: prefs.cycles,
            builder: (_, _) => PlatformListTile(
              title: PlatformText(
                l10n.timerSettingsCyclesLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: PlatformText(
                prefs.cycles.value.toString(),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              onTap: () => _showRoundsPicker(
                context,
                roundsNotifier: prefs.cycles,
                timer: timer,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: const Divider(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: PlatformText(
              l10n.themeSettingsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListenableBuilder(
            listenable: prefs.theme,
            builder: (_, _) => SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSettingsSystemLabel),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeSettingsLightLabel),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeSettingsDarkLabel),
                ),
              ],
              selected: {ThemeMode.values[prefs.theme.value]},
              onSelectionChanged: (newSelection) {
                prefs.theme.value = newSelection.single.index;
                timer.reset();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: const Divider(),
          ),
          PlatformListTile(
            title: PlatformText(l10n.appBarTitle),
            leading: Icon(context.platformIcons.info),
            onTap: () => _showAboutDialog(context),
          ),
        ]),
      ),
    );
  }

  void _showTimeIntervalPicker(
    BuildContext context, {
    required ValueNotifier<int> timeNotifier,
    required Timer timer,
  }) => showPlatformModalSheet(
    context: context,
    material: MaterialModalSheetData(
      constraints: BoxConstraints.tight(Size.fromHeight(250)),
    ),
    builder: (context) => SafeArea(
      child: CupertinoTimerPicker(
        mode: .ms,
        alignment: .bottomCenter,
        itemExtent: 60,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        initialTimerDuration: Duration(seconds: timeNotifier.value),
        onTimerDurationChanged: (newDuration) {
          timeNotifier.value = max(
            newDuration.inSeconds,
            _minimumTimePeriodSeconds,
          );
          timer.reset();
        },
      ),
    ),
  );

  void _showRoundsPicker(
    BuildContext context, {
    required ValueNotifier<int> roundsNotifier,
    required Timer timer,
  }) => showPlatformModalSheet(
    context: context,
    material: MaterialModalSheetData(
      constraints: BoxConstraints.tight(Size.fromHeight(250)),
    ),
    builder: (context) => SafeArea(
      child: SizedBox(
        height: 250,
        child: CupertinoPicker(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          itemExtent: 60,
          scrollController: FixedExtentScrollController(
            initialItem: roundsNotifier.value - 1,
          ),
          onSelectedItemChanged: (index) {
            roundsNotifier.value = index + 1;
            timer.reset();
          },
          children: List.generate(
            10,
            (index) => Center(
              child: Text(
                (index + 1).toString(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = SharedAppPrefs.instance;
    return PlatformScaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: ClampingScrollPhysics(),
          slivers: [
            PlatformSliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: PlatformIconButton(
                padding: Theme.of(context).platform == TargetPlatform.iOS
                    ? EdgeInsets.only(right: 24)
                    : EdgeInsets.zero,
                icon: Icon(AdaptiveIcons.close),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(L10n.of(context)!.settingsDialogTitle),
            ),
            _content(context, prefs: prefs, ref: ref),
          ],
        ),
      ),
    );
  }
}
