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
const _unknownExerciseName = 'unknown';
const _unknownTagName = 'unknown-tag';
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

  factory ExiconTag.fromApiJson(Map<String, Object?> json) => ExiconTag(
    id: _readString(json, const ['id']),
    name: _readString(json, const ['name', 'label', 'title']) ?? _unknownTagName,
    data: Map<String, Object?>.of(json),
  );
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

  factory ExiconEntry.fromApiJson(Map<String, Object?> json) => ExiconEntry(
    id: _readString(json, const ['id']),
    name:
        _readString(json, const ['name', 'exercise', 'title']) ??
        _unknownExerciseName,
    description: _readString(
      json,
      const ['description', 'details', 'explanation'],
    ),
    type: _readString(json, const ['type']),
    aliases: _readStringList(json, const ['aliases', 'alias']),
    tags: _readTags(json, const ['tags']),
    videoUrl: _readUri(
      json,
      const [
        'videoUrl',
        'video_url',
        'video',
        'videoLink',
        'video_link',
        'youtube',
        'youtubeUrl',
        'youtube_url',
      ],
    ),
    mentionedEntries: _readStringList(
      json,
      const ['mentionedEntries', 'mentioned_entries'],
    ),
    referencedBy: _readStringList(json, const ['referencedBy', 'referenced_by']),
    data: Map<String, Object?>.of(json),
  );
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

String? _readString(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

Uri? _readUri(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String) {
      final parsed = Uri.tryParse(value.trim());
      if (parsed != null && parsed.hasScheme) {
        return parsed;
      }
    }
    if (value is Map) {
      final urlCandidate = value['url'];
      if (urlCandidate is String) {
        final parsed = Uri.tryParse(urlCandidate.trim());
        if (parsed != null && parsed.hasScheme) {
          return parsed;
        }
      }
    }
  }
  return null;
}

List<String> _readStringList(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final parsed = _stringListFromValue(value);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }
  return const [];
}

List<String> _stringListFromValue(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return [trimmed];
    }
    return const [];
  }

  if (value is List) {
    final parsed = <String>[];
    for (final item in value) {
      final asString = _stringValue(item);
      if (asString != null) {
        parsed.add(asString);
      }
    }
    return parsed;
  }

  final asString = _stringValue(value);
  return asString == null ? const [] : [asString];
}

String? _stringValue(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  if (value is Map) {
    final id = value['id'];
    if (id is String && id.trim().isNotEmpty) {
      return id.trim();
    }
    final name = value['name'];
    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }
  }
  return null;
}

List<ExiconTag> _readTags(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is! List) {
      continue;
    }

    final tags = <ExiconTag>[];
    for (final item in value) {
      if (item is Map) {
        tags.add(ExiconTag.fromApiJson(Map<String, Object?>.from(item)));
        continue;
      }
      final name = _stringValue(item);
      if (name != null) {
        tags.add(ExiconTag(name: name));
      }
    }

    if (tags.isNotEmpty) {
      return tags;
    }
  }

  return const [];
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
