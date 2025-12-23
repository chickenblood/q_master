import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/ui/adaptive_icons.dart';

final class BeatdownBrowser extends StatelessWidget {
  final _pageIndex = ValueNotifier<int>(0);
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
        title: ListenableBuilder(
          listenable: _pageIndex,
          builder: (_, _) =>
              PlatformText(_exerciseTypeAtIndex(_pageIndex.value, context)),
        ),
      ),
      body: SafeArea(
        minimum: EdgeInsets.all(16),
        child: PageView.builder(
          controller: _pageController,
          itemCount: exerciseCount,
          onPageChanged: (index) => _pageIndex.value = index,
          itemBuilder: (context, index) {
            final exercise = _exerciseAtIndex(index);
            return Column(
              mainAxisSize: .max,
              mainAxisAlignment: .spaceBetween,
              crossAxisAlignment: .center,
              children: [
                Spacer(),
                PlatformText(
                  exercise.name,
                  textAlign: .center,
                  overflow: .fade,
                  maxLines: 5,
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                PlatformTextButton(
                  onPressed: () => _onNextPage(index, context),
                  child: PlatformText(
                    (index + 1) < exerciseCount
                        ? L10n.of(
                            context,
                          )!.workoutNextUpText(_exerciseAtIndex(index + 1).name)
                        : L10n.of(context)!.workoutCompleteText,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: .end,
                    overflow: .ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
