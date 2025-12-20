import 'package:intl/intl.dart';

extension Utils on DateTime {
  /// Formats a DateTime object into a readable string representation.
  String formattedForDisplay() {
    final format = DateFormat.yMMMMd().add_Hm();
    String localizedDate = format.format(this);
    return localizedDate;
  }
}
