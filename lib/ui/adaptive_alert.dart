
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Returns a native-style alert action for use with showAdaptiveDialog/AlertDialog.adaptive.
Widget adaptiveAlertAction({required BuildContext context,
required VoidCallback onPressed,
required Widget child,
bool isDefault = false,
bool isDestructive = false
}) {
  return Theme.of(context).platform == TargetPlatform.android ? 
  TextButton(onPressed: onPressed, child: child) :  
  CupertinoDialogAction(
    onPressed: onPressed, 
    isDefaultAction: isDefault, 
    isDestructiveAction: isDestructive, 
    child: child);
}