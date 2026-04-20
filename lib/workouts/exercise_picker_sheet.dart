import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_modal_sheet.dart';
import 'workout_auto_completions.dart';
import 'workout_constants.dart';

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

  static const orderedCategories = <ExerciseCategory>[
    .core,
    .cardio,
    .strength,
    .legs,
    .arms,
    .fullBody,
  ];

  void _toggleCategory(ExerciseCategory category) {
    setState(() {
      if (!selectedCategories.add(category)) {
        selectedCategories.remove(category);
      }
    });
  }

  void _selectExercise(String exerciseName) {
    widget.controller.value = TextEditingValue(
      text: exerciseName,
      selection: TextSelection.collapsed(offset: exerciseName.length),
    );
  }

  bool get _canSubmitSelection => widget.controller.text.trim().isNotEmpty;

  void _submitSelection(BuildContext context) {
    final selection = widget.controller.text.trim();
    if (selection.isEmpty) {
      return;
    }
    Navigator.of(context).pop(selection);
  }

  List<String> get _filteredExercises {
    return workoutCompletions.entries
        .where((entry) {
          if (selectedCategories.isEmpty) {
            return true;
          }
          return entry.value.any(selectedCategories.contains);
        })
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredExercises = _filteredExercises;

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
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: filteredExercises.length,
                                    itemBuilder: (context, index) {
                                      final exerciseName =
                                          filteredExercises[index];
                                      return PlatformListTile(
                                        title: Text(exerciseName),
                                        onTap: () =>
                                            _selectExercise(exerciseName),
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
