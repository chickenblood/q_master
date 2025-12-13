import 'package:intl/intl.dart';

/// Formats a DateTime object into a readable string representation.
String formattedDateTime(DateTime dateTime) {
  final format = DateFormat.yMMMMd();
  String localizedDate = format.format(dateTime);
  return localizedDate;
}
