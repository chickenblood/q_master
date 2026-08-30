import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'f3_nation_credentials.g.dart';

const _apiKeyStorageKey = 'f3_nation_api_key';

/// Securely persists the user-provided F3 Nation API key.
final class F3NationCredentialsStore {
  final FlutterSecureStorage _storage;

  const F3NationCredentialsStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  Future<String?> readApiKey() => _storage.read(key: _apiKeyStorageKey);

  Future<void> writeApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) {
      return _storage.delete(key: _apiKeyStorageKey);
    }
    return _storage.write(key: _apiKeyStorageKey, value: apiKey);
  }
}

/// The currently stored F3 Nation API key, or `null` if none has been set.
@riverpod
final class F3NationApiKey extends _$F3NationApiKey {
  static const _store = F3NationCredentialsStore();

  @override
  Future<String?> build() => _store.readApiKey();

  /// Persists [apiKey] (or clears it if `null`/empty) and refreshes dependents.
  Future<void> setApiKey(String? apiKey) async {
    await _store.writeApiKey(apiKey);
    ref.invalidateSelf();
    await future;
  }
}
