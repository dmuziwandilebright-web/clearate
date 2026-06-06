import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.releaseNotes,
  });

  final String latestVersion;
  final Uri apkUrl;
  final String releaseNotes;
}

class UpdateChecker {
  UpdateChecker({http.Client? httpClient}) : _http = httpClient ?? http.Client();

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
      latestVersion: (map['version'] as String).trim(),
      apkUrl: Uri.parse((map['apk_url'] as String).trim()),
      releaseNotes: ((map['notes'] as String?) ?? '').trim(),
    );
  }
}

