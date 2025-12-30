import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final class AdaptiveIcons {
  static IconData get timer =>
      Platform.isIOS ? CupertinoIcons.stopwatch : Icons.timer;

  static IconData get history =>
      /*Platform.isIOS ? CupertinoIcons.speedometer :*/ Icons.history;

  static IconData get sports =>
      /*Platform.isIOS ? CupertinoIcons.sportscourt :*/ Icons.sports_soccer;

  static IconData get close =>
      Platform.isIOS ? CupertinoIcons.xmark : Icons.close;

  static IconData get more =>
      Platform.isIOS ? CupertinoIcons.ellipsis : Icons.more_vert;

  static IconData get location =>
      Platform.isIOS ? CupertinoIcons.compass : Icons.location_on;
}
