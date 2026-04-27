import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/l10n.dart';
import '../model/timer.dart';
import '../theme/theme.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_modal_sheet.dart';
import '../ui/cupertino_sheet_fork.dart';
import '../utils/datetime_utils.dart';
import '../utils/shared_app_prefs.dart';

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
      return showAdaptiveModalSheet(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? const Color(0xFFD0D0D0)
        : const Color(0xFF333333);
    final valueColor = Theme.of(context).colorScheme.onSurface;
    final inactiveSegmentColor = isDark
        ? const Color(0xFF7A7A7A)
        : const Color(0xFF6F6F6F);
    final segmentBorderColor = isDark
        ? const Color(0xFF252525)
        : const Color(0xFFDADADA);
    final rowValueStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: valueColor,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    final rowLabelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 16,
      color: labelColor,
      fontWeight: FontWeight.w500,
    );
    final segmentedStyle = SegmentedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: inactiveSegmentColor,
      selectedForegroundColor: Colors.white,
      selectedBackgroundColor: Theme.of(context).colorScheme.primary,
      side: BorderSide(color: segmentBorderColor, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final timeIntervalSettings = [
      (
        prefs.prepareIntervalSeconds,
        L10n.of(context)!.timerSettingsPrepareLabel,
        TimerColors.prepareFg(context),
      ),
      (
        prefs.workIntervalSeconds,
        L10n.of(context)!.timerSettingsWorkLabel,
        TimerColors.workFg(context),
      ),
      (
        prefs.restIntervalSeconds,
        L10n.of(context)!.timerSettingsRestLabel,
        TimerColors.restFg(context),
      ),
    ];

    return ListenableBuilder(
      listenable: prefs,
      builder: (_, _) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _SettingsCard(
              header: l10n.workoutsSettingsTitle,
              child: _SettingsRow(
                label: l10n.exercisesPerPageSettingsLabel,
                labelStyle: rowLabelStyle,
                trailing: SizedBox(
                  width: 164,
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            Theme.of(context).platform ==
                                    TargetPlatform.android ||
                                Theme.of(context).platform ==
                                    TargetPlatform.fuchsia
                            ? SliderTheme(
                                data: SliderTheme.of(
                                  context,
                                ).copyWith(trackHeight: 7),
                                child: Slider(
                                  value: prefs.exercisesPerPage.value
                                      .toDouble(),
                                  min: 1,
                                  max: SharedAppPrefs.maxExercisesPerPage
                                      .toDouble(),
                                  divisions: 30,
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  inactiveColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.24),
                                  thumbColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  onChanged: (value) =>
                                      prefs.exercisesPerPage.value = value
                                          .round(),
                                ),
                              )
                            : Slider.adaptive(
                                value: prefs.exercisesPerPage.value.toDouble(),
                                min: 1,
                                max: SharedAppPrefs.maxExercisesPerPage
                                    .toDouble(),
                                divisions: 30,
                                activeColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                inactiveColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.24),
                                thumbColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                onChanged: (value) =>
                                    prefs.exercisesPerPage.value = value
                                        .round(),
                              ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          prefs.exercisesPerPage.value.toString(),
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.right,
                          style: rowValueStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _SettingsCard(
              header: l10n.timerSettingsTitle,
              child: Column(
                children: [
                  _SettingsRow(
                    label: l10n.timerTypeSettingsLabel,
                    labelStyle: rowLabelStyle,
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 190),
                      child: SegmentedButton<int>(
                        style: segmentedStyle,
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 0,
                            label: Text(l10n.timerTypeStopwatchLabel),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text(l10n.timerTypeTabataLabel),
                          ),
                        ],
                        selected: {prefs.timerType.value},
                        onSelectionChanged: (newSelection) {
                          prefs.timerType.value = newSelection.single;
                          timer.reset();
                        },
                      ),
                    ),
                  ),
                  for (final (intervalNotifier, label, color)
                      in timeIntervalSettings)
                    _SettingsRow(
                      label: label,
                      labelStyle: rowLabelStyle,
                      value: formatDuration(
                        Duration(seconds: intervalNotifier.value),
                      ),
                      valueStyle: rowValueStyle?.copyWith(color: color),
                      onTap: () => _showTimeIntervalPicker(
                        context,
                        timeNotifier: intervalNotifier,
                        timer: timer,
                      ),
                    ),
                  _SettingsRow(
                    label: l10n.timerSettingsRoundsLabel,
                    labelStyle: rowLabelStyle,
                    value: prefs.rounds.value.toString(),
                    valueStyle: rowValueStyle,
                    onTap: () => _showRoundsPicker(
                      context,
                      roundsNotifier: prefs.rounds,
                      timer: timer,
                    ),
                  ),
                  _SettingsRow(
                    label: l10n.timerSettingsCyclesLabel,
                    labelStyle: rowLabelStyle,
                    value: prefs.cycles.value.toString(),
                    valueStyle: rowValueStyle,
                    showDivider: false,
                    onTap: () => _showRoundsPicker(
                      context,
                      roundsNotifier: prefs.cycles,
                      timer: timer,
                    ),
                  ),
                ],
              ),
            ),
            _SettingsCard(
              header: l10n.generalSettingsTitle,
              child: Column(
                children: [
                  _SettingsRow(
                    label: l10n.themeSettingsTitle,
                    labelStyle: rowLabelStyle,
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: SegmentedButton<ThemeMode>(
                        style: segmentedStyle,
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
                  ),
                  _SettingsRow(
                    label: l10n.motorboatSoundSettingsLabel,
                    labelStyle: rowLabelStyle,
                    trailing: Switch.adaptive(
                      value: prefs.motorboatSoundEnabled.value,
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      activeColor: Colors.white,
                      onChanged: (value) =>
                          prefs.motorboatSoundEnabled.value = value,
                    ),
                  ),
                  _SettingsRow(
                    label: l10n.appBarTitle,
                    labelStyle: rowLabelStyle,
                    showDivider: false,
                    trailing: Icon(
                      context.platformIcons.info,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
          ]),
        ),
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
          physics: BottomSheetScrollPhysics(),
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

final class _SettingsCard extends StatelessWidget {
  final String header;
  final Widget child;

  const _SettingsCard({required this.header, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF);
    final cardBorder = isDark
        ? const Color(0xFF1C1C1C)
        : const Color(0xFFE8E8E8);
    final headerBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Text(
              header.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

final class _SettingsRow extends StatelessWidget {
  final String label;
  final String? value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Widget? trailing;
  final bool showDivider;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.label,
    this.value,
    this.labelStyle,
    this.valueStyle,
    this.trailing,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowBorder = isDark
        ? const Color(0xFF141414)
        : const Color(0xFFF0F0F0);

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: rowBorder))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: labelStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
            if (trailing == null && value != null)
              Text(value!, style: valueStyle),
          ],
        ),
      ),
    );
  }
}
