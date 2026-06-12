import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../config/demo_rates.dart';
import '../domain/rate_snapshot.dart';
import '../services/rates_cache.dart';
import '../services/rates_client.dart';

@immutable
class RatesState {
  const RatesState({
    required this.snapshot,
    required this.isRefreshing,
    required this.warning,
  });

  final RateSnapshot? snapshot;
  final bool isRefreshing;
  final String? warning;

  RatesState copyWith({
    RateSnapshot? snapshot,
    bool? isRefreshing,
    String? warning,
  }) {
    return RatesState(
      snapshot: snapshot ?? this.snapshot,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      warning: warning,
    );
  }

  static const empty =
      RatesState(snapshot: null, isRefreshing: false, warning: null);
}

enum RatesRefreshResult {
  refreshed,
  alreadyFresh,
  failed,
  rejected,
}

class RatesController extends ChangeNotifier {
  RatesController({
    required RatesCache cache,
    required RatesClient client,
    required AppConfig config,
  })  : _cache = cache,
        _client = client,
        _config = config {
    final cached = _cache.readLatest();
    final snapshot = cached ?? buildDemoSnapshot(fetchedAt: DateTime.now());
    _usingDemoFallback = cached == null;
    _state = RatesState(
      snapshot: snapshot,
      isRefreshing: false,
      warning: null,
    );
  }

  final RatesCache _cache;
  final RatesClient _client;
  final AppConfig _config;
  bool _usingDemoFallback = false;

  late RatesState _state;
  RatesState get state => _state;

  RateSnapshot? get previousSnapshot => _cache.readPrevious();

  bool get hasSnapshot => _state.snapshot != null;

  DateTime? _ageReference(RateSnapshot snapshot) {
    return snapshot.serverTime?.toLocal() ??
        snapshot.meta?.serverTime?.toLocal();
  }

  Future<void> restoreFromStorage() async {
    final latest = _cache.readLatest() ?? await _cache.readBackupLatest();
    if (latest == null) return;

    final current = _state.snapshot;
    final latestStamp = _ageReference(latest);
    final currentStamp = current == null ? null : _ageReference(current);
    if (_usingDemoFallback ||
        current == null ||
        (latestStamp != null &&
            (currentStamp == null || latestStamp.isAfter(currentStamp)))) {
      _usingDemoFallback = false;
      _state = RatesState(
        snapshot: latest,
        isRefreshing: false,
        warning: null,
      );
      notifyListeners();
    }
  }

  Future<RatesRefreshResult> refreshIfAllowed({bool force = false}) async {
    final current = _state.snapshot;
    if (current == null || current.serverTime == null) {
      return _refresh();
    }
    if (!force) {
      final ref = _ageReference(current);
      if (ref != null) {
        final age = DateTime.now().difference(ref);
        if (age < _config.refreshMinInterval) {
          return RatesRefreshResult.alreadyFresh;
        }
      }
    }
    return _refresh();
  }

  Future<RatesRefreshResult> forceRefresh() => _refresh();

  Future<bool> importSnapshot(RateSnapshot snapshot) async {
    final current = _state.snapshot;
    if (current != null) {
      final incomingStamp = _ageReference(snapshot);
      final currentStamp = _ageReference(current);
      if (incomingStamp != null &&
          currentStamp != null &&
          (incomingStamp.isBefore(currentStamp) ||
              incomingStamp.isAtSameMomentAs(currentStamp))) {
        return false;
      }
    }
    final saved =
        await _cache.writeLatest(snapshot.copyWithFetchedAt(DateTime.now()));
    if (!saved) {
      _state = _state.copyWith(
        isRefreshing: false,
        warning:
            'Could not save imported rates. Kept the current rates safely.',
      );
      notifyListeners();
      return false;
    }
    _usingDemoFallback = false;
    _state = RatesState(
      snapshot: _cache.readLatest(),
      isRefreshing: false,
      warning: null,
    );
    notifyListeners();
    return true;
  }

  Future<RatesRefreshResult> _refresh() async {
    if (_state.isRefreshing) return RatesRefreshResult.alreadyFresh;
    _state = _state.copyWith(isRefreshing: true, warning: null);
    notifyListeners();

    try {
      final incoming = await _client.fetchRates(_config);
      final anomaly = _detectAnomaly(incoming);
      if (anomaly != null) {
        _state = _state.copyWith(isRefreshing: false, warning: anomaly);
        notifyListeners();
        return RatesRefreshResult.rejected;
      }

      final saved = await _cache.writeLatest(incoming);
      if (!saved) {
        _state = _state.copyWith(
          isRefreshing: false,
          warning: 'Could not save fresh rates. Keeping the previous rates.',
        );
        notifyListeners();
        return RatesRefreshResult.failed;
      }
      _usingDemoFallback = false;
      _state = _state.copyWith(
          snapshot: incoming, isRefreshing: false, warning: null);
      notifyListeners();
      return RatesRefreshResult.refreshed;
    } on RatesClientException catch (e) {
      _state = _state.copyWith(
        isRefreshing: false,
        warning: _warningForCode(e.code, e.message),
      );
      notifyListeners();
      return RatesRefreshResult.failed;
    } catch (e) {
      _state = _state.copyWith(
        isRefreshing: false,
        warning: 'Could not refresh rates. Showing last saved official rates.',
      );
      notifyListeners();
      return RatesRefreshResult.failed;
    }
  }

  String? _detectAnomaly(RateSnapshot incoming) {
    final demoUsdZar = (demoRates['usd_zar'] as num).toDouble();
    final threshold = _config.anomalyRejectThreshold;
    if (demoUsdZar <= 0 || incoming.usdZar <= 0)
      return 'Rate anomaly detected. Using last known official rates.';

    final diff = (incoming.usdZar - demoUsdZar).abs() / demoUsdZar;
    if (diff <= threshold) return null;

    return 'Rate anomaly detected. Keeping saved rates.';
  }

  String _warningForCode(String code, String fallback) {
    return switch (code) {
      'zimrate_timeout' =>
        'Cloudflare took too long to reply. Showing your saved rates.',
      'incomplete_rates' =>
        'Cloudflare returned incomplete rates. Showing your saved rates.',
      'rate_anomaly' =>
        'Cloudflare returned unusual rates. Showing your saved rates.',
      'worker_error' => 'Cloudflare worker error. Showing your saved rates.',
      _ => fallback.isEmpty
          ? 'Could not refresh rates. Showing your saved rates.'
          : fallback,
    };
  }
}
