import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.releaseNotes,
    required this.reportFeatureActive,
    required this.supportContactNumbers,
    required this.maintenanceMode,
    required this.minAppVersion,
    required this.announcementMessage,
    required this.announcementActive,
    required this.tagline,
    required this.complaintDisclaimer,
    required this.demoRates,
  });

  final String latestVersion;
  final Uri apkUrl;
  final String releaseNotes;
  final bool reportFeatureActive;
  final List<String> supportContactNumbers;
  final bool maintenanceMode;
  final String minAppVersion;
  final String announcementMessage;
  final bool announcementActive;
  final String tagline;
  final String complaintDisclaimer;
  final Map<String, double> demoRates;
}

class UpdateChecker {
  UpdateChecker({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<UpdateInfo> fetch(AppConfig config) async {
    final res = await _http.get(
      config.versionInfoUrl,
      headers: const {HttpHeaders.acceptHeader: 'application/json'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('Version check failed ${res.statusCode}');
    }
    final decoded = json.decode(res.body);
    if (decoded is! Map) {
      throw const FormatException('Invalid version.json: not an object');
    }
    final map = decoded.map((k, v) => MapEntry(k.toString(), v));
    return UpdateInfo(
      latestVersion: _readString(map, 'latest'),
      apkUrl: Uri.parse((map['apk_url'] as String).trim()),
      releaseNotes: _readString(map, 'release_notes', fallbackKey: 'notes'),
      reportFeatureActive: map['report_feature_active'] is bool
          ? map['report_feature_active'] as bool
          : false,
      supportContactNumbers:
          _readStringList(map['support'] ?? map['support_contact_numbers']),
      maintenanceMode: map['maintenance_mode'] is bool
          ? map['maintenance_mode'] as bool
          : false,
      minAppVersion: ((map['min_app_version'] as String?) ?? '').trim(),
      announcementMessage:
          ((map['announcement_message'] as String?) ?? '').trim(),
      announcementActive: map['announcement_active'] is bool
          ? map['announcement_active'] as bool
          : false,
      tagline: _readString(map, 'tagline'),
      complaintDisclaimer: _readString(map, 'complaint_disclaimer'),
      demoRates: _readDemoRates(map['demo_rates']),
    );
  }
}

String _readString(
  Map<String, Object?> map,
  String key, {
  String? fallbackKey,
}) {
  final value = map[key] ?? (fallbackKey == null ? null : map[fallbackKey]);
  return value?.toString().trim() ?? '';
}

Map<String, double> _readDemoRates(Object? value) {
  if (value is! Map) return const <String, double>{};
  final map = value.cast<Object?, Object?>();
  final out = <String, double>{};
  for (final entry in map.entries) {
    final parsed = double.tryParse(entry.value?.toString() ?? '');
    if (parsed != null && parsed > 0) {
      out[entry.key.toString()] = parsed;
    }
  }
  return out;
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return [value.trim()];
  }
  return const <String>[];
}
