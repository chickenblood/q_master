import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import './adaptive_accessory_action_item.dart';
import './adaptive_app_bar.dart';

/// Returns the padding that should be applied to bodies in an adaptive
/// scaffold.
///
/// This may be used as padding for simple widget bodies, but should be used
/// as headers and footers for scrollable content.
final adaptivePadding = defaultTargetPlatform == .iOS
    ? EdgeInsets.only(top: kToolbarHeight, bottom: kTextTabBarHeight)
    : EdgeInsets.zero;

/// A class representing an adaptive scaffold that works on both Material and
/// Cupertino platforms.
///
/// The scaffold can have an optional [appBar], a required [body], and an
/// optional [bottomBar].
final class AdaptiveScaffold extends StatelessWidget {
  final AdaptiveAppBar? appBar;
  final Widget body;
  final Widget? bottomBar;
  final Color? backgroundColor;
  final AdaptiveAccessoryActionItem? floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  final bool? extendBody;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomBar,
    this.backgroundColor,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    this.extendBody,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (_, _) => Scaffold(
        appBar: appBar,
        extendBodyBehindAppBar: true,
        extendBody: extendBody ?? true,
        backgroundColor: backgroundColor,
        body: body,
        bottomNavigationBar: bottomBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton != null
            ? FloatingActionButton(
                onPressed: () => floatingActionButton!.onPressed(null),
                foregroundColor: floatingActionButton!.foregroundColor,
                backgroundColor: floatingActionButton!.backgroundColor,
                heroTag: floatingActionButton!.id,
                child: floatingActionButton!.icon,
              )
            : null,
      ),
      cupertino: (_, _) => GlassScaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        body: body,
        bottomBar: bottomBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody ?? true,
      ),
    );
  }
}
