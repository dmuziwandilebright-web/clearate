import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../state/rates_controller.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.config,
    required this.ratesController,
    required super.child,
  });

  final AppConfig config;
  final RatesController ratesController;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return config != oldWidget.config || ratesController != oldWidget.ratesController;
  }
}

