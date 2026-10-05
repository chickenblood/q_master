import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A class representing a menu item with an icon, an optional label, and a
/// callback.
///
/// Used within an [AdaptiveMenu] or [AdaptiveAccessoryActionItem] to define
/// individual menu options.
final class AdaptiveMenuItem {
  final Widget icon;
  final String title;
  final bool isDestructive;
  final void Function() onPressed;

  const AdaptiveMenuItem({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    required this.onPressed,
  });
}

/// Popup menu that adopts iOS or Material native style.
final class AdaptiveMenu extends StatelessWidget {
  final Icon icon;
  final List<AdaptiveMenuItem> menuChildren;

  const AdaptiveMenu({
    super.key,
    required this.icon,
    required this.menuChildren,
  });

  @override
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (context, platform) => GlassPullDownButton(
      menuWidth: 280,
      icon: icon,
      items: [
        ...menuChildren.map(
          (item) => GlassMenuItem(
            title: item.title,
            icon: item.icon,
            isDestructive: item.isDestructive,
            onTap: item.onPressed,
          ),
        ),
      ],
    ),
    material: (context, platform) => MenuAnchor(
      consumeOutsideTap: true,
      builder: (context, controller, child) => PlatformIconButton(
        icon: icon,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: menuChildren
          .map(
            (item) => MenuItemButton(
              onPressed: item.onPressed,
              trailingIcon: Row(children: [SizedBox(width: 20), item.icon]),
              child: PlatformText(
                item.title,
                style: TextTheme.of(context).titleLarge!,
              ),
            ),
          )
          .toList(),
    ),
  );
}
