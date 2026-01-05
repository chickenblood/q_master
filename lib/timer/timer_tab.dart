import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/timer.dart';

final class TimerTab extends ConsumerWidget {
  const TimerTab({super.key});

  Widget _layoutTiles(
    L10n l10n, {
    required bool isPortrait,
    required Timer timerNotifier,
    required _TileSpec firstTile,
    required _TileSpec secondTile,
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
              flex: 3,
              child: _PrimaryTile(tileSpec: firstTile, isPortrait: isPortrait),
            ),
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: .stretch,
                children: [
                  Expanded(
                    child: _StatusTile(
                      timerNotifier: timerNotifier,
                      isPortrait: isPortrait,
                    ),
                  ),
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
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return PlatformScaffold(
      body: SafeArea(
        child: switch (notifier.timerState) {
          .preparing => _layoutTiles(
            l10n,
            isPortrait: isPortrait,
            timerNotifier: notifier,
            firstTile: _TileSpec(
              label: l10n.timerPrepareLabel,
              timeSeconds: notifier.remainingPrepareSeconds,
              fgColor: Colors.black,
              bgColor: Colors.yellow,
            ),
            secondTile: _TileSpec(
              label: l10n.timerWorkLabel,
              timeSeconds: notifier.remainingWorkSeconds,
              fgColor: Colors.black,
              bgColor: Colors.green,
            ),
          ),
          .working => _layoutTiles(
            l10n,
            isPortrait: isPortrait,
            timerNotifier: notifier,
            firstTile: _TileSpec(
              label: l10n.timerWorkLabel,
              timeSeconds: notifier.remainingWorkSeconds,
              fgColor: Colors.black,
              bgColor: Colors.green,
            ),
            secondTile: _TileSpec(
              label: l10n.timerRestLabel,
              timeSeconds: notifier.remainingRestSeconds,
              fgColor: Colors.white,
              bgColor: Colors.red,
            ),
          ),
          .resting => _layoutTiles(
            l10n,
            isPortrait: isPortrait,
            timerNotifier: notifier,
            firstTile: _TileSpec(
              label: l10n.timerRestLabel,
              timeSeconds: notifier.remainingRestSeconds,
              fgColor: Colors.white,
              bgColor: Colors.red,
            ),
            secondTile: _TileSpec(
              label: l10n.timerWorkLabel,
              // Upcoming work is for the next round (not the current one),
              // so show the full interval.
              timeSeconds: notifier.workIntervalSeconds,
              fgColor: Colors.black,
              bgColor: Colors.green,
            ),
          ),
        },
      ),
    );
  }
}

final class _TileSpec {
  final String label;
  final int timeSeconds;
  final Color fgColor;
  final Color bgColor;

  const _TileSpec({
    required this.label,
    required this.timeSeconds,
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
    color: tileSpec.bgColor,
    child: Column(
      children: [
        if (isPortrait) SizedBox(height: 16),
        PlatformText(
          tileSpec.label,
          textAlign: .center,
          style: Theme.of(
            context,
          ).textTheme.displayLarge!.copyWith(color: tileSpec.fgColor),
        ),
        Spacer(),
        PlatformText(
          formatSeconds(tileSpec.timeSeconds),
          style: Theme.of(context).textTheme.displayLarge!.copyWith(
            fontFeatures: [FontFeature.tabularFigures()],
            color: tileSpec.fgColor,
            fontSize: 130,
            fontWeight: .bold,
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
      color: tileSpec.bgColor,
      child: Flex(
        mainAxisAlignment: .spaceAround,
        direction: isPortrait ? Axis.vertical : Axis.horizontal,
        children: [
          PlatformText(
            tileSpec.label,
            textAlign: .center,
            style: Theme.of(
              context,
            ).textTheme.displayMedium!.copyWith(color: tileSpec.fgColor),
          ),
          PlatformText(
            formatSeconds(tileSpec.timeSeconds),
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
              fontFeatures: [FontFeature.tabularFigures()],
              color: tileSpec.fgColor,
              fontWeight: .bold,
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
    final timerHasStarted = timerNotifier.elapsedSeconds > 0;
    return Container(
      color: Colors.black,
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: [
          Expanded(
            child: Flex(
              direction: isPortrait ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: .center,
              children: [
                if (isPortrait) SizedBox(height: 16),
                PlatformText(
                  '${timerNotifier.remainingRounds}',
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    color: Colors.blue,
                    fontSize: 54,
                    fontWeight: .bold,
                  ),
                ),
                if (isPortrait) SizedBox(height: 22),
                if (!isPortrait) SizedBox(width: 16),
                PlatformText(
                  l10n.timerRoundsLeftLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Flex(
              mainAxisAlignment: .center,
              direction: isPortrait ? Axis.vertical : Axis.horizontal,
              children: [
                PlatformIconButton(
                  icon: Icon(
                    timerNotifier.executionState == .playing
                        ? context.platformIcons.pause
                        : context.platformIcons.playCircle,
                    size: isPortrait ? 80 : 44,
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
                PlatformText(
                  timerNotifier.executionState == .playing
                      ? l10n.timerPauseLabel
                      : (timerHasStarted
                            ? l10n.timerResumeLabel
                            : l10n.timerStartLabel),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          if (isPortrait) Expanded(child: Container()),
        ],
      ),
    );
  }
}
