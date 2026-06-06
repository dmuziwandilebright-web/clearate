import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clearate/app/app_scope.dart';
import 'package:clearate/config/app_config.dart';
import 'package:clearate/main.dart';
import 'package:clearate/services/rates_cache.dart';
import 'package:clearate/services/rates_client.dart';
import 'package:clearate/state/rates_controller.dart';

void main() {
  testWidgets('Clearate app smoke test', (WidgetTester tester) async {
    // 1. Setup mock SharedPreferences values
    final mockSnapshot = {
      'usd_zar': 18.43,
      'usd_zwg': 13.60,
      'zar_zwg': 0.74,
      'server_time': '2026-06-03T08:00:00Z',
      'source': 'RBZ interbank',
      'fetched_at': '2026-06-03T08:00:00Z',
    };

    SharedPreferences.setMockInitialValues({
      'clearate_rate_snapshot_v1': json.encode(mockSnapshot),
    });

    // 2. Initialize dependencies
    final config = AppConfig.fromEnv();
    final prefs = await SharedPreferences.getInstance();
    final cache = RatesCache(prefs);
    final client = RatesClient();
    final ratesController = RatesController(cache: cache, client: client, config: config);

    // 3. Build our app and trigger a frame.
    await tester.pumpWidget(
      AppScope(
        config: config,
        ratesController: ratesController,
        child: const ClearateApp(),
      ),
    );

    // 4. Verify that our title is rendered.
    expect(find.text('Clearate'), findsOneWidget);

    // 5. Verify that our currency rate card is rendered.
    expect(find.text('USD to ZiG'), findsOneWidget);
  });
}
