import '../domain/rate_snapshot.dart';

const Map<String, double> fallbackDemoRates = <String, double>{
  'usd_zar': 16.5837,
  'usd_zwg': 26.7782,
  'zar_zwg': 1.6147,
  'zwg_zar': 0.6193,
  'usd_bwp': 13.6,
  'bwp_zar': 1.2194,
  'bwp_zwg': 1.9690,
};

const String demoRatesSource = 'Reference rates';

Map<String, Object?> buildDemoRatesJson([Map<String, double>? overrideRates]) {
  final rates = overrideRates == null || overrideRates.isEmpty
      ? fallbackDemoRates
      : {...fallbackDemoRates, ...overrideRates};
  return <String, Object?>{
    ...rates,
    'server_time': null,
    'source': demoRatesSource,
  };
}

RateSnapshot buildDemoSnapshot({
  required DateTime fetchedAt,
  Map<String, double>? demoRates,
}) {
  final rates = buildDemoRatesJson(demoRates);
  return RateSnapshot(
    usdZar: (rates['usd_zar'] as num).toDouble(),
    usdZwg: (rates['usd_zwg'] as num).toDouble(),
    zarZwg: (rates['zar_zwg'] as num).toDouble(),
    zwgZar: (rates['zwg_zar'] as num).toDouble(),
    usdBwp: (rates['usd_bwp'] as num).toDouble(),
    bwpZar: (rates['bwp_zar'] as num).toDouble(),
    bwpZwg: (rates['bwp_zwg'] as num).toDouble(),
    serverTime: rates['server_time'] as DateTime?,
    source: rates['source'] as String,
    fetchedAt: fetchedAt,
    thresholds: null,
    meta: null,
    usdZarSpread: null,
    usdZwgSpread: null,
    zwgZarSpread: null,
  );
}
