import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

final class AdaptiveSegment {
  final String label;
  final Widget? icon;

  const AdaptiveSegment({required this.label, this.icon});
}

final class AdaptiveSegmentedControl extends StatelessWidget {
  final List<AdaptiveSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;

  const AdaptiveSegmentedControl({
    super.key,
    required this.segments,
    this.selectedIndex = 0,
    required this.onSegmentSelected,
  });

  @override
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (innerContext, _) => GlassSegmentedControl(
      segments: segments
          .map((e) => GlassSegment(label: e.label, icon: e.icon))
          .toList(),
      selectedIndex: selectedIndex,
      onSegmentSelected: onSegmentSelected,
      indicatorColor: Theme.of(innerContext).colorScheme.primary,
    ),
    material: (_, _) => SegmentedButton<int>(
      showSelectedIcon: false,
      segments: segments
          .asMap()
          .entries
          .map(
            (entry) => ButtonSegment<int>(
              value: entry.key,
              icon: entry.value.icon,
              label: Text(entry.value.label),
            ),
          )
          .toList(),
      selected: {selectedIndex},
      onSelectionChanged: (values) => onSegmentSelected(values.first),
    ),
  );
}
