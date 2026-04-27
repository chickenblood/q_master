import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../utils/shared_app_prefs.dart';

const _beatdownAccent = Color(0xFFE53935);

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

    for (final section in widget.workout.sections) {
      final pageContent = <String>[];

      for (final exercise in section.exercises.indexed) {
        pageContent.add(exercise.$2);
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

  String _exerciseTypeAtPage({
    required int pageIndex,
    required int exercisesPerPage,
  }) {
    if (exercisesPerPage <= 0) return '';
    var cumulativePages = 0;
    for (final section in widget.workout.sections) {
      cumulativePages += (section.exercises.length / exercisesPerPage).ceil();
      if (pageIndex < cumulativePages) return section.name;
    }
    return '';
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
        final sectionName = _exerciseTypeAtPage(
          pageIndex: _pageIndex.value,
          exercisesPerPage: exercisesPerPage,
        );
        return PlatformScaffold(
          body: SafeArea(
            child: GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              child: Column(
                children: [
                  // Red section identity bar
                  if (sectionName.isNotEmpty)
                    Container(
                      color: _beatdownAccent,
                      width: double.infinity,
                      height: 44,
                      child: Stack(
                        alignment: .center,
                        children: [
                          Positioned(
                            left: 0,
                            child: PlatformIconButton(
                              icon: Icon(
                                PlatformIcons(context).back,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 24,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                          Text(
                            textAlign: .center,
                            sectionName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pages.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: (_pageIndex.value + 1) / pages.length,
                                minHeight: 3,
                                backgroundColor: const Color(0xFF1A1A1A),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _beatdownAccent,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                              fontWeight: FontWeight.w900,
                                              fontSize: 60,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                              letterSpacing: -2,
                                              height: 1.05,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  child: PlatformElevatedButton(
                                    color: _beatdownAccent,
                                    material: (_, _) =>
                                        MaterialElevatedButtonData(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _beatdownAccent,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size.fromHeight(
                                              58,
                                            ),
                                          ),
                                        ),
                                    cupertino: (_, _) =>
                                        CupertinoElevatedButtonData(
                                          color: _beatdownAccent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                        ),
                                    onPressed: () => _onNextPage(
                                      context,
                                      pageIndex: index,
                                      pageCount: pages.length,
                                    ),
                                    child: (index + 1) < pages.length
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                L10n.of(
                                                  context,
                                                )!.beatdownBrowserNextLabel,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white54,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  '${pages[index + 1].lines.first} →',
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            L10n.of(
                                              context,
                                            )!.workoutCompleteText,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (pages.isNotEmpty)
                    DotsIndicator(
                      animate: true,
                      dotsCount: pages.length,
                      decorator: DotsDecorator(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.24),
                        activeDotColor: _beatdownAccent,
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
