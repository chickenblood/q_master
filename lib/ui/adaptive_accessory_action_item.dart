import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A class representing an action button with an icon and a callback.
///
/// Used for a GlassTabBarTrailingButton on iOS and a FloatingActionButton on
/// Android.
/// The colors will be ignored on iOS as the trailing button will use the style
/// of the tab bar.
final class AdaptiveAccessoryActionItem {
  final Widget icon;
  // GlassMorphAnchor is used for the iOS trailing button tap callback.
  final Function(GlassMorphAnchor? glassAnchor) onTap;
  final Object? id;
  final Color? foregroundColor;
  final Color? backgroundColor;
  const AdaptiveAccessoryActionItem({
    required this.icon,
    this.id,
    this.foregroundColor,
    this.backgroundColor,
    required this.onTap,
  });
}
