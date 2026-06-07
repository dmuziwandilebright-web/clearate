import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_scope.dart';
import 'config/app_config.dart';
import 'services/rates_cache.dart';
import 'services/rates_client.dart';
import 'state/rates_controller.dart';
import 'ui/screens/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnv();
  final prefs = await SharedPreferences.getInstance();
  final cache = RatesCache(prefs);
  final client = RatesClient();
  final ratesController = RatesController(cache: cache, client: client, config: config);

  runApp(
    AppScope(
      config: config,
      ratesController: ratesController,
      child: const ClearateApp(),
    ),
  );
}

class ClearateApp extends StatelessWidget {
  const ClearateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clearate',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: buildClearateTheme(),
      home: const HomeShell(),
    );
  }
}
