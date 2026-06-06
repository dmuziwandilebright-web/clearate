import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'currency.dart';

@immutable
class RateSnapshot {
  const RateSnapshot({
    required this.usdZar,
    required this.usdZwg,
    required this.zarZwg,
    required this.serverTime,
    required this.source,
    required this.fetchedAt,
  });

  final double usdZar;
  final double usdZwg;
  final double zarZwg;
  final DateTime serverTime;
  final String source;

  /// Local timestamp when this snapshot was fetched/accepted.
  final DateTime fetchedAt;

  double rate(Currency from, Currency to) {
    if (from == to) return 1.0;

    // Direct pairs from proxy.
    if (from == Currency.usd && to == Currency.zar) return usdZar;
    if (from == Currency.usd && to == Currency.zwg) return usdZwg;
    if (from == Currency.zar && to == Currency.zwg) return zarZwg;

    // Inverses.
    if (from == Currency.zar && to == Currency.usd) return 1.0 / usdZar;
    if (from == Currency.zwg && to == Currency.usd) return 1.0 / usdZwg;
    if (from == Currency.zwg && to == Currency.zar) return 1.0 / zarZwg;

    // Cross pairs.
    if (from == Currency.zar && to == Currency.zwg) return zarZwg;
    if (from == Currency.zwg && to == Currency.zar) return 1.0 / zarZwg;

    // USD<->ZAR<->ZWG triangles cover all combinations.
    if (from == Currency.usd && to == Currency.zar) return usdZar;
    if (from == Currency.zar && to == Currency.usd) return 1.0 / usdZar;

    // Remaining cross: ZAR->ZWG and USD->ZWG are already direct.
    // USD->ZAR->ZWG is also derivable, but we prefer direct if present.
    if (from == Currency.usd && to == Currency.zwg) return usdZwg;
    if (from == Currency.zwg && to == Currency.usd) return 1.0 / usdZwg;

    throw StateError('Unsupported conversion: ${from.code} -> ${to.code}');
  }

  RateSnapshot copyWithFetchedAt(DateTime time) {
    return RateSnapshot(
      usdZar: usdZar,
      usdZwg: usdZwg,
      zarZwg: zarZwg,
      serverTime: serverTime,
      source: source,
      fetchedAt: time,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'usd_zar': usdZar,
        'usd_zwg': usdZwg,
        'zar_zwg': zarZwg,
        'server_time': serverTime.toIso8601String(),
        'source': source,
        'fetched_at': fetchedAt.toIso8601String(),
      };

  static RateSnapshot fromJson(Map<String, Object?> json) {
    return RateSnapshot(
      usdZar: (json['usd_zar'] as num).toDouble(),
      usdZwg: (json['usd_zwg'] as num).toDouble(),
      zarZwg: (json['zar_zwg'] as num).toDouble(),
      serverTime: DateTime.parse(json['server_time'] as String),
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

    return RateSnapshot(
      usdZar: (map['usd_zar'] as num).toDouble(),
      usdZwg: (map['usd_zwg'] as num).toDouble(),
      zarZwg: (map['zar_zwg'] as num).toDouble(),
      serverTime: DateTime.parse(map['server_time'] as String),
      source: (map['source'] as String?) ?? 'RBZ interbank',
      fetchedAt: fetchedAt,
    );
  }
}

