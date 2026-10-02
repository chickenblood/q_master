import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

final class AdaptiveSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const AdaptiveSlider({
    super.key,
    this.value = 0.5,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 10,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (context, platform) => GlassSlider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    ),
    material: (context, platform) => Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    ),
  );
}
