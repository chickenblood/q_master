import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../model/timer.dart';
import '../settings/settings_sheet.dart';
import '../ui/adaptive_icons.dart';
import '../ui/media_query.dart';
import '../utils/datetime_utils.dart';

final class TimerTab extends ConsumerWidget {
  static const fontFamily = 'RobotoCondensed-VariableFont_wght';
  const TimerTab({super.key});

  Future<void> _resetTimer(WidgetRef ref) async {
    final notifier = ref.read(timerProvider.notifier);
    await notifier.reset();
  }

  // The FAB is only for Android. We use app bar actions on iOS.
  Widget? _androidResetFAB(BuildContext context, {required WidgetRef ref}) {
    return FloatingActionButton(
      backgroundColor: Colors.red,
      onPressed: () => _resetTimer(ref),
      child: Icon(PlatformIcons(context).refresh),
    );
  }

  Widget _layoutTiles(
    L10n l10n, {
    required bool isPortrait,
    required Timer timerNotifier,
    required _TileSpec firstTile,
    required _TileSpec? secondTile,
  }) => isPortrait
      ? Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .max,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: .max,
                crossAxisAlignment: .stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _PrimaryTile(
                      tileSpec: firstTile,
                      isPortrait: isPortrait,
                    ),
                  ),
                  if (secondTile != null)
                    Expanded(
                      flex: 1,
                      child: _SecondaryTile(
                        tileSpec: secondTile,
                        isPortrait: isPortrait,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: _StatusTile(
                timerNotifier: timerNotifier,
                isPortrait: isPortrait,
              ),
            ),
          ],
        )
      : Column(
          mainAxisSize: .max,
          crossAxisAlignment: .stretch,
          children: [
            Expanded(
              flex: 5,
              child: _PrimaryTile(tileSpec: firstTile, isPortrait: isPortrait),
            ),
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: .stretch,
                children: [
                  Expanded(
                    child: _StatusTile(
                      timerNotifier: timerNotifier,
                      isPortrait: isPortrait,
                    ),
                  ),
                  if (secondTile != null)
                    Expanded(
                      child: _SecondaryTile(
                        tileSpec: secondTile,
                        isPortrait: isPortrait,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timerProvider);
    final l10n = L10n.of(context)!;
    final notifier = ref.read(timerProvider.notifier);
    final timerType = notifier.timerType;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isTablet = MediaUtils.isTablet(context);
    final workTime = timerType == .tabata
        ? notifier.remainingWorkTime
        : notifier.elapsedTime;
    final formatter = timerType == .tabata
        ? formatDuration
        : formatPreciseDuration;
    return PlatformScaffold(
      appBar: isPortrait || isTablet
          ? PlatformAppBar(
              leading: const SettingsActionButton(),
              title: Text(
                L10n.of(context)!.timerTabTitle,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.6),
              ),

              cupertino: (appBarContext, _) => CupertinoNavigationBarData(
                backgroundColor: Colors.transparent,
                // Action buttons – iOS only
                trailing: PlatformIconButton(
                  icon: Icon(PlatformIcons(context).refresh),
                  padding: const EdgeInsets.only(right: 16.0),
                  onPressed: () => _resetTimer(ref),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: switch (notifier.timerState) {
          .preparing => _layoutTiles(
            l10n,
            isPortrait: isPortrait,
            timerNotifier: notifier,
            firstTile: _TileSpec(
              label: l10n.timerPrepareLabel,
              timeLabel: formatter(notifier.remainingPrepareTime),
              fgColor: Colors.black,
              bgColor: Colors.orange,
            ),
            secondTile: timerType == .tabata
                ? _TileSpec(
                    label: l10n.timerWorkLabel,
                    timeLabel: formatter(workTime),
                    fgColor: Colors.black,
                    bgColor: Colors.green,
                  )
                : null,
          ),
          .working => _layoutTiles(
            l10n,
            isPortrait: isPortrait,
            timerNotifier: notifier,
            firstTile: _TileSpec(
              label: l10n.timerWorkLabel,
              timeLabel: formatter(workTime),
              fgColor: Colors.black,
              bgColor: Colors.green,
            ),
            secondTile: timerType == .tabata
                ? _TileSpec(
                    label: l10n.timerRestLabel,
                    timeLabel: formatter(notifier.remainingRestTime),
                    fgColor: Colors.white,
                    bgColor: Colors.red,
                  )
                : null,
          ),
          .resting => _layoutTiles(
            l10n,
            isPortrait: isPortrait,
            timerNotifier: notifier,
            firstTile: _TileSpec(
              label: l10n.timerRestLabel,
              timeLabel: formatter(notifier.remainingRestTime),
              fgColor: Colors.white,
              bgColor: Colors.red,
            ),
            secondTile: timerType == .tabata
                ? _TileSpec(
                    label: l10n.timerWorkLabel,
                    // Upcoming work is for the next round (not the current one),
                    // so show the full interval.
                    timeLabel: formatter(notifier.workInterval),
                    fgColor: Colors.black,
                    bgColor: Colors.green,
                  )
                : null,
          ),
        },
      ),
      material: (innerContext, _) => MaterialScaffoldData(
        floatingActionButton: _androidResetFAB(innerContext, ref: ref),
      ),
    );
  }
}

final class _TileSpec {
  final String label;
  final String timeLabel;
  final Color fgColor;
  final Color bgColor;

  const _TileSpec({
    required this.label,
    required this.timeLabel,
    required this.fgColor,
    required this.bgColor,
  });
}

// Tile displaying the countdown for current ongoing work.
final class _PrimaryTile extends StatelessWidget {
  final _TileSpec tileSpec;
  final bool isPortrait;

  const _PrimaryTile({required this.tileSpec, required this.isPortrait});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(4),
    color: tileSpec.bgColor,
    child: Column(
      mainAxisAlignment: .spaceBetween,
      spacing: 8,
      children: [
        PlatformText(
          tileSpec.label,
          textAlign: .center,
          style: Theme.of(
            context,
          ).textTheme.displayLarge!.copyWith(color: tileSpec.fgColor),
          textScaler: TextScaler.noScaling,
        ),
        Expanded(
          child: Center(
            child: AutoSizeText(
              tileSpec.timeLabel,
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                fontFamily: TimerTab.fontFamily,
                fontVariations: [FontVariation.weight(600)],
                fontFeatures: [FontFeature.tabularFigures()],
                color: tileSpec.fgColor,
                fontSize: 800,
              ),
              textScaleFactor: 1.0,
              maxLines: 1,
            ),
          ),
        ),
      ],
    ),
  );
}

// Tile displaying the upcoming stage of work.
final class _SecondaryTile extends StatelessWidget {
  final _TileSpec tileSpec;
  final bool isPortrait;

  const _SecondaryTile({required this.tileSpec, required this.isPortrait});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      color: tileSpec.bgColor,
      child: Flex(
        mainAxisAlignment: .spaceBetween,
        direction: isPortrait ? Axis.vertical : Axis.horizontal,
        spacing: 8,
        children: [
          PlatformText(
            tileSpec.label,
            textAlign: .center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall!.copyWith(color: tileSpec.fgColor),
            textScaler: TextScaler.noScaling,
          ),
          Expanded(
            child: Center(
              child: AutoSizeText(
                tileSpec.timeLabel,
                style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontFamily: TimerTab.fontFamily,
                  fontVariations: [FontVariation.weight(600)],
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: tileSpec.fgColor,
                  fontWeight: .w900,
                  fontSize: 400,
                ),
                textScaleFactor: 1,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _StatusTile extends StatelessWidget {
  final Timer timerNotifier;
  final bool isPortrait;

  const _StatusTile({required this.timerNotifier, required this.isPortrait});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final timerHasStarted = timerNotifier.elapsedTime > Duration.zero;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final isTabata = timerNotifier.timerType == .tabata;
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: [
          Expanded(
            child: Visibility(
              visible: isTabata,
              child: _StatusElement(
                label: l10n.timerRoundsLeftLabel,
                value: timerNotifier.remainingRounds.toString(),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              children: [
                PlatformIconButton(
                  icon: Icon(
                    timerNotifier.executionState == .playing
                        ? AdaptiveIcons.pauseCircle
                        : context.platformIcons.playCircle,
                    size: isPortrait ? 80 : 52,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (timerNotifier.executionState == .playing) {
                      timerNotifier.pause();
                    } else {
                      timerNotifier.start();
                    }
                  },
                ),
                if (isPortrait || isTablet)
                  PlatformText(
                    timerNotifier.executionState == .playing
                        ? l10n.timerPauseLabel
                        : (timerHasStarted
                              ? l10n.timerResumeLabel
                              : l10n.timerStartLabel),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(color: Colors.white),
                    textScaler: TextScaler.noScaling,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Visibility(
              visible: isTabata,
              child: _StatusElement(
                label: l10n.timerCyclesLeftLabel,
                value: timerNotifier.remainingCycles.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _StatusElement extends StatelessWidget {
  final String label;
  final String value;

  const _StatusElement({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: .spaceAround,
    children: [
      Spacer(),
      Expanded(
        flex: 3,
        child: Center(
          child: AutoSizeText(
            value,
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
              color: Colors.blue,
              fontSize: 54,
              fontWeight: .bold,
            ),
            textScaleFactor: 1,
          ),
        ),
      ),
      SizedBox(height: 8),
      Expanded(
        flex: 1,
        child: Center(
          child: AutoSizeText(
            label,
            softWrap: true,
            maxLines: 1,
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(color: Colors.white),
            textScaleFactor: 1,
            minFontSize: 10,
          ),
        ),
      ),
      Spacer(flex: 2),
    ],
  );
}
