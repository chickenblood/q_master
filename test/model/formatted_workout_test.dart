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
        'type': 'section',
        'text': {
          'type': 'mrkdwn',
          'text': '*WARMUP*\nSSH x 20',
          'verbatim': false,
        },
      },
      {
        'type': 'section',
        'text': {
          'type': 'mrkdwn',
          'text': '*THANG*\nMerkins x 10',
          'verbatim': false,
        },
      },
      {
        'type': 'section',
        'text': {
          'type': 'mrkdwn',
          'text': '*ANNOUNCEMENTS:*',
          'verbatim': false,
        },
      },
      {
        'type': 'section',
        'text': {'type': 'mrkdwn', 'text': '*COT:*', 'verbatim': false},
      },
    ]);
  });
}
