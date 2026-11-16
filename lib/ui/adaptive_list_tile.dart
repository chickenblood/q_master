import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material;

import 'adaptive_platform.dart';

/// A tappable Material or Cupertino list row with shared title and padding.
///
/// Material rows use the split-package theme and a transparent Material
/// ancestor so their background and ink effects render in legacy screens.
class AdaptiveListTile extends StatelessWidget {
  const AdaptiveListTile({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
    this.padding,
  });

  final Widget title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => isMaterialPlatform(context)
      ? material.Material(
          type: material.MaterialType.transparency,
          child: material.ListTile(
            title: title,
            trailing: trailing,
            onTap: onTap,
            contentPadding: padding,
          ),
        )
      : cupertino.CupertinoListTile(
          title: title,
          trailing: trailing,
          onTap: onTap,
          padding: padding,
        );
}
