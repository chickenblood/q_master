import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (_, _) => GlassSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      focusNode: focusNode,
      autofocus: autofocus ?? false,
    ),
    material: (_, _) => Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: activeColor,
      inactiveTrackColor: inactiveColor,
      focusNode: focusNode,
      autofocus: autofocus ?? false,
    ),
  );
}
