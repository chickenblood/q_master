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

  /// Formats workout sections as Slack's structured `rich_text` blocks.
  List<Map<String, Object?>> get richTextForSlackPost => [
    for (final section in sections)
      _slackRichTextSection(
        title: section.name.toUpperCase(),
        lines: section.exercises,
      ),
    _slackRichTextSection(title: 'ANNOUNCEMENTS:'),
    _slackRichTextSection(title: 'COT:'),
  ];
}

Map<String, Object?> _slackRichTextSection({
  required String title,
  List<String> lines = const [],
}) => {
  'type': 'rich_text',
  'elements': [
    {
      'type': 'rich_text_section',
      'elements': [
        {
          'type': 'text',
          'text': title,
          'style': {'bold': true},
        },
        if (lines.isNotEmpty) {'type': 'text', 'text': '\n${lines.join('\n')}'},
      ],
    },
  ],
};
