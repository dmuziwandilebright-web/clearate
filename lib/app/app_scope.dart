import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/remote_flags.dart';
import '../services/update_checker.dart';
import '../state/rates_controller.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.config,
    required this.ratesController,
    this.releaseInfo,
    required this.remoteFlagsController,
    required super.child,
  });

  final AppConfig config;
  final RatesController ratesController;
  final UpdateInfo? releaseInfo;
  final RemoteFlagsController remoteFlagsController;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return config != oldWidget.config ||
        ratesController != oldWidget.ratesController ||
        releaseInfo != oldWidget.releaseInfo ||
        remoteFlagsController != oldWidget.remoteFlagsController;
  }
}
