import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/exicon.dart';

part 'exicon_fetcher.g.dart';

const _exiconEndpoint = 'https://codex.f3nation.com/api/exicon';
const _exiconCacheFilename = 'exicon_latest_fetch.json';

/// Provides a list of Exicon entries fetched from the F3 Codex API, along with
/// a method to refresh the data. The latest successful fetch is also persisted
/// locally for offline access and faster subsequent loads.
@riverpod
final class ExiconFetcher extends _$ExiconFetcher {
  @override
  Future<List<ExiconEntry>> build() async {
    final cachedEntries = await _readLatestEntries();
    if (cachedEntries != null) {
      unawaited(_refreshFromNetwork(preserveCurrentStateOnError: true));
      return cachedEntries;
    }

    return _fetchEntries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchEntries);
  }

  Future<void> _refreshFromNetwork({
    required bool preserveCurrentStateOnError,
  }) async {
    try {
      final entries = await _fetchEntriesFromNetwork();
      state = AsyncData(entries);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to refresh Exicon data from network.',
        name: 'ExiconFetcher',
        error: error,
        stackTrace: stackTrace,
      );

      if (!preserveCurrentStateOnError) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<List<ExiconEntry>> _fetchEntries() async {
    try {
      return await _fetchEntriesFromNetwork();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Falling back to cached Exicon data after fetch failure.',
        name: 'ExiconFetcher',
        error: error,
        stackTrace: stackTrace,
      );

      final cachedEntries = await _readLatestEntries();
      if (cachedEntries == null) {
        rethrow;
      }

      return cachedEntries;
    }
  }

  Future<List<ExiconEntry>> _fetchEntriesFromNetwork() async {
    final httpClient = HttpClient();
    final uri = Uri.parse(_exiconEndpoint);
    try {
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Failed to fetch exicon data: ${response.statusCode}',
          uri: uri,
        );
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final rows = _decodeRows(responseBody);
      unawaited(_persistLatestFetch(responseBody));
      return rows.map(ExiconEntry.fromApiJson).toList(growable: false);
    } finally {
      httpClient.close();
    }
  }
}

Future<void> _persistLatestFetch(String responseBody) async {
  try {
    final directory = await getApplicationCacheDirectory();
    final file = File('${directory.path}/$_exiconCacheFilename');
    await file.writeAsString(responseBody, flush: true);
  } on Object catch (error, stackTrace) {
    developer.log(
      'Failed to persist latest Exicon fetch.',
      name: 'ExiconFetcher',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<String?> _readLatestFetch() async {
  try {
    final directory = await getApplicationCacheDirectory();
    final file = File('${directory.path}/$_exiconCacheFilename');
    if (!await file.exists()) {
      return null;
    }
    return await file.readAsString();
  } on Object catch (error, stackTrace) {
    developer.log(
      'Failed to read cached Exicon fetch.',
      name: 'ExiconFetcher',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

Future<List<ExiconEntry>?> _readLatestEntries() async {
  final cachedResponseBody = await _readLatestFetch();
  if (cachedResponseBody == null) {
    return null;
  }

  final rows = _decodeRows(cachedResponseBody);
  return rows.map(ExiconEntry.fromApiJson).toList(growable: false);
}

List<Map<String, Object?>> _decodeRows(String responseBody) {
  final decoded = jsonDecode(responseBody);
  return _extractRows(decoded);
}

List<Map<String, Object?>> _extractRows(Object? decoded) {
  if (decoded is List) {
    return _rowsFromList(decoded);
  }

  if (decoded is Map) {
    final map = Map<String, Object?>.from(decoded);
    for (final key in const ['data', 'rows', 'results', 'exicon']) {
      final value = map[key];
      if (value is List) {
        return _rowsFromList(value);
      }
    }
  }

  throw const FormatException('Unexpected exicon response format.');
}

List<Map<String, Object?>> _rowsFromList(List<dynamic> rows) {
  final mappedRows = <Map<String, Object?>>[];
  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    if (row is! Map) {
      throw FormatException(
        'Exicon row at index $index must be a JSON object (found ${row.runtimeType}).',
      );
    }
    mappedRows.add(Map<String, Object?>.from(row));
  }
  return mappedRows;
}
