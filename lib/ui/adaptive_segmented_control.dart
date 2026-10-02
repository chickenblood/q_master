import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

final class AdaptiveSegment {
  final String label;

  const AdaptiveSegment({required this.label});
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
      segments: segments.map((e) => GlassSegment(label: e.label)).toList(),
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
              label: Text(entry.value.label),
            ),
          )
          .toList(),
      selected: {selectedIndex},
      onSelectionChanged: (values) => onSegmentSelected(values.first),
    ),
  );
}
