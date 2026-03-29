import 'package:flutter/material.dart';

import '../utils/datetime_utils.dart';
import 'workout.dart';

extension FormatttedOutput on Workout {
  /// Processes the workoout to share as plain text.
  ///
  /// Uses markdown formatting, since Slack knows how to display it.
  String formattedText(BuildContext context) {
    var result = StringBuffer();
    result.writeln('*$name*');
    result.writeln(date.formattedForDisplay());
    result.writeln();

    for (final section in sections) {
      result.writeln('*${section.name.toUpperCase()}*');
      for (final exercise in section.exercises) {
        result.writeln(exercise);
      }
      result.writeln();
    }

    return result.toString();
  }
}
