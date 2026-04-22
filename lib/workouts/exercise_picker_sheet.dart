import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    show YoutubePlayer;

import '../l10n/l10n.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_modal_sheet.dart';
import 'workout_auto_completions.dart';
import 'workout_constants.dart';
import 'youtube_video_screen.dart';

Future<String?> showExercisePicker(BuildContext context, {String? text}) async {
  final controller = TextEditingController(text: text);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: text?.length ?? 0,
  );

  return showAdaptiveModalSheet<String>(
    context: context,
    child: _ExercisePickerSheet(controller: controller),
  );
}

class _ExercisePickerSheet extends StatefulWidget {
  final TextEditingController controller;

  const _ExercisePickerSheet({required this.controller});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final selectedCategories = <ExerciseCategory>{};
  bool videoFilter = false;
  String? pressedExerciseName;

  static const orderedCategories = <ExerciseCategory>[
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

  void _toggleCategory(ExerciseCategory category) {
    setState(() {
      if (!selectedCategories.add(category)) {
        selectedCategories.remove(category);
      }
    });
  }

  void _selectExercise(BuildContext context, String exerciseName) {
    widget.controller.value = TextEditingValue(
      text: exerciseName,
      selection: TextSelection.collapsed(offset: exerciseName.length),
    );
    FocusScope.of(context).unfocus();
  }

  void _setPressedExercise(String? exerciseName) {
    if (pressedExerciseName == exerciseName) {
      return;
    }
    setState(() {
      pressedExerciseName = exerciseName;
    });
  }

  bool get _canSubmitSelection => widget.controller.text.trim().isNotEmpty;

  void _submitSelection(BuildContext context) {
    final selection = widget.controller.text.trim();
    if (selection.isEmpty) {
      return;
    }
    Navigator.of(context).pop(selection);
  }

  Future<void> _openExerciseVideo(BuildContext context, Uri videoUrl) async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      final videoId = YoutubePlayer.convertUrlToId(videoUrl.toString());
      if (videoId == null) {
        await launchUrl(videoUrl, mode: LaunchMode.externalApplication);
        return;
      }
      await Navigator.of(context, rootNavigator: true).push(
        platformPageRoute(
          context: context,
          fullscreenDialog: true,
          builder: (_) => YoutubeVideoScreen(videoId: videoId),
        ),
      );
    } else {
      await launchUrl(videoUrl, mode: LaunchMode.externalApplication);
    }
  }

  List<String> get _filteredExercises {
    return workoutCompletions.entries
        .where((entry) {
          if (videoFilter && entry.value.videoUrl == null) {
            return false;
          }
          if (selectedCategories.isEmpty) {
            return true;
          }
          return selectedCategories.every(entry.value.categories.contains);
        })
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredExercises = _filteredExercises;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final gridColumnCount = isLandscape ? 4 : 2;

    return PlatformScaffold(
      appBar: PlatformAppBar(
        trailingActions: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, child) => PlatformIconButton(
              icon: Icon(PlatformIcons(context).checkMark),
              onPressed: _canSubmitSelection
                  ? () => _submitSelection(context)
                  : null,
            ),
          ),
        ],
        cupertino: (appBarContext, _) => CupertinoNavigationBarData(
          backgroundColor: Colors.transparent,
          leading: PlatformIconButton(
            padding: const EdgeInsets.only(right: 22),
            icon: Icon(AdaptiveIcons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailing: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, child) => PlatformIconButton(
              icon: Icon(PlatformIcons(context).checkMark),
              onPressed: _canSubmitSelection
                  ? () => _submitSelection(context)
                  : null,
            ),
          ),
          title: PlatformText(
            L10n.of(context)!.exerciseEntryPromptText,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkoutAutocompleteTextField(
                textEditingController: widget.controller,
                autofocus: true,
                minLines: 1,
                maxLines: 1,
                categoryFilter: selectedCategories,
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, child) {
                  final showPickerContent = value.text.isEmpty;

                  return Flexible(
                    fit: FlexFit.loose,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: showPickerContent
                          ? Column(
                              key: const ValueKey('picker-content'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final category in orderedCategories)
                                      FilterChip(
                                        label: Text(
                                          category.displayLabel(context),
                                        ),
                                        selected: selectedCategories.contains(
                                          category,
                                        ),
                                        onSelected: (_) =>
                                            _toggleCategory(category),
                                        showCheckmark: false,
                                        labelStyle: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color:
                                                  selectedCategories.contains(
                                                    category,
                                                  )
                                                  ? colorScheme.onPrimary
                                                  : colorScheme.onSurface,
                                            ),
                                        backgroundColor:
                                            colorScheme.surfaceContainerHighest,
                                        selectedColor: colorScheme.primary,
                                        side: BorderSide(
                                          color:
                                              selectedCategories.contains(
                                                category,
                                              )
                                              ? colorScheme.primary
                                              : colorScheme.outlineVariant,
                                        ),
                                        shape: const StadiumBorder(),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    FilterChip(
                                      label: Text(
                                        L10n.of(context)!.exerciseFilterVideoLabel,
                                      ),
                                      selected: videoFilter,
                                      onSelected: (_) => setState(
                                        () => videoFilter = !videoFilter,
                                      ),
                                      showCheckmark: false,
                                      avatar: Icon(
                                        Icons.ondemand_video,
                                        size: 18,
                                        color: videoFilter
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                      ),
                                      labelStyle: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: videoFilter
                                                ? colorScheme.onPrimary
                                                : colorScheme.onSurface,
                                          ),
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      selectedColor: colorScheme.primary,
                                      side: BorderSide(
                                        color: videoFilter
                                            ? colorScheme.primary
                                            : colorScheme.outlineVariant,
                                      ),
                                      shape: const StadiumBorder(),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Expanded(
                                  child: GridView.builder(
                                    itemCount: filteredExercises.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: gridColumnCount,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          mainAxisExtent: 72,
                                        ),
                                    itemBuilder: (context, index) {
                                      final exerciseName =
                                          filteredExercises[index];
                                      final exerciseEntry =
                                          workoutCompletions[exerciseName]!;
                                      final videoUrl = exerciseEntry.videoUrl;
                                      final isSelected =
                                          widget.controller.text ==
                                          exerciseName;
                                      final isPressed =
                                          pressedExerciseName == exerciseName;

                                      return GestureDetector(
                                        onTapDown: (_) =>
                                            _setPressedExercise(exerciseName),
                                        onTapCancel: () =>
                                            _setPressedExercise(null),
                                        onTapUp: (_) =>
                                            _setPressedExercise(null),
                                        onTap: () => _selectExercise(
                                          context,
                                          exerciseName,
                                        ),
                                        child: AnimatedScale(
                                          duration: const Duration(
                                            milliseconds: 100,
                                          ),
                                          scale: isPressed ? 0.97 : 1,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 100,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPressed
                                                  ? (isSelected
                                                        ? colorScheme.primary
                                                              .withValues(
                                                                alpha: 0.22,
                                                              )
                                                        : colorScheme.primary
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ))
                                                  : (isSelected
                                                        ? colorScheme
                                                              .primaryContainer
                                                        : colorScheme
                                                              .surfaceContainerHighest),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? colorScheme.primary
                                                    : colorScheme
                                                          .outlineVariant,
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                    12,
                                                    12,
                                                    videoUrl == null ? 12 : 45,
                                                    12,
                                                  ),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: AutoSizeText(
                                                      exerciseName,
                                                      maxLines: 2,
                                                      minFontSize: 10,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            color: isSelected
                                                                ? colorScheme
                                                                      .onPrimaryContainer
                                                                : colorScheme
                                                                      .onSurface,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                if (videoUrl != null)
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: IconButton(
                                                      onPressed: () =>
                                                          _openExerciseVideo(
                                                            context,
                                                            videoUrl,
                                                          ),
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 42,
                                                            minHeight: 42,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      style: IconButton.styleFrom(
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                        foregroundColor:
                                                            isSelected
                                                            ? colorScheme
                                                                  .onPrimaryContainer
                                                            : colorScheme
                                                                  .primary,
                                                      ),
                                                      icon: const Icon(
                                                        Icons.ondemand_video,
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('hidden-picker-content'),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
