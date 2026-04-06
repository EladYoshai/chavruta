/// Stub for non-web platforms. No-op.
class WebNotificationService {
  static Future<bool> requestPermission() async => false;
  static bool get isSupported => false;
  static bool get hasPermission => false;
  static void show({required String title, required String body, String? icon}) {}
  static void checkDailyReminder({required int hour, required int minute, required bool hasStudiedToday}) {}
  static void checkStreakWarning({required bool hasStudiedToday, required int streakDays}) {}
  static void checkCandleLighting() {}
}
