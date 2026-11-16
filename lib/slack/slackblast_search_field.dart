import 'package:flutter/widgets.dart';

import '../ui/adaptive_text_field.dart';

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
  Widget build(BuildContext context) => AdaptiveTextField(
    controller: widget.controller,
    focusNode: widget.focusNode,
    hintText: widget.hintText,
    autocorrect: false,
    onChanged: widget.onChanged,
    onMaterialClear: _clearText,
    showClearButton: _showClearButton,
  );
}
