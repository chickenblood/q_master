import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A plain clearable search text field, styled to match
/// [WorkoutAutocompleteTextField] but without autocomplete behavior.
class SlackblastSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final void Function(String) onChanged;

  /// Creates a clearable input that sends search text through [onChanged].
  const SlackblastSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hintText,
  });

  @override
  State<SlackblastSearchField> createState() => _SlackblastSearchFieldState();
}

class _SlackblastSearchFieldState extends State<SlackblastSearchField> {
  bool get _showClearButton => widget.controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  /// Clears the input and immediately reports the empty search query.
  void _clearText() {
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlatformTextField(
    controller: widget.controller,
    focusNode: widget.focusNode,
    hintText: widget.hintText,
    autocorrect: false,
    onChanged: widget.onChanged,
    cupertino: (_, _) =>
        CupertinoTextFieldData(clearButtonMode: OverlayVisibilityMode.editing),
    material: (_, _) => MaterialTextFieldData(
      decoration: InputDecoration(
        hintText: widget.hintText,
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
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              )
            : null,
      ),
    ),
  );
}
