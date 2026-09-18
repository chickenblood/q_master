import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'f3_nation_fetcher.freezed.dart';
part 'f3_nation_fetcher.g.dart';

const _f3NationApiHost = 'api.f3nation.com';

/// Raised when a request to the F3 Nation API fails, either due to a
/// transport error, a non-2xx response, or an unexpected response shape.
final class F3NationApiException implements Exception {
  final String message;
  final int? statusCode;

  const F3NationApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'F3NationApiException: $message'
      : 'F3NationApiException($statusCode): $message';
}

/// A region, area, or AO returned by the F3 Nation `org` endpoints.
@freezed
abstract class F3Region with _$F3Region {
  const factory F3Region({required int id, required String name}) = _F3Region;

  factory F3Region.fromApiJson(Map<String, Object?> json) => F3Region(
    id: _readInt(json, 'id') ?? (throw const FormatException('org missing id')),
    name: _readString(json, 'name') ?? '',
  );
}

/// An AO (workout location) nested under a region.
@freezed
abstract class F3Ao with _$F3Ao {
  const factory F3Ao({required int id, required String name, int? parentId}) =
      _F3Ao;

  factory F3Ao.fromApiJson(Map<String, Object?> json) => F3Ao(
    id: _readInt(json, 'id') ?? (throw const FormatException('org missing id')),
    name: _readString(json, 'name') ?? '',
    parentId: _readInt(json, 'parentId'),
  );
}

/// A lightweight summary of an event instance, used when listing available
/// dates for an AO before fetching the full event detail.
@freezed
abstract class F3EventInstanceSummary with _$F3EventInstanceSummary {
  const factory F3EventInstanceSummary({
    required int id,
    required String name,
    required DateTime startDate,
    String? startTime,
    String? endTime,
  }) = _F3EventInstanceSummary;

  factory F3EventInstanceSummary.fromApiJson(Map<String, Object?> json) =>
      F3EventInstanceSummary(
        id:
            _readInt(json, 'id') ??
            (throw const FormatException('event instance missing id')),
        name: _readString(json, 'name') ?? '',
        startDate:
            _readDate(json, 'startDate') ??
            (throw const FormatException('event instance missing startDate')),
        startTime: _readString(json, 'startTime'),
        endTime: _readString(json, 'endTime'),
      );
}

/// Full detail for a single event instance, including its preblast and
/// backblast content.
@freezed
abstract class F3EventInstance with _$F3EventInstance {
  const factory F3EventInstance({
    required int id,
    required String name,
    String? description,
    required int orgId,
    required DateTime startDate,
    String? startTime,
    String? endTime,
    String? preblast,
    String? backblast,
    int? paxCount,
    int? fngCount,
  }) = _F3EventInstance;

  factory F3EventInstance.fromApiJson(Map<String, Object?> json) =>
      F3EventInstance(
        id:
            _readInt(json, 'id') ??
            (throw const FormatException('event instance missing id')),
        name: _readString(json, 'name') ?? '',
        description: _readString(json, 'description'),
        orgId:
            _readInt(json, 'orgId') ??
            (throw const FormatException('event instance missing orgId')),
        startDate:
            _readDate(json, 'startDate') ??
            (throw const FormatException('event instance missing startDate')),
        startTime: _readString(json, 'startTime'),
        endTime: _readString(json, 'endTime'),
        preblast: _readString(json, 'preblast'),
        backblast: _readString(json, 'backblast'),
        paxCount: _readInt(json, 'paxCount'),
        fngCount: _readInt(json, 'fngCount'),
      );
}

/// Client for the F3 Nation API (https://api.f3nation.com/docs), providing a
/// drill-down path from regions to AOs to event instances.
///
/// Requires an API key supplied by Firebase Remote Config before any method is
/// called.
@Riverpod(keepAlive: true)
final class F3NationFetcher extends _$F3NationFetcher {
  @override
  FutureOr<void> build() {}

  /// Lists regions, optionally filtered by [searchTerm].
  Future<List<F3Region>> listRegions({String? searchTerm}) async {
    final json = await _get(
      '/org',
      queryParameters: {
        'orgTypes': const ['region'],
        if (searchTerm != null && searchTerm.isNotEmpty)
          'searchTerm': searchTerm,
        'pageSize': 100,
      },
    );
    final regions = _readList(json, 'orgs').map(F3Region.fromApiJson).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return regions;
  }

  /// Fetches the Region with [regionId] directly from the organization API.
  Future<F3Region> fetchRegion({required int regionId}) async {
    final json = await _get('/org/id/$regionId');
    return F3Region.fromApiJson(_readObject(json, 'org'));
  }

  /// Lists AOs under the region with the given [regionId], optionally
  /// filtered by [searchTerm].
  Future<List<F3Ao>> listAos({
    required int regionId,
    String? searchTerm,
  }) async {
    final json = await _get(
      '/org',
      queryParameters: {
        'orgTypes': const ['ao'],
        'parentOrgIds': [regionId],
        if (searchTerm != null && searchTerm.isNotEmpty)
          'searchTerm': searchTerm,
        'pageSize': 200,
      },
    );
    final aos = _readList(json, 'orgs').map(F3Ao.fromApiJson).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return aos;
  }

  /// Fetches the AO with [aoId] directly from the organization API.
  Future<F3Ao> fetchAo({required int aoId}) async {
    final json = await _get('/org/id/$aoId');
    return F3Ao.fromApiJson(_readObject(json, 'org'));
  }

  /// Lists event instances at [aoOrgId] from [from] through [to], sorted
  /// earliest first. The default window is the previous seven days through
  /// today.
  ///
  /// The API's `startDate` query filter does not reliably restrict results
  /// to an exact date, so a page of instances is fetched and filtered here.
  Future<List<F3EventInstanceSummary>> listAvailableDates({
    required int aoOrgId,
    DateTime? from,
    DateTime? to,
  }) async {
    final today = _dateOnly(DateTime.now());
    final start = _dateOnly(from ?? today.subtract(const Duration(days: 7)));
    final end = _dateOnly(to ?? today);
    final json = await _get(
      '/event-instance',
      queryParameters: {'aoOrgId': aoOrgId, 'pageSize': 500},
    );
    final instances =
        _readList(json, 'eventInstances')
            .map(F3EventInstanceSummary.fromApiJson)
            .where(
              (instance) =>
                  !instance.startDate.isBefore(start) &&
                  !instance.startDate.isAfter(end),
            )
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return instances;
  }

  /// Fetches full detail (including preblast/backblast) for the event
  /// instance with the given [eventInstanceId].
  Future<F3EventInstance> fetchEvent({required int eventInstanceId}) async {
    final json = await _get('/event-instance/id/$eventInstanceId');
    return F3EventInstance.fromApiJson(json);
  }

  /// Non-destructively updates only the backblast text for the event
  /// instance with the given [eventInstanceId].
  ///
  /// The write endpoint has no partial-update support, so this performs a
  /// read-modify-write: it fetches the full current representation of the
  /// event instance, replaces just the backblast (and its timestamp), and
  /// posts the merged object back, leaving every other field (preblast,
  /// backblastRich, meta, PAX counts, etc.) untouched.
  Future<F3EventInstance> updateBackblast({
    required int eventInstanceId,
    required String name,
    required List<Map<String, Object?>> backblastRich,
  }) async {
    final payload = Map<String, Object?>.of(
      await _get('/event-instance/id/$eventInstanceId'),
    );

    // These are read-only relations included in GET responses but rejected
    // by the write schema; map them to their writable id fields instead.
    final eventTypes = payload.remove('eventTypes');
    if (eventTypes is List && eventTypes.isNotEmpty) {
      final firstType = eventTypes.first;
      if (firstType is Map) {
        payload['eventTypeId'] = firstType['eventTypeId'];
      }
    }
    final eventTags = payload.remove('eventTags');
    if (eventTags is List && eventTags.isNotEmpty) {
      final firstTag = eventTags.first;
      if (firstTag is Map) {
        payload['eventTagId'] = firstTag['eventTagId'];
      }
    }
    payload.remove('org');
    payload.remove('location');

    payload['name'] = name;
    payload.remove('backblast');
    payload['backblastRich'] = backblastRich;
    payload['backblastTs'] = DateTime.now().millisecondsSinceEpoch / 1000;

    final response = await _post('/event-instance', payload: payload);
    return F3EventInstance.fromApiJson(response);
  }

  Future<Map<String, Object?>> _get(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getEventData')
          .call({'url': uri.toString()});

      return result.data;
    } on FirebaseFunctionsException catch (e) {
      developer.log('Cloud Function error: ${e.code} - ${e.message}');

      throw F3NationApiException('Request to $path failed: $e');
    }
  }
}

// Writing to the event requires the API key, which we do not want to store
// locally, so we use a secure Cloud Function.
Future<Map<String, Object?>> _post(
  String path, {
  required Map<String, Object?> payload,
}) async {
  final uri = _buildUri(path, const {});
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('postEventData')
        .call({'url': uri.toString(), 'payload': payload});

    return result.data;
  } on FirebaseFunctionsException catch (e) {
    developer.log('Cloud Function error: ${e.code} - ${e.message}');
    rethrow;
  }
}

Uri _buildUri(String path, Map<String, Object?> queryParameters) {
  final params = <String, Object?>{};
  for (final entry in queryParameters.entries) {
    final value = entry.value;
    if (value == null) continue;
    if (value is Iterable) {
      final list = value.map((e) => '$e').toList();
      if (list.isEmpty) continue;
      params[entry.key] = list;
    } else {
      params[entry.key] = '$value';
    }
  }
  return Uri.https(_f3NationApiHost, '/v1$path', params);
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String? _readErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, Object?>) {
      return _readString(decoded, 'message');
    }
  } on FormatException {
    // Fall through to null below.
  }
  return null;
}

List<Map<String, Object?>> _readList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) return const [];
  return value.whereType<Map>().map(Map<String, Object?>.from).toList();
}

Map<String, Object?> _readObject(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('Expected an object at "$key".');
}

int? _readInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

DateTime? _readDate(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
