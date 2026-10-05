import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'adaptive_menu.dart';

/// A class representing an action button with an icon and a callback.
///
/// Used for a GlassTabBarTrailingButton on iOS and a FloatingActionButton on
/// Android.
/// The colors will be ignored on iOS as the trailing button will use the style
/// of the tab bar.
final class AdaptiveAccessoryActionItem {
  static void _noOp(GlassMorphAnchor? _) {}

  final Widget icon;
  final List<AdaptiveMenuItem> menuItems;
  // GlassMorphAnchor is used for the iOS trailing button tap callback.
  final Function(GlassMorphAnchor? glassAnchor) onPressed;
  final Object? id;
  final Color? foregroundColor;
  final Color? backgroundColor;

  /// Creates a standard action item with an icon and a callback.
  const AdaptiveAccessoryActionItem({
    required this.icon,
    this.id,
    this.foregroundColor,
    this.backgroundColor,
    required this.onPressed,
  }) : menuItems = const [];

  /// Creates an action item that invokes a menu when tapped.
  const AdaptiveAccessoryActionItem.menu({
    required this.icon,
    required this.menuItems,
    this.id,
    this.foregroundColor,
    this.backgroundColor,
  }) : onPressed = _noOp,
       assert(
         menuItems != const <AdaptiveMenuItem>[],
         'Menu items cannot be empty',
       );
}
