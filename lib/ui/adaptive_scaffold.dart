import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import './adaptive_app_bar.dart';
import './adaptive_tab_bar.dart';

/// A class representing an adaptive scaffold that works on both Material and
/// Cupertino platforms.
///
/// The scaffold can have an optional [appBar], a required [body], and an
/// optional [bottomBar].
final class AdaptiveScaffold extends StatelessWidget {
  final AdaptiveAppBar? appBar;
  final Widget body;
  final Widget? bottomBar;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) => PlatformWidget(
    material: (_, _) {
      final accessoryActionButton = (bottomBar is AdaptiveTabBar)
          ? (bottomBar as AdaptiveTabBar).accessoryActionButton
          : null;
      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomBar,
        floatingActionButton: accessoryActionButton != null
            ? FloatingActionButton(
                onPressed: accessoryActionButton.onTap,
                foregroundColor: accessoryActionButton.foregroundColor,
                backgroundColor: accessoryActionButton.backgroundColor,
                child: accessoryActionButton.icon,
              )
            : null,
      );
    },
    cupertino: (_, _) =>
        GlassScaffold(appBar: appBar, body: body, bottomBar: bottomBar),
  );
}
