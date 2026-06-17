import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/complaint_report.dart';

class ComplaintReportStore {
  ComplaintReportStore(this._prefs);

  static const _key = 'clearate_complaint_reports_v1';
  static const _pendingKey = 'clearate_pending_complaint_reports_v1';

  final SharedPreferences _prefs;

  static Future<ComplaintReportStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ComplaintReportStore(prefs);
  }

  List<ComplaintReport> readAll() {
    try {
      final reports = _readLocalReports();
      reports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return reports;
    } catch (_) {
      return const <ComplaintReport>[];
    }
  }

  Future<void> save(ComplaintReport report) async {
    await _saveLocal(report);
    final submitted = await _writeRemote(report);
    if (submitted) {
      await _removePending(report.referenceNumber);
    } else {
      await _markPending(report.referenceNumber);
    }
  }

  Future<List<ComplaintReport>> syncAndRead() async {
    await retryPending();
    await _syncStatusesFromFirestore();
    return readAll();
  }

  Future<void> retryPending() async {
    final pending = _prefs.getStringList(_pendingKey) ?? const <String>[];
    if (pending.isEmpty) return;

    final byReference = {
      for (final report in readAll()) report.referenceNumber: report,
    };
    for (final reference in pending) {
      final report = byReference[reference];
      if (report == null) {
        await _removePending(reference);
        continue;
      }
      final submitted = await _writeRemote(report);
      if (submitted) {
        await _removePending(reference);
      }
    }
  }

  Future<void> _saveLocal(ComplaintReport report) async {
    final currentReports = _readLocalReports()
        .where((entry) => entry.referenceNumber != report.referenceNumber);
    final next = <String>[json.encode(report.toJson())];
    next.addAll(currentReports.map((entry) => json.encode(entry.toJson())));
    if (next.length > 50) {
      next.removeRange(50, next.length);
    }
    await _prefs.setStringList(_key, next);
  }

  Future<bool> _writeRemote(ComplaintReport report) async {
    if (Firebase.apps.isEmpty) return false;
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(report.referenceNumber)
          .set(report.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncStatusesFromFirestore() async {
    if (Firebase.apps.isEmpty) return;
    final localReports = readAll();
    if (localReports.isEmpty) return;

    final updated = <ComplaintReport>[];
    var changed = false;
    for (final report in localReports) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('complaints')
            .doc(report.referenceNumber)
            .get()
            .timeout(const Duration(seconds: 8));
        final data = doc.data();
        if (data == null) {
          updated.add(report);
          continue;
        }
        final merged = <String, Object?>{
          ...report.toJson(),
          ..._normaliseFirestoreMap(data),
        };
        final synced = ComplaintReport.fromJson(merged) ?? report;
        updated.add(synced);
        changed = changed ||
            json.encode(synced.toJson()) != json.encode(report.toJson());
      } catch (_) {
        updated.add(report);
      }
    }

    if (!changed) return;
    await _prefs.setStringList(
      _key,
      updated.take(50).map((report) => json.encode(report.toJson())).toList(),
    );
  }

  Map<String, Object?> _normaliseFirestoreMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      return MapEntry(key, value);
    });
  }

  List<ComplaintReport> _readLocalReports() {
    final raw = _prefs.getStringList(_key) ?? const <String>[];
    final reports = <ComplaintReport>[];
    for (final entry in raw) {
      try {
        final decoded = json.decode(entry);
        final report = ComplaintReport.fromJson(decoded);
        if (report != null) reports.add(report);
      } catch (_) {}
    }
    return reports;
  }

  Future<void> _markPending(String reference) async {
    final pending = _prefs.getStringList(_pendingKey) ?? const <String>[];
    if (pending.contains(reference)) return;
    await _prefs.setStringList(_pendingKey, <String>[reference, ...pending]);
  }

  Future<void> _removePending(String reference) async {
    final pending = _prefs.getStringList(_pendingKey) ?? const <String>[];
    if (!pending.contains(reference)) return;
    await _prefs.setStringList(
      _pendingKey,
      pending.where((entry) => entry != reference).toList(),
    );
  }
}
