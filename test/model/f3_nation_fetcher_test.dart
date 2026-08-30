import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/model/f3_nation_fetcher.dart';

void main() {
  group('F3Region.fromApiJson', () {
    test('parses id and name', () {
      final region = F3Region.fromApiJson({'id': 1, 'name': 'Bay Area'});
      expect(region.id, 1);
      expect(region.name, 'Bay Area');
    });
  });

  group('F3Ao.fromApiJson', () {
    test('parses id, name, and parentId', () {
      final ao = F3Ao.fromApiJson({
        'id': 35022,
        'name': 'Hangar 1',
        'parentId': 25248,
      });
      expect(ao.id, 35022);
      expect(ao.name, 'Hangar 1');
      expect(ao.parentId, 25248);
    });
  });

  group('F3EventInstanceSummary.fromApiJson', () {
    test('parses id, name, and startDate', () {
      final summary = F3EventInstanceSummary.fromApiJson({
        'id': 1094348,
        'name': 'F\u2019ruckin @ H1',
        'startDate': '2026-08-28',
        'startTime': '0545',
        'endTime': '0645',
      });
      expect(summary.id, 1094348);
      expect(summary.name, 'F\u2019ruckin @ H1');
      expect(summary.startDate, DateTime.parse('2026-08-28'));
      expect(summary.startTime, '0545');
      expect(summary.endTime, '0645');
    });

    test('throws when startDate is missing', () {
      expect(
        () => F3EventInstanceSummary.fromApiJson({'id': 1, 'name': 'Hangar 1'}),
        throwsFormatException,
      );
    });
  });

  group('F3EventInstance.fromApiJson', () {
    test('parses preblast and backblast content', () {
      final event = F3EventInstance.fromApiJson({
        'id': 1094348,
        'name': 'F\u2019ruckin @ H1',
        'description': 'Meet by the bathrooms on Middlefield Rd.',
        'orgId': 35022,
        'startDate': '2026-08-28',
        'startTime': '0545',
        'endTime': '0645',
        'preblast': '\nWHAT: \nWHY:  ',
        'backblast': 'Backblast! F\u2019ruckin @ H1',
        'paxCount': 10,
        'fngCount': 0,
      });

      expect(event.id, 1094348);
      expect(event.orgId, 35022);
      expect(event.startDate, DateTime.parse('2026-08-28'));
      expect(event.preblast, 'WHAT: \nWHY:');
      expect(event.backblast, 'Backblast! F\u2019ruckin @ H1');
      expect(event.paxCount, 10);
      expect(event.fngCount, 0);
    });
  });
}
