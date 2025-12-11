import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

final class AdaptiveIcons {
  static IconData get timer => Platform.isIOS ? CupertinoIcons.stopwatch : Icons.timer;
    
  static IconData get history => Icons.history;

  static IconData get sports => Icons.sports_soccer;
}