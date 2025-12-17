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
  var _baseText = '';

  @override
  Widget build(BuildContext context) => Autocomplete<String>(
    textEditingController: widget.textEditingController,
    focusNode: focusNode,
    displayStringForOption: (option) => _baseText + option,
    optionsBuilder: (TextEditingValue textEditingValue) {
      var currentComposedText = textEditingValue.text;
      // Get the last word typed by the user
      final lastSpace = textEditingValue.text.lastIndexOf(' ');
      if (lastSpace != -1) {
        currentComposedText = textEditingValue.text.substring(lastSpace + 1);
        _baseText = textEditingValue.text.substring(0, lastSpace + 1);
      }

      // If the field is empty, show no options
      if (currentComposedText == '') {
        return [];
      }

      // Otherwise, filter options based on user input
      return workoutCompletions.where((String option) {
        return option.toLowerCase().startsWith(
          currentComposedText.toLowerCase(),
        );
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
