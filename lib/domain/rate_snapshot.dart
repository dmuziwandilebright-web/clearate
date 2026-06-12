import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'currency.dart';

Map<String, Object?>? _asObject(Object? value) {
  if (value is! Map) return null;
  return value.cast<String, Object?>();
}

double _readNum(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

DateTime? _readDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

RateSpreadQuote? _readSpreadQuote(
  Map<String, Object?> root, {
  required String pair,
  Map<String, Object?>? spreadsMap,
}) {
  final nested = _asObject(spreadsMap?[pair]);
  final source = nested ?? root;

  final bid = _readNum(source, 'bid') > 0
      ? _readNum(source, 'bid')
      : _readNum(root, '${pair}_bid');
  final ask = _readNum(source, 'ask') > 0
      ? _readNum(source, 'ask')
      : _readNum(root, '${pair}_ask');

  if (bid <= 0 && ask <= 0) return null;
  return RateSpreadQuote(
    bid: bid > 0 ? bid : null,
    ask: ask > 0 ? ask : null,
  );
}

@immutable
class RateSpreadQuote {
  const RateSpreadQuote({
    required this.bid,
    required this.ask,
  });

  final double? bid;
  final double? ask;

  Map<String, Object?> toJson() => <String, Object?>{
        'bid': bid,
        'ask': ask,
      };

  static RateSpreadQuote? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();
    return RateSpreadQuote(
      bid: _readNum(map, 'bid'),
      ask: _readNum(map, 'ask'),
    );
  }
}

@immutable
class RateThresholds {
  const RateThresholds({
    required this.upperPct,
    required this.lowerPct,
    required this.spreadPct,
    required this.isVolatile,
    required this.source,
  });

  final double? upperPct;
  final double? lowerPct;
  final double? spreadPct;
  final bool? isVolatile;
  final String? source;

  Map<String, Object?> toJson() => <String, Object?>{
        'upper_pct': upperPct,
        'lower_pct': lowerPct,
        'spread_pct': spreadPct,
        'is_volatile': isVolatile,
        'source': source,
      };

  static RateThresholds? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();
    return RateThresholds(
      upperPct: _readNum(map, 'upper_pct'),
      lowerPct: _readNum(map, 'lower_pct'),
      spreadPct: _readNum(map, 'spread_pct'),
      isVolatile:
          map['is_volatile'] is bool ? map['is_volatile'] as bool : null,
      source: map['source']?.toString(),
    );
  }
}

@immutable
class RateMeta {
  const RateMeta({
    required this.serverTime,
    required this.rateDate,
    required this.rbzUpdated,
    required this.changePct,
    required this.source,
    required this.derivedPairs,
    required this.bwpSource,
    required this.note,
  });

  final DateTime? serverTime;
  final String? rateDate;
  final DateTime? rbzUpdated;
  final double? changePct;
  final String? source;
  final List<String> derivedPairs;
  final String? bwpSource;
  final String? note;

  Map<String, Object?> toJson() => <String, Object?>{
        'server_time': serverTime?.toIso8601String(),
        'rate_date': rateDate,
        'rbz_updated': rbzUpdated?.toIso8601String(),
        'change_pct': changePct,
        'source': source,
        'derived_pairs': derivedPairs,
        'bwp_source': bwpSource,
        'note': note,
      };

  static RateMeta? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();
    final derivedPairsRaw = map['derived_pairs'];
    return RateMeta(
      serverTime: _readDate(map['server_time']?.toString()),
      rateDate: map['rate_date']?.toString(),
      rbzUpdated: _readDate(map['rbz_updated']?.toString()),
      changePct: _readNum(map, 'change_pct'),
      source: map['source']?.toString(),
      derivedPairs: derivedPairsRaw is List
          ? derivedPairsRaw.map((value) => value.toString()).toList()
          : const <String>[],
      bwpSource: map['bwp_source']?.toString(),
      note: map['note']?.toString(),
    );
  }
}

@immutable
class RateSnapshot {
  const RateSnapshot({
    required this.usdZar,
    required this.usdZwg,
    required this.zarZwg,
    required this.zwgZar,
    required this.usdBwp,
    required this.bwpZar,
    required this.bwpZwg,
    required this.serverTime,
    required this.source,
    required this.fetchedAt,
    required this.thresholds,
    required this.meta,
    required this.usdZarSpread,
    required this.usdZwgSpread,
    required this.zwgZarSpread,
  });

  final double usdZar;
  final double usdZwg;
  final double zarZwg;
  final double zwgZar;
  final double usdBwp;
  final double bwpZar;
  final double bwpZwg;
  final DateTime? serverTime;
  final String source;

  /// Device-local timestamp when this snapshot was saved.
  final DateTime fetchedAt;
  final RateThresholds? thresholds;
  final RateMeta? meta;
  final RateSpreadQuote? usdZarSpread;
  final RateSpreadQuote? usdZwgSpread;
  final RateSpreadQuote? zwgZarSpread;

  DateTime get effectiveTimestamp =>
      (serverTime ?? meta?.serverTime ?? fetchedAt).toLocal();

  double? get changePct => meta?.changePct;

  bool get isVolatile => thresholds?.isVolatile ?? false;

  double get upperThresholdPct => thresholds?.upperPct ?? 8.0;

  double get lowerThresholdPct => thresholds?.lowerPct ?? 3.0;

  String get thresholdSource => thresholds?.source ?? 'reference_rate';

  double rate(Currency from, Currency to) {
    if (from == to) return 1.0;

    if (from == Currency.bwp && to == Currency.zar && bwpZar > 0) return bwpZar;
    if (from == Currency.zar && to == Currency.bwp && bwpZar > 0)
      return 1.0 / bwpZar;
    if (from == Currency.bwp && to == Currency.zwg && bwpZwg > 0) return bwpZwg;
    if (from == Currency.zwg && to == Currency.bwp && bwpZwg > 0)
      return 1.0 / bwpZwg;

    double usdPerUnit(Currency currency) {
      return switch (currency) {
        Currency.usd => 1.0,
        Currency.zar => usdZar > 0 ? 1.0 / usdZar : 0.0,
        Currency.zwg => usdZwg > 0 ? 1.0 / usdZwg : 0.0,
        Currency.bwp => usdBwp > 0
            ? 1.0 / usdBwp
            : (usdZar > 0 && bwpZar > 0
                ? bwpZar / usdZar
                : (usdZwg > 0 && bwpZwg > 0 ? bwpZwg / usdZwg : 0.0)),
      };
    }

    final fromUsd = usdPerUnit(from);
    final toUsd = usdPerUnit(to);
    if (fromUsd <= 0 || toUsd <= 0) return 0.0;
    return fromUsd / toUsd;
  }

  RateSnapshot copyWithFetchedAt(DateTime time) {
    return RateSnapshot(
      usdZar: usdZar,
      usdZwg: usdZwg,
      zarZwg: zarZwg,
      zwgZar: zwgZar,
      usdBwp: usdBwp,
      bwpZar: bwpZar,
      bwpZwg: bwpZwg,
      serverTime: serverTime,
      source: source,
      fetchedAt: time,
      thresholds: thresholds,
      meta: meta,
      usdZarSpread: usdZarSpread,
      usdZwgSpread: usdZwgSpread,
      zwgZarSpread: zwgZarSpread,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'rates': <String, Object?>{
          'usd_zwg': usdZwg,
          'usd_zar': usdZar,
          'zar_zwg': zarZwg,
          'zwg_zar': zwgZar,
          'usd_bwp': usdBwp,
          'bwp_zar': bwpZar,
          'bwp_zwg': bwpZwg,
        },
        if (usdZarSpread != null ||
            usdZwgSpread != null ||
            zwgZarSpread != null)
          'spreads': <String, Object?>{
            if (usdZarSpread != null) 'usd_zar': usdZarSpread!.toJson(),
            if (usdZwgSpread != null) 'usd_zwg': usdZwgSpread!.toJson(),
            if (zwgZarSpread != null) 'zwg_zar': zwgZarSpread!.toJson(),
          },
        if (thresholds != null) 'thresholds': thresholds!.toJson(),
        if (meta != null) 'meta': meta!.toJson(),
        'usd_zar': usdZar,
        'usd_zwg': usdZwg,
        'zar_zwg': zarZwg,
        'zwg_zar': zwgZar,
        'usd_bwp': usdBwp,
        'bwp_zar': bwpZar,
        'bwp_zwg': bwpZwg,
        'server_time': serverTime?.toIso8601String() ??
            meta?.serverTime?.toIso8601String(),
        'source': source,
        'local_saved_time': fetchedAt.toIso8601String(),
        'fetched_at': fetchedAt.toIso8601String(),
      };

  static RateSnapshot fromJson(Map<String, Object?> json) {
    final ratesMap = _asObject(json['rates']) ?? json;
    final spreadsMap = _asObject(json['spreads']);
    final thresholdsMap = _asObject(json['thresholds']);
    final metaMap = _asObject(json['meta']);

    final usdZar = _readNum(ratesMap, 'usd_zar');
    final usdZwg = _readNum(ratesMap, 'usd_zwg');
    final zarZwg = _readNum(ratesMap, 'zar_zwg');
    final zwgZarRaw = _readNum(ratesMap, 'zwg_zar');
    final usdBwpRaw = _readNum(ratesMap, 'usd_bwp');
    final legacyBwpUsd = _readNum(ratesMap, 'bwp_usd');
    final usdBwp = usdBwpRaw > 0
        ? usdBwpRaw
        : (legacyBwpUsd > 0 ? 1.0 / legacyBwpUsd : 0.0);
    final bwpZarRaw = _readNum(ratesMap, 'bwp_zar');
    final bwpZwgRaw = _readNum(ratesMap, 'bwp_zwg');
    final bwpZar =
        bwpZarRaw > 0 ? bwpZarRaw : (usdBwp > 0 ? usdZar / usdBwp : 0.0);
    final bwpZwg =
        bwpZwgRaw > 0 ? bwpZwgRaw : (usdBwp > 0 ? usdZwg / usdBwp : 0.0);
    final zwgZar =
        zwgZarRaw > 0 ? zwgZarRaw : (usdZwg > 0 ? usdZar / usdZwg : 0.0);
    final savedAtRaw = json['local_saved_time'] ?? json['fetched_at'];
    final savedAt = savedAtRaw == null
        ? DateTime.now()
        : _readDate(savedAtRaw.toString()) ?? DateTime.now();

    final serverTimeRaw = metaMap?['server_time'] ?? json['server_time'];
    final sourceRaw = metaMap?['source'] ?? json['source'];

    return RateSnapshot(
      usdZar: usdZar,
      usdZwg: usdZwg,
      zarZwg: zarZwg,
      zwgZar: zwgZar,
      usdBwp: usdBwp,
      bwpZar: bwpZar,
      bwpZwg: bwpZwg,
      serverTime: _readDate(serverTimeRaw?.toString()),
      source: sourceRaw?.toString() ?? 'Official',
      fetchedAt: savedAt,
      thresholds: RateThresholds.fromJson(thresholdsMap ?? json['thresholds']),
      meta: RateMeta.fromJson(metaMap ?? json['meta']),
      usdZarSpread:
          _readSpreadQuote(json, pair: 'usd_zar', spreadsMap: spreadsMap),
      usdZwgSpread:
          _readSpreadQuote(json, pair: 'usd_zwg', spreadsMap: spreadsMap),
      zwgZarSpread:
          _readSpreadQuote(json, pair: 'zwg_zar', spreadsMap: spreadsMap),
    );
  }

  static RateSnapshot fromWorkerResponse(String body,
      {required DateTime fetchedAt}) {
    final decoded = json.decode(body);
    if (decoded is! Map) {
      throw const FormatException('Invalid rates response: not an object');
    }
    final map = decoded.map((k, v) => MapEntry(k.toString(), v));
    final ratesMap = _asObject(map['rates']) ?? map;
    final spreadsMap = _asObject(map['spreads']);
    final thresholdsMap = _asObject(map['thresholds']);
    final metaMap = _asObject(map['meta']);

    final usdZar = _readNum(ratesMap, 'usd_zar');
    final usdZwg = _readNum(ratesMap, 'usd_zwg');
    final zarZwg = _readNum(ratesMap, 'zar_zwg');
    final zwgZarRaw = _readNum(ratesMap, 'zwg_zar');
    final usdBwpRaw = _readNum(ratesMap, 'usd_bwp');
    final bwpZarRaw = _readNum(ratesMap, 'bwp_zar');
    final bwpZwgRaw = _readNum(ratesMap, 'bwp_zwg');
    final usdBwp = usdBwpRaw > 0
        ? usdBwpRaw
        : (bwpZarRaw > 0 && usdZar > 0
            ? usdZar / bwpZarRaw
            : (bwpZwgRaw > 0 && usdZwg > 0 ? usdZwg / bwpZwgRaw : 0.0));
    final bwpZar =
        bwpZarRaw > 0 ? bwpZarRaw : (usdBwp > 0 ? usdZar / usdBwp : 0.0);
    final bwpZwg =
        bwpZwgRaw > 0 ? bwpZwgRaw : (usdBwp > 0 ? usdZwg / usdBwp : 0.0);
    final zwgZar =
        zwgZarRaw > 0 ? zwgZarRaw : (usdZwg > 0 ? usdZar / usdZwg : 0.0);

    return RateSnapshot(
      usdZar: usdZar,
      usdZwg: usdZwg,
      zarZwg: zarZwg,
      zwgZar: zwgZar,
      usdBwp: usdBwp,
      bwpZar: bwpZar,
      bwpZwg: bwpZwg,
      serverTime: _readDate(
          (metaMap?['server_time'] ?? map['server_time'])?.toString()),
      source: (metaMap?['source'] as String?) ??
          (map['source'] as String?) ??
          'RBZ interbank',
      fetchedAt: fetchedAt,
      thresholds: RateThresholds.fromJson(thresholdsMap),
      meta: RateMeta.fromJson(metaMap),
      usdZarSpread:
          _readSpreadQuote(map, pair: 'usd_zar', spreadsMap: spreadsMap),
      usdZwgSpread:
          _readSpreadQuote(map, pair: 'usd_zwg', spreadsMap: spreadsMap),
      zwgZarSpread:
          _readSpreadQuote(map, pair: 'zwg_zar', spreadsMap: spreadsMap),
    );
  }
}
