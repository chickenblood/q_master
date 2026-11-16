import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material;

import 'adaptive_platform.dart';

/// An icon button using Material or Cupertino styling for the active platform.
///
/// [cupertinoPadding] overrides [padding] on Cupertino platforms.
class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.padding,
    this.cupertinoPadding,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? cupertinoPadding;

  @override
  Widget build(BuildContext context) => isMaterialPlatform(context)
      ? material.Material(
          type: material.MaterialType.transparency,
          child: material.IconButton(
            icon: icon,
            onPressed: onPressed,
            padding: padding ?? const EdgeInsets.all(8),
          ),
        )
      : cupertino.CupertinoButton(
          onPressed: onPressed,
          padding: cupertinoPadding ?? padding,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          pressedOpacity: 0.4,
          disabledColor: cupertino.CupertinoColors.quaternarySystemFill,
          child: icon,
        );
}

/// A Material text button or an unfilled Cupertino button.
///
/// A null [onPressed] disables the button on either platform.
class AdaptiveTextButton extends StatelessWidget {
  const AdaptiveTextButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => isMaterialPlatform(context)
      ? material.TextButton(
          onPressed: onPressed,
          style: material.TextButton.styleFrom(padding: padding),
          child: child,
        )
      : cupertino.CupertinoButton(
          onPressed: onPressed,
          padding: padding,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          pressedOpacity: 0.4,
          disabledColor: cupertino.CupertinoColors.quaternarySystemFill,
          child: child,
        );
}

/// An elevated Material button or a filled Cupertino button.
///
/// When supplied, [color] sets the background on both platforms.
class AdaptiveElevatedButton extends StatelessWidget {
  const AdaptiveElevatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (isMaterialPlatform(context)) {
      return material.ElevatedButton(
        onPressed: onPressed,
        style: material.ElevatedButton.styleFrom(backgroundColor: color),
        child: child,
      );
    }

    final button = cupertino.CupertinoButton.filled(
      onPressed: onPressed,
      color: color,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      pressedOpacity: 0.4,
      disabledColor: cupertino.CupertinoColors.quaternarySystemFill,
      child: child,
    );
    return color == null
        ? button
        : cupertino.CupertinoTheme(
            data: cupertino.CupertinoTheme.of(context)
                .copyWith(primaryColor: color),
            child: button,
          );
  }
}
