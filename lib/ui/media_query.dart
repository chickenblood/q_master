import 'package:flutter/material.dart';

extension MediaUtils on MediaQueryData {
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 800;
}
