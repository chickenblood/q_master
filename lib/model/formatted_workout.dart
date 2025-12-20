import 'package:flutter/material.dart';
import 'workout.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/utils/datetime_utils.dart';

extension FormatttedOutput on Workout {
  /// Processes the workoout to share as plain text.
  ///
  /// Uses markdown formatting, since Slack knows how to display it.
  String formattedText(BuildContext context) {
    final l10n = L10n.of(context)!;
    var result = StringBuffer();
    result.writeln('**$name**');
    result.writeln(date.formattedForDisplay());
    result.writeln();

    result.writeln('**${l10n.workoutWarmupFieldLabel}**');
    for (final exercise in warmup) {
      result.writeln(exercise.name);
    }
    result.writeln();

    result.writeln('**${l10n.workoutThangFieldLabel}**');
    for (final exercise in thang) {
      result.writeln(exercise.name);
    }
    result.writeln();

    result.writeln('**${l10n.workoutMaryFieldLabel}**');
    for (final exercise in mary) {
      result.writeln(exercise.name);
    }

    return result.toString();
  }
}
