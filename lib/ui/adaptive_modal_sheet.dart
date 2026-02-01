import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../ui/media_query.dart';

/// Presents a modal sheet, utlizing the perspetive modal presentation style on
/// iPhone.
///
/// On tablet, it presents a form-style dialog for iOS and Android.
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required Widget child,
  bool dismissible = true,
}) {
  final platform = Theme.of(context).platform;
  final isTablet = MediaUtils.isTablet(context);
  return switch ((platform, isTablet)) {
    (_, true) => showAdaptiveDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: .blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          insetPadding: const EdgeInsets.all(150),
          clipBehavior: .hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: child,
        ),
      ),
    ),
    (TargetPlatform.iOS, false) => showCupertinoSheet(
      context: context,
      enableDrag: dismissible,
      builder: (_) => child,
    ),
    (TargetPlatform.android, false) => Navigator.push(
      context,
      platformPageRoute(
        context: context,
        fullscreenDialog: true,
        builder: (_) => child,
      ),
    ),
    _ => Future.value(null),
  };
  return null;
}
