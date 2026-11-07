import '../model/exicon.dart';

final class NormalizedExiconTag {
  final String key;
  final String label;

  const NormalizedExiconTag({required this.key, required this.label});
}

final class WorkoutCatalogExercise {
  final String name;
  final String? description;
  final Uri? videoUrl;
  final List<String> aliases;
  final List<NormalizedExiconTag> filterTags;
  final Set<String> filterTagKeys;

  WorkoutCatalogExercise({
    required this.name,
    this.description,
    this.videoUrl,
    this.aliases = const [],
    this.filterTags = const [],
    this.filterTagKeys = const <String>{},
  });

  bool matchesQuery(String query) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return false;
    }

    return _searchTerms.any((term) => term.contains(normalizedQuery));
  }

  List<String> get _searchTerms => _cachedSearchTerms ??= [
    _normalizeSearchText(name),
    ...aliases.map(_normalizeSearchText),
  ].where((term) => term.isNotEmpty).toList(growable: false);

  List<String>? _cachedSearchTerms;
}

List<WorkoutCatalogExercise> buildWorkoutCatalog(List<ExiconEntry> entries) {
  final catalogByName = <String, WorkoutCatalogExercise>{};

  for (final entry in entries) {
    final name = entry.name.trim();
    if (name.isEmpty) {
      continue;
    }

    final normalizedName = _normalizeSearchText(name);
    catalogByName.putIfAbsent(normalizedName, () {
      final tagsByKey = <String, NormalizedExiconTag>{
        for (final tag in entry.tags)
          if (normalizeExiconTagKey(tag.name).isNotEmpty)
            normalizeExiconTag(tag.name).key: normalizeExiconTag(tag.name),
      };
      final filterTags = tagsByKey.values.toList(growable: false)
        ..sort(
          (left, right) =>
              left.label.toLowerCase().compareTo(right.label.toLowerCase()),
        );

      return WorkoutCatalogExercise(
        name: name,
        description: entry.description?.trim(),
        videoUrl: entry.videoUrl,
        aliases: entry.aliases
            .map((alias) => alias.trim())
            .where((alias) => alias.isNotEmpty)
            .toList(growable: false),
        filterTags: filterTags,
        filterTagKeys: tagsByKey.keys.toSet(),
      );
    });
  }

  final catalog = catalogByName.values.toList(growable: false)
    ..sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
  return catalog;
}

Set<String> normalizeExerciseFilterKeys(Iterable<String> rawKeys) {
  return rawKeys
      .map(normalizeExiconTagKey)
      .where((key) => key.isNotEmpty)
      .toSet();
}

NormalizedExiconTag normalizeExiconTag(String rawTag) {
  final key = normalizeExiconTagKey(rawTag);
  return NormalizedExiconTag(key: key, label: _displayLabelForTag(key));
}

String normalizeExiconTagKey(String rawTag) {
  final trimmed = rawTag.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final canonical = trimmed
      .replaceAll(RegExp(r'[_\-/]+'), ' ')
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();

  return _tagSynonyms[canonical] ?? canonical;
}

const _tagSynonyms = <String, String>{
  'full-body': 'full body',
  'full body': 'full body',
  'upper-body': 'upper body',
  'upper body': 'upper body',
  'lower-body': 'lower body',
  'lower body': 'lower body',
};

String _displayLabelForTag(String key) {
  if (key.isEmpty) {
    return '';
  }

  return key
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(_displayWordForTagPart)
      .join(' ');
}

String _displayWordForTagPart(String word) {
  return switch (word) {
    'amrap' => 'AMRAP',
    'emom' => 'EMOM',
    'hiit' => 'HIIT',
    'tabata' => 'Tabata',
    _ => '${word[0].toUpperCase()}${word.substring(1)}',
  };
}

String _normalizeSearchText(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
