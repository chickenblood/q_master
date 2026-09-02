import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:logger/logger.dart';

const _apiKeyStorageKey = 'THIRD_PARTY_API_KEY';

/// Retrieves the F3 Nation API key from Firebase Remote Config.
final class F3NationApiKey {
  F3NationApiKey._();

  static final _logger = Logger();
  static Future<void>? _initialization;

  /// Configures and fetches Remote Config once for the app process.
  static Future<void> ensureInitialized() => _initialization ??= _initialize();

  static Future<void> _initialize() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ),
    );

    await remoteConfig.setDefaults({_apiKeyStorageKey: ''});
    try {
      final updated = await remoteConfig.fetchAndActivate();
      _logger.i('Config updated: $updated');
    } on Object catch (error, stackTrace) {
      _logger.e('Fetch failed: $error', stackTrace: stackTrace);
    }
  }

  /// Returns the fetched API key, or `null` when no value is configured.
  static String? get value {
    final apiKey = FirebaseRemoteConfig.instance.getString(_apiKeyStorageKey);
    return apiKey.isEmpty ? null : apiKey;
  }
}
