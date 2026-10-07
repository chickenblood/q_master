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
final class AdaptiveTabBar extends StatefulWidget {
  final List<AdaptiveTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool visible;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final AdaptiveAccessoryActionItem? trailingButton;
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
  State<AdaptiveTabBar> createState() => _AdaptiveTabBarState();
}

final class _AdaptiveTabBarState extends State<AdaptiveTabBar> {
  // Handle minimizing the tab bar when scrolling down.
  final _minimizeController = GlassTabBarMinimizeController(
    behavior: .onScrollDown,
  );

  @override
  void dispose() {
    _minimizeController.dispose();
    super.dispose();
  }

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
    visible: widget.visible,
    child: PlatformWidget(
      material: (_, _) => BottomNavigationBar(
        items: widget.items
            .map(
              (item) =>
                  BottomNavigationBarItem(icon: item.icon, label: item.label),
            )
            .toList(),
        currentIndex: widget.selectedIndex,
        onTap: widget.onTabSelected,
        selectedItemColor: widget.selectedIconColor,
        unselectedItemColor: widget.unselectedIconColor,
      ),
      cupertino: (_, _) => SafeArea(
        bottom: false,
        child: GlassMorphTrigger(
          builder: (innerContext, anchor) => GlassTabBar.minimizable(
            tabs: widget.items
                .map((item) => GlassTab(icon: item.icon, label: item.label))
                .toList(),
            selectedIndex: widget.selectedIndex,
            onTabSelected: widget.onTabSelected,
            selectedIconColor: widget.selectedIconColor,
            minimizeController: _minimizeController,
            scrollController: widget.scrollController,
            onMinimizedTabTap: _minimizeController.expand,
            trailingButton: _buildTrailingButton(
              widget.trailingButton,
              anchor: anchor,
            ),
          ),
        ),
      ),
    ),
  );
}
