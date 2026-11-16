import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoColors;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import 'src/adaptive_platform_widget.dart';

final class AdaptiveSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final String? label;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final FocusNode? focusNode;
  final bool? autofocus;

  const AdaptiveSlider({
    super.key,
    this.value = 0.5,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 10,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.focusNode,
    this.autofocus,
  });

  @override
  Widget build(BuildContext context) => AdaptivePlatformWidget(
    cupertino: (_) => GlassSlider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      label: label,
      activeColor: activeColor ?? Theme.of(context).colorScheme.primary,
      inactiveColor: inactiveColor,
      thumbColor: thumbColor ?? CupertinoColors.white,
      focusNode: focusNode,
      autofocus: autofocus ?? false,
    ),
    material: (_) => Material(
      type: MaterialType.transparency,
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        label: label,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        thumbColor: thumbColor,
        focusNode: focusNode,
        autofocus: autofocus ?? false,
      ),
    ),
  );
}
