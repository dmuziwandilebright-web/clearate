import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../domain/rate_snapshot.dart';

class RatesClientException implements Exception {
  const RatesClientException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'RatesClientException($code): $message';
}

class RatesClient {
  RatesClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<RateSnapshot> fetchRates(AppConfig config) async {
    final res = await _http
        .get(
          config.proxyRatesUrl,
          headers: const {
            HttpHeaders.acceptHeader: 'application/json',
          },
        )
        .timeout(const Duration(seconds: 12));
    final body = res.body.trim();
    Map<String, Object?>? decoded;
    if (body.isNotEmpty) {
      try {
        final jsonBody = json.decode(body);
        if (jsonBody is Map) {
          decoded = jsonBody.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        decoded = null;
      }
    }

    final errorCode = decoded?['error_code']?.toString();
    if (errorCode != null && errorCode.isNotEmpty) {
      throw RatesClientException(
        code: errorCode,
        message: (decoded?['message']?.toString() ?? errorCode).trim(),
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw RatesClientException(
        code: 'worker_error',
        message: 'Proxy error ${res.statusCode}',
        statusCode: res.statusCode,
      );
    }

    return RateSnapshot.fromWorkerResponse(res.body, fetchedAt: DateTime.now());
  }
}
