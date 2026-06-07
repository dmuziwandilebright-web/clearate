import '../domain/rate_snapshot.dart';

const Map<String, Object?> demoRates = <String, Object?>{
  'usd_zar': 18.50,
  'usd_zwg': 13.60,
  'zar_zwg': 0.74,
  'bwp_usd': 0.073,
  'bwp_zar': 1.35,
  'server_time': null,
  'source': 'Reference rates',
};

RateSnapshot buildDemoSnapshot({required DateTime fetchedAt}) {
  return RateSnapshot(
    usdZar: (demoRates['usd_zar'] as num).toDouble(),
    usdZwg: (demoRates['usd_zwg'] as num).toDouble(),
    zarZwg: (demoRates['zar_zwg'] as num).toDouble(),
    bwpUsd: (demoRates['bwp_usd'] as num).toDouble(),
    bwpZar: (demoRates['bwp_zar'] as num).toDouble(),
    serverTime: demoRates['server_time'] as DateTime?,
    source: demoRates['source'] as String,
    fetchedAt: fetchedAt,
  );
}
