import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum StudySectionType {
  tehillim,
  shnayimMikra,
  halacha,
  mishna,
  emunah,
  gemara,
  rambam,
  shmiratHalashon,
  pirkeiAvot,
  penineiHalacha,
  nachYomi,
}

class StudySection {
  final StudySectionType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int zuzimReward;
  final String key;

  const StudySection({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.zuzimReward,
    required this.key,
  });

  static List<StudySection> get dailySections => [
        StudySection(
          type: StudySectionType.tehillim,
          title: AppStrings.tehillim,
          subtitle: 'פרק תהילים היומי',
          icon: Icons.menu_book,
          color: AppColors.deepBlue,
          zuzimReward: ZuzimRewards.tehillimComplete,
          key: 'tehillim',
        ),
        StudySection(
          type: StudySectionType.shnayimMikra,
          title: AppStrings.shnayimMikra,
          subtitle: 'פרשת השבוע',
          icon: Icons.auto_stories,
          color: AppColors.darkGold,
          zuzimReward: ZuzimRewards.shnayimMikraComplete,
          key: 'shnayim_mikra',
        ),
        StudySection(
          type: StudySectionType.halacha,
          title: AppStrings.halacha,
          subtitle: 'משנה ברורה',
          icon: Icons.gavel,
          color: AppColors.success,
          zuzimReward: ZuzimRewards.halachaComplete,
          key: 'halacha',
        ),
        StudySection(
          type: StudySectionType.mishna,
          title: AppStrings.mishna,
          subtitle: 'משנה יומית עם ברטנורא',
          icon: Icons.library_books,
          color: const Color(0xFF00838F),
          zuzimReward: ZuzimRewards.mishnaComplete,
          key: 'mishna',
        ),
        StudySection(
          type: StudySectionType.emunah,
          title: AppStrings.emunah,
          subtitle: 'ספר התניא - שיעור יומי',
          icon: Icons.auto_awesome,
          color: const Color(0xFF6A1B9A),
          zuzimReward: ZuzimRewards.emunahComplete,
          key: 'emunah',
        ),
        StudySection(
          type: StudySectionType.gemara,
          title: AppStrings.gemara,
          subtitle: 'הדף היומי עם פרשנים וסיכום',
          icon: Icons.school,
          color: const Color(0xFFC62828),
          zuzimReward: ZuzimRewards.gemaraComplete,
          key: 'gemara',
        ),
        StudySection(
          type: StudySectionType.rambam,
          title: 'רמב"ם יומי',
          subtitle: 'פרק יומי ברמב"ם',
          icon: Icons.account_balance,
          color: const Color(0xFF1565C0),
          zuzimReward: 10,
          key: 'rambam',
        ),
        StudySection(
          type: StudySectionType.shmiratHalashon,
          title: 'שמירת הלשון',
          subtitle: 'חפץ חיים - הלכות לשון הרע',
          icon: Icons.record_voice_over,
          color: const Color(0xFF00695C),
          zuzimReward: 10,
          key: 'shmirat_halashon',
        ),
        StudySection(
          type: StudySectionType.pirkeiAvot,
          title: 'פרקי אבות',
          subtitle: 'פרק שבועי במסכת אבות',
          icon: Icons.groups,
          color: const Color(0xFF4E342E),
          zuzimReward: 10,
          key: 'pirkei_avot',
        ),
        StudySection(
          type: StudySectionType.nachYomi,
          title: 'נ"ך יומי',
          subtitle: 'שני פרקים ביום עם רש"י ומצודות',
          icon: Icons.history_edu,
          color: const Color(0xFF5D4037),
          zuzimReward: 10,
          key: 'nach_yomi',
        ),
        StudySection(
          type: StudySectionType.penineiHalacha,
          title: 'פניני הלכה',
          subtitle: 'הרב אליעזר מלמד - הלכה יומית',
          icon: Icons.diamond,
          color: const Color(0xFF7B1FA2),
          zuzimReward: 10,
          key: 'peninei_halacha',
        ),
      ];
}
