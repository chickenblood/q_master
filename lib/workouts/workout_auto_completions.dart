import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/utils/text_editing_value_utils.dart';

import 'workout_constants.dart';

/// A text field with autocomplete functionality for describing workouts.
class WorkoutAutocompleteTextField extends StatefulWidget {
  final TextEditingController textEditingController;
  final OptionsViewOpenDirection optionsViewOpenDirection;
  final bool autofocus;
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

  // Adjusts the caret to be placed after the newly-inserted text.
  void _updateCaretForOptionText(String text) {
    if (_replacementRange.isValid) {
      // Hack to ensure the caret is placed at the correct point after the
      // replacement.
      final selection = TextSelection.collapsed(
        offset: _replacementRange.start + text.length,
      );
      final entireText = widget.textEditingController.text;

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
      final completions = workoutCompletions.where((String option) {
        return option.toLowerCase().startsWith(precedingText.toLowerCase());
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
            autofocus: widget.autofocus,
            expands: widget.expands,
            autocorrect: false,
            textCapitalization: TextCapitalization.sentences,
            controller: textEditingController,
            focusNode: focusNode,
            onTap: widget.onTap,
            onSubmitted: (String value) {
              onFieldSubmitted();
              widget.onSubmitted?.call(); // Important for form submission
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
