import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics wrapper backed by Firebase Analytics.
/// Works on web, Android, and iOS (requires google-services.json on Android).
class AnalyticsService {
  static FirebaseAnalytics? _fa;

  /// Call once after Firebase.initializeApp().
  static void init() {
    try {
      _fa = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('Analytics init failed: $e');
    }
  }

  static void logEvent(String name, [Map<String, Object>? params]) {
    final fa = _fa;
    if (fa == null) return;
    try {
      fa.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics logEvent failed: $e');
    }
  }

  static void screenView(String screenName) {
    final fa = _fa;
    if (fa == null) return;
    try {
      fa.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  static void sectionCompleted(String section) =>
      logEvent('section_completed', {'section': section});

  static void quizCompleted(int score, int total) =>
      logEvent('quiz_completed', {'score': score, 'total': total});

  static void trackerChecked(String target) =>
      logEvent('tracker_checked', {'target': target});

  static void streakMilestone(int days) =>
      logEvent('streak_milestone', {'days': days});

  static void siyumCompleted(String masechet) =>
      logEvent('siyum_completed', {'masechet': masechet});

  static void badgeEarned(String badge) =>
      logEvent('badge_earned', {'badge': badge});

  static void profileCreated(String gender) =>
      logEvent('profile_created', {'gender': gender});
}
