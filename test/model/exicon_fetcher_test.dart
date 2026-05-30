import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/model/exicon_fetcher.dart';

void main() {
  group('ExiconEntry.fromApiJson', () {
    test('parses only schema-defined fields', () {
      final entry = ExiconEntry.fromApiJson({
        'id': 'exicon-1',
        'name': 'Burpee',
        'description': 'A full-body movement',
        'type': 'exicon',
        'aliases': ['8-count bodybuilder', 'squat thrust'],
        'tags': [
          {'id': 't5', 'name': 'Full Body'},
          {'id': 't6', 'name': 'Partner'},
        ],
        'videoLink': 'https://example.com/burpee',
        'mentionedEntries': ['Merkin'],
        'referencedBy': ['Beatdown-1'],
      });

      expect(entry.id, 'exicon-1');
      expect(entry.name, 'Burpee');
      expect(entry.description, 'A full-body movement');
      expect(entry.type, 'exicon');
      expect(entry.aliases, ['8-count bodybuilder', 'squat thrust']);
      expect(
        entry.tags,
        [
          const ExiconTag(
            id: 't5',
            name: 'Full Body',
            data: {'id': 't5', 'name': 'Full Body'},
          ),
          const ExiconTag(
            id: 't6',
            name: 'Partner',
            data: {'id': 't6', 'name': 'Partner'},
          ),
        ],
      );
      expect(entry.videoUrl, Uri.parse('https://example.com/burpee'));
      expect(entry.mentionedEntries, ['Merkin']);
      expect(entry.referencedBy, ['Beatdown-1']);
    });

    test('does not use alternate keys', () {
      expect(
        () => ExiconEntry.fromApiJson({
          'exercise': 'Lunge Walk',
          'details': 'Walking lunges',
          'alias': ['lunge'],
          'youtubeUrl': 'https://example.com/lunge',
          'mentioned_entries': ['Squat'],
          'referenced_by': ['Beatdown-2'],
        }),
        throwsFormatException,
      );
    });

    test('parses tags from id/name only', () {
      final entry = ExiconEntry.fromApiJson({
        'name': 'Merkin',
        'tags': [
          {'id': 't1', 'name': 'Upper Body'},
          {'label': 'Ignored'},
          'Also Ignored',
        ],
      });

      expect(
        entry.tags,
        const [
          ExiconTag(
            id: 't1',
            name: 'Upper Body',
            data: {'id': 't1', 'name': 'Upper Body'},
          ),
        ],
      );
    });
  });
}
