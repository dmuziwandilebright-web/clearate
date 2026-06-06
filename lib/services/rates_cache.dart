import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/rate_snapshot.dart';

class RatesCache {
  RatesCache(this._prefs);

  static const _key = 'clearate_rate_snapshot_v1';
  static const _prevKey = 'clearate_rate_snapshot_prev_v1';

  final SharedPreferences _prefs;

  RateSnapshot? readLatest() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    final decoded = json.decode(raw);
    if (decoded is! Map) return null;
    return RateSnapshot.fromJson(decoded.cast<String, Object?>());
  }

  RateSnapshot? readPrevious() {
    final raw = _prefs.getString(_prevKey);
    if (raw == null) return null;
    final decoded = json.decode(raw);
    if (decoded is! Map) return null;
    return RateSnapshot.fromJson(decoded.cast<String, Object?>());
  }

  Future<void> writeLatest(RateSnapshot snapshot) async {
    final current = readLatest();
    if (current != null) {
      await _prefs.setString(_prevKey, json.encode(current.toJson()));
    }
    await _prefs.setString(_key, json.encode(snapshot.toJson()));
  }
}

