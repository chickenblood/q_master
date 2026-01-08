import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/ui/adaptive_icons.dart';
import 'package:q_master/utils/datetime_utils.dart';
import 'package:q_master/utils/shared_app_prefs.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  Future<void> _showAboutDialog(BuildContext context) async {
    final l10n = L10n.of(context)!;
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    return showAdaptiveAboutDialog(
      context: context,
      applicationName: L10n.of(context)!.appBarTitle,
      applicationVersion: packageInfo.version,
      applicationIcon: Image.asset(
        'assets/icon/app_icon.png',
        width: 48.0,
        height: 48.0,
      ),
      children: [Text(l10n.settingsAboutDialogDescription)],
    );
  }

  Widget _content(BuildContext context, {required SharedAppPrefs prefs}) {
    final l10n = L10n.of(context)!;
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
              title: Text(L10n.of(context)!.exercisesPerPageSettingsLabel),
              subtitle: Slider.adaptive(
                value: prefs.exercisesPerPage.value.toDouble(),
                min: 1,
                max: 30,
                divisions: 30,
                onChanged: (value) =>
                    prefs.exercisesPerPage.value = value.round(),
              ),
              trailing: Text(prefs.exercisesPerPage.value.toString()),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: PlatformText(
              l10n.timerSettingsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListenableBuilder(
            listenable: prefs.prepareIntervalSeconds,
            builder: (_, _) => PlatformListTile(
              title: PlatformText(
                l10n.timerSettingsPrepareLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: PlatformText(
                formatSeconds(prefs.prepareIntervalSeconds.value),
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              onTap: () => _showTimeIntervalPicker(
                context,
                timeNotifier: prefs.prepareIntervalSeconds,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: prefs.workIntervalSeconds,
            builder: (_, _) => PlatformListTile(
              title: PlatformText(
                l10n.timerSettingsWorkLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: PlatformText(
                formatSeconds(prefs.workIntervalSeconds.value),
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              onTap: () => _showTimeIntervalPicker(
                context,
                timeNotifier: prefs.workIntervalSeconds,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: prefs.restIntervalSeconds,
            builder: (_, _) => PlatformListTile(
              title: PlatformText(
                l10n.timerSettingsRestLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: PlatformText(
                formatSeconds(prefs.restIntervalSeconds.value),
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              onTap: () => _showTimeIntervalPicker(
                context,
                timeNotifier: prefs.restIntervalSeconds,
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
              onTap: () =>
                  _showRoundsPicker(context, roundsNotifier: prefs.rounds),
            ),
          ),
          const Divider(),
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
  }) => showPlatformModalSheet(
    context: context,
    material: MaterialModalSheetData(
      constraints: BoxConstraints.tight(Size.fromHeight(250)),
    ),
    builder: (context) => CupertinoTimerPicker(
      mode: .ms,
      alignment: .bottomCenter,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      initialTimerDuration: Duration(seconds: timeNotifier.value),
      onTimerDurationChanged: (newDuration) =>
          timeNotifier.value = max(newDuration.inSeconds, 5),
    ),
  );

  void _showRoundsPicker(
    BuildContext context, {
    required ValueNotifier<int> roundsNotifier,
  }) => showPlatformModalSheet(
    context: context,
    material: MaterialModalSheetData(
      constraints: BoxConstraints.tight(Size.fromHeight(250)),
    ),
    builder: (context) => SizedBox(
      height: 250,
      child: CupertinoPicker(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        itemExtent: 32,
        scrollController: FixedExtentScrollController(
          initialItem: roundsNotifier.value - 1,
        ),
        onSelectedItemChanged: (index) => roundsNotifier.value = index + 1,
        looping: true,
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
  );

  @override
  Widget build(BuildContext context) {
    final prefs = SharedAppPrefs.instance;
    return PlatformScaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: ClampingScrollPhysics(),
          slivers: [
            PlatformSliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: PlatformIconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(AdaptiveIcons.close),
              ),
              title: Text(L10n.of(context)!.settingsDialogTitle),
            ),
            _content(context, prefs: prefs),
          ],
        ),
      ),
    );
  }
}
