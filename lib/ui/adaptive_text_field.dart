import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material;

import 'adaptive_platform.dart';

/// A text field backed by the split Material and Cupertino packages.
///
/// Providing [onMaterialClear] enables a themed outline and optional clear
/// button on Material, and the native editing-time clear button on Cupertino.
/// Cupertino reports a clear through [onChanged], rather than this callback.
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.autofocus = false,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.minLines,
    this.maxLines = 1,
    this.expands = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onMaterialClear,
    this.showClearButton = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final bool autofocus;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;

  /// Clears the Material field and enables clearing on both platforms.
  final VoidCallback? onMaterialClear;

  /// Whether to show the Material clear button when clearing is enabled.
  final bool showClearButton;

  @override
  Widget build(BuildContext context) {
    if (!isMaterialPlatform(context)) {
      return cupertino.CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: hintText,
        autofocus: autofocus,
        autocorrect: autocorrect,
        textCapitalization: textCapitalization,
        minLines: minLines,
        maxLines: maxLines,
        expands: expands,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
        padding: const EdgeInsets.all(6),
        cursorColor: cupertino.CupertinoColors.activeBlue,
        clearButtonMode: onMaterialClear == null
            ? cupertino.OverlayVisibilityMode.never
            : cupertino.OverlayVisibilityMode.editing,
      );
    }

    final theme = material.Theme.of(context);
    return material.Material(
      type: material.MaterialType.transparency,
      child: material.TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        autocorrect: autocorrect,
        textCapitalization: textCapitalization,
        minLines: minLines,
        maxLines: maxLines,
        expands: expands,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
        decoration: onMaterialClear == null
            ? material.InputDecoration(hintText: hintText)
            : material.InputDecoration(
                hintText: hintText,
                enabledBorder: material.OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline,
                    width: 2,
                  ),
                ),
                focusedBorder: material.OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                suffixIcon: showClearButton
                    ? material.IconButton(
                        onPressed: onMaterialClear,
                        icon: const Icon(material.Icons.clear),
                        tooltip: material.MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                      )
                    : null,
              ),
      ),
    );
  }
}
