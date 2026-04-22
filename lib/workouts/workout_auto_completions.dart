import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../utils/text_editing_value_utils.dart';
import 'workout_constants.dart';

/// A text field with autocomplete functionality for describing workouts.
class WorkoutAutocompleteTextField extends StatefulWidget {
  final TextEditingController textEditingController;
  final OptionsViewOpenDirection optionsViewOpenDirection;
  final bool autofocus;
  final Set<ExerciseCategory> categoryFilter;
  final int? _minLines;
  final int? _maxLines;
  final bool? expands;
  final VoidCallback? onTap;
  final VoidCallback? onSubmitted;

  const WorkoutAutocompleteTextField({
    super.key,
    required this.textEditingController,
    this.optionsViewOpenDirection = .down,
    this.autofocus = false,
    this.categoryFilter = const <ExerciseCategory>{},
    int? minLines,
    int? maxLines,
    this.expands,
    this.onTap,
    this.onSubmitted,
  }) : _minLines = expands == true ? null : (minLines ?? 1),
       _maxLines = expands == true ? null : (maxLines ?? 1);

  @override
  State<WorkoutAutocompleteTextField> createState() =>
      _WorkoutAutocompleteTextFieldState();
}

class _WorkoutAutocompleteTextFieldState
    extends State<WorkoutAutocompleteTextField> {
  final focusNode = FocusNode();
  var _replacementRange = TextRange.collapsed(-1);

  @override
  void initState() {
    super.initState();

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(focusNode);
      });
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  // Adjusts the caret to be placed after the newly-inserted text.
  void _updateCaretForOptionText(String text) {
    if (_replacementRange.isValid) {
      final entireText = widget.textEditingController.text;

      // Hack to ensure the caret is placed at the correct point after the
      // replacement.
      final selection = TextSelection.collapsed(
        offset: min(_replacementRange.start + text.length, entireText.length),
      );

      widget.textEditingController.value = TextEditingValue(
        text: entireText,
        selection: selection,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Autocomplete<String>(
    textEditingController: widget.textEditingController,
    focusNode: focusNode,
    displayStringForOption: (option) => _replacementRange.isValid
        ? widget.textEditingController.value
              .replaced(_replacementRange, option)
              .text
        : '',
    optionsBuilder: (textEditingValue) {
      final (precedingText, replacementRange) = textEditingValue
          .currentComposedWord();

      // If the field is empty, show no options
      if (precedingText.isEmpty) return [];

      // Otherwise, filter options based on user input
      final completions = workoutCompletions.keys.where((String option) {
        final optionMatchesText = option.toLowerCase().contains(
          precedingText.toLowerCase(),
        );
        if (!optionMatchesText) {
          return false;
        }

        if (widget.categoryFilter.isEmpty) {
          return true;
        }

        final entry = workoutCompletions[option];
        return entry != null &&
            widget.categoryFilter.every(entry.categories.contains);
      });
      if (precedingText.isNotEmpty && completions.isNotEmpty) {
        _replacementRange = replacementRange;
      }
      return completions;
    },
    onSelected: _updateCaretForOptionText,
    fieldViewBuilder:
        (
          BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted,
        ) {
          // Builds the actual text field
          return PlatformTextField(
            minLines: widget._minLines,
            maxLines: widget._maxLines,
            expands: widget.expands,
            autocorrect: false,
            textCapitalization: TextCapitalization.sentences,
            controller: textEditingController,
            focusNode: focusNode,
            onTap: widget.onTap,
            // Important for form submission
            onSubmitted: (_) => onFieldSubmitted,
            onEditingComplete: () {
              widget.onSubmitted?.call();
              focusNode.unfocus();
            },
          );
        },
    optionsViewOpenDirection: widget.optionsViewOpenDirection,
    optionsViewBuilder:
        (
          BuildContext context,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options,
        ) {
          late String highlightText;
          if (_replacementRange.isValid) {
            highlightText = widget.textEditingController.value.text
                .substring(_replacementRange.start, _replacementRange.end)
                .toLowerCase();
          } else {
            highlightText = '';
          }
          // Builds the list of suggestions
          return Material(
            child: SafeArea(
              child: ListView.builder(
                shrinkWrap: true,
                reverse: widget.optionsViewOpenDirection == .up,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  final startIndex = option.toLowerCase().indexOf(
                    highlightText,
                  );
                  final textStyle = Theme.of(context).textTheme.titleLarge!;
                  return PlatformListTile(
                    title: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: option.substring(0, startIndex),
                            style: textStyle,
                          ),
                          TextSpan(
                            text: option.substring(
                              startIndex,
                              startIndex + highlightText.length,
                            ),
                            style: textStyle.copyWith(fontWeight: .bold),
                          ),
                          TextSpan(
                            text: option.substring(
                              startIndex + highlightText.length,
                            ),
                            style: textStyle,
                          ),
                        ],
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          );
        },
  );
}
