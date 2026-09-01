import '../utils/datetime_utils.dart';
import 'workout.dart';

extension FormatttedOutput on Workout {
  /// Processes the workoout to share as plain text.
  ///
  /// Uses markdown formatting, since Slack knows how to display it.
  String get formattedText {
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

  /// Formats the workout as Slack Block Kit section blocks using the same
  /// markdown content as [formattedText].
  List<Map<String, Object?>> get richTextForSlackPost => [
    for (final section in sections)
      _slackMarkdownSection(
        ['*${section.name.toUpperCase()}*', ...section.exercises].join('\n'),
      ),
    _slackMarkdownSection('*ANNOUNCEMENTS:*'),
    _slackMarkdownSection('*COT:*'),
  ];
}

Map<String, Object?> _slackMarkdownSection(String text) => {
  'type': 'section',
  'text': {'type': 'mrkdwn', 'text': text, 'verbatim': false},
};
