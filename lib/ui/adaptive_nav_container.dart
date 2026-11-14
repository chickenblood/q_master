import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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
  Widget build(BuildContext context) => PlatformWidget(
    cupertino: (context, platform) => GlassContainer(
      shape: LiquidRoundedRectangle(borderRadius: kToolbarHeight / 2),
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      margin: margin,
      color: color,
      child: child,
    ),
    material: (context, platform) => Container(
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
