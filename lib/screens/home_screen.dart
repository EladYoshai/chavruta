import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app_state.dart';
import '../services/analytics_service.dart';
import '../models/study_section.dart';
import '../models/user_progress.dart';
import '../services/sefaria_service.dart';
import '../utils/constants.dart';
import '../widgets/rabbi_avatar.dart';
import '../widgets/streak_counter.dart';
import '../widgets/zuzim_counter.dart';
import '../widgets/section_card.dart';
import 'study_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'quiz_screen.dart';
import 'achievements_screen.dart';
import 'shop_screen.dart';
import 'siddur_screen.dart';
import 'tehillim_screen.dart';
import 'women_screen.dart';
import 'siyum_yahrzeit_screen.dart';
import 'bookmarks_screen.dart';
import 'daily_tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const _hebrewDayNames = [
    'יום ראשון',
    'יום שני',
    'יום שלישי',
    'יום רביעי',
    'יום חמישי',
    'יום שישי',
    'שבת קודש',
  ];

const omerHebrew = [
    '', // 0
    'היום יום אחד לעומר',
    'היום שני ימים לעומר',
    'היום שלושה ימים לעומר',
    'היום ארבעה ימים לעומר',
    'היום חמישה ימים לעומר',
    'היום שישה ימים לעומר',
    'היום שבעה ימים שהם שבוע אחד לעומר',
    'היום שמונה ימים שהם שבוע אחד ויום אחד לעומר',
    'היום תשעה ימים שהם שבוע אחד ושני ימים לעומר',
    'היום עשרה ימים שהם שבוע אחד ושלושה ימים לעומר',
    'היום אחד עשר יום שהם שבוע אחד וארבעה ימים לעומר',
    'היום שנים עשר יום שהם שבוע אחד וחמישה ימים לעומר',
    'היום שלושה עשר יום שהם שבוע אחד ושישה ימים לעומר',
    'היום ארבעה עשר יום שהם שני שבועות לעומר',
    'היום חמישה עשר יום שהם שני שבועות ויום אחד לעומר',
    'היום שישה עשר יום שהם שני שבועות ושני ימים לעומר',
    'היום שבעה עשר יום שהם שני שבועות ושלושה ימים לעומר',
    'היום שמונה עשר יום שהם שני שבועות וארבעה ימים לעומר',
    'היום תשעה עשר יום שהם שני שבועות וחמישה ימים לעומר',
    'היום עשרים יום שהם שני שבועות ושישה ימים לעומר',
    'היום אחד ועשרים יום שהם שלושה שבועות לעומר',
    'היום שנים ועשרים יום שהם שלושה שבועות ויום אחד לעומר',
    'היום שלושה ועשרים יום שהם שלושה שבועות ושני ימים לעומר',
    'היום ארבעה ועשרים יום שהם שלושה שבועות ושלושה ימים לעומר',
    'היום חמישה ועשרים יום שהם שלושה שבועות וארבעה ימים לעומר',
    'היום שישה ועשרים יום שהם שלושה שבועות וחמישה ימים לעומר',
    'היום שבעה ועשרים יום שהם שלושה שבועות ושישה ימים לעומר',
    'היום שמונה ועשרים יום שהם ארבעה שבועות לעומר',
    'היום תשעה ועשרים יום שהם ארבעה שבועות ויום אחד לעומר',
    'היום שלושים יום שהם ארבעה שבועות ושני ימים לעומר',
    'היום אחד ושלושים יום שהם ארבעה שבועות ושלושה ימים לעומר',
    'היום שנים ושלושים יום שהם ארבעה שבועות וארבעה ימים לעומר',
    'היום שלושה ושלושים יום שהם ארבעה שבועות וחמישה ימים לעומר',
    'היום ארבעה ושלושים יום שהם ארבעה שבועות ושישה ימים לעומר',
    'היום חמישה ושלושים יום שהם חמישה שבועות לעומר',
    'היום שישה ושלושים יום שהם חמישה שבועות ויום אחד לעומר',
    'היום שבעה ושלושים יום שהם חמישה שבועות ושני ימים לעומר',
    'היום שמונה ושלושים יום שהם חמישה שבועות ושלושה ימים לעומר',
    'היום תשעה ושלושים יום שהם חמישה שבועות וארבעה ימים לעומר',
    'היום ארבעים יום שהם חמישה שבועות וחמישה ימים לעומר',
    'היום אחד וארבעים יום שהם חמישה שבועות ושישה ימים לעומר',
    'היום שנים וארבעים יום שהם שישה שבועות לעומר',
    'היום שלושה וארבעים יום שהם שישה שבועות ויום אחד לעומר',
    'היום ארבעה וארבעים יום שהם שישה שבועות ושני ימים לעומר',
    'היום חמישה וארבעים יום שהם שישה שבועות ושלושה ימים לעומר',
    'היום שישה וארבעים יום שהם שישה שבועות וארבעה ימים לעומר',
    'היום שבעה וארבעים יום שהם שישה שבועות וחמישה ימים לעומר',
    'היום שמונה וארבעים יום שהם שישה שבועות ושישה ימים לעומר',
    'היום תשעה וארבעים יום שהם שבעה שבועות לעומר',
  ];

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _parshaHeName = '';
  String _hebrewDate = '';
  String _dayOfWeek = '';
  String _omerText = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCalendarInfo();
    AnalyticsService.screenView('home');
    // Refresh every 30 seconds to update meat/dairy timer countdown
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh UI when user returns to the app (updates meat/dairy timer etc.)
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  Future<void> _loadCalendarInfo() async {
    try {
      final sefaria = SefariaService();
      final calendar = await sefaria.getCalendarInfo();

      final now = DateTime.now();
      final jewishCalendar = JewishCalendar.fromDateTime(now);
      final formatter = HebrewDateFormatter()..hebrewFormat = true;

      // Day of week
      final dayIndex = now.weekday % 7; // Sunday = 0
      final dayName = _hebrewDayNames[dayIndex];

      // Omer counting - after shkia (sunset) show next day's count
      // Use Jerusalem default for sunset calculation
      final geoLocation = GeoLocation.setLocation(
        'Jerusalem', 31.7683, 35.2137, now);
      final zmanimCal = ComplexZmanimCalendar.intGeoLocation(geoLocation);
      final sunset = zmanimCal.getSunset();
      final isAfterShkia = sunset != null && now.isAfter(sunset);

      // If after shkia, use tomorrow's Hebrew date for omer
      final omerDate = isAfterShkia
          ? JewishCalendar.fromDateTime(now.add(const Duration(days: 1)))
          : jewishCalendar;
      final omerMonth = omerDate.getJewishMonth();
      final omerDayOfMonth = omerDate.getJewishDayOfMonth();
      int omerDay = 0;
      if (omerMonth == 1 && omerDayOfMonth >= 16) omerDay = omerDayOfMonth - 15;
      if (omerMonth == 2) omerDay = omerDayOfMonth + 15;
      if (omerMonth == 3 && omerDayOfMonth <= 5) omerDay = omerDayOfMonth + 44;
      final omer = (omerDay > 0 && omerDay <= 49) ? omerHebrew[omerDay] : '';

      if (mounted) {
        setState(() {
          _parshaHeName = calendar.parshaHeName;
          _hebrewDate = formatter.format(jewishCalendar);
          _dayOfWeek = dayName;
          _omerText = omer;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.deepBlue),
            ),
          );
        }

        final progress = appState.progress;

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // App bar with stats
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.deepBlue, AppColors.warmBlue],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        children: [
                          // Top row - app name, settings icon, level
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.appName,
                                  style: GoogleFonts.rubik(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        progress.displayTitle,
                                        style: GoogleFonts.rubik(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SettingsScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.settings,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Greeting with user name
                          if (progress.hasProfile)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                progress.greeting,
                                style: GoogleFonts.rubik(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),

                          // Day of week + Parsha + Hebrew date
                          if (_parshaHeName.isNotEmpty ||
                              _hebrewDate.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                [_dayOfWeek, _parshaHeName, _hebrewDate]
                                    .where((s) => s.isNotEmpty)
                                    .join(' • '),
                                style: GoogleFonts.rubik(
                                  fontSize: 14,
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),

                          // Omer counting
                          if (_omerText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _omerText,
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ZuzimCounter(zuzim: progress.zuzim),
                              const SizedBox(width: 12),
                              StreakCounter(
                                  streakDays: progress.streakDays),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Rabbi / Woman avatar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: RabbiAvatar(
                      phrase: appState.getRabbiPhrase(),
                      streakDays: progress.streakDays,
                      isFemale: progress.isFemale,
                      avatarEmoji: progress.avatarEmoji,
                    ),
                  ),
                ),

                // Calendar button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CalendarScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.15),
                              AppColors.parchment,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: AppColors.darkGold, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'לוח יומי • זמני היום',
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_back_ios,
                                  color: AppColors.darkGold, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Siddur button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SiddurScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1B5E20).withValues(alpha: 0.1),
                              const Color(0xFF2E7D32).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            children: [
                              const Icon(Icons.menu_book,
                                  color: Color(0xFF1B5E20), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'סידור תפילה',
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_back_ios,
                                  color: Color(0xFF1B5E20), size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Tehillim
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TehillimScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1565C0).withValues(alpha: 0.1),
                              const Color(0xFF1565C0).withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            children: [
                              const Icon(Icons.auto_stories,
                                  color: Color(0xFF1565C0), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'תהילים',
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_back_ios,
                                  color: Color(0xFF1565C0), size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Beit Knesset finder
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: GestureDetector(
                      onTap: () => _openBeitKnessetMap(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.deepBlue.withValues(alpha: 0.1),
                              AppColors.warmBlue.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.deepBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            children: [
                              const Text('🏛️', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'בתי כנסת בסביבה',
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ),
                              Icon(Icons.navigation,
                                  color: AppColors.deepBlue, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Mikvah button (married women only)
                if (progress.showMikvah)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: GestureDetector(
                        onTap: () => _openMikvahMap(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                                const Color(0xFF8E24AA).withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                const Text('🏊‍♀️', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'מקוואות בסביבה',
                                    style: GoogleFonts.rubik(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkBrown,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.navigation,
                                    color: Color(0xFF6A1B9A), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Women's section (shown for נקבה)
                if (progress.isFemale)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WomenScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                                const Color(0xFF8E24AA).withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                const Text('👩', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'עולם האישה • תפילות ומצוות',
                                    style: GoogleFonts.rubik(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkBrown,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_back_ios,
                                    color: Color(0xFF6A1B9A), size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Meat/dairy timer
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildMeatDairyWidget(appState, progress),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Action buttons row: Quiz, Achievements, Shop
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context,
                              icon: Icons.quiz,
                              label: 'חידון',
                              color: const Color(0xFF6A1B9A),
                              badge: progress.didQuizToday ? '✓' : null,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const QuizScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              context,
                              icon: Icons.emoji_events,
                              label: 'הישגים',
                              color: AppColors.darkGold,
                              badge: '${progress.earnedBadges.length}',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AchievementsScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              context,
                              icon: Icons.store,
                              label: 'חנות',
                              color: AppColors.success,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ShopScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Daily tracker (מעקב יומי) card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyTrackerScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00838F).withValues(alpha: 0.1),
                              const Color(0xFF00838F).withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF00838F).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            children: [
                              const Text('📋', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'מעקב יומי',
                                      style: GoogleFonts.rubik(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkBrown,
                                      ),
                                    ),
                                    Text(
                                      '${progress.dailyTrackerChecked}/${progress.dailyTrackerTotal} יעדים הושלמו',
                                      style: GoogleFonts.rubik(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Mini progress
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: progress.dailyTrackerTotal > 0
                                          ? progress.dailyTrackerChecked /
                                              progress.dailyTrackerTotal
                                          : 0,
                                      strokeWidth: 4,
                                      backgroundColor: AppColors.parchment,
                                      color: progress.dailyTrackerChecked ==
                                              progress.dailyTrackerTotal
                                          ? AppColors.success
                                          : const Color(0xFF00838F),
                                    ),
                                    Text(
                                      '${progress.dailyTrackerChecked}',
                                      style: GoogleFonts.rubik(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF00838F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Daily progress indicator
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.dailyGoal,
                                style: GoogleFonts.rubik(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkBrown,
                                ),
                              ),
                              Text(
                                '${progress.todayCompletedCount}/${progress.dailyGoalSections}',
                                style: GoogleFonts.rubik(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.deepBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress.todayCompletedCount / progress.dailyGoalSections,
                              backgroundColor: AppColors.parchment,
                              color: progress.dailyGoalMet
                                  ? AppColors.success
                                  : AppColors.deepBlue,
                              minHeight: 10,
                            ),
                          ),
                          if (progress.dailyGoalMet)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '🎉 ${AppStrings.wellDone} ${progress.isFemale ? "סיימת את כל הלימודים היום" : "סיימת את כל הלימודים היום"}',
                                style: GoogleFonts.rubik(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Study sections
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final section = StudySection.dailySections[index];
                      final isCompleted =
                          progress.todayCompleted[section.key] ?? false;

                      return SectionCard(
                        section: section,
                        isCompleted: isCompleted,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudyScreen(section: section),
                            ),
                          );
                        },
                      );
                    },
                    childCount: StudySection.dailySections.length,
                  ),
                ),

                // Tools section: Bookmarks + Yahrzeit
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToolCard(
                              context,
                              emoji: '🔖',
                              label: 'סימניות',
                              color: AppColors.darkGold,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const BookmarksScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildToolCard(
                              context,
                              emoji: '🕯️',
                              label: 'מחשבון יארצייט',
                              color: AppColors.deepBlue,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const YahrzeitScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openBeitKnessetMap() async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/%D7%91%D7%99%D7%AA+%D7%9B%D7%A0%D7%A1%D7%AA/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMikvahMap() async {
    // Try Google Maps first, then Waze, then browser
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/%D7%9E%D7%A7%D7%95%D7%95%D7%94/');
    // "מקווה" URL-encoded

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildMeatDairyWidget(AppState appState, UserProgress progress) {
    final remaining = progress.meatDairyRemaining;

    if (remaining != null) {
      // Timer is active - show countdown
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      final timeStr = hours > 0
          ? '$hours:${minutes.toString().padLeft(2, '0')} שעות'
          : '$minutes דקות';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE65100).withValues(alpha: 0.12),
              const Color(0xFFFF8F00).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE65100).withValues(alpha: 0.3),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Text('🥩', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'נותרו $timeStr עד חלבי',
                      style: GoogleFonts.rubik(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                    Text(
                      'המתנה של ${(progress.meatDairyHours - 5.0167).abs() < 0.01 ? "תחילת שעה שישית" : progress.meatDairyHours == progress.meatDairyHours.roundToDouble() ? "${progress.meatDairyHours.toInt()} שעות" : "${progress.meatDairyHours} שעות"}',
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => appState.clearMeatTimer(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No active timer - show "I ate meat" button
    return GestureDetector(
      onTap: () => appState.eatMeat(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.parchment.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.2),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Text('🥩', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'אכלתי בשרי!',
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
              Icon(Icons.timer, color: AppColors.darkGold, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 26),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.rubik(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.rubik(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
