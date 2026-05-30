import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exicon_fetcher.freezed.dart';
part 'exicon_fetcher.g.dart';

const _exiconEndpoint = 'https://codex.f3nation.com/api/exicon';
const _exiconCacheFilename = 'exicon_latest_fetch.json';

@freezed
class ExiconTag with _$ExiconTag {
  const factory ExiconTag({
    String? id,
    required String name,
    @Default(<String, Object?>{}) Map<String, Object?> data,
  }) = _ExiconTag;

  factory ExiconTag.fromJson(Map<String, Object?> json) =>
      _$ExiconTagFromJson(json);

  factory ExiconTag.fromApiJson(Map<String, Object?> json) {
    final name = _readString(json, 'name');
    if (name == null) {
      throw const FormatException('Exicon tag must include a non-empty name.');
    }

    return ExiconTag(
      id: _readString(json, 'id'),
      name: name,
      data: Map<String, Object?>.of(json),
    );
  }
}

@freezed
class ExiconEntry with _$ExiconEntry {
  const factory ExiconEntry({
    String? id,
    required String name,
    String? description,
    String? type,
    @Default(<String>[]) List<String> aliases,
    @Default(<ExiconTag>[]) List<ExiconTag> tags,
    Uri? videoUrl,
    @Default(<String>[]) List<String> mentionedEntries,
    @Default(<String>[]) List<String> referencedBy,
    @Default(<String, Object?>{}) Map<String, Object?> data,
  }) = _ExiconEntry;

  factory ExiconEntry.fromJson(Map<String, Object?> json) =>
      _$ExiconEntryFromJson(json);

  factory ExiconEntry.fromApiJson(Map<String, Object?> json) {
    final name = _readString(json, 'name');
    if (name == null) {
      throw const FormatException('Exicon entry must include a non-empty name.');
    }

    return ExiconEntry(
      id: _readString(json, 'id'),
      name: name,
      description: _readString(json, 'description'),
      type: _readString(json, 'type'),
      aliases: _readStringList(json, 'aliases'),
      tags: _readTags(json),
      videoUrl: _readUri(json, 'videoLink'),
      mentionedEntries: _readStringList(json, 'mentionedEntries'),
      referencedBy: _readStringList(json, 'referencedBy'),
      data: Map<String, Object?>.of(json),
    );
  }
}

@riverpod
final class ExiconFetcher extends _$ExiconFetcher {
  @override
  Future<List<ExiconEntry>> build() => _fetchEntries();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchEntries);
  }

  Future<List<ExiconEntry>> _fetchEntries() async {
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
      final decoded = jsonDecode(responseBody);
      final rows = _extractRows(decoded);
      unawaited(_persistLatestFetch(responseBody));
      return rows.map(ExiconEntry.fromApiJson).toList(growable: false);
    } finally {
      httpClient.close();
    }
  }
}

Future<void> _persistLatestFetch(String responseBody) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
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

/// Reads a non-empty string from a single schema-defined field.
String? _readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

/// Reads a URI from one schema-defined field (for example, `videoLink`).
Uri? _readUri(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) {
    final parsed = Uri.tryParse(value.trim());
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
  }
  return null;
}

/// Reads a list of strings from one schema-defined field (e.g. `aliases`).
List<String> _readStringList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) {
    return const [];
  }

  final parsed = <String>[];
  for (final item in value) {
    if (item is String && item.trim().isNotEmpty) {
      parsed.add(item.trim());
    }
  }
  return parsed;
}

/// Reads schema-defined `tags` and extracts nested `id` and `name` values.
List<ExiconTag> _readTags(Map<String, Object?> json) {
  final value = json['tags'];
  if (value is! List) {
    return const [];
  }

  final tags = <ExiconTag>[];
  for (final item in value) {
    if (item is! Map) {
      continue;
    }

    final tag = Map<String, Object?>.from(item);
    final name = _readString(tag, 'name');
    if (name == null) {
      continue;
    }

    tags.add(
      ExiconTag(
        id: _readString(tag, 'id'),
        name: name,
        data: tag,
      ),
    );
  }
  return tags;
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
