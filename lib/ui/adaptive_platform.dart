import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

/// Whether the app uses Material controls for the current platform.
///
/// Web uses Material regardless of the browser's reported platform.
bool isMaterialPlatform(BuildContext context) {
  if (kIsWeb) return true;
  final platform = Theme.of(context).platform;
  return platform != TargetPlatform.iOS && platform != TargetPlatform.macOS;
}
