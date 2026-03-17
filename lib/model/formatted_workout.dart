import 'dart:convert';

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

  /// Formats workout sections in a single Slack `rich_text` block.
  List<Map<String, Object?>> get richTextForSlackPost => [
    {
      'type': 'rich_text',
      'elements': [
        for (final section in sections) ...[
          _slackRichTextSection(
            title: section.name.toUpperCase(),
            lines: section.exercises,
          ),
          _slackBlankSection(),
        ],
        _slackRichTextSection(title: 'ANNOUNCEMENTS:'),
        _slackBlankSection(),
        _slackRichTextSection(title: 'COT:'),
      ],
    },
  ];

  String get formattedJson => jsonEncode(this);
}

Map<String, Object?> _slackRichTextSection({
  required String title,
  List<String> lines = const [],
}) => {
  'type': 'rich_text_section',
  'elements': [
    {
      'type': 'text',
      'text': title,
      'style': {'bold': true},
    },
    if (lines.isNotEmpty) {'type': 'text', 'text': '\n${lines.join('\n')}'},
  ],
};

// Adds a blank line between sections, since Slack doesn't support multiple
// newlines in a single section.
Map<String, Object?> _slackBlankSection() => {
  'type': 'rich_text_section',
  'elements': [
    {'type': 'text', 'text': '\n'},
  ],
};
