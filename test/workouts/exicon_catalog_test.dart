import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/model/exicon_fetcher.dart';
import 'package:q_master/workouts/exicon_catalog.dart';

void main() {
  group('normalizeExiconTag', () {
    test('normalizes tag keys and display labels', () {
      final tag = normalizeExiconTag('  full-body  ');

      expect(tag.key, 'full body');
      expect(tag.label, 'Full Body');
    });

    test('preserves supported acronyms in display labels', () {
      final tag = normalizeExiconTag('hiit');

      expect(tag.key, 'hiit');
      expect(tag.label, 'HIIT');
    });
  });

  group('buildWorkoutCatalog', () {
    test('deduplicates names and matches aliases', () {
      final catalog = buildWorkoutCatalog([
        const ExiconEntry(
          name: 'Burpee',
          aliases: ['8-count bodybuilder'],
          tags: [ExiconTag(name: 'full-body')],
        ),
        const ExiconEntry(
          name: 'burpee',
          aliases: ['squat thrust'],
          tags: [ExiconTag(name: 'HIIT')],
        ),
      ]);

      expect(catalog, hasLength(1));
      expect(catalog.single.name, 'Burpee');
      expect(catalog.single.filterTagKeys, {'full body'});
      expect(catalog.single.matchesQuery('bodybuilder'), isTrue);
      expect(catalog.single.matchesQuery('burp'), isTrue);
    });
  });
}
