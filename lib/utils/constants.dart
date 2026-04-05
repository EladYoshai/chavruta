import 'package:flutter/material.dart';

class AppColors {
  static const Color gold = Color(0xFFD4A847);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color deepBlue = Color(0xFF1A237E);
  static const Color warmBlue = Color(0xFF283593);
  static const Color cream = Color(0xFFFFF8E7);
  static const Color parchment = Color(0xFFF5E6C8);
  static const Color darkBrown = Color(0xFF3E2723);
  static const Color warmWhite = Color(0xFFFFFDF5);
  static const Color success = Color(0xFF2E7D32);
  static const Color streak = Color(0xFFFF6D00);
}

class AppStrings {
  static const String appName = 'חברותא';
  static const String zuzim = 'זוזים';
  static const String streak = 'רצף';
  static const String days = 'ימים';
  static const String today = 'היום';
  static const String startLearning = 'בוא ללמוד!';
  static const String completed = 'הושלם!';
  static const String wellDone = '!כל הכבוד';
  static const String keepGoing = '!המשך כך';
  static const String blessed = '!אשריך שזכית';
  static const String missedYou = 'התגעגענו אליך...';
  static const String dailyGoal = 'מטרה יומית';

  // Section names
  static const String tehillim = 'תהילים יומי';
  static const String shnayimMikra = 'שניים מקרא ואחד תרגום';
  static const String halacha = 'הלכה יומית';
  static const String mishna = 'משנה יומית';
  static const String emunah = 'תניא יומי';
  static const String gemara = 'דף יומי';
}

class ZuzimRewards {
  static const int tehillimComplete = 10;
  static const int shnayimMikraComplete = 15;
  static const int halachaComplete = 10;
  static const int mishnaComplete = 10;
  static const int emunahComplete = 15;
  static const int gemaraComplete = 25;
  static const int allDailyComplete = 20; // Bonus for completing all
  static const int streakBonus7 = 50;
  static const int streakBonus30 = 200;
  static const int streakBonus100 = 500;
  static const int streakShieldCost = 100;
}

class RabbiPhrases {
  static const String _phrase = 'להצלחת עם ישראל 🇮🇱';

  static const List<String> encouragement = [_phrase];
  static const List<String> encouragementFemale = [_phrase];
  static const List<String> streakPhrases = [_phrase];
  static const List<String> returnPhrases = [_phrase];
}
