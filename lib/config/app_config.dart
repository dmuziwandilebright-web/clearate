import 'package:flutter/foundation.dart';

@immutable
class AppConfig {
  const AppConfig({
    required this.proxyRatesUrl,
    required this.versionInfoUrl,
    this.refreshMinInterval = const Duration(hours: 24),
    this.anomalyRejectThreshold = 0.15,
  });

  /// Cloudflare Worker endpoint that returns the nested rates payload.
  ///
  /// Example response:
  /// {
  ///   "rates": {
  ///     "usd_zar": 16.58,
  ///     "usd_zwg": 26.77,
  ///     "zar_zwg": 1.61
  ///   },
  ///   "thresholds": {
  ///     "upper_pct": 10.28,
  ///     "lower_pct": 2.57
  ///   },
  ///   "meta": {
  ///     "server_time": "2026-05-26T08:00:00Z"
  ///   }
  /// }
  final Uri proxyRatesUrl;

  /// Hosted JSON that contains the latest app version and APK URL.
  final Uri versionInfoUrl;

  /// Minimum time between successful online refreshes. Enforced by timestamp,
  /// not timers (closing/reopening within the window won't refetch).
  final Duration refreshMinInterval;

  /// If any rate differs by more than this fraction vs cached rate, reject it.
  final double anomalyRejectThreshold;

  static AppConfig fromEnv() {
    final proxy = const String.fromEnvironment(
      'CLEARATE_PROXY_RATES_URL',
      defaultValue: 'https://clearate-rates.dmuziwandilebright.workers.dev',
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
