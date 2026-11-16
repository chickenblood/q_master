import 'dart:io' show Platform;

// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'adaptive_platform.dart';

final class AdaptiveIcons {
  static IconData add(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.add : CupertinoIcons.add;

  static IconData back(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.arrow_back : CupertinoIcons.back;

  static IconData checkMark(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.check : CupertinoIcons.check_mark;

  static IconData delete(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.delete : CupertinoIcons.delete;

  static IconData edit(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.edit : CupertinoIcons.pencil;

  static IconData gearSolid(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.settings : CupertinoIcons.gear_solid;

  static IconData info(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.info : CupertinoIcons.info;

  static IconData playArrowSolid(BuildContext context) =>
      isMaterialPlatform(context)
      ? Icons.play_arrow
      : CupertinoIcons.play_arrow_solid;

  static IconData playCircle(BuildContext context) =>
      isMaterialPlatform(context)
      ? Icons.play_circle_outline
      : CupertinoIcons.play_circle;

  static IconData refresh(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.refresh : CupertinoIcons.refresh;

  static IconData refreshBold(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.refresh : CupertinoIcons.refresh_bold;

  static IconData share(BuildContext context) =>
      isMaterialPlatform(context) ? Icons.share : CupertinoIcons.share;

  static IconData get create =>
      Platform.isIOS ? CupertinoIcons.create : Icons.note_add;

  static IconData get timer =>
      Platform.isIOS ? CupertinoIcons.stopwatch : Icons.timer;

  static IconData get history =>
      /*Platform.isIOS ? CupertinoIcons.speedometer :*/ Icons.fitness_center;

  static IconData get sports =>
      /*Platform.isIOS ? CupertinoIcons.sportscourt :*/ Icons.sports_soccer;

  static IconData get close =>
      Platform.isIOS ? CupertinoIcons.xmark : Icons.close;

  static IconData get more =>
      Platform.isIOS ? CupertinoIcons.ellipsis_circle : Icons.more_vert;

  static IconData get location =>
      Platform.isIOS ? CupertinoIcons.compass : Icons.location_on;

  static IconData get pauseCircle =>
      Platform.isIOS ? CupertinoIcons.pause_circle : Icons.pause_circle_filled;

  static IconData get paste =>
      Platform.isIOS ? CupertinoIcons.doc_on_clipboard : Icons.content_paste;

  static IconData get microphone =>
      Platform.isIOS ? CupertinoIcons.mic_fill : Icons.mic;

  static IconData get sparkles =>
      Platform.isIOS ? CupertinoIcons.sparkles : Icons.auto_awesome;

  static IconData get notes =>
      Platform.isIOS ? CupertinoIcons.doc_text : Icons.description_outlined;

  static IconData get file =>
      Platform.isIOS ? CupertinoIcons.doc : Icons.attach_file;
}
