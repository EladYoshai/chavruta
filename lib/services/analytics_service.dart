import 'package:flutter/foundation.dart';
import 'analytics_stub.dart' if (dart.library.js_interop) 'analytics_web.dart';

/// Lightweight Google Analytics wrapper.
/// Sends custom events via gtag() on web. No-op on mobile.
class AnalyticsService {
  static void logEvent(String name, [Map<String, Object>? params]) {
    if (!kIsWeb) return;
    sendGtagEvent(name, params);
  }

  static void screenView(String screenName) =>
      logEvent('screen_view', {'screen_name': screenName});

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
