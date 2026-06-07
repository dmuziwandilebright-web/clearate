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

  static const empty = RatesState(snapshot: null, isRefreshing: false, warning: null);
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
    _state = RatesState(
      snapshot: snapshot,
      isRefreshing: false,
      warning: null,
    );
    if (cached == null) {
      Future(() async {
        await _cache.writeLatest(snapshot);
      });
    }
  }

  final RatesCache _cache;
  final RatesClient _client;
  final AppConfig _config;

  late RatesState _state;
  RatesState get state => _state;

  RateSnapshot? get previousSnapshot => _cache.readPrevious();

  bool get hasSnapshot => _state.snapshot != null;

  Future<void> refreshIfAllowed({bool force = false}) async {
    final current = _state.snapshot;
    if (current == null || current.serverTime == null) {
      await _refresh(force: force);
      return;
    }
    if (!force && current != null) {
      final age = DateTime.now().difference(current.fetchedAt);
      if (age < _config.refreshMinInterval) return;
    }
    await _refresh();
  }

  Future<void> forceRefresh() => _refresh(force: true);

  Future<void> importSnapshot(RateSnapshot snapshot) async {
    await _cache.writeLatest(snapshot.copyWithFetchedAt(DateTime.now()));
    _state = RatesState(
      snapshot: _cache.readLatest(),
      isRefreshing: false,
      warning: null,
    );
    notifyListeners();
  }

  Future<void> _refresh({bool force = false}) async {
    if (_state.isRefreshing) return;
    _state = _state.copyWith(isRefreshing: true, warning: null);
    notifyListeners();

    try {
      final incoming = await _client.fetchRates(_config);
      final previous = _cache.readLatest();

      if (!force && previous != null) {
        final anomaly = _detectAnomaly(previous, incoming);
        if (anomaly != null) {
          _state = _state.copyWith(isRefreshing: false, warning: anomaly);
          notifyListeners();
          return;
        }
      }

      await _cache.writeLatest(incoming);
      _state = _state.copyWith(snapshot: incoming, isRefreshing: false, warning: null);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isRefreshing: false,
        warning: 'Could not refresh rates. Showing last saved official rates.',
      );
      notifyListeners();
    }
  }

  String? _detectAnomaly(RateSnapshot previous, RateSnapshot incoming) {
    final threshold = _config.anomalyRejectThreshold;

    bool tooDifferent(double oldValue, double newValue) {
      if (oldValue <= 0 || newValue <= 0) return true;
      final diff = (newValue - oldValue).abs() / oldValue;
      return diff > threshold;
    }

    final bad = <String>[];
    if (tooDifferent(previous.usdZar, incoming.usdZar)) bad.add('USD/ZAR');
    if (tooDifferent(previous.usdZwg, incoming.usdZwg)) bad.add('USD/ZWG');
    if (tooDifferent(previous.zarZwg, incoming.zarZwg)) bad.add('ZAR/ZWG');
    if (previous.bwpUsd > 0 && incoming.bwpUsd > 0 && tooDifferent(previous.bwpUsd, incoming.bwpUsd)) {
      bad.add('BWP/USD');
    }
    if (previous.bwpZar > 0 && incoming.bwpZar > 0 && tooDifferent(previous.bwpZar, incoming.bwpZar)) {
      bad.add('BWP/ZAR');
    }

    if (bad.isEmpty) return null;
    return 'Rate anomaly detected (${bad.join(', ')}). Using last known official rates.';
  }
}
