import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

// TODO: Don't hardcode the API key in the app. Use a secure vault or
// backend proxy.
const _apiKey = 'AIzaSyDiMOG9DqnV9t7_XVnLKNmJDKseBXWwKSI';
const _promptText = '''
You are a helpful assistant that creates F3-based workouts based on user input
details.  The user will provide details about their workout preferences and
goals, and you will respond with a structured workout plan. The workout plan
should include a list of exercises, each with a name that may include the number
of sets, and the number of reps. Make sure to tailor the workout to the user's
preferences and goals as much as possible.

Use the Exicon from f3nation.com as a reference for exercise names and
descriptions. If the user provides preferences that are too vague, use your best
judgment to create a workout that is balanced and effective

Assume 45 minutes overall duration if the user does not specify otherwise in
their details.

The response should be in json format and contain the current date. Example of
how the response should be structured:
{
  "name": "Monday Full Body Blast",
  "date": "2024-06-01",
  "sections": [
    {
      "name": "Warm-up",
      "exercises": [
        "20 Side-Shuttle Hops",
        "15 Windmills"
      ]
    },
    {
      "name": "Thang",
      "exercises": [
        "15 Burpees",
        "12 Lunges",
        "60 second Plank"
      ]
    },
    {
      "name": "Mary",
        "exercises": [
          "20 LBCs",
          "10 Side dips (each side)",
      ]
    }
  ]
}

User details: {details}
''';

final class GeminiClient {
  GeminiClient({String? apiKey})
    : model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey ?? _apiKey,
      );

  final _logger = Logger();
  final GenerativeModel model;

  /// Requests a workout plan based on the provided user details.
  ///
  /// The [details] string should contain the user's workout preferences and
  /// goals.
  /// Returns a JSON string containing the structured workout plan.
  Future<String> requestWorkout(String details) async {
    final queryText = _promptText.replaceAll('{details}', details);
    _logger.i('Full prompt: $queryText');
    final response = await model.generateContent([
      Content.multi([TextPart(queryText)]),
    ]);
    _logger.i(response.text);
    return Future.value(response.text);
  }
}
