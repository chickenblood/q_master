import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../model/exicon_fetcher.dart';
import '../utils/text_editing_value_utils.dart';
import 'exicon_catalog.dart';

/// A text field with autocomplete functionality for describing workouts.
class WorkoutAutocompleteTextField extends ConsumerStatefulWidget {
  final TextEditingController textEditingController;
  final OptionsViewOpenDirection optionsViewOpenDirection;
  final bool autofocus;
  final Set<String> tagFilter;
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
    this.tagFilter = const <String>{},
    int? minLines,
    int? maxLines,
    this.expands,
    this.onTap,
    this.onSubmitted,
  }) : _minLines = expands == true ? null : (minLines ?? 1),
       _maxLines = expands == true ? null : (maxLines ?? 1);

  @override
  ConsumerState<WorkoutAutocompleteTextField> createState() =>
      _WorkoutAutocompleteTextFieldState();
}

class _WorkoutAutocompleteTextFieldState
    extends ConsumerState<WorkoutAutocompleteTextField> {
  final focusNode = FocusNode();
  var _replacementRange = TextRange.collapsed(-1);

  bool get _showClearButton => widget.textEditingController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_onTextChanged);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(focusNode);
      });
    }
  }

  @override
  void didUpdateWidget(covariant WorkoutAutocompleteTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textEditingController != widget.textEditingController) {
      oldWidget.textEditingController.removeListener(_onTextChanged);
      widget.textEditingController.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearText() {
    widget.textEditingController.clear();
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_onTextChanged);
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
  Widget build(BuildContext context) {
    final catalog = ref
        .watch(exiconFetcherProvider)
        .maybeWhen(
          data: buildWorkoutCatalog,
          orElse: () => const <WorkoutCatalogExercise>[],
        );

    return Autocomplete<String>(
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

        if (precedingText.isEmpty) {
          return const Iterable<String>.empty();
        }

        final completions = catalog
            .where((exercise) {
              if (!exercise.matchesQuery(precedingText)) {
                return false;
              }

              if (widget.tagFilter.isEmpty) {
                return true;
              }

              return widget.tagFilter.every(exercise.filterTagKeys.contains);
            })
            .map((exercise) => exercise.name);

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
            return PlatformTextField(
              minLines: widget._minLines,
              maxLines: widget._maxLines,
              expands: widget.expands,
              autocorrect: false,
              textCapitalization: TextCapitalization.sentences,
              controller: textEditingController,
              focusNode: focusNode,
              onTap: widget.onTap,
              cupertino: (_, _) => CupertinoTextFieldData(
                clearButtonMode: OverlayVisibilityMode.editing,
              ),
              material: (_, _) => MaterialTextFieldData(
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  suffixIcon: _showClearButton
                      ? IconButton(
                          onPressed: _clearText,
                          icon: const Icon(Icons.clear),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).deleteButtonTooltip,
                        )
                      : null,
                ),
              ),
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
            return Material(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                reverse: widget.optionsViewOpenDirection == .up,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  final startIndex = option.toLowerCase().indexOf(
                    highlightText,
                  );
                  final textStyle = Theme.of(context).textTheme.titleLarge!;
                  final title = startIndex < 0
                      ? Text(option, style: textStyle)
                      : RichText(
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
                        );
                  return GlassListTile(
                    title: title,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            );
          },
    );
  }
}
