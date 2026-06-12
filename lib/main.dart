import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_scope.dart';
import 'config/app_config.dart';
import 'config/brand_assets.dart';
import 'services/rates_cache.dart';
import 'services/rates_client.dart';
import 'state/rates_controller.dart';
import 'ui/screens/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClearateBootstrapApp());
}

class ClearateBootstrapApp extends StatefulWidget {
  const ClearateBootstrapApp({super.key});

  @override
  State<ClearateBootstrapApp> createState() => _ClearateBootstrapAppState();
}

class _ClearateBootstrapAppState extends State<ClearateBootstrapApp> {
  late Future<_BootstrapResult> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<_BootstrapResult> _bootstrap() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase stays optional. The app should still open with cached rates.
    }

    final config = AppConfig.fromEnv();
    final prefs = await SharedPreferences.getInstance();
    final cache = RatesCache(prefs);
    final client = RatesClient();
    final ratesController = RatesController(
      cache: cache,
      client: client,
      config: config,
    );
    await ratesController.restoreFromStorage();

    return _BootstrapResult(
      config: config,
      ratesController: ratesController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _LoadingScreen(),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return MaterialApp(
            title: 'Clearate',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: buildClearateTheme(),
            home: _BootstrapErrorScreen(
              message: 'Unable to open Clearate right now.',
              onRetry: () => setState(() {
                _bootstrapFuture = _bootstrap();
              }),
            ),
          );
        }

        final result = snapshot.data!;
        return AppScope(
          config: result.config,
          ratesController: result.ratesController,
          child: MaterialApp(
            title: 'Clearate',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: buildClearateTheme(),
            home: const ClearateContent(),
          ),
        );
      },
    );
  }
}

class _BootstrapResult {
  const _BootstrapResult({
    required this.config,
    required this.ratesController,
  });

  final AppConfig config;
  final RatesController ratesController;
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

class ClearateContent extends StatelessWidget {
  const ClearateContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShell();
  }
}

class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060B14), Color(0xFF0B1C30), Color(0xFF121F38)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 340,
                      maxHeight: 720,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 36,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      BrandAssets.loadingScreen,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _AnimatedDots(controller: _controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.18;
            final phase = ((t + delay) % 1.0) * 2 * 3.14159;
            final pulse = 0.5 + 0.5 * math.sin(phase);
            final scale = 0.82 + (0.22 * pulse);
            final opacity = 0.45 + (0.55 * pulse);
            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B1C30),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  BrandAssets.appLogo,
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  'Clearate',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
