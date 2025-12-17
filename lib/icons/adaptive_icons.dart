import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

final class AdaptiveIcons {
  static IconData get timer =>
      Platform.isIOS ? CupertinoIcons.stopwatch : Icons.timer;

  static IconData get history =>
      Platform.isIOS ? CupertinoIcons.speedometer : Icons.history;

  static IconData get sports =>
      Platform.isIOS ? CupertinoIcons.sportscourt : Icons.sports_soccer;

  static IconData get close =>
      Platform.isIOS ? CupertinoIcons.xmark : Icons.close;

  static IconData get more =>
      Platform.isIOS ? CupertinoIcons.ellipsis : Icons.more_vert;
}
