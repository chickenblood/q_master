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
  final GlassTabBarMinimizeController minimizeController;
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
    GlassTabBarMinimizeController? minimizeController,
    this.trailingButton,
  }) : minimizeController = minimizeController ?? GlassTabBarMinimizeController();

  GlassTabBarTrailingButton? _buildTrailingButton(
    AdaptiveAccessoryActionItem? trailingItem, {
    GlassMorphAnchor? anchor,
  }) {
    if (trailingItem == null) return null;

    if (trailingItem.menuItems.isEmpty) {
      return GlassTabBarTrailingButton(
        icon: trailingItem.icon,
        onTap: () => trailingItem.onPressed(anchor),
      );
    } else {
      return GlassTabBarTrailingButton.menu(
        icon: trailingItem.icon,
        menuWidth: 250,
        menuItems: trailingItem.menuItems
            .map(
              (e) => GlassMenuItem(
                icon: e.icon,
                title: e.title,
                onTap: e.onPressed,
                isDestructive: e.isDestructive,
              ),
            )
            .toList(),
      );
    }
  }

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
      cupertino: (_, _) => SafeArea(
        bottom: false,
        child: GlassMorphTrigger(
          builder: (innerContext, anchor) => GlassTabBar.minimizable(
            tabs: items
                .map((item) => GlassTab(icon: item.icon, label: item.label))
                .toList(),
            selectedIndex: selectedIndex,
            onTabSelected: onTabSelected,
            selectedIconColor: selectedIconColor,
            minimizeController: minimizeController,
            scrollController: scrollController,
            onMinimizedTabTap: minimizeController.expand,
            trailingButton: _buildTrailingButton(
              trailingButton,
              anchor: anchor,
            ),
          ),
        ),
      ),
    ),
  );
}
