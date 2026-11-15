// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'src/adaptive_platform_widget.dart';

/// Container that adopts iOS Liquid Glass or Material native style.
///
/// For use in app bars and floating chrome.
final class AdaptiveNavContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Widget? child;

  const AdaptiveNavContainer({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.alignment,
    this.margin,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) => AdaptivePlatformWidget(
    cupertino: (_) => GlassContainer(
      shape: LiquidRoundedRectangle(borderRadius: kToolbarHeight / 2),
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      margin: margin,
      color: color,
      child: child,
    ),
    material: (_) => Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      margin: margin,
      color: color,
      child: child,
    ),
  );
}
