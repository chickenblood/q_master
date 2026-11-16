// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material;

import 'material_theme.dart' as gloom;

/// Supplies split-package themes alongside the existing Flutter themes.
///
/// Place above the root navigator so routes inherit both theme families. The
/// split theme follows the legacy Material theme's brightness and platform.
class TransitionTheme extends StatelessWidget {
  const TransitionTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final legacyTheme = legacy.Theme.of(context);
    final theme = legacyTheme.brightness == Brightness.dark
        ? gloom.darkTheme()
        : gloom.lightTheme();
    return material.Theme(
      data: theme.copyWith(platform: legacyTheme.platform),
      child: child,
    );
  }
}
