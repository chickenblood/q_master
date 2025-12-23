import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'workout_constants.dart';

/// A text field with autocomplete functionality for describing workouts.
class WorkoutAutocompleteTextField extends StatefulWidget {
  final TextEditingController textEditingController;
  final OptionsViewOpenDirection optionsViewOpenDirection;
  final int? _minLines;
  final int? _maxLines;
  final bool? expands;

  const WorkoutAutocompleteTextField({
    super.key,
    required this.textEditingController,
    this.optionsViewOpenDirection = .down,
    int? minLines,
    int? maxLines,
    this.expands,
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
  Widget build(BuildContext context) => Autocomplete<String>(
    textEditingController: widget.textEditingController,
    focusNode: focusNode,
    displayStringForOption: (option) => (_replacementRange.isValid)
        ? widget.textEditingController.value
              .replaced(_replacementRange, option)
              .text
        : '',
    optionsBuilder: (textEditingValue) {
      _replacementRange = TextRange.collapsed(-1);
      final currentComposedText = textEditingValue.text;
      // Do not perform completions if there is a selection.
      if (!textEditingValue.selection.isCollapsed) return [];
      // Get the current word being typed by the user and see if it can be
      // expanded to a suggestion.
      final caretIndex = textEditingValue.selection.baseOffset;
      // Find whitespace or beginning of line.
      var wordStart =
          currentComposedText.lastIndexOf(
            RegExp(r'(^|\s)', multiLine: true),
            max(caretIndex - 1, 0),
          ) +
          1;
      if (wordStart > caretIndex) return [];
      // Find whitespace or end of line.
      var wordEnd = currentComposedText.indexOf(
        RegExp(r'(\$|\n|\s)', multiLine: true),
        caretIndex,
      );
      if (wordEnd == -1) wordEnd = currentComposedText.length;
      final precedingText = currentComposedText.substring(
        wordStart,
        caretIndex,
      );
      if (wordStart != wordEnd && caretIndex == wordEnd) {
        _replacementRange = TextRange(start: wordStart, end: caretIndex);
      }
      debugPrint(
        'wordStart: $wordStart, wordEnd: $wordEnd, '
        'caret index: $caretIndex, '
        'replacementRange: $_replacementRange, '
        'currentComposedText: $currentComposedText '
        'precedingText: $precedingText',
      );

      // If the field is empty, show no options
      if (precedingText == '') {
        return [];
      }

      // Otherwise, filter options based on user input
      return workoutCompletions.where((String option) {
        return option.toLowerCase().startsWith(precedingText.toLowerCase());
      });
    },
    onSelected: (String selection) {
      debugPrint('Suggestion selected $selection');
    },
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
            onSubmitted: (String value) =>
                onFieldSubmitted(), // Important for form submission
          );
        },
    optionsViewOpenDirection: widget.optionsViewOpenDirection,
    optionsViewBuilder:
        (
          BuildContext context,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options,
        ) {
          // Builds the list of suggestions
          return Material(
            child: SafeArea(
              child: ListView.builder(
                shrinkWrap: true,
                reverse: widget.optionsViewOpenDirection == .up,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return PlatformListTile(
                    title: PlatformText(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          );
        },
  );
}
