import 'package:intl/intl.dart';

extension Utils on DateTime {
  /// Formats a DateTime object into a readable string representation.
  String formattedForDisplay() {
    final format = DateFormat.yMMMMd().add_Hm();
    String localizedDate = format.format(this);
    return localizedDate;
  }
}

// Displays seconds in a readable MM:SS format.
String formatDuration(Duration duration) {
  final minutes = duration.inSeconds ~/ 60;
  final seconds = duration.inSeconds % 60;
  final minutesStr = minutes.toString().padLeft(2, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');
  return '$minutesStr:$secondsStr';
}

// Displays milliseconds in a readable MM:SS:ss format.
String formatPreciseDuration(Duration duration) {
  final minutes = duration.inMilliseconds ~/ 60000;
  final seconds = (duration.inMilliseconds % 60000) ~/ 1000;
  final hundredths = (duration.inMilliseconds % 1000) ~/ 10;
  final minutesStr = minutes.toString().padLeft(2, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');
  final hundredthsStr = hundredths.toString().padLeft(2, '0');
  return '$minutesStr:$secondsStr:$hundredthsStr';
}
