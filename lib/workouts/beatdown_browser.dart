import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/icons/adaptive_icons.dart';

final class BeatdownBrowser extends StatelessWidget {
  final _pageController = PageController();
  final Workout workout;

  BeatdownBrowser({super.key, required this.workout});

  int get exerciseCount =>
      workout.warmup.length + workout.thang.length + workout.mary.length;

  Exercise _exerciseAtIndex(int index) {
    if (index < workout.warmup.length) {
      return workout.warmup[index];
    }
    index -= workout.warmup.length;
    if (index < workout.thang.length) {
      return workout.thang[index];
    }
    index -= workout.thang.length;
    return workout.mary[index];
  }

  String _exerciseTypeAtIndex(int index, BuildContext context) {
    if (index < workout.warmup.length) {
      return L10n.of(context)!.workoutWarmupFieldLabel;
    }
    index -= workout.warmup.length;
    if (index < workout.thang.length) {
      return L10n.of(context)!.workoutThangFieldLabel;
    }
    index -= workout.thang.length;
    return L10n.of(context)!.workoutMaryFieldLabel;
  }

  void _onNextPage(int index, BuildContext context) {
    if ((index + 1) < exerciseCount) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        leading: PlatformIconButton(
          icon: Icon(AdaptiveIcons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: PlatformText(L10n.of(context)!.beatdownBrowserTitle),
      ),
      body: SafeArea(
        minimum: EdgeInsets.all(16),
        child: PageView.builder(
          controller: _pageController,
          itemCount: exerciseCount,
          itemBuilder: (context, index) {
            final exercise = _exerciseAtIndex(index);
            final exerciseType = _exerciseTypeAtIndex(index, context);
            return Column(
              mainAxisSize: .max,
              mainAxisAlignment: .spaceBetween,
              crossAxisAlignment: .center,
              children: [
                PlatformText(
                  exerciseType,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                PlatformText(
                  exercise.name,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: .end,
                  children: [
                    PlatformTextButton(
                      onPressed: () => _onNextPage(index, context),
                      child: PlatformText(
                        (index + 1) < exerciseCount
                            ? L10n.of(context)!.workoutNextUpText(exercise.name)
                            : L10n.of(context)!.workoutCompleteText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
