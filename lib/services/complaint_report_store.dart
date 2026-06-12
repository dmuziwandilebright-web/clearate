import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/complaint_report.dart';

class ComplaintReportStore {
  ComplaintReportStore(this._prefs);

  static const _key = 'clearate_complaint_reports_v1';

  final SharedPreferences _prefs;

  static Future<ComplaintReportStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ComplaintReportStore(prefs);
  }

  List<ComplaintReport> readAll() {
    try {
      final raw = _prefs.getStringList(_key) ?? const <String>[];
      final reports = raw
          .map((entry) => ComplaintReport.fromJson(json.decode(entry)))
          .whereType<ComplaintReport>()
          .toList();
      reports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return reports;
    } catch (_) {
      return const <ComplaintReport>[];
    }
  }

  Future<void> save(ComplaintReport report) async {
    final current = _prefs.getStringList(_key) ?? const <String>[];
    final next = <String>[
      json.encode(report.toJson()),
      ...current,
    ];
    if (next.length > 40) {
      next.removeRange(40, next.length);
    }
    await _prefs.setStringList(_key, next);
  }
}
