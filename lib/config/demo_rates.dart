import '../domain/rate_snapshot.dart';

const Map<String, Object?> demoRates = <String, Object?>{
  'usd_zar': 16.5837,
  'usd_zwg': 26.7782,
  'zar_zwg': 1.6147,
  'zwg_zar': 0.6193,
  'usd_bwp': 13.6,
  'bwp_zar': 1.2194,
  'bwp_zwg': 1.9690,
  'server_time': null,
  'source': 'Reference rates',
};

RateSnapshot buildDemoSnapshot({required DateTime fetchedAt}) {
  return RateSnapshot(
    usdZar: (demoRates['usd_zar'] as num).toDouble(),
    usdZwg: (demoRates['usd_zwg'] as num).toDouble(),
    zarZwg: (demoRates['zar_zwg'] as num).toDouble(),
    zwgZar: (demoRates['zwg_zar'] as num).toDouble(),
    usdBwp: (demoRates['usd_bwp'] as num).toDouble(),
    bwpZar: (demoRates['bwp_zar'] as num).toDouble(),
    bwpZwg: (demoRates['bwp_zwg'] as num).toDouble(),
    serverTime: demoRates['server_time'] as DateTime?,
    source: demoRates['source'] as String,
    fetchedAt: fetchedAt,
    thresholds: null,
    meta: null,
    usdZarSpread: null,
    usdZwgSpread: null,
    zwgZarSpread: null,
  );
}
