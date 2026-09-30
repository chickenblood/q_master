import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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

/// A class representing an action button with an icon and a callback.
///
/// Creates a GlassTabBarTrailingButton on iOS and a FloatingActionButton on
/// Android.
/// The colors will be ignored on iOS as the trailing button will use the style
/// of the tab bar.
final class AdaptiveAccessoryActionButton {
  final Widget icon;
  final VoidCallback onTap;
  final Object? id;
  final Color? foregroundColor;
  final Color? backgroundColor;
  const AdaptiveAccessoryActionButton({
    required this.icon,
    this.id,
    this.foregroundColor,
    this.backgroundColor,
    required this.onTap,
  });
}

/// A tab bar that adapts to the platform (Material or Cupertino).
///
/// Supports auto-minimizing on iOS if a ScrollController is provided.
final class AdaptiveTabBar extends StatelessWidget {
  final List<AdaptiveTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final AdaptiveAccessoryActionButton? accessoryActionButton;
  final minimizeController = GlassTabBarMinimizeController();
  final ScrollController? scrollController;

  AdaptiveTabBar({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    required this.onTabSelected,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.scrollController,
    this.accessoryActionButton,
  });

  @override
  Widget build(BuildContext context) => PlatformWidget(
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
    cupertino: (_, _) => GlassTabBar.minimizable(
      tabs: items
          .map((item) => GlassTab(icon: item.icon, label: item.label))
          .toList(),
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      minimizeController: minimizeController,
      scrollController: scrollController,
      onMinimizedTabTap: minimizeController.expand,
      trailingButton: accessoryActionButton != null
          ? GlassTabBarTrailingButton(
              icon: accessoryActionButton!.icon,
              onTap: accessoryActionButton!.onTap,
            )
          : null,
    ),
  );
}
