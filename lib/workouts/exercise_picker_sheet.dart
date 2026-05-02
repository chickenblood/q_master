import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../l10n/l10n.dart';
import '../utils/shared_app_prefs.dart';
import 'workout_auto_completions.dart';
import 'workout_constants.dart';
import 'youtube_video_screen.dart';

Future<String?> showExercisePicker(
  BuildContext context, {
  String? text,
  required void Function(String) onExerciseAdded,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final controller = TextEditingController(text: text)
    ..selection = TextSelection(baseOffset: 0, extentOffset: text?.length ?? 0);

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    clipBehavior: .antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: colorScheme.outlineVariant),
    ),
    builder: (context) => _ExercisePickerSheet(
      controller: controller,
      onExerciseAdded: onExerciseAdded,
    ),
  );
}

class _ExercisePickerSheet extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onExerciseAdded;

  const _ExercisePickerSheet({
    required this.controller,
    required this.onExerciseAdded,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  bool _canAdd = false;

  void _addExercise() {
    final selection = widget.controller.text.trim();
    if (selection.isEmpty) return;
    widget.onExerciseAdded(selection);
    // Clear text so that the user can easily add another exercise.
    widget.controller.clear();
  }

  late final Set<ExerciseCategory> _selectedCategories;
  late bool _videoFilter;

  static const _orderedCategories = <ExerciseCategory>[
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

  @override
  void initState() {
    super.initState();
    final prefs = SharedAppPrefs.instance;
    final savedNames = prefs.selectedCategoryFilters.value;
    _selectedCategories = savedNames
        .map((name) {
          try {
            return ExerciseCategory.values.byName(name);
          } on ArgumentError {
            return null;
          }
        })
        .whereType<ExerciseCategory>()
        .toSet();
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

  void _toggleCategory(ExerciseCategory category) {
    setState(() {
      if (!_selectedCategories.add(category)) {
        _selectedCategories.remove(category);
      }
    });
    SharedAppPrefs.instance.selectedCategoryFilters.value = _selectedCategories
        .map((e) => e.name)
        .toList();
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
      final videoId = YoutubePlayer.convertUrlToId(videoUrl.toString());
      if (videoId == null) {
        await launchUrl(videoUrl, mode: .externalApplication);
        return;
      }
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => YoutubeVideoScreen(videoId: videoId),
        ),
      );
    } else {
      await launchUrl(videoUrl, mode: .externalApplication);
    }
  }

  List<String> get _filteredExercises {
    return workoutCompletions.entries
        .where((entry) {
          if (_videoFilter && entry.value.videoUrl == null) {
            return false;
          }
          if (_selectedCategories.isEmpty) {
            return true;
          }
          return _selectedCategories.every(entry.value.categories.contains);
        })
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  Widget _dragHandle() {
    final bottomSheetTheme = Theme.of(context).bottomSheetTheme;
    final dragHandleSize = bottomSheetTheme.dragHandleSize ?? const Size(60, 4);
    return Container(
      width: dragHandleSize.width,
      height: dragHandleSize.height,
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: bottomSheetTheme.dragHandleColor!,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _filterChips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              for (final category in _orderedCategories)
                FilterChip(
                  label: Text(category.displayLabel(context)),
                  selected: _selectedCategories.contains(category),
                  onSelected: (_) => _toggleCategory(category),
                  showCheckmark: false,
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: .w700,
                    color: _selectedCategories.contains(category)
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  selectedColor: colorScheme.primary,
                  side: BorderSide(
                    width: 1.5,
                    color: _selectedCategories.contains(category)
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  materialTapTargetSize: .shrinkWrap,
                ),
              FilterChip(
                label: Text(L10n.of(context)!.exerciseFilterVideoLabel),
                selected: _videoFilter,
                onSelected: (_) => setState(() {
                  _videoFilter = !_videoFilter;
                  SharedAppPrefs.instance.exerciseVideoFilter.value =
                      _videoFilter;
                }),
                showCheckmark: false,
                avatar: Icon(
                  Icons.ondemand_video,
                  size: 18,
                  color: _videoFilter
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: .w700,
                  color: _videoFilter
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                backgroundColor: colorScheme.surfaceContainerHighest,
                selectedColor: colorScheme.primary,
                side: BorderSide(
                  width: 1.5,
                  color: _videoFilter
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                materialTapTargetSize: .shrinkWrap,
              ),
            ],
          ),
          SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _exerciseGrid(BuildContext context, {required int gridColumnCount}) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumnCount,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        mainAxisExtent: 72,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index >= _filteredExercises.length) {
          return null;
        }
        final exerciseName = _filteredExercises[index];
        final exerciseEntry = workoutCompletions[exerciseName]!;
        final videoUrl = exerciseEntry.videoUrl;
        final isSelected = widget.controller.text == exerciseName;

        return GestureDetector(
          onTap: () => _selectExercise(context, exerciseName),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.12)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                width: 1.5,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AutoSizeText(
                        exerciseName,
                        maxLines: 2,
                        minFontSize: 11,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  if (videoUrl != null)
                    IconButton(
                      onPressed: () => _openExerciseVideo(context, videoUrl),
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
                      icon: const Icon(Icons.ondemand_video, size: 29),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;
    final gridColumnCount = isLandscape ? 4 : 2;

    return DraggableScrollableSheet(
      expand: false,
      snap: true,
      shouldCloseOnMinExtent: false,
      initialChildSize: 0.7,
      minChildSize: 0.7,
      maxChildSize: 0.9,
      snapSizes: [0.7, 0.9],
      builder: (_, scrollController) => Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              mainAxisSize: .min,
              children: [
                _dragHandle(),
                Row(
                  children: [
                    Expanded(
                      child: WorkoutAutocompleteTextField(
                        textEditingController: widget.controller,
                        //autofocus: true,
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
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        onPressed: _canAdd ? _addExercise : null,
                        child: Text(
                          L10n.of(context)!.exercisePickerAddButtonLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                PinnedHeaderSliver(
                  child: Container(
                    padding: EdgeInsets.all(8),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: _filterChips(context),
                  ),
                ),
                SliverSafeArea(
                  sliver: _exerciseGrid(
                    context,
                    gridColumnCount: gridColumnCount,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
