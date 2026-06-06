import 'package:flutter/foundation.dart';

@immutable
class AppConfig {
  const AppConfig({
    required this.proxyRatesUrl,
    required this.versionInfoUrl,
    this.refreshMinInterval = const Duration(hours: 1),
    this.anomalyRejectThreshold = 0.15,
    this.overchargeThreshold = 0.08,
    this.undervaluedThreshold = 0.03,
  });

  /// Cloudflare Worker endpoint that returns the 3 official mid-rates.
  ///
  /// Example response:
  /// {
  ///   "usd_zar": 18.43,
  ///   "usd_zwg": 13.60,
  ///   "zar_zwg": 0.74,
  ///   "server_time": "2026-05-26T08:00:00Z",
  ///   "source": "RBZ interbank"
  /// }
  final Uri proxyRatesUrl;

  /// Hosted JSON that contains the latest app version and APK URL.
  final Uri versionInfoUrl;

  /// Minimum time between successful online refreshes. Enforced by timestamp,
  /// not timers (closing/reopening within the window won't refetch).
  final Duration refreshMinInterval;

  /// If any rate differs by more than this fraction vs cached rate, reject it.
  final double anomalyRejectThreshold;

  /// Verdict: OVERCHARGED if shop rate is more than this fraction above official.
  final double overchargeThreshold;

  /// Verdict: UNDERVALUED if shop rate is more than this fraction below official.
  final double undervaluedThreshold;

  static AppConfig fromEnv() {
    final proxy = const String.fromEnvironment(
      'CLEARATE_PROXY_RATES_URL',
      defaultValue: 'https://example.clearate.workers.dev/rates',
    );
    final version = const String.fromEnvironment(
      'CLEARATE_VERSION_INFO_URL',
      defaultValue: 'https://yourusername.github.io/clearate/version.json',
    );

    return AppConfig(
      proxyRatesUrl: Uri.parse(proxy),
      versionInfoUrl: Uri.parse(version),
    );
  }
}

