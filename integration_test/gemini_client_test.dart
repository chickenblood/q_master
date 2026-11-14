// Run with: flutter test integration_test/gemini_client_test.dart -d <device>
// Register the device's App Check debug token in the Firebase console first.
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:q_master/ai_clients/gemini_client.dart';
import 'package:q_master/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiClient (live network)', () {
    late GeminiClient client;

    setUpAll(() async {
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.android &&
              defaultTargetPlatform != TargetPlatform.iOS)) {
        throw UnsupportedError('Run this test on an Android or iOS device.');
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidDebugProvider(),
        providerApple: const AppleDebugProvider(),
      );
    });

    setUp(() {
      client = GeminiClient();
    });

    testWidgets('requestWorkout returns a non-empty JSON response', (
      tester,
    ) async {
      final result = await client.requestWorkout(
        'Outdoor 60mins, all PAX levels, focus on legs',
      );

      expect(result, isNotEmpty);
      // The prompt asks for JSON — verify it at least contains a brace.
      expect(result, contains('{'));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
