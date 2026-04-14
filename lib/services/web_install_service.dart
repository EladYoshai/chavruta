import 'package:flutter/foundation.dart';
import 'web_install_interop_stub.dart'
    if (dart.library.js_interop) 'web_install_interop_web.dart' as interop;

/// Wraps JS interop for PWA install + notification permission on web.
/// All methods are no-ops on non-web platforms.
class WebInstallService {
  static bool get isSupported => kIsWeb;

  /// Is the app already running as an installed PWA?
  static bool isStandalone() => kIsWeb && interop.isStandalone();

  /// Is the device iOS (no native install prompt possible)?
  static bool isIOS() => kIsWeb && interop.isIOS();

  /// Can we fire a native Chrome install prompt right now?
  static bool canPromptInstall() => kIsWeb && interop.canPromptInstall();

  /// Fire the native install prompt. Returns outcome:
  /// 'accepted' | 'dismissed' | 'unavailable' | 'error'
  static Future<String> promptInstall() async {
    if (!kIsWeb) return 'unsupported';
    return await interop.promptInstall();
  }

  /// Notification permission: 'default' | 'granted' | 'denied' | 'unsupported'
  static String notificationStatus() {
    if (!kIsWeb) return 'unsupported';
    return interop.notificationStatus();
  }

  /// Ask user for notification permission + register FCM token.
  /// Returns: 'granted' | 'denied' | 'default' | 'unsupported' | 'no_token' | 'error'
  static Future<String> enableNotifications() async {
    if (!kIsWeb) return 'unsupported';
    return await interop.enableNotifications();
  }

  /// Hand Flutter's Firebase UID to the JS FCM layer so push_tokens/$uid
  /// and users/$uid share the same UID.
  static void setUserId(String uid) {
    if (!kIsWeb) return;
    interop.setUserId(uid);
  }

  /// Expose a Dart function to JS for saving push tokens via Flutter's
  /// authenticated Firestore client (avoids auth mismatch with JS SDK).
  static void registerTokenSaver(
    Future<bool> Function(String token, String userAgent) fn,
  ) {
    if (!kIsWeb) return;
    interop.registerTokenSaver(fn);
  }
}
