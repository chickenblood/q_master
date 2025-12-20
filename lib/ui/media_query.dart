import 'package:flutter/material.dart';

extension Utils on MediaQueryData {
  bool get isTablet => size.shortestSide >= 800;

  bool get isLandscape => size.width > size.height;
}
