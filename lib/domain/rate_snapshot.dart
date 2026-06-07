import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'currency.dart';

@immutable
class RateSnapshot {
  const RateSnapshot({
    required this.usdZar,
    required this.usdZwg,
    required this.zarZwg,
    required this.bwpUsd,
    required this.bwpZar,
    required this.serverTime,
    required this.source,
    required this.fetchedAt,
  });

  final double usdZar;
  final double usdZwg;
  final double zarZwg;
  final double bwpUsd;
  final double bwpZar;
  final DateTime? serverTime;
  final String source;

  /// Local timestamp when this snapshot was fetched/accepted.
  final DateTime fetchedAt;

  double rate(Currency from, Currency to) {
    if (from == to) return 1.0;

    if (from == Currency.bwp && to == Currency.zar && bwpZar > 0) return bwpZar;
    if (from == Currency.zar && to == Currency.bwp && bwpZar > 0) return 1.0 / bwpZar;

    double toUsd(Currency currency) {
      return switch (currency) {
        Currency.usd => 1.0,
        Currency.zar => 1.0 / usdZar,
        Currency.zwg => 1.0 / usdZwg,
        Currency.bwp => bwpUsd > 0 ? bwpUsd : 0.0,
      };
    }

    double fromUsd(Currency currency) {
      return switch (currency) {
        Currency.usd => 1.0,
        Currency.zar => usdZar,
        Currency.zwg => usdZwg,
        Currency.bwp => bwpUsd > 0 ? 1.0 / bwpUsd : 0.0,
      };
    }

    final fromUsdRate = toUsd(from);
    final toUsdRate = fromUsd(to);
    if (fromUsdRate <= 0 || toUsdRate <= 0) return 0.0;
    return toUsdRate * fromUsdRate;
  }

  RateSnapshot copyWithFetchedAt(DateTime time) {
    return RateSnapshot(
      usdZar: usdZar,
      usdZwg: usdZwg,
      zarZwg: zarZwg,
      bwpUsd: bwpUsd,
      bwpZar: bwpZar,
      serverTime: serverTime,
      source: source,
      fetchedAt: time,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'usd_zar': usdZar,
        'usd_zwg': usdZwg,
        'zar_zwg': zarZwg,
        'bwp_usd': bwpUsd,
        'bwp_zar': bwpZar,
        'server_time': serverTime?.toIso8601String(),
        'source': source,
        'fetched_at': fetchedAt.toIso8601String(),
      };

  static RateSnapshot fromJson(Map<String, Object?> json) {
    final usdZar = (json['usd_zar'] as num).toDouble();
    final bwpUsd = ((json['bwp_usd'] as num?) ?? 0).toDouble();
    final bwpZarRaw = ((json['bwp_zar'] as num?) ?? 0).toDouble();
    final bwpZar = bwpZarRaw > 0 ? bwpZarRaw : (bwpUsd > 0 ? bwpUsd * usdZar : 0.0);

    return RateSnapshot(
      usdZar: usdZar,
      usdZwg: (json['usd_zwg'] as num).toDouble(),
      zarZwg: (json['zar_zwg'] as num).toDouble(),
      bwpUsd: bwpUsd,
      bwpZar: bwpZar,
      serverTime: json['server_time'] == null ? null : DateTime.parse(json['server_time'] as String),
      source: (json['source'] as String?) ?? 'Official',
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
    );
  }

  static RateSnapshot fromProxyResponse(String body, {required DateTime fetchedAt}) {
    final decoded = json.decode(body);
    if (decoded is! Map) {
      throw const FormatException('Invalid rates response: not an object');
    }
    final map = decoded.map((k, v) => MapEntry(k.toString(), v));
    final usdZar = (map['usd_zar'] as num).toDouble();
    final bwpUsd = ((map['bwp_usd'] as num?) ?? 0).toDouble();
    final bwpZarRaw = ((map['bwp_zar'] as num?) ?? 0).toDouble();
    final bwpZar = bwpZarRaw > 0 ? bwpZarRaw : (bwpUsd > 0 ? bwpUsd * usdZar : 0.0);

    return RateSnapshot(
      usdZar: usdZar,
      usdZwg: (map['usd_zwg'] as num).toDouble(),
      zarZwg: (map['zar_zwg'] as num).toDouble(),
      bwpUsd: bwpUsd,
      bwpZar: bwpZar,
      serverTime: map['server_time'] == null ? null : DateTime.parse(map['server_time'] as String),
      source: (map['source'] as String?) ?? 'RBZ interbank',
      fetchedAt: fetchedAt,
    );
  }
}
