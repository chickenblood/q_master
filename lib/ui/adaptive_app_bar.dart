import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A class representing an item in the adaptive app bar.
///
/// Each item has an optional [label], a required [icon], an optional [id],
/// and a required [onPressed] callback.
final class AdaptiveBarItem {
  final String? label;
  final Widget icon;
  final Object? id;
  final VoidCallback onPressed;
  const AdaptiveBarItem({
    this.label,
    required this.icon,
    this.id,
    required this.onPressed,
  });
}

/// A class representing an adaptive app bar that works on both Material and
/// Cupertino platforms.
///
/// The app bar can have an optional [title], a list of [leading] items, a list
/// of [actions] items.
/// The bar supports Liquid Glass animations on iOS.
final class AdaptiveAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final Widget? title;
  final List<AdaptiveBarItem> leading;
  final List<AdaptiveBarItem> actions;

  const AdaptiveAppBar({
    super.key,
    this.title,
    this.leading = const [],
    this.actions = const [],
  });

  // TODO: This could be wrong.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => PlatformWidget(
    material: (_, _) {
      final leadingItems = leading
          .map((item) => IconButton(icon: item.icon, onPressed: item.onPressed))
          .toList();
      final actionsItems = actions
          .map((item) => IconButton(icon: item.icon, onPressed: item.onPressed))
          .toList();
      return AppBar(
        title: title,
        leading: Row(children: leadingItems),
        actions: actionsItems,
      );
    },
    cupertino: (_, _) {
      final leadingItems = leading
          .map(
            (item) => GlassBarItem.icon(icon: item.icon, onTap: item.onPressed),
          )
          .toList();
      final actionsItems = actions
          .map(
            (item) => GlassBarItem.icon(icon: item.icon, onTap: item.onPressed),
          )
          .toList();
      return GlassAppBar.pinned(
        title: title,
        leading: leadingItems,
        actions: actionsItems,
      );
    },
  );
}
