import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

/// Navigation text field that adapts to iOS Liquid Glass or Material style.
///
/// Use this widget for text fields in app bars and bottom bars that need to
/// match the platform's style.
final class AdaptiveNavTextField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final bool enabled;
  final EdgeInsets padding;
  final FocusNode? focusNode;
  final TextStyle? textStyle;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool? obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization? textCapitalization;
  final bool? readOnly;
  final bool? autofocus;
  final TapRegionCallback? onTapOutside;

  const AdaptiveNavTextField({
    super.key,
    this.label,
    this.controller,
    this.enabled = true,
    this.padding = EdgeInsets.zero,
    this.focusNode,
    this.textStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textCapitalization,
    this.readOnly,
    this.autofocus,
    this.onTapOutside,
  });
  @override
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (context, platform) => GlassTextField(
      controller: controller,
      enabled: enabled,
      padding: padding,
      focusNode: focusNode,
      textStyle: textStyle,
      placeholder: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText ?? false,
      maxLines: maxLines ?? 1,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      readOnly: readOnly ?? false,
      autofocus: autofocus ?? false,
      onTapOutside: onTapOutside,
    ),
    material: (context, platform) => TextField(
      controller: controller,
      enabled: enabled,
      focusNode: focusNode,
      style: textStyle,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText ?? false,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      readOnly: readOnly ?? false,
      autofocus: autofocus ?? false,
      onTapOutside: onTapOutside,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: padding,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    ),
  );
}
