import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/timer.dart';

final class TimerTab extends ConsumerWidget {
  const TimerTab({super.key});

  Widget _preparingLayout(L10n l10n, {required Timer timerNotifier}) => Column(
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
                remainingSeconds: timerNotifier.remainingPrepareSeconds,
                text: l10n.timerPrepareLabel,
                fgColor: Colors.black,
                bgColor: Colors.yellow,
              ),
            ),
            Expanded(
              flex: 1,
              child: _SecondaryTile(
                remainingSeconds: timerNotifier.remainingWorkSeconds,
                text: l10n.timerWorkLabel,
                fgColor: Colors.black,
                bgColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
      Expanded(flex: 1, child: _StatusTile(timerNotifier: timerNotifier)),
    ],
  );

  Widget _workingLayout(L10n l10n, {required Timer timerNotifier}) => Column(
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
                remainingSeconds: timerNotifier.remainingWorkSeconds,
                text: l10n.timerWorkLabel,
                fgColor: Colors.black,
                bgColor: Colors.green,
              ),
            ),
            Expanded(
              flex: 1,
              child: _SecondaryTile(
                remainingSeconds: timerNotifier.remainingRestSeconds,
                text: l10n.timerRestLabel,
                fgColor: Colors.white,
                bgColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
      Expanded(flex: 1, child: _StatusTile(timerNotifier: timerNotifier)),
    ],
  );

  Widget _restingLayout(L10n l10n, {required Timer timerNotifier}) => Column(
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
                remainingSeconds: timerNotifier.remainingRestSeconds,
                text: l10n.timerRestLabel,
                fgColor: Colors.white,
                bgColor: Colors.red,
              ),
            ),
            Expanded(
              flex: 1,
              child: _SecondaryTile(
                // Upcoming work is for the next round (not the current one),
                // so show the full interval.
                remainingSeconds: timerNotifier.workIntervalSeconds,
                text: l10n.timerWorkLabel,
                fgColor: Colors.black,
                bgColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
      Expanded(flex: 1, child: _StatusTile(timerNotifier: timerNotifier)),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timerProvider);
    final l10n = L10n.of(context)!;
    final notifier = ref.read(timerProvider.notifier);
    return PlatformScaffold(
      body: SafeArea(
        child: switch (notifier.timerState) {
          .preparing => _preparingLayout(l10n, timerNotifier: notifier),
          .working => _workingLayout(l10n, timerNotifier: notifier),
          .resting => _restingLayout(l10n, timerNotifier: notifier),
        },
      ),
    );
  }
}

// Tile displaying the countdown for current ongoing work.
final class _PrimaryTile extends StatelessWidget {
  final int remainingSeconds;
  final String text;
  final Color fgColor;
  final Color bgColor;

  const _PrimaryTile({
    required this.remainingSeconds,
    required this.text,
    required this.fgColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: Column(
        children: [
          SizedBox(height: 16),
          PlatformText(
            text,
            textAlign: .center,
            style: Theme.of(
              context,
            ).textTheme.displayLarge!.copyWith(color: fgColor),
          ),
          SizedBox(height: 32),
          PlatformText(
            formatSeconds(remainingSeconds),
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
              fontFeatures: [FontFeature.tabularFigures()],
              color: fgColor,
              fontSize: 130,
              fontWeight: .bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Tile displaying the upcoming stage of work.
final class _SecondaryTile extends StatelessWidget {
  final int remainingSeconds;
  final String text;
  final Color fgColor;
  final Color bgColor;

  const _SecondaryTile({
    required this.remainingSeconds,
    required this.text,
    required this.fgColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: Column(
        mainAxisAlignment: .spaceAround,
        children: [
          PlatformText(
            text,
            textAlign: .center,
            style: Theme.of(
              context,
            ).textTheme.displayMedium!.copyWith(color: fgColor),
          ),
          PlatformText(
            formatSeconds(remainingSeconds),
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
              fontFeatures: [FontFeature.tabularFigures()],
              color: fgColor,
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

  const _StatusTile({required this.timerNotifier});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      color: Colors.black,
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              children: [
                SizedBox(height: 16),
                PlatformText(
                  '${timerNotifier.remainingRounds}',
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    color: Colors.blue,
                    fontSize: 54,
                    fontWeight: .bold,
                  ),
                ),
                SizedBox(height: 22),
                PlatformText(l10n.timerRoundsLeftLabel),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              children: [
                PlatformIconButton(
                  icon: Icon(
                    timerNotifier.executionState == .playing
                        ? context.platformIcons.pause
                        : context.platformIcons.playCircle,
                    size: 80,
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
                      : l10n.timerStartLabel,
                ),
              ],
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }
}
