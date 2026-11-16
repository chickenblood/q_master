import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

/// Whether the app uses Material controls for the current platform.
///
/// Web uses Material regardless of the browser's reported platform.
bool isMaterialPlatform(BuildContext context) {
  if (kIsWeb) return true;
  final platform = Theme.of(context).platform;
  return platform != TargetPlatform.iOS && platform != TargetPlatform.macOS;
}
