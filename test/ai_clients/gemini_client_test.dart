// Live network test — not run in CI.
// To run locally: flutter test --tags live_network
@Tags(['live_network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/ai_clients/gemini_client.dart';

void main() {
  group('GeminiClient (live network)', () {
    late GeminiClient client;

    setUp(() {
      client = GeminiClient();
    });

    test('requestWorkout returns a non-empty JSON response', () async {
      final result = await client.requestWorkout(
        'Outdoor 60mins, all PAX levels, focus on legs',
      );

      expect(result, isNotEmpty);
      // The prompt asks for JSON — verify it at least contains a brace.
      expect(result, contains('{'));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
