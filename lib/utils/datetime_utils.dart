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
String formatSeconds(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final minutesStr = minutes.toString().padLeft(2, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');
  return '$minutesStr:$secondsStr';
}
