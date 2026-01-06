import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/ui/adaptive_icons.dart';
import 'package:q_master/utils/shared_preferences_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class BeatdownBrowser extends StatelessWidget {
  final _pageIndex = ValueNotifier<int>(0);
  final _pageController = PageController();
  final Workout workout;

  BeatdownBrowser({super.key, required this.workout});

  // Calculate the total number of pages with their content, based on exercises
  // per page
  List<String> _calculatePages({required int exercisesPerPage}) {
    final pages = <String>[];

    for (final exercises in {workout.warmup, workout.thang, workout.mary}) {
      final pageContent = StringBuffer();

      for (final exercise in exercises.indexed) {
        pageContent.write('${exercise.$2.name}\n');
        if (((exercise.$1 + 1) % exercisesPerPage) == 0) {
          pages.add(pageContent.toString());
          pageContent.clear();
        }
      }
      if (pageContent.isNotEmpty) {
        pages.add(pageContent.toString());
        pageContent.clear();
      }
    }
    return pages;
  }

  String _exerciseTypeAtPage(
    BuildContext context, {
    required int pageIndex,
    required int exercisesPerPage,
  }) {
    final lastWarmupPageIndex =
        (workout.warmup.length / exercisesPerPage).ceil() - 1;
    if (pageIndex <= lastWarmupPageIndex) {
      return L10n.of(context)!.workoutWarmupFieldLabel;
    }
    final lastThangPageIndex =
        lastWarmupPageIndex + (workout.thang.length / exercisesPerPage).ceil();
    if (pageIndex <= lastThangPageIndex) {
      return L10n.of(context)!.workoutThangFieldLabel;
    }
    return L10n.of(context)!.workoutMaryFieldLabel;
  }

  void _onNextPage(
    BuildContext context, {
    required int pageIndex,
    required int pageCount,
  }) {
    if ((pageIndex + 1) < pageCount) {
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
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final exercisesPerPage = snapshot.data!.exercisesPerPage;
        final pages = _calculatePages(exercisesPerPage: exercisesPerPage);
        return PlatformScaffold(
          appBar: PlatformAppBar(
            leading: PlatformIconButton(
              icon: Icon(AdaptiveIcons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: ListenableBuilder(
              listenable: _pageIndex,
              builder: (_, _) => PlatformText(
                _exerciseTypeAtPage(
                  context,
                  pageIndex: _pageIndex.value,
                  exercisesPerPage: exercisesPerPage,
                ),
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.6),
              ),
            ),
          ),
          body: SafeArea(
            minimum: EdgeInsets.all(16),
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) => _pageIndex.value = index,
              itemBuilder: (context, index) {
                final pageText = pages[index];
                return Column(
                  mainAxisSize: .max,
                  mainAxisAlignment: .spaceAround,
                  crossAxisAlignment: .stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: AutoSizeText(
                          pageText,
                          textAlign: exercisesPerPage == 1
                              ? TextAlign.center
                              : TextAlign.left,
                          overflow: .fade,
                          maxLines: 30,
                          minFontSize: 12,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                          ),
                        ),
                      ),
                    ),
                    PlatformTextButton(
                      onPressed: () => _onNextPage(
                        context,
                        pageIndex: index,
                        pageCount: pages.length,
                      ),
                      child: PlatformText(
                        (index + 1) < pages.length
                            ? L10n.of(context)!.workoutNextUpText(
                                pages[index + 1].split('\n').first,
                              )
                            : L10n.of(context)!.workoutCompleteText,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
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
      },
    );
  }
}
