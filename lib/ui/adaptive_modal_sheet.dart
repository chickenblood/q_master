import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// Presents a modal sheet, utlizing the perspetive modal presentation style on
/// iOS.
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required Widget child,
}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return showCupertinoSheet(context: context, builder: (_) => child);
  } else {
    return Navigator.push(
      context,
      platformPageRoute(
        context: context,
        fullscreenDialog: true,
        builder: (_) => child,
      ),
    );
  }
}
