import 'package:freezed_annotation/freezed_annotation.dart';

part 'f3_nation.freezed.dart';

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
