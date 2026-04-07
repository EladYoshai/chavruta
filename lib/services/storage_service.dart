import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';
import 'notification_service.dart';

class StorageService {
  static const String _progressKey = 'user_progress';
  static const String _lastResetKey = 'last_daily_reset';

  Future<UserProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_progressKey);
    if (data != null) {
      final progress = UserProgress.fromJson(json.decode(data));
      // Check if we need to reset daily completions
      await _checkDailyReset(progress);
      return progress;
    }
    return UserProgress();
  }

  Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(progress.toJson());
    await prefs.setString(_progressKey, jsonStr);
    // Force flush to ensure persistence (critical for web)
    await prefs.reload();
  }

  Future<void> _checkDailyReset(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final lastReset = prefs.getString(_lastResetKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastReset != today) {
      // New day - check streak
      if (progress.lastStudyDate != null) {
        final lastStudy = progress.lastStudyDate!;
        final daysSince = DateTime.now().difference(lastStudy).inDays;

        if (daysSince > 1) {
          // Missed a day - check for streak shield
          if (progress.streakShields > 0) {
            progress.streakShields--;
          } else {
            progress.streakDays = 0;
          }
        }
      }

      // Reset daily completions (preserve all keys, just set to false)
      progress.todayCompleted.updateAll((key, value) => false);
      // Ensure all section keys exist
      for (final key in ['tehillim', 'shnayim_mikra', 'halacha', 'mishna',
          'emunah', 'gemara', 'rambam', 'shmirat_halashon', 'pirkei_avot',
          'nach_yomi', 'peninei_halacha']) {
        progress.todayCompleted.putIfAbsent(key, () => false);
      }

      // Reset daily tracker
      if (progress.lastTrackerDate != today) {
        progress.dailyTracker.updateAll((key, value) => false);
        progress.lastTrackerDate = today;
        progress.rebuildTracker();
      }

      await prefs.setString(_lastResetKey, today);
      await saveProgress(progress);
    }
  }

  Future<void> markSectionComplete(
      UserProgress progress, String sectionKey, int zuzimReward) async {
    if (progress.todayCompleted[sectionKey] == true) return;

    progress.todayCompleted[sectionKey] = true;
    progress.zuzim += zuzimReward;
    progress.totalSectionsCompleted++;

    // Update streak if this is the first completion today
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (progress.lastStudyDate == null ||
        DateTime(progress.lastStudyDate!.year, progress.lastStudyDate!.month,
                progress.lastStudyDate!.day)
            .isBefore(todayDate)) {
      progress.streakDays++;
      progress.totalDaysStudied++;
      progress.lastStudyDate = today;

      // Cancel today's streak warning - user studied!
      if (!kIsWeb) {
        NotificationService.cancelStreakWarning();
      }

      // Streak bonuses + notifications
      if (progress.streakDays == 7) {
        progress.zuzim += 50;
        if (!kIsWeb) NotificationService.notifyStreakMilestone(7);
      }
      if (progress.streakDays == 30) {
        progress.zuzim += 200;
        if (!kIsWeb) NotificationService.notifyStreakMilestone(30);
      }
      if (progress.streakDays == 100) {
        progress.zuzim += 500;
        if (!kIsWeb) NotificationService.notifyStreakMilestone(100);
      }
    }

    // All daily sections bonus
    if (progress.allTodayCompleted) {
      progress.zuzim += 20;
      if (!kIsWeb) {
        NotificationService.showMilestoneNotification(
          title: 'חברותא - יום מושלם!',
          body: 'כל הכבוד! סיימת את כל הלימודים להיום ⭐',
        );
      }
    }

    progress.currentLevel = progress.levelTitle;
    await saveProgress(progress);
  }
}
