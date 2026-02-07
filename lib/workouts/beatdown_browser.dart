import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../utils/shared_app_prefs.dart';

final class BeatdownBrowser extends StatefulWidget {
  final Workout workout;

  const BeatdownBrowser({super.key, required this.workout});

  @override
  State<BeatdownBrowser> createState() => _BeatdownBrowserState();
}

class _BeatdownBrowserState extends State<BeatdownBrowser> {
  final _pageIndex = ValueNotifier<int>(0);
  final _pageController = PageController();
  double _initialScale = 1.0;

  @override
  void dispose() {
    _pageController.dispose();
    _pageIndex.dispose();
    super.dispose();
  }

  // Calculate the total number of pages with their content, based on exercises
  List<({AutoSizeGroup group, List<String> lines})> _calculatePages({
    required int exercisesPerPage,
  }) {
    if (exercisesPerPage <= 0) return [];
    final pages = <({AutoSizeGroup group, List<String> lines})>[];

    for (final exercises in {
      widget.workout.warmup,
      widget.workout.thang,
      widget.workout.mary,
    }) {
      final pageContent = <String>[];

      for (final exercise in exercises.indexed) {
        pageContent.add(exercise.$2.name);
        if (((exercise.$1 + 1) % exercisesPerPage) == 0) {
          pages.add((group: AutoSizeGroup(), lines: List.of(pageContent)));
          pageContent.clear();
        }
      }
      if (pageContent.isNotEmpty) {
        pages.add((group: AutoSizeGroup(), lines: List.of(pageContent)));
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
    if (exercisesPerPage <= 0) return '';
    final lastWarmupPageIndex =
        (widget.workout.warmup.length / exercisesPerPage).ceil() - 1;
    if (pageIndex <= lastWarmupPageIndex) {
      return L10n.of(context)!.workoutWarmupFieldLabel;
    }
    final lastThangPageIndex =
        lastWarmupPageIndex +
        (widget.workout.thang.length / exercisesPerPage).ceil();
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

  void _handleScaleStart(ScaleStartDetails details) {
    final prefs = SharedAppPrefs.instance;
    _initialScale =
        prefs.exercisesPerPage.value.toDouble() /
        SharedAppPrefs.maxExercisesPerPage;
    // Must reset to first page before changing exercises per page, so
    // that the current page index is still valid.
    _pageIndex.value = 0;
    _pageController.jumpToPage(0);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final prefs = SharedAppPrefs.instance;
    final maxPerPage = SharedAppPrefs.maxExercisesPerPage;

    late double updatedScale;
    if (details.scale >= 1.0) {
      updatedScale = _initialScale + (details.scale - 1);
    } else if (details.scale < 1.0) {
      updatedScale = _initialScale - (1 - details.scale);
    }
    prefs.exercisesPerPage.value = (updatedScale * maxPerPage)
        .clamp(1, maxPerPage)
        .toInt();
  }

  @override
  Widget build(BuildContext context) {
    final SharedAppPrefs prefs = SharedAppPrefs.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([prefs.exercisesPerPage, _pageIndex]),
      builder: (_, _) {
        final exercisesPerPage = prefs.exercisesPerPage.value;
        final pages = _calculatePages(exercisesPerPage: exercisesPerPage);
        return PlatformScaffold(
          appBar: PlatformAppBar(
            automaticallyImplyLeading: true,
            title: PlatformText(
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
          body: SafeArea(
            minimum: EdgeInsets.all(16),
            child: GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) => _pageIndex.value = index,
                      itemBuilder: (context, index) {
                        final autoSizeGroup = pages[index].group;
                        final pageLines = pages[index].lines;
                        return Column(
                          crossAxisAlignment: .end,
                          children: [
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: .max,
                                  mainAxisAlignment: .spaceBetween,
                                  crossAxisAlignment: exercisesPerPage == 1
                                      ? .center
                                      : .start,
                                  children: [
                                    Spacer(),
                                    ...pageLines.map(
                                      (line) => Expanded(
                                        child: AutoSizeText(
                                          group: autoSizeGroup,
                                          line,
                                          textAlign: exercisesPerPage == 1
                                              ? TextAlign.center
                                              : TextAlign.left,
                                          overflow: .fade,
                                          maxLines: 2,
                                          minFontSize: 12,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 48,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                  ],
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
                                        pages[index + 1].lines.first,
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
                  if (pages.isNotEmpty)
                    DotsIndicator(
                      animate: true,
                      dotsCount: pages.length,
                      decorator: DotsDecorator(
                        activeColor: Theme.of(context).colorScheme.onSurface,
                      ),
                      position: _pageIndex.value.toDouble(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
