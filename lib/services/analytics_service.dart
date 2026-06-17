import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsService {
  static Future<void> logScreenView(String screenName) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    } catch (_) {
      // Ignore analytics failures so the app stays usable offline or in tests.
    }
  }

  static Future<void> logEvent({
    required String name,
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: Map<String, Object>.fromEntries(
          parameters.entries
              .where((entry) => entry.value != null)
              .map((entry) => MapEntry(entry.key, entry.value as Object)),
        ),
      );
    } catch (_) {
      // Keep analytics best-effort only.
    }
  }
}
