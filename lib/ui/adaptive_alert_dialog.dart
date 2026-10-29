import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<T?> showAlertDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  required List<AdaptiveDialogAction> actions,
}) => (Theme.of(context).platform == TargetPlatform.iOS)
    ? GlassDialog.show(
        context: context,
        title: title,
        message: message,
        content: content,
        actions: actions
            .map(
              (e) => GlassDialogAction(
                label: e.title,
                isDestructive: e.isDestructive,
                isPrimary: e.isPrimary,
                onPressed: e.onPressed,
              ),
            )
            .toList(),
      )
    : showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [if (message != null) Text(message), ?content],
          ),
          actions: actions
              .map(
                (e) => TextButton(
                  onPressed: e.onPressed,
                  child: Text(
                    e.title,
                    style: TextStyle(
                      color: e.isDestructive ? Colors.red : null,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );

/// A class representing a button in an alert with a title, and a callback.
///
/// Used within by [showAlertDialog] to specify the actions available in the
/// alert.
final class AdaptiveDialogAction {
  final String title;
  final bool isDestructive;
  final bool isPrimary;
  final void Function() onPressed;

  const AdaptiveDialogAction({
    required this.title,
    this.isDestructive = false,
    this.isPrimary = false,
    required this.onPressed,
  });
}
