import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../utils/constants.dart';

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int zuzimReward;
  final bool Function(dynamic progress) isEarned;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.zuzimReward,
    required this.isEarned,
  });
}

final List<Achievement> allAchievements = [
  Achievement(
    id: 'first_step',
    emoji: '🌱',
    title: 'צעד ראשון',
    description: 'השלמת את הלימוד הראשון שלך',
    zuzimReward: 10,
    isEarned: (p) => p.totalSectionsCompleted >= 1,
  ),
  Achievement(
    id: 'streak_7',
    emoji: '🔥',
    title: 'שבוע של תורה',
    description: 'רצף של 7 ימים ברציפות',
    zuzimReward: 50,
    isEarned: (p) => p.streakDays >= 7,
  ),
  Achievement(
    id: 'streak_30',
    emoji: '💎',
    title: 'חודש של התמדה',
    description: 'רצף של 30 ימים ברציפות',
    zuzimReward: 200,
    isEarned: (p) => p.streakDays >= 30,
  ),
  Achievement(
    id: 'streak_100',
    emoji: '👑',
    title: 'מאה ימים!',
    description: 'רצף מדהים של 100 ימים',
    zuzimReward: 500,
    isEarned: (p) => p.streakDays >= 100,
  ),
  Achievement(
    id: 'all_daily',
    emoji: '⭐',
    title: 'יום מושלם',
    description: 'השלמת את כל 5 הלימודים ביום אחד',
    zuzimReward: 30,
    isEarned: (p) => p.allTodayCompleted,
  ),
  Achievement(
    id: 'sections_10',
    emoji: '📚',
    title: 'עשרה פרקים',
    description: 'השלמת 10 פרקי לימוד',
    zuzimReward: 20,
    isEarned: (p) => p.totalSectionsCompleted >= 10,
  ),
  Achievement(
    id: 'sections_50',
    emoji: '📖',
    title: 'חמישים פרקים',
    description: 'השלמת 50 פרקי לימוד',
    zuzimReward: 75,
    isEarned: (p) => p.totalSectionsCompleted >= 50,
  ),
  Achievement(
    id: 'sections_100',
    emoji: '🏆',
    title: 'מאה פרקים!',
    description: 'השלמת 100 פרקי לימוד',
    zuzimReward: 150,
    isEarned: (p) => p.totalSectionsCompleted >= 100,
  ),
  Achievement(
    id: 'quiz_perfect',
    emoji: '🧠',
    title: 'גאון ההלכה',
    description: 'ציון מושלם בחידון - 5 מתוך 5',
    zuzimReward: 50,
    isEarned: (p) => p.totalQuizCorrect >= 5 && p.totalQuizAnswered >= 5,
  ),
  Achievement(
    id: 'quiz_10',
    emoji: '🎓',
    title: 'תלמיד שקדן',
    description: 'ענית על 10 שאלות נכונות בחידונים',
    zuzimReward: 30,
    isEarned: (p) => p.totalQuizCorrect >= 10,
  ),
  Achievement(
    id: 'zuzim_100',
    emoji: '🪙',
    title: 'אוסף ראשון',
    description: 'צברת 100 זוזים',
    zuzimReward: 0,
    isEarned: (p) => p.zuzim >= 100,
  ),
  Achievement(
    id: 'zuzim_500',
    emoji: '💰',
    title: 'עשיר בתורה',
    description: 'צברת 500 זוזים',
    zuzimReward: 0,
    isEarned: (p) => p.zuzim >= 500,
  ),
  Achievement(
    id: 'days_30',
    emoji: '📅',
    title: 'חודש ראשון',
    description: 'למדת 30 ימים בסך הכל',
    zuzimReward: 100,
    isEarned: (p) => p.totalDaysStudied >= 30,
  ),
  Achievement(
    id: 'days_365',
    emoji: '🎉',
    title: 'שנה של תורה!',
    description: 'למדת 365 ימים בסך הכל',
    zuzimReward: 1000,
    isEarned: (p) => p.totalDaysStudied >= 365,
  ),
];

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final progress = appState.progress;
        final earned = allAchievements.where((a) => a.isEarned(progress)).toList();
        final locked = allAchievements.where((a) => !a.isEarned(progress)).toList();

        // Award new badges after the build completes to avoid infinite rebuild
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final achievement in earned) {
            if (!progress.earnedBadges.contains(achievement.id)) {
              appState.earnBadge(achievement.id, achievement.zuzimReward);
            }
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('הישגים ותגים'),
            backgroundColor: AppColors.darkGold,
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.darkGold, AppColors.gold],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${earned.length} / ${allAchievements.length}',
                          style: GoogleFonts.rubik(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'הישגים שהושגו',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Earned badges
                  if (earned.isNotEmpty) ...[
                    Text(
                      'הושגו',
                      style: GoogleFonts.rubik(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...earned.map((a) => _buildBadgeCard(a, true)),
                    const SizedBox(height: 20),
                  ],

                  // Locked badges
                  if (locked.isNotEmpty) ...[
                    Text(
                      'עדיין נעולים',
                      style: GoogleFonts.rubik(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...locked.map((a) => _buildBadgeCard(a, false)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeCard(Achievement achievement, bool earned) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: earned ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: earned
              ? AppColors.gold.withValues(alpha: 0.4)
              : Colors.grey.shade300,
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Emoji
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: earned
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                earned ? achievement.emoji : '🔒',
                style: TextStyle(
                  fontSize: earned ? 28 : 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: earned ? AppColors.darkBrown : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    color: earned ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          if (achievement.zuzimReward > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: earned
                    ? AppColors.success.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                earned ? '✓ +${achievement.zuzimReward}' : '+${achievement.zuzimReward}',
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: earned ? AppColors.success : Colors.grey.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
