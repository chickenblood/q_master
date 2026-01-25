import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../utils/datetime_utils.dart';
import 'workout.dart';

extension FormatttedOutput on Workout {
  /// Processes the workoout to share as plain text.
  ///
  /// Uses markdown formatting, since Slack knows how to display it.
  String formattedText(BuildContext context) {
    final l10n = L10n.of(context)!;
    var result = StringBuffer();
    result.writeln('*$name*');
    result.writeln(date.formattedForDisplay());
    result.writeln();

    result.writeln('*${l10n.workoutWarmupFieldLabel.toUpperCase()}*');
    for (final exercise in warmup) {
      result.writeln(exercise.name);
    }
    result.writeln();

    result.writeln('*${l10n.workoutThangFieldLabel.toUpperCase()}*');
    for (final exercise in thang) {
      result.writeln(exercise.name);
    }
    result.writeln();

    result.writeln('*${l10n.workoutMaryFieldLabel.toUpperCase()}*');
    for (final exercise in mary) {
      result.writeln(exercise.name);
    }

    return result.toString();
  }
}
