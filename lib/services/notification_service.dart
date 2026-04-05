import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Notification service for daily reminders and milestone celebrations.
/// Only works on mobile (Android/iOS). On web, notifications are skipped.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Notification channel IDs
  static const String _dailyChannelId = 'daily_reminder';
  static const String _streakChannelId = 'streak_warning';
  static const String _milestoneChannelId = 'milestone';
  static const String _omerChannelId = 'omer_reminder';

  // Notification IDs
  static const int _dailyReminderId = 1;
  static const int _streakWarningId = 2;
  static const int _omerReminderId = 3;
  static const int _milestoneBaseId = 100;

  /// Initialize notification service
  static Future<void> init() async {
    if (kIsWeb || _initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationAction,
    );
    _initialized = true;
  }

  /// Handle notification action tap
  static void _onNotificationAction(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload == 'omer_snooze') {
      // Snooze: reschedule in 1 hour
      _snoozeOmer();
    }
    // 'omer_done' or tap = just dismiss (default)
  }

  /// Snooze omer reminder for 1 hour
  static Future<void> _snoozeOmer() async {
    if (kIsWeb || !_initialized) return;

    final snoozeTime = DateTime.now().add(const Duration(hours: 1));
    await _plugin.zonedSchedule(
      _omerReminderId + 10, // different ID so it doesn't cancel the daily one
      'חברותא - ספירת העומר (תזכורת)',
      'לא לשכוח לספור ספירת העומר!',
      tz.TZDateTime.from(snoozeTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _omerChannelId,
          'ספירת העומר',
          channelDescription: 'תזכורת יומית לספירת העומר',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedule a daily learning reminder
  static Future<void> scheduleDailyReminder({
    int hour = 8,
    int minute = 0,
  }) async {
    if (kIsWeb || !_initialized) return;

    await _plugin.cancel(_dailyReminderId);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'חברותא',
      'בוקר טוב! הגיע הזמן ללמוד תורה 📖',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          'תזכורת יומית',
          channelDescription: 'תזכורת יומית ללימוד תורה',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a streak warning notification for 20:00 if user hasn't studied
  static Future<void> scheduleStreakWarning() async {
    if (kIsWeb || !_initialized) return;

    await _plugin.cancel(_streakWarningId);

    final now = DateTime.now();
    var warningTime = DateTime(now.year, now.month, now.day, 20, 0);
    if (warningTime.isBefore(now)) {
      warningTime = warningTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _streakWarningId,
      'חברותא - הרצף שלך בסכנה!',
      'עוד לא למדת היום! הרצף שלך בסכנה 🔥',
      tz.TZDateTime.from(warningTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _streakChannelId,
          'אזהרת רצף',
          channelDescription: 'אזהרה כשהרצף בסכנה',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancel streak warning (called when user completes a section today)
  static Future<void> cancelStreakWarning() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(_streakWarningId);
  }

  /// Show an immediate milestone notification
  static Future<void> showMilestoneNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) return;

    final id = _milestoneBaseId + DateTime.now().millisecondsSinceEpoch % 1000;
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _milestoneChannelId,
          'הישגים',
          channelDescription: 'התראות על הישגים ואבני דרך',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Show streak milestone notification
  static Future<void> notifyStreakMilestone(int days) async {
    final messages = {
      7: 'כל הכבוד! רצף של שבוע שלם! 🔥',
      30: 'מדהים! חודש של לימוד רצוף! 💎',
      100: 'אגדי! 100 ימים של לימוד תורה! 👑',
    };
    final message = messages[days];
    if (message != null) {
      await showMilestoneNotification(
        title: 'חברותא - אבן דרך!',
        body: message,
      );
    }
  }

  /// Schedule daily omer reminder
  static Future<void> scheduleOmerReminder({
    int hour = 20,
    int minute = 0,
    required String omerText,
  }) async {
    if (kIsWeb || !_initialized) return;

    await _plugin.cancel(_omerReminderId);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _omerReminderId,
      'חברותא - ספירת העומר 🌾',
      omerText,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _omerChannelId,
          'ספירת העומר',
          channelDescription: 'תזכורת יומית לספירת העומר',
          importance: Importance.high,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'omer_done',
              'קראתי, תודה ✓',
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'omer_snooze',
              'תזכיר לי מאוחר יותר',
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'omer',
    );
  }

  /// Cancel omer reminder
  static Future<void> cancelOmerReminder() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(_omerReminderId);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }
}
