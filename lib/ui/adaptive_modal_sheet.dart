import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../ui/media_query.dart';

/// Presents a modal sheet on phone.
///
/// On tablet, it presents a form-style dialog for iOS and Android.
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required Widget child,
  bool dismissible = true,
}) {
  final isTablet = MediaUtils.isTablet(context);
  return isTablet
      ? showAdaptiveDialog(
          context: context,
          builder: (_) => BackdropFilter(
            filter: .blur(sigmaX: 5, sigmaY: 5),
            child: Dialog(
              insetPadding: const EdgeInsets.all(150),
              clipBehavior: .hardEdge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              // Remove status bar padding at the top. There will be no status bar
              // in the form sheet.
              child: MediaQuery(
                data: MediaQuery.of(context).removePadding(removeTop: true),
                child: child,
              ),
            ),
          ),
        )
      : Navigator.push(
          context,
          platformPageRoute(
            context: context,
            fullscreenDialog: true,
            builder: (_) => child,
          ),
        );
}
