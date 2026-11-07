import 'dart:developer' as developer;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'exicon.freezed.dart';
part 'exicon.g.dart';

@freezed
abstract class ExiconTag with _$ExiconTag {
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
      throw FormatException(
        'Exicon tag must include a non-empty name. Received keys: ${json.keys.join(', ')}',
      );
    }

    return ExiconTag(
      id: _readString(json, 'id'),
      name: name,
      data: Map<String, Object?>.of(json),
    );
  }
}

@freezed
abstract class ExiconEntry with _$ExiconEntry {
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
      throw FormatException(
        'Exicon entry must include a non-empty name. Received keys: ${json.keys.join(', ')}',
      );
    }

    final id = _readString(json, 'id');
    final entryIdentifier = id ?? name;

    return ExiconEntry(
      id: id,
      name: name,
      description: _readString(json, 'description'),
      type: _readString(json, 'type'),
      aliases: _readStringList(json, 'aliases'),
      tags: _readTags(json, entryIdentifier),
      videoUrl: _readUri(json, 'videoLink'),
      mentionedEntries: _readStringList(json, 'mentionedEntries'),
      referencedBy: _readStringList(json, 'referencedBy'),
      data: Map<String, Object?>.of(json),
    );
  }
}

/// Reads a non-empty string from a single schema-defined field.
String? _readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

/// Reads a URI from a single schema-defined key.
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
    if (item is String) {
      final trimmed = item.trim();
      if (trimmed.isNotEmpty) {
        parsed.add(trimmed);
      }
    }
  }
  return parsed;
}

/// Reads schema-defined `tags` and extracts nested `id` and `name` values.
List<ExiconTag> _readTags(Map<String, Object?> json, String entryIdentifier) {
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
    try {
      tags.add(ExiconTag.fromApiJson(tag));
    } on FormatException catch (error) {
      developer.log(
        'Skipping malformed Exicon tag for entry: $entryIdentifier.',
        name: 'ExiconFetcher',
        error: error,
      );
      continue;
    }
  }
  return tags;
}
