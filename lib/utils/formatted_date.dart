import 'package:intl/intl.dart';

/// Formats a DateTime object into a readable string representation.
String formattedDate(DateTime dateTime) {
  final format = DateFormat.yMMMMd();
  String localizedDate = format.format(dateTime);
  return localizedDate;
}
