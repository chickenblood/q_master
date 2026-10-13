import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A class representing an item in the adaptive button bar.
///
/// Each item has an optional [label], a required [icon], an optional [id],
/// and a required [onPressed] callback.
final class AdaptiveButtonBarItem {
  final Widget icon;
  final Object? id;
  final VoidCallback onPressed;
  const AdaptiveButtonBarItem({
    required this.icon,
    this.id,
    required this.onPressed,
  });
}

/// A button bar that adapts to the platform (Material or Cupertino).
///
/// Usually displayed at the bottom of a scaffold as an alternative to
/// [AdaptiveTabBar].
final class AdaptiveButtonBar extends StatelessWidget {
  final List<AdaptiveButtonBarItem> items;
  final MainAxisAlignment mainAxisAlignment;

  const AdaptiveButtonBar({
    super.key,
    required this.items,
    this.mainAxisAlignment = .end,
  });

  @override
  Widget build(BuildContext context) => PlatformWidget(
    material: (_, _) => Padding(
      padding: EdgeInsets.only(bottom: 40, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          ...items.map(
            (item) => IconButton(icon: item.icon, onPressed: item.onPressed),
          ),
        ],
      ),
    ),
    cupertino: (_, _) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          GlassButtonGroup.icons(
            items: items
                .map(
                  (item) => GlassButtonGroupItem(
                    icon: item.icon,
                    onTap: item.onPressed,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );
}
