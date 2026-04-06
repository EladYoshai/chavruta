import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web Notification API wrapper.
/// Shows browser notifications on web (PWA on phone).
class WebNotificationService {
  static bool _permissionGranted = false;

  /// Request notification permission from the user
  static Future<bool> requestPermission() async {
    try {
      final notification = globalContext.getProperty('Notification'.toJS);
      if (notification.isUndefinedOrNull) return false;

      // Check current permission
      final permission = (notification as JSObject).getProperty('permission'.toJS);
      if (permission.toString() == 'granted') {
        _permissionGranted = true;
        return true;
      }
      if (permission.toString() == 'denied') return false;

      // Request permission
      final result = await (notification.callMethod('requestPermission'.toJS) as JSPromise).toDart;
      _permissionGranted = result.toString() == 'granted';
      return _permissionGranted;
    } catch (_) {
      return false;
    }
  }

  /// Check if notifications are supported
  static bool get isSupported {
    try {
      final notification = globalContext.getProperty('Notification'.toJS);
      return !notification.isUndefinedOrNull;
    } catch (_) {
      return false;
    }
  }

  /// Check if permission is granted
  static bool get hasPermission {
    if (_permissionGranted) return true;
    try {
      final notification = globalContext.getProperty('Notification'.toJS);
      if (notification.isUndefinedOrNull) return false;
      final permission = (notification as JSObject).getProperty('permission'.toJS);
      _permissionGranted = permission.toString() == 'granted';
      return _permissionGranted;
    } catch (_) {
      return false;
    }
  }

  /// Show a notification immediately
  static void show({
    required String title,
    required String body,
    String? icon,
  }) {
    if (!hasPermission) return;
    try {
      final options = {
        'body': body,
        'icon': icon ?? '/icons/Icon-192.png',
        'dir': 'rtl',
        'lang': 'he',
      }.jsify();
      final notifClass = globalContext.getProperty('Notification'.toJS);
      if (notifClass != null) {
        (notifClass as JSFunction).callAsConstructor(title.toJS, options);
      }
    } catch (_) {}
  }

  /// Check if it's time for daily reminder and show it
  /// Call this on app startup
  static void checkDailyReminder({
    required int hour,
    required int minute,
    required bool hasStudiedToday,
  }) {
    if (!hasPermission) return;
    final now = DateTime.now();
    final reminderTime = DateTime(now.year, now.month, now.day, hour, minute);

    // Show if we're within 30 minutes after the reminder time and haven't studied
    if (now.isAfter(reminderTime) &&
        now.difference(reminderTime).inMinutes <= 30 &&
        !hasStudiedToday) {
      show(
        title: 'חברותא',
        body: 'בוקר טוב! הגיע הזמן ללמוד תורה 📖',
      );
    }
  }

  /// Check streak warning (evening)
  static void checkStreakWarning({
    required bool hasStudiedToday,
    required int streakDays,
  }) {
    if (!hasPermission || hasStudiedToday || streakDays == 0) return;
    final now = DateTime.now();

    // Show warning after 20:00 if hasn't studied today and has a streak
    if (now.hour >= 20) {
      show(
        title: 'חברותא - הרצף שלך בסכנה!',
        body: 'עוד לא למדת היום! הרצף שלך בסכנה 🔥',
      );
    }
  }

  /// Check candle lighting (Friday)
  static void checkCandleLighting() {
    if (!hasPermission) return;
    final now = DateTime.now();

    // Friday between 16:00-17:30 (approximate candle lighting window)
    if (now.weekday == DateTime.friday && now.hour >= 16 && now.hour < 18) {
      show(
        title: 'חברותא - הדלקת נרות שבת 🕯️',
        body: 'הגיע הזמן להדליק נרות שבת!',
      );
    }
  }
}
