import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  UserProgress _progress = UserProgress();
  bool _isLoading = true;

  UserProgress get progress => _progress;
  bool get isLoading => _isLoading;

  AppState() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    _progress = await _storage.loadProgress();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeSection(String sectionKey, int zuzimReward) async {
    await _storage.markSectionComplete(_progress, sectionKey, zuzimReward);
    AnalyticsService.sectionCompleted(sectionKey);
    notifyListeners();
  }

  Future<void> buyStreakShield() async {
    if (_progress.zuzim >= ZuzimRewards.streakShieldCost) {
      _progress.zuzim -= ZuzimRewards.streakShieldCost;
      _progress.streakShields++;
      await _storage.saveProgress(_progress);
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String name,
    required String gender,
    required int age,
    required String city,
    String? nusach,
    String? maritalStatus,
    String? iluiNeshama,
    int? dailyGoalSections,
    bool? notificationsEnabled,
    String? notificationTime,
    List<int>? reminderDays,
    bool? omerReminderEnabled,
    String? omerReminderTime,
    double? meatDairyHours,
    bool? candleLightingEnabled,
  }) async {
    final isNewProfile = _progress.userName.isEmpty && name.isNotEmpty;
    _progress.userName = name;
    _progress.gender = gender;
    _progress.age = age;
    _progress.city = city;
    if (isNewProfile) AnalyticsService.profileCreated(gender);
    if (nusach != null) _progress.nusach = nusach;
    if (maritalStatus != null) _progress.maritalStatus = maritalStatus;
    if (iluiNeshama != null) _progress.iluiNeshama = iluiNeshama;
    if (dailyGoalSections != null) {
      _progress.dailyGoalSections = dailyGoalSections;
    }
    if (notificationsEnabled != null) {
      _progress.notificationsEnabled = notificationsEnabled;
    }
    if (notificationTime != null) {
      _progress.notificationTime = notificationTime;
    }
    if (reminderDays != null) {
      _progress.reminderDays = reminderDays;
    }
    if (omerReminderEnabled != null) {
      _progress.omerReminderEnabled = omerReminderEnabled;
    }
    if (omerReminderTime != null) {
      _progress.omerReminderTime = omerReminderTime;
    }
    if (meatDairyHours != null) {
      _progress.meatDairyHours = meatDairyHours;
    }
    if (candleLightingEnabled != null) {
      _progress.candleLightingEnabled = candleLightingEnabled;
    }
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> completeQuiz(int correct, int total, int zuzimEarned) async {
    _progress.totalQuizCorrect += correct;
    _progress.totalQuizAnswered += total;
    _progress.lastQuizDate = DateTime.now().toIso8601String().substring(0, 10);
    _progress.zuzim += zuzimEarned;
    AnalyticsService.quizCompleted(correct, total);
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> purchaseItem(
      String itemId, int price, String category, String? titleName) async {
    if (_progress.zuzim < price) return;
    _progress.zuzim -= price;

    switch (category) {
      case 'avatar':
        if (!_progress.purchasedAvatars.contains(itemId)) {
          _progress.purchasedAvatars.add(itemId);
        }
        _progress.activeAvatar = itemId;
      case 'title':
        if (!_progress.purchasedTitles.contains(itemId)) {
          _progress.purchasedTitles.add(itemId);
        }
        if (titleName != null) _progress.activeTitle = titleName;
      case 'shield':
        if (itemId == 'shield_3') {
          _progress.streakShields += 3;
        } else {
          _progress.streakShields += 1;
        }
    }

    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> setActiveAvatar(String avatarId) async {
    _progress.activeAvatar = avatarId;
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> setActiveTitle(String title) async {
    _progress.activeTitle = title;
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> earnBadge(String badgeId, int zuzimReward) async {
    if (_progress.earnedBadges.contains(badgeId)) return;
    _progress.earnedBadges.add(badgeId);
    _progress.zuzim += zuzimReward;
    AnalyticsService.badgeEarned(badgeId);
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  /// Toggle a daily tracker target and award 5 zuzim if checked
  Future<void> toggleDailyTracker(String target) async {
    final wasChecked = _progress.dailyTracker[target] ?? false;
    _progress.dailyTracker[target] = !wasChecked;
    if (!wasChecked) {
      _progress.zuzim += 5;
      AnalyticsService.trackerChecked(target);
    } else {
      _progress.zuzim = (_progress.zuzim - 5).clamp(0, _progress.zuzim);
    }
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  /// Add a custom daily target
  Future<void> addCustomTarget(String name) async {
    if (name.trim().isEmpty) return;
    if (_progress.customTargets.contains(name)) return;
    _progress.customTargets.add(name);
    _progress.dailyTracker[name] = false;
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  /// Remove a custom daily target
  Future<void> removeCustomTarget(String name) async {
    _progress.customTargets.remove(name);
    _progress.dailyTracker.remove(name);
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  /// Record that user just ate meat - starts the timer
  Future<void> eatMeat() async {
    _progress.lastMeatTime = DateTime.now().toIso8601String();
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  /// Clear meat timer
  Future<void> clearMeatTimer() async {
    _progress.lastMeatTime = null;
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  String getRabbiPhrase() {
    final random = Random();
    final isFemale = _progress.isFemale;

    List<String> phrases;
    if (_progress.streakDays == 0 && _progress.totalDaysStudied > 0) {
      phrases = RabbiPhrases.returnPhrases;
    } else if (_progress.streakDays >= 7) {
      phrases = RabbiPhrases.streakPhrases;
    } else {
      phrases = isFemale
          ? RabbiPhrases.encouragementFemale
          : RabbiPhrases.encouragement;
    }
    return phrases[random.nextInt(phrases.length)];
  }
}
