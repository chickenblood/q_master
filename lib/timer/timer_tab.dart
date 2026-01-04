import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/model/timer.dart';

final class TimerTab extends ConsumerWidget {
  const TimerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    return PlatformScaffold(
      body: SafeArea(
        child: Column(
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
                    child: Container(
                      color: Colors.yellow,
                      child: Column(
                        children: [
                          SizedBox(height: 16),
                          PlatformText(
                            'PREPARE',
                            textAlign: .center,
                            style: Theme.of(context).textTheme.displayLarge!
                                .copyWith(color: Colors.black),
                          ),
                          SizedBox(height: 32),
                          PlatformText(
                            formatSeconds(notifier.remainingPrepareSeconds),
                            style: Theme.of(context).textTheme.displayLarge!
                                .copyWith(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: Colors.black,
                                  fontSize: 130,
                                  fontWeight: .bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.green,
                      child: Column(
                        mainAxisAlignment: .spaceAround,
                        children: [
                          PlatformText(
                            'WORK',
                            textAlign: .center,
                            style: Theme.of(context).textTheme.displayMedium!
                                .copyWith(color: Colors.black),
                          ),
                          PlatformText(
                            formatSeconds(notifier.remainingWorkSeconds),
                            style: Theme.of(context).textTheme.displayLarge!
                                .copyWith(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: Colors.black,
                                  fontWeight: .bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
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
                            '${notifier.remainingRounds}',
                            style: Theme.of(context).textTheme.displayLarge!
                                .copyWith(fontSize: 48, fontWeight: .bold),
                          ),
                          SizedBox(height: 22),
                          PlatformText('ROUNDS LEFT'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: .center,
                        children: [
                          PlatformIconButton(
                            icon: Icon(
                              notifier.executionState == ExecutionState.playing
                                  ? context.platformIcons.pause
                                  : context.platformIcons.playCircle,
                              size: 80,
                            ),
                            onPressed: () {
                              if (notifier.executionState == .playing) {
                                notifier.pause();
                              } else {
                                notifier.start();
                              }
                            },
                          ),
                          PlatformText('START'),
                        ],
                      ),
                    ),
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
