import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:q_master/ui/adaptive_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../model/exicon_fetcher.dart';
import '../ui/adaptive_draggable_sheet.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_route_page.dart';
import '../ui/simple_alert.dart';
import '../utils/shared_app_prefs.dart';
import 'exicon_catalog.dart';
import 'workout_auto_completions.dart';
import 'workout_constants.dart';
import 'youtube_video_screen.dart';

/// Route name for full-screen YouTube playback opened from the exercise picker.
const youtubeVideoRouteName = 'youtube-video';

/// Builds the video route on the root navigator so it covers the tab shell.
GoRoute youtubeVideoRoute({
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) => GoRoute(
  path: 'youtube-video',
  name: youtubeVideoRouteName,
  parentNavigatorKey: rootNavigatorKey,
  pageBuilder: (context, state) {
    final videoId = state.extra;
    if (videoId is! String || videoId.isEmpty) {
      throw StateError('YouTube video route requires a video ID.');
    }
    return adaptiveRoutePage(
      context,
      state,
      YoutubeVideoScreen(videoId: videoId),
      fullscreenDialog: true,
    );
  },
);

Future<String?> showExercisePicker(
  BuildContext context, {
  String? text,
  required void Function(String) onExerciseAdded,
}) async {
  final controller = TextEditingController(text: text)
    ..selection = TextSelection(baseOffset: 0, extentOffset: text?.length ?? 0);

  return showAdaptiveDraggableSheet(
    context: context,
    builder: (context) => _ExercisePickerSheet(
      controller: controller,
      onExerciseAdded: onExerciseAdded,
    ),
  );
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final void Function(String) onExerciseAdded;

  const _ExercisePickerSheet({
    required this.controller,
    required this.onExerciseAdded,
  });

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  static const _orderedFilterCategories = <ExerciseCategory>[
    .core,
    .cardio,
    .strength,
    .chest,
    .shoulders,
    .legs,
    .arms,
    .coupon,
    .fullBody,
  ];

  bool _canAdd = false;

  void _addExercise() {
    final selection = widget.controller.text.trim();
    if (selection.isEmpty) return;
    widget.onExerciseAdded(selection);
    // Clear text so that the user can easily add another exercise.
    widget.controller.clear();

    GlassToast.show(
      context,
      message: L10n.of(context)!.exerciseAddedSnackbarMessage,
      type: .success,
    );
  }

  late final Set<String> _selectedTagKeys;
  late bool _videoFilter;

  @override
  void initState() {
    super.initState();
    final prefs = SharedAppPrefs.instance;
    _selectedTagKeys = normalizeExerciseFilterKeys(
      prefs.selectedCategoryFilters.value,
    );
    _videoFilter = prefs.exerciseVideoFilter.value;

    widget.controller.addListener(_updateCanAdd);
  }

  void _updateCanAdd() {
    setState(() {
      _canAdd = widget.controller.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCanAdd);
    super.dispose();
  }

  Set<String> _effectiveSelectedTagKeys(Set<String> availableTagKeys) {
    return _selectedTagKeys.where(availableTagKeys.contains).toSet();
  }

  List<NormalizedExiconTag> _curatedFilterTags(BuildContext context) {
    return _orderedFilterCategories
        .map(
          (category) => NormalizedExiconTag(
            key: _tagKeyForCategory(category),
            label: category.displayLabel(context),
          ),
        )
        .toList(growable: false);
  }

  String _tagKeyForCategory(ExerciseCategory category) {
    return switch (category) {
      ExerciseCategory.fullBody => 'full body',
      _ => category.name,
    };
  }

  void _toggleTag(
    NormalizedExiconTag tag, {
    required Set<String> availableTagKeys,
  }) {
    final nextSelectedTagKeys = _effectiveSelectedTagKeys(availableTagKeys);
    setState(() {
      if (!nextSelectedTagKeys.add(tag.key)) {
        nextSelectedTagKeys.remove(tag.key);
      }
      _selectedTagKeys
        ..clear()
        ..addAll(nextSelectedTagKeys);
    });

    final storedKeys = nextSelectedTagKeys.toList()..sort();
    SharedAppPrefs.instance.selectedCategoryFilters.value = storedKeys;
  }

  void _selectExercise(BuildContext context, String exerciseName) {
    widget.controller.value = TextEditingValue(
      text: exerciseName,
      selection: TextSelection.collapsed(offset: exerciseName.length),
    );
    FocusScope.of(context).unfocus();
  }

  Future<void> _openExerciseVideo(BuildContext context, Uri videoUrl) async {
    if (defaultTargetPlatform == .iOS || defaultTargetPlatform == .android) {
      final videoId = _extractYoutubeVideoId(videoUrl);
      if (videoId == null) {
        await launchUrl(videoUrl, mode: .externalApplication);
        return;
      }
      await context.pushNamed<void>(youtubeVideoRouteName, extra: videoId);
    } else {
      await launchUrl(videoUrl, mode: .externalApplication);
    }
  }

  String? _extractYoutubeVideoId(Uri url) {
    final host = url.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final firstSegment = url.pathSegments.isEmpty
          ? null
          : url.pathSegments.first;
      return _normalizeYoutubeId(firstSegment);
    }

    if (!host.contains('youtube.com') &&
        !host.contains('youtube-nocookie.com')) {
      return null;
    }

    final fromQuery = _normalizeYoutubeId(url.queryParameters['v']);
    if (fromQuery != null) {
      return fromQuery;
    }

    final embedIndex = url.pathSegments.indexOf('embed');
    if (embedIndex >= 0 && embedIndex + 1 < url.pathSegments.length) {
      return _normalizeYoutubeId(url.pathSegments[embedIndex + 1]);
    }

    final shortsIndex = url.pathSegments.indexOf('shorts');
    if (shortsIndex >= 0 && shortsIndex + 1 < url.pathSegments.length) {
      return _normalizeYoutubeId(url.pathSegments[shortsIndex + 1]);
    }

    return null;
  }

  String? _normalizeYoutubeId(String? candidate) {
    if (candidate == null || candidate.isEmpty) {
      return null;
    }

    final match = RegExp(r'^[A-Za-z0-9_-]{11}$').firstMatch(candidate);
    return match?.group(0);
  }

  Future<void> _showExerciseDescription(
    BuildContext context,
    String exerciseName,
    String description,
  ) => showSimpleAlert(context, title: exerciseName, message: description);

  List<WorkoutCatalogExercise> _filteredExercises(
    List<WorkoutCatalogExercise> exercises, {
    required Set<String> selectedTagKeys,
  }) {
    return exercises
        .where((exercise) {
          if (_videoFilter && exercise.videoUrl == null) {
            return false;
          }
          if (selectedTagKeys.isEmpty) {
            return true;
          }
          return selectedTagKeys.every(exercise.filterTagKeys.contains);
        })
        .toList(growable: false);
  }

  Widget _filterChips(
    BuildContext context, {
    required List<NormalizedExiconTag> availableTags,
    required Set<String> selectedTagKeys,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableTagKeys = availableTags.map((tag) => tag.key).toSet();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Column(
        key: const ValueKey('picker-content'),
        crossAxisAlignment: .stretch,
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in availableTags)
                GlassChip(
                  label: tag.label,
                  selected: selectedTagKeys.contains(tag.key),
                  onTap: () =>
                      _toggleTag(tag, availableTagKeys: availableTagKeys),
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: .w700,
                    color: selectedTagKeys.contains(tag.key)
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  selectedColor: colorScheme.primary,
                ),
              GlassChip(
                label: L10n.of(context)!.exerciseFilterVideoLabel,
                selected: _videoFilter,
                onTap: () => setState(() {
                  _videoFilter = !_videoFilter;
                  SharedAppPrefs.instance.exerciseVideoFilter.value =
                      _videoFilter;
                }),
                icon: Icon(
                  Icons.ondemand_video,
                  size: 18,
                  color: _videoFilter
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: .w700,
                  color: _videoFilter
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                selectedColor: colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _stateSliver(
    BuildContext context, {
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseGrid(
    BuildContext context, {
    required int gridColumnCount,
    required List<WorkoutCatalogExercise> exercises,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverPadding(
      // Allow a margin for the frame of the GlassModalSheet to show.
      padding: const EdgeInsets.symmetric(horizontal: 1),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumnCount,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          mainAxisExtent: 72,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= exercises.length) {
            return null;
          }
          final exercise = exercises[index];
          final exerciseName = exercise.name;
          final videoUrl = exercise.videoUrl;
          final hasVideo = videoUrl != null;
          final description = exercise.description;
          final hasDescription =
              description != null && description.trim().isNotEmpty;
          final isSelected = widget.controller.text == exerciseName;

          return GestureDetector(
            onTap: () => _selectExercise(context, exerciseName),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  width: isSelected ? 2 : 1,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: .center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          exerciseName,
                          maxLines: 2,
                          minFontSize: 11,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                backgroundColor: Colors.transparent,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ),
                    if (hasVideo || hasDescription)
                      IconButton(
                        onPressed: () => hasVideo
                            ? _openExerciseVideo(context, videoUrl)
                            : _showExerciseDescription(
                                context,
                                exerciseName,
                                description!,
                              ),
                        constraints: const BoxConstraints(
                          minWidth: 52,
                          minHeight: 52,
                        ),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                        icon: Icon(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          hasVideo ? Icons.ondemand_video : AdaptiveIcons.notes,
                          size: 26,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;
    final gridColumnCount = isLandscape ? 4 : 2;
    final exiconEntries = ref.watch(exiconFetcherProvider);
    final catalog = exiconEntries.maybeWhen(
      data: buildWorkoutCatalog,
      orElse: () => const <WorkoutCatalogExercise>[],
    );
    final availableTags = _curatedFilterTags(context);
    final availableTagKeys = availableTags.map((tag) => tag.key).toSet();
    final selectedTagKeys = _effectiveSelectedTagKeys(availableTagKeys);
    final filteredExercises = _filteredExercises(
      catalog,
      selectedTagKeys: selectedTagKeys,
    );

    return AdaptiveScaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AdaptiveLiquidGlassLayer(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: WorkoutAutocompleteTextField(
                            textEditingController: widget.controller,
                            minLines: 1,
                            maxLines: 1,
                            onSubmitted: _addExercise,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              textStyle: Theme.of(context).textTheme.labelLarge,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                            onPressed: _canAdd ? _addExercise : null,
                            child: Text(
                              L10n.of(context)!.exercisePickerAddButtonLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    _filterChips(
                      context,
                      availableTags: availableTags,
                      selectedTagKeys: selectedTagKeys,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    exiconEntries.when(
                      data: (_) {
                        if (catalog.isEmpty) {
                          return _stateSliver(
                            context,
                            icon: AdaptiveIcons.notes,
                            message: L10n.of(
                              context,
                            )!.exercisePickerEmptyCatalogLabel,
                          );
                        }

                        if (filteredExercises.isEmpty) {
                          return _stateSliver(
                            context,
                            icon: Icons.filter_alt_off,
                            message: L10n.of(
                              context,
                            )!.exercisePickerEmptyFilteredLabel,
                          );
                        }

                        return SliverSafeArea(
                          bottom: true,
                          minimum: const EdgeInsets.only(bottom: 60),
                          sliver: _exerciseGrid(
                            context,
                            gridColumnCount: gridColumnCount,
                            exercises: filteredExercises,
                          ),
                        );
                      },
                      loading: () => SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                      error: (_, _) => _stateSliver(
                        context,
                        icon: Icons.cloud_off,
                        message: L10n.of(
                          context,
                        )!.exercisePickerLoadErrorMessage,
                        actionLabel: L10n.of(
                          context,
                        )!.exercisePickerRetryButtonLabel,
                        onAction: () =>
                            ref.read(exiconFetcherProvider.notifier).refresh(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
