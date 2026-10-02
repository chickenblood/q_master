import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import './adaptive_accessory_action_item.dart';

/// A class representing an item in the adaptive tab bar.
///
/// Each item has an optional [label], a required [icon], an optional [id],
/// and a required [onPressed] callback.
final class AdaptiveTabItem {
  final String? label;
  final Widget icon;
  final Object? id;
  const AdaptiveTabItem({this.label, required this.icon, this.id});
}

/// A tab bar that adapts to the platform (Material or Cupertino).
///
/// Supports auto-minimizing on iOS if a ScrollController is provided.
final class AdaptiveTabBar extends StatelessWidget {
  final List<AdaptiveTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool visible;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final AdaptiveAccessoryActionItem? trailingButton;
  final minimizeController = GlassTabBarMinimizeController();
  final ScrollController? scrollController;

  AdaptiveTabBar({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    required this.onTabSelected,
    this.visible = true,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.scrollController,
    this.trailingButton,
  });

  @override
  Widget build(BuildContext context) => Visibility(
    visible: visible,
    child: PlatformWidget(
      material: (_, _) => BottomNavigationBar(
        items: items
            .map(
              (item) =>
                  BottomNavigationBarItem(icon: item.icon, label: item.label),
            )
            .toList(),
        currentIndex: selectedIndex,
        onTap: onTabSelected,
        selectedItemColor: selectedIconColor,
        unselectedItemColor: unselectedIconColor,
      ),
      cupertino: (_, _) => GlassMorphTrigger(
        builder: (_, anchor) => GlassTabBar.minimizable(
          tabs: items
              .map((item) => GlassTab(icon: item.icon, label: item.label))
              .toList(),
          selectedIndex: selectedIndex,
          onTabSelected: onTabSelected,
          minimizeController: minimizeController,
          scrollController: scrollController,
          onMinimizedTabTap: minimizeController.expand,
          trailingButton: trailingButton != null
              ? GlassTabBarTrailingButton(
                  icon: trailingButton!.icon,
                  onTap: () => trailingButton!.onTap(anchor),
                )
              : null,
        ),
      ),
    ),
  );
}
