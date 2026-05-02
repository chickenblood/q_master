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
import '../ui/action_button.dart';
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
        title: Text(
          l10n.timerSetupTabTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.6),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: const SettingsActionButton(),
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    prefs.timerType,
                    prefs.prepareIntervalSeconds,
                    prefs.workIntervalSeconds,
                    prefs.restIntervalSeconds,
                    prefs.rounds,
                  ]),
                  builder: (context, _) => Column(
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
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.timerModeLabel
                                    .toUpperCase(), // Localized: "Mode"
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .1,
                                  color: Theme.of(context).colorScheme.primary,
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
                                  showSelectedIcon: false,
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
                            color: Theme.of(context).colorScheme.outlineVariant,
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
                                color: Theme.of(context).colorScheme.surface,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                              child: Text(
                                l10n.timerIntervalsLabel
                                    .toUpperCase(), // Localized: "Intervals — tap to change"
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .1,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            _IntervalSetupRow(
                              label: l10n.timerSettingsPrepareLabel,
                              value: formatDuration(
                                Duration(
                                  seconds: prefs.prepareIntervalSeconds.value,
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
                                  seconds: prefs.workIntervalSeconds.value,
                                ),
                              ),
                              valueColor: TimerColors.workFg(context),
                              onTap: () => _showTimeIntervalPicker(
                                context,
                                prefs.workIntervalSeconds,
                                timer,
                              ),
                            ),
                            if (prefs.timerType.value ==
                                TimerType
                                    .tabata
                                    .index) // Only show rest interval for Tabata
                              _IntervalSetupRow(
                                label: l10n.timerSettingsRestLabel,
                                value: formatDuration(
                                  Duration(
                                    seconds: prefs.restIntervalSeconds.value,
                                  ),
                                ),
                                valueColor: TimerColors.restFg(context),
                                onTap: () => _showTimeIntervalPicker(
                                  context,
                                  prefs.restIntervalSeconds,
                                  timer,
                                ),
                              ),
                            if (prefs.timerType.value == TimerType.tabata.index)
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: SizedBox(
                height: 62,
                child: ActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      platformPageRoute(
                        context: context,
                        builder: (_) => const TimerScreen(),
                      ),
                    );
                  },
                  label: l10n.timerStartButtonLabel,
                  icon: context.platformIcons.playArrowSolid,
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
              ? Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
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
