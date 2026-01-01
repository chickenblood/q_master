import 'package:flutter/material.dart';

extension MediaUtils on MediaQueryData {
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 800;

  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }
}
