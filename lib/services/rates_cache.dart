import 'dart:io';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/rate_snapshot.dart';

class RatesCache {
  RatesCache(this._prefs);

  static const _key = 'clearate_rate_snapshot_v1';
  static const _prevKey = 'clearate_rate_snapshot_prev_v1';
  static const _backupFileName = 'clearate_rate_snapshot_backup.json';

  final SharedPreferences _prefs;

  RateSnapshot? readLatest() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return null;
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      return RateSnapshot.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  RateSnapshot? readPrevious() {
    try {
      final raw = _prefs.getString(_prevKey);
      if (raw == null) return null;
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      return RateSnapshot.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  Future<RateSnapshot?> readBackupLatest() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_backupFileName');
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      return RateSnapshot.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  Future<bool> writeLatest(RateSnapshot snapshot) async {
    final current = readLatest();
    if (current != null) {
      try {
        await _prefs.setString(_prevKey, json.encode(current.toJson()));
      } catch (_) {
        // Ignore and continue to best-effort backup storage.
      }
    }
    final payload = json.encode(snapshot.toJson());
    var wrotePrefs = false;
    try {
      wrotePrefs = await _prefs.setString(_key, payload);
    } catch (_) {
      wrotePrefs = false;
    }

    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_backupFileName');
      await file.writeAsString(payload, flush: true);
      return true;
    } catch (_) {
      return wrotePrefs;
    }
  }
}
