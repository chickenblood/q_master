import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:q_master/utils/shared_app_prefs.dart';

import '../l10n/l10n.dart';
import '../model/timer.dart';
import '../settings/settings_sheet.dart';
import '../theme/theme.dart';
import '../ui/action_button.dart';
import '../ui/media_query.dart';
import '../utils/datetime_utils.dart';
import 'timer_tab.dart';

/// TimerSetupTab — matches Option 3 "Timer Tab (Setup-First)" mock
class TimerSetupTab extends ConsumerWidget {
  const TimerSetupTab({super.key});

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
        bottom: false,
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

  void showIntegerPicker(
    BuildContext context,
    ValueNotifier<int> roundsNotifier,
    Timer timer,
    int maxValue,
  ) {
    showPlatformModalSheet(
      context: context,
      material: MaterialModalSheetData(
        constraints: BoxConstraints.tight(const Size.fromHeight(250)),
      ),
      builder: (context) => SafeArea(
        bottom: false,
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
              maxValue,
              (i) => Center(
                child: Text('${i + 1}', style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useBottomPadding =
        MediaUtils.isTablet(context) ||
        MediaQuery.of(context).orientation == .portrait;
    final l10n = L10n.of(context)!;
    final timer = ref.read(timerProvider.notifier);
    final prefs = SharedAppPrefs.instance;
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: Text(
          l10n.timerSetupTabTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.6),
        ),
        leading: [settingsGlassBarItem(id: 'left-item', context: context)],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 56, 0, 12),
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    prefs.timerType,
                    prefs.prepareIntervalSeconds,
                    prefs.workIntervalSeconds,
                    prefs.restIntervalSeconds,
                    prefs.rounds,
                    prefs.cycles,
                  ]),
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mode selector
                      GlassGroupedSection(
                        header: Text(
                          l10n.timerModeLabel
                              .toUpperCase(), // Localized: "Mode"
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                letterSpacing: .1,
                                color: Theme.of(context).colorScheme.primary,
                                textBaseline: TextBaseline.alphabetic,
                              ),
                        ),
                        children: [
                          GlassSegmentedControl(
                            segments: [
                              GlassSegment(label: l10n.timerTypeStopwatchLabel),
                              GlassSegment(label: l10n.timerTypeTabataLabel),
                              GlassSegment(label: l10n.timerTypeCountdownLabel),
                            ],
                            selectedIndex: prefs.timerType.value,
                            onSegmentSelected: (index) {
                              prefs.timerType.value = index;
                              timer.reset();
                            },
                            indicatorColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Interval card
                      GlassGroupedSection(
                        header: Text(
                          l10n.timerIntervalsLabel
                              .toUpperCase(), // Localized: "Intervals — tap to change"
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                letterSpacing: 1.0,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        children: [
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
                          if ([
                            TimerType.tabata.index,
                            TimerType.countdown.index,
                          ].contains(prefs.timerType.value))
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
                          if (prefs.timerType.value ==
                              TimerType.tabata.index) ...[
                            _IntervalSetupRow(
                              label: l10n.timerSettingsRoundsLabel,
                              value: prefs.rounds.value.toString(),
                              valueColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                              onTap: () => showIntegerPicker(
                                context,
                                prefs.rounds,
                                timer,
                                20,
                              ),
                              showDivider: true,
                            ),
                            _IntervalSetupRow(
                              label: l10n.timerSettingsCyclesLabel,
                              value: prefs.cycles.value.toString(),
                              valueColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                              onTap: () => showIntegerPicker(
                                context,
                                prefs.cycles,
                                timer,
                                8,
                              ),
                              showDivider: false,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                0,
                12,
                useBottomPadding ? kTextTabBarHeight + 20 : 0,
              ),
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
