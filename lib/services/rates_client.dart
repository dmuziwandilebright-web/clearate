import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../domain/rate_snapshot.dart';

class RatesClient {
  RatesClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<RateSnapshot> fetchRates(AppConfig config) async {
    final res = await _http.get(
      config.proxyRatesUrl,
      headers: const {
        HttpHeaders.acceptHeader: 'application/json',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('Proxy error ${res.statusCode}');
    }

    return RateSnapshot.fromProxyResponse(res.body, fetchedAt: DateTime.now());
  }
}

