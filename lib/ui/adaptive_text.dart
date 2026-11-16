import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

import 'adaptive_platform.dart';

/// Text that preserves the app's platform-specific capitalization rules.
///
/// The shared Flutter text widget is used by both split UI packages. Material
/// 2 text is uppercased; Material 3 and Cupertino text retain their casing.
class AdaptiveText extends StatelessWidget {
  const AdaptiveText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.textScaler,
    this.maxLines,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
    isMaterialPlatform(context) && !Theme.of(context).useMaterial3
        ? data.toUpperCase()
        : data,
    style: style,
    textAlign: textAlign,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
  );
}
