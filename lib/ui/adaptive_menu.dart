import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:pull_down_button/pull_down_button.dart';

final class AdaptiveMenuItem {
  final String text;
  final IconData icon;
  final void Function() onPressed;

  const AdaptiveMenuItem({required this.text, required this.icon, required this.onPressed});
}

/// Popup menu that adopts iOS or Material native style.
final class AdaptiveMenu extends StatelessWidget {
  final Icon icon;
  final List<AdaptiveMenuItem> menuChildren;

  const AdaptiveMenu({super.key, required this.icon, required this.menuChildren});

  @override
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (context, platform) => PullDownButton(
      buttonBuilder: (_, showMenu) => CupertinoButton(
        onPressed: showMenu,
    child: const Icon(CupertinoIcons.ellipsis_circle),
      ),
      itemBuilder: (context) => menuChildren.map((item) => PullDownMenuItem(
        title: item.text,
        icon: item.icon,
        onTap: item.onPressed)
      ).toList(),
    ),
    material: (context, platform) => MenuAnchor(
        consumeOutsideTap: true,
      builder: (context, controller, child) => PlatformIconButton(
            icon: icon,
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        menuChildren: menuChildren.map(
          (item) => MenuItemButton(
          onPressed: item.onPressed,
            trailingIcon: Row(
              children: [
                SizedBox(width: 20),
                Icon(item.icon),
              ],
            ),
            child: PlatformText(
              item.text,
              style: TextTheme.of(context).titleLarge!,
            ),
          ),
        ).toList(),
      ),
  );

}