import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/utils/shared_app_prefs.dart';

import '../l10n/l10n.dart';
import '../model/timer.dart';
import '../settings/settings_sheet.dart';
import '../theme/theme.dart';
import '../utils/datetime_utils.dart';
import 'timer_tab.dart';

/// TimerSetupTab — matches Option 3 "Timer Tab (Setup-First)" mock
class TimerSetupTab extends ConsumerWidget {
  void _showTimeIntervalPicker(
    BuildContext context,
    ValueNotifier<int> timeNotifier,
    Timer timer,
  ) {
    showPlatformModalSheet(
      context: context,
      material: MaterialModalSheetData(
        constraints: BoxConstraints.tight(const Size.fromHeight(250)),
      ),
      builder: (context) => SafeArea(
        child: CupertinoTimerPicker(
          mode: CupertinoTimerPickerMode.ms,
          alignment: Alignment.bottomCenter,
          itemExtent: 60,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          initialTimerDuration: Duration(seconds: timeNotifier.value),
          onTimerDurationChanged: (newDuration) {
            timeNotifier.value = max(newDuration.inSeconds, 1);
            timer.reset();
          },
        ),
      ),
    );
  }

  void _showRoundsPicker(
    BuildContext context,
    ValueNotifier<int> roundsNotifier,
    Timer timer,
  ) {
    showPlatformModalSheet(
      context: context,
      material: MaterialModalSheetData(
        constraints: BoxConstraints.tight(const Size.fromHeight(250)),
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
              20,
              (i) => Center(
                child: Text('${i + 1}', style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  const TimerSetupTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final timer = ref.read(timerProvider.notifier);
    final prefs = SharedAppPrefs.instance;
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(l10n.timerTabTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
        material: (_, _) => MaterialAppBarData(
          elevation: 0,
          leading: const SettingsActionButton(),
        ),
        cupertino: (_, _) => CupertinoNavigationBarData(
          backgroundColor: Theme.of(context).colorScheme.surface,
          leading: const SettingsActionButton(),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: ValueListenableBuilder(
                  valueListenable: prefs.prepareIntervalSeconds,
                  builder: (context, _, _) => ValueListenableBuilder(
                    valueListenable: prefs.workIntervalSeconds,
                    builder: (context, _, _) => ValueListenableBuilder(
                      valueListenable: prefs.restIntervalSeconds,
                      builder: (context, _, _) => ValueListenableBuilder(
                        valueListenable: prefs.rounds,
                        builder: (context, _, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mode selector
                            Card(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.timerModeLabel, // Localized: "Mode"
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .1,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        height: 1.2,
                                        textBaseline: TextBaseline.alphabetic,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: SegmentedButton<int>(
                                        segments: [
                                          ButtonSegment(
                                            value: 0,
                                            label: Text(
                                              l10n.timerTypeStopwatchLabel,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ),
                                          ButtonSegment(
                                            value: 1,
                                            label: Text(
                                              l10n.timerTypeTabataLabel,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ),
                                        ],
                                        selected: {prefs.timerType.value},
                                        onSelectionChanged: (newSelection) {
                                          prefs.timerType.value =
                                              newSelection.single;
                                          timer.reset();
                                        },
                                        showSelectedIcon: false,
                                        style: SegmentedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor:
                                              TimerColors.controlFg(context),
                                          selectedForegroundColor: Colors.white,
                                          selectedBackgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          side: BorderSide(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF252525)
                                                : const Color(0xFFDADADA),
                                            width: 1.5,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 0,
                                            vertical: 10,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.1,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Interval card
                            Card(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outlineVariant,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.timerIntervalsLabel, // Localized: "Intervals — tap to change"
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .1,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  _IntervalSetupRow(
                                    label: l10n.timerSettingsPrepareLabel,
                                    value: formatDuration(
                                      Duration(
                                        seconds:
                                            prefs.prepareIntervalSeconds.value,
                                      ),
                                    ),
                                    valueColor: TimerColors.prepareFg(context),
                                    onTap: () => _showTimeIntervalPicker(
                                      context,
                                      prefs.prepareIntervalSeconds,
                                      timer,
                                    ),
                                  ),
                                  _IntervalSetupRow(
                                    label: l10n.timerSettingsWorkLabel,
                                    value: formatDuration(
                                      Duration(
                                        seconds:
                                            prefs.workIntervalSeconds.value,
                                      ),
                                    ),
                                    valueColor: TimerColors.workFg(context),
                                    onTap: () => _showTimeIntervalPicker(
                                      context,
                                      prefs.workIntervalSeconds,
                                      timer,
                                    ),
                                  ),
                                  _IntervalSetupRow(
                                    label: l10n.timerSettingsRestLabel,
                                    value: formatDuration(
                                      Duration(
                                        seconds:
                                            prefs.restIntervalSeconds.value,
                                      ),
                                    ),
                                    valueColor: TimerColors.restFg(context),
                                    onTap: () => _showTimeIntervalPicker(
                                      context,
                                      prefs.restIntervalSeconds,
                                      timer,
                                    ),
                                  ),
                                  _IntervalSetupRow(
                                    label: l10n.timerSettingsRoundsLabel,
                                    value: prefs.rounds.value.toString(),
                                    valueColor: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    onTap: () => _showRoundsPicker(
                                      context,
                                      prefs.rounds,
                                      timer,
                                    ),
                                    showDivider: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                height: 62,
                child: PlatformElevatedButton(
                  color: Theme.of(context).colorScheme.primary,
                  material: (_, _) => MaterialElevatedButtonData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                      ),
                      minimumSize: const Size.fromHeight(62),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  cupertino: (_, _) => CupertinoElevatedButtonData(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      platformPageRoute(
                        context: context,
                        builder: (_) => const TimerScreen(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        context.platformIcons.playArrowSolid,
                        size: 26,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.timerStartButtonLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntervalSetupRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback onTap;
  final bool showDivider;

  const _IntervalSetupRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: Color(0xFF1a1a1a)))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            // Chevron removed per mock
          ],
        ),
      ),
    );
  }
}
