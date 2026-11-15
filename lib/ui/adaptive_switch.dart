// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'src/adaptive_platform_widget.dart';

final class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final Color? activeColor;
  final Color? inactiveColor;
  final FocusNode? focusNode;
  final bool? autofocus;
  final ValueChanged<bool> onChanged;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.activeColor,
    this.inactiveColor,
    this.focusNode,
    this.autofocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => AdaptivePlatformWidget(
    cupertino: (_) => GlassSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      focusNode: focusNode,
      autofocus: autofocus ?? false,
    ),
    material: (_) => Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: activeColor,
      inactiveTrackColor: inactiveColor,
      focusNode: focusNode,
      autofocus: autofocus ?? false,
    ),
  );
}
