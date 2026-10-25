import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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

  const AdaptiveNavTextField({
    super.key,
    this.label,
    this.controller,
    this.enabled = true,
    this.padding = EdgeInsets.zero,
    this.focusNode,
    this.textStyle,
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
    ),
    material: (context, platform) => TextField(
      controller: controller,
      enabled: enabled,
      focusNode: focusNode,
      style: textStyle,
      decoration: InputDecoration(labelText: label, contentPadding: padding),
    ),
  );
}
