import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';

/// A simple alert with a message and an OK button.
Future<void> showSimpleAlert(
  BuildContext context, {
  String? title,
  required String message,
}) => showAdaptiveDialog(
  context: context,
  builder: (BuildContext innerContext) => AlertDialog.adaptive(
    title: title != null ? PlatformText(title) : null,

    content: PlatformText(message),
    actions: [
      PlatformDialogAction(
        onPressed: () => Navigator.pop(innerContext),
        child: PlatformText(L10n.of(innerContext)!.okAction),
      ),
    ],
  ),
);
