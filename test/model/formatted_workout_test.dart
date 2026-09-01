import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/model/formatted_workout.dart';
import 'package:q_master/model/workout.dart';

void main() {
  test('richTextForSlackPost formats workout sections for a Slack post', () {
    final workout = Workout(
      name: 'Morning Beatdown',
      date: DateTime(2026, 8, 28),
      sections: [
        WorkoutSection(name: 'Warmup', exercises: ['SSH x 20']),
        WorkoutSection(name: 'Thang', exercises: ['Merkins x 10']),
      ],
    );

    expect(workout.richTextForSlackPost, [
      {
        'type': 'rich_text',
        'elements': [
          {
            'type': 'rich_text_section',
            'elements': [
              {
                'type': 'text',
                'text': 'WARMUP',
                'style': {'bold': true},
              },
              {'type': 'text', 'text': '\nSSH x 20'},
            ],
          },
        ],
      },
      {
        'type': 'rich_text',
        'elements': [
          {
            'type': 'rich_text_section',
            'elements': [
              {
                'type': 'text',
                'text': 'THANG',
                'style': {'bold': true},
              },
              {'type': 'text', 'text': '\nMerkins x 10'},
            ],
          },
        ],
      },
      {
        'type': 'rich_text',
        'elements': [
          {
            'type': 'rich_text_section',
            'elements': [
              {
                'type': 'text',
                'text': 'ANNOUNCEMENTS:',
                'style': {'bold': true},
              },
            ],
          },
        ],
      },
      {
        'type': 'rich_text',
        'elements': [
          {
            'type': 'rich_text_section',
            'elements': [
              {
                'type': 'text',
                'text': 'COT:',
                'style': {'bold': true},
              },
            ],
          },
        ],
      },
    ]);
  });
}
