import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/user_progress.dart';

/// Firebase service for cloud sync + push notifications.
/// Uses anonymous auth + Firestore + FCM.
class FirebaseService {
  static bool _initialized = false;
  static String? _userId;
  static String? _fcmToken;

  static const _vapidKey =
      'BMqBYnqNLgUGrRj8CMnBYQInR8aNphnr1_i4s0zrJgi8zdadB30ODHPA4PWjzZY4U4C5m4GUUE5Bsl9UpwIOdI0';

  static const _firebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyCBn-LugNq3tlzHi-W-maIfMylK-lKDBuk',
    authDomain: 'chavroota-6c454.firebaseapp.com',
    projectId: 'chavroota-6c454',
    storageBucket: 'chavroota-6c454.firebasestorage.app',
    messagingSenderId: '547246231621',
    appId: '1:547246231621:web:48edf32de0acac1e90532c',
    measurementId: 'G-JYXXDVTNXW',
  );

  /// Initialize Firebase, auth, and push notifications
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

      // Set up push notifications
      await _setupMessaging();
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
  }

  /// Set up FCM for push notifications
  static Future<void> _setupMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _fcmToken = await messaging.getToken(vapidKey: _vapidKey);
        debugPrint('FCM token: $_fcmToken');

        // Save token to Firestore
        if (_fcmToken != null && _userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .set({
            'fcmToken': _fcmToken,
            'notificationsEnabled': true,
          }, SetOptions(merge: true));
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          if (_userId != null) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(_userId)
                .set({'fcmToken': newToken}, SetOptions(merge: true));
          }
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Foreground message: ${message.notification?.title}');
        });
      }
    } catch (e) {
      debugPrint('FCM setup failed: $e');
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
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync failed: $e');
    }
  }
}
