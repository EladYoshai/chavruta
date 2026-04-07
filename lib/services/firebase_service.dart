import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_progress.dart';

/// Firebase service for cloud sync of user data.
/// Uses anonymous auth + Firestore.
class FirebaseService {
  static bool _initialized = false;
  static String? _userId;

  static const _firebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyCBn-LugNq3tlzHi-W-maIfMylK-lKDBuk',
    authDomain: 'chavroota-6c454.firebaseapp.com',
    projectId: 'chavroota-6c454',
    storageBucket: 'chavroota-6c454.firebasestorage.app',
    messagingSenderId: '547246231621',
    appId: '1:547246231621:web:48edf32de0acac1e90532c',
    measurementId: 'G-JYXXDVTNXW',
  );

  /// Initialize Firebase and sign in anonymously
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(options: _firebaseOptions);
      // Sign in anonymously
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      _userId = auth.currentUser?.uid;
      _initialized = true;
      debugPrint('Firebase initialized. User: $_userId');
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
  }

  /// Get current user ID
  static String? get userId => _userId;

  /// Sync user progress to Firestore
  static Future<void> syncProgress(UserProgress progress) async {
    if (!_initialized || _userId == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).set({
        'userName': progress.userName,
        'gender': progress.gender,
        'age': progress.age,
        'city': progress.city,
        'nusach': progress.nusach,
        'zuzim': progress.zuzim,
        'streakDays': progress.streakDays,
        'totalDaysStudied': progress.totalDaysStudied,
        'totalSectionsCompleted': progress.totalSectionsCompleted,
        'currentLevel': progress.levelTitle,
        'dailyGoalSections': progress.dailyGoalSections,
        'totalQuizCorrect': progress.totalQuizCorrect,
        'totalQuizAnswered': progress.totalQuizAnswered,
        'earnedBadges': progress.earnedBadges,
        'todayCompleted': progress.todayCompleted,
        'lastActive': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'android',
        // Push notification preferences
        'omerReminderPush': progress.omerReminderPush,
        'streakReminderPush': progress.streakReminderPush,
        'meatDairyReminderPush': progress.meatDairyReminderPush,
        'encouragementLevel': progress.encouragementLevel,
        'lastMeatTime': progress.lastMeatTime,
        'meatDairyHours': progress.meatDairyHours,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync failed: $e');
    }
  }
}
