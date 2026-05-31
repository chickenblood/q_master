import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';

/// A simple alert with a message and an OK button.
/// Supports basic HTML markup in the message for formatting and links.
Future<void> showSimpleAlert(
  BuildContext context, {
  String? title,
  required String message,
}) => showAdaptiveDialog(
  context: context,
  builder: (BuildContext innerContext) => AlertDialog.adaptive(
    title: title != null ? PlatformText(title) : null,
    content: _AlertMessageContent(message: message),
    actions: [
      PlatformDialogAction(
        onPressed: () => Navigator.pop(innerContext),
        child: PlatformText(L10n.of(innerContext)!.okAction),
      ),
    ],
  ),
);

final class _AlertMessageContent extends StatelessWidget {
  final String message;

  const _AlertMessageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    if (!_containsHtmlMarkup(message)) {
      return PlatformText(message);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodyMedium;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: double.maxFinite,
        maxHeight: MediaQuery.sizeOf(context).height * 0.35,
      ),
      child: SingleChildScrollView(
        child: HtmlWidget(
          message,
          textStyle: textStyle?.copyWith(color: colorScheme.onSurface),
          onTapUrl: (url) {
            final uri = Uri.tryParse(url);
            if (uri == null || !uri.hasScheme) {
              return false;
            }

            unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
            return true;
          },
        ),
      ),
    );
  }
}

bool _containsHtmlMarkup(String message) {
  return RegExp(r'<[^>]+>').hasMatch(message);
}
