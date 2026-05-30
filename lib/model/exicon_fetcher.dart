import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exicon_fetcher.freezed.dart';
part 'exicon_fetcher.g.dart';

const _exiconEndpoint = 'https://codex.f3nation.com/submit?type=exicon';

@freezed
abstract class ExiconEntry with _$ExiconEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ExiconEntry({
    required String name,
    String? description,
    @Default(<String, Object?>{}) Map<String, Object?> data,
  }) = _ExiconEntry;

  factory ExiconEntry.fromJson(Map<String, Object?> json) =>
      _$ExiconEntryFromJson(json);

  factory ExiconEntry.fromApiJson(Map<String, Object?> json) => ExiconEntry(
    name: _readString(json, const ['name', 'exercise', 'title']) ?? 'unknown',
    description: _readString(
      json,
      const ['description', 'details', 'explanation'],
    ),
    data: Map<String, Object?>.of(json),
  );
}

@riverpod
final class ExiconFetcher extends _$ExiconFetcher {
  static final _httpClient = HttpClient();

  @override
  Future<List<ExiconEntry>> build() => _fetchEntries();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchEntries);
  }

  Future<List<ExiconEntry>> _fetchEntries() async {
    final uri = Uri.parse(_exiconEndpoint);
    final request = await _httpClient.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Failed to fetch exicon data: ${response.statusCode}',
        uri: uri,
      );
    }

    final payload = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(payload);
    final rows = _extractRows(decoded);
    return rows.map(ExiconEntry.fromApiJson).toList(growable: false);
  }
}

String? _readString(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
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

List<Map<String, Object?>> _rowsFromList(List<dynamic> rows) => [
  for (final row in rows)
    if (row is Map) Map<String, Object?>.from(row),
];
