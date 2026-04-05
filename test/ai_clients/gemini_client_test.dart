// Live network test — requires a valid Gemini API key.
// Set the GEMINI_API_KEY environment variable, then run:
//   flutter test test/ai_clients/gemini_client_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/ai_clients/gemini_client.dart';

void main() {
  final apiKey = Platform.environment['GEMINI_API_KEY'];

  group(
    'GeminiClient (live network)',
    skip: (apiKey == null || apiKey.isEmpty)
        ? 'Set GEMINI_API_KEY to run live network tests'
        : null,
    () {
      late GeminiClient client;

      setUp(() {
        client = GeminiClient(apiKey: apiKey!);
      });

      test(
        'requestWorkout returns a non-empty JSON response',
        () async {
          final result = await client.requestWorkout(
            '30 minutes, outdoor, all PAX levels, focus on legs',
          );

          expect(result, isNotEmpty);
          // The prompt asks for JSON — verify it at least contains a brace.
          expect(result, contains('{'));
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    },
  );
}
