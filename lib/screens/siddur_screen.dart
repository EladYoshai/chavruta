import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../data/siddur_structure.dart';
import '../services/jewish_calendar_service.dart';
import '../services/prayer_decision_engine.dart';
import '../services/sefaria_service.dart';
import '../utils/constants.dart';
import '../widgets/torah_text_viewer.dart';

/// Redesigned Siddur with context-aware categories and beautiful typography
class SiddurScreen extends StatefulWidget {
  const SiddurScreen({super.key});

  @override
  State<SiddurScreen> createState() => _SiddurScreenState();
}

class _SiddurScreenState extends State<SiddurScreen> {
  List<PrayerCategory> _mainCategories = [];
  SiddurDayInfo? _dayInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final nusach = context.read<AppState>().progress.nusach;
    final results = await Future.wait([
      SiddurStructure.loadCategories(nusach),
      JewishCalendarService.getDayInfo(),
    ]);
    if (mounted) {
      setState(() {
        _mainCategories = results[0] as List<PrayerCategory>;
        _dayInfo = results[1] as SiddurDayInfo;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nusach = context.watch<AppState>().progress.nusach;
    final nusachName = _getNusachName(nusach);
    final dayInfo = _dayInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('סידור תפילה'),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'נוסח $nusachName',
                  style: GoogleFonts.rubik(fontSize: 13, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  SizedBox(height: 16),
                  Text('...טוען סידור'),
                ],
              ),
            )
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Smart day info banner with all modifications
                  _buildDayBanner(dayInfo, nusach),
                  const SizedBox(height: 16),

                  // Main tefilot from Sefaria index (these work via tree-walking)
                  _buildSectionHeader('תפילות'),
                  ..._buildMainTefilot(context, dayInfo),

                  // Musaf - show on days that need it
                  if (dayInfo != null && (dayInfo.isShabbat || dayInfo.isRoshChodesh ||
                      dayInfo.isCholHamoed || dayInfo.isYomTov))
                    _buildSimpleCard(context, '📜', 'מוסף',
                        dayInfo.isShabbatRoshChodesh ? 'מוסף שבת ראש חודש (אתה יצרת)'
                        : dayInfo.isCholHamoed ? 'מוסף לחול המועד'
                        : dayInfo.isShabbat ? 'מוסף שבת'
                        : 'מוסף',
                        _getMusafMainRef(nusach, dayInfo)),

                  // Omer - only during season
                  if (dayInfo != null && dayInfo.isOmerSeason) ...[
                    _buildOmerCard(context, nusach, dayInfo),
                  ],

                  const SizedBox(height: 16),
                  _buildSectionHeader('ברכות'),
                  _buildSimpleCard(context, '🍞', 'ברכת המזון',
                      'ברכה אחרי סעודה עם לחם', _getBirkatHamazonRef(nusach)),
                  _buildSimpleCard(context, '🍎', 'ברכה מעין שלוש',
                      'על המחיה / על הגפן / על העץ', _getMeeinShaloshRef(nusach)),
                  _buildSimpleCard(context, '🚿', 'אשר יצר',
                      'ברכת אשר יצר', _getAsherYatzarRef(nusach)),

                  const SizedBox(height: 16),
                  _buildSectionHeader('תפילות מיוחדות'),
                  _buildSimpleCard(context, '🛏️', 'קריאת שמע על המיטה',
                      'לפני השינה', _getBedtimeShemaRef(nusach)),
                  _buildSimpleCard(context, '🌙', 'קידוש לבנה',
                      'ברכת הלבנה', _getKiddushLevanaRef(nusach)),
                  _buildSimpleCard(context, '🚗', 'תפילת הדרך',
                      'לפני נסיעה', _getTefilatHaderechRef(nusach)),

                  const SizedBox(height: 16),
                  _buildSectionHeader('אירועים'),
                  _buildSimpleCard(context, '👶', 'ברית מילה',
                      'סדר ברית מילה', _getBritMilaRef(nusach)),
                  _buildSimpleCard(context, '💍', 'שבע ברכות',
                      'שבע ברכות לחתן וכלה', _getShevaBrachotRef(nusach)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const _ChanukatHabayitScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            const Text('🏠', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('חנוכת הבית', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
                                Text('נוסח לחנוכת בית חדש', style: GoogleFonts.rubik(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            )),
                            const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF1B5E20)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildSectionHeader('לעילוי נשמה'),
                  _buildAzkaraCard(context),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const _MishnayotAzkaraScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            const Text('📚', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('משניות לעילוי נשמה', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
                                Text('משניות לפי אותיות שם הנפטר/ת', style: GoogleFonts.rubik(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            )),
                            const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF1B5E20)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  /// Build main tefilot cards from the loaded categories
  List<Widget> _buildMainTefilot(BuildContext context, SiddurDayInfo? dayInfo) {
    final isShabbat = dayInfo?.isShabbat ?? false;
    final showOrder = isShabbat
        ? ['שחרית שבת', 'מוסף שבת', 'מנחה שבת', 'קבלת שבת', 'הבדלה']
        : ['שחרית', 'מנחה', 'ערבית'];

    final widgets = <Widget>[];
    for (final name in showOrder) {
      final cat = _mainCategories.where((c) => c.name == name).firstOrNull;
      if (cat != null) {
        widgets.add(_buildCategoryCard(context, cat));
      }
    }

    // If no specific matches, show all main categories
    if (widgets.isEmpty) {
      for (final cat in _mainCategories) {
        if (['שחרית', 'מנחה', 'ערבית', 'קבלת שבת', 'שחרית שבת',
             'מוסף שבת', 'מנחה שבת'].contains(cat.name)) {
          widgets.add(_buildCategoryCard(context, cat));
        }
      }
    }
    return widgets;
  }

  Widget _buildCategoryCard(BuildContext context, PrayerCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _PrayerListScreen(category: category),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: GoogleFonts.rubik(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
              const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF1B5E20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleCard(BuildContext context, String emoji, String title,
      String subtitle, String ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _SiddurTextScreen(title: title, ref: ref),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.rubik(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown)),
                    Text(subtitle,
                        style: GoogleFonts.rubik(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF1B5E20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOmerCard(BuildContext context, String nusach, SiddurDayInfo dayInfo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _OmerTodayScreen(omerDay: dayInfo.omerDay),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Text('🌾', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ספירת העומר',
                        style: GoogleFonts.rubik(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown)),
                    if (dayInfo.omerDay > 0)
                      Text('היום: יום ${dayInfo.omerDay} לעומר',
                          style: GoogleFonts.rubik(
                              fontSize: 13,
                              color: const Color(0xFF1B5E20),
                              fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF1B5E20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAzkaraCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const _AzkaraScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              const Text('🕯️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('נוסח לאזכרה',
                        style: GoogleFonts.rubik(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown)),
                    Text('תהילים לפי אותיות שם הנפטר/ת',
                        style: GoogleFonts.rubik(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF1B5E20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayBanner(SiddurDayInfo? dayInfo, String nusach) {
    if (dayInfo == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('טוען נתוני יום...', style: GoogleFonts.rubik(fontSize: 14, color: Colors.grey)),
      );
    }

    final mods = dayInfo.getActiveModifications(nusach);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day title
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayInfo.dayDescription,
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      dayInfo.hebrewDate,
                      style: GoogleFonts.rubik(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (mods.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Show per-tefila breakdown
            for (final tefila in [TefilaType.shacharit, TefilaType.mincha, TefilaType.arvit])
              _buildTefilaFlowCard(dayInfo, tefila, nusach),
          ],
        ],
      ),
    );
  }

  Widget _buildTefilaFlowCard(SiddurDayInfo dayInfo, TefilaType tefila, String nusach) {
    final minhag = MinhagProfile.fromOverrides(
      context.read<AppState>().progress.minhagOverrides);
    final flow = PrayerDecisionEngine.getFlow(dayInfo, tefila, nusach, minhag);
    final summary = flow.getSummary();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tefila.hebrewName,
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          ...summary.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              item,
              style: GoogleFonts.rubik(fontSize: 12, color: AppColors.darkBrown, height: 1.3),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown)),
    );
  }

  // ==========================================
  // Refs for simple prayers
  // ==========================================

  String _getNusachName(String nusach) {
    switch (nusach) {
      case 'ashkenaz': return 'אשכנז';
      case 'sefard': return 'ספרד';
      case 'edot_hamizrach': return 'עדות המזרח';
      default: return 'אשכנז';
    }
  }

  String _getKiddushLevanaRef(String nusach) => switch (nusach) {
    'edot_hamizrach' => 'Siddur_Sefard,_Kiddush_Levanah', // fallback
    _ => 'Siddur_Sefard,_Kiddush_Levanah',
  };

  String _getBedtimeShemaRef(String nusach) => switch (nusach) {
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Bedtime_Shema',
    _ => 'Siddur_Sefard,_Bedtime_Shema',
  };

  String _getBirkatHamazonRef(String nusach) => switch (nusach) {
    'ashkenaz' => 'Siddur_Ashkenaz,_Berachot,_Birkat_HaMazon',
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Post_Meal_Blessing',
    _ => 'Siddur_Sefard,_Birchat_HaMazon,_Birchat_HaMazon',
  };

  // Edot HaMizrach has a clean standalone me'ein shalosh ref; use for all nusachot
  String _getMeeinShaloshRef(String nusach) =>
    'Siddur_Edot_HaMizrach,_Al_Hamihya';

  // Ashkenaz has a clean standalone Asher Yatzar ref; others don't, so use it for all
  String _getAsherYatzarRef(String nusach) =>
    'Siddur_Ashkenaz,_Weekday,_Shacharit,_Preparatory_Prayers,_Asher_Yatzar';

  String _getShevaBrachotRef(String nusach) => switch (nusach) {
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Assorted_Blessings_and_Prayers,_Sheva_Berachot',
    _ => 'Siddur_Edot_HaMizrach,_Assorted_Blessings_and_Prayers,_Sheva_Berachot', // fallback
  };

  String _getBritMilaRef(String nusach) => switch (nusach) {
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Assorted_Blessings_and_Prayers,_Brit_Mila',
    _ => 'Siddur_Sefard,_Various_Blessings,_Circumcision',
  };

  String _getMusafMainRef(String nusach, SiddurDayInfo? dayInfo) {
    return switch (nusach) {
      'ashkenaz' => 'Siddur_Ashkenaz,_Shabbat,_Musaf_LeShabbat',
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Shabbat_Mussaf',
      _ => 'Siddur_Sefard,_Musaf',
    };
  }

  String _getTefilatHaderechRef(String nusach) => switch (nusach) {
    'ashkenaz' => 'Siddur_Ashkenaz,_Berachot,_Tefillat_HaDerech',
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Assorted_Blessings_and_Prayers,_Traveler%27s_Prayer',
    _ => 'Siddur_Sefard,_Blessings,_Traveler%27s_Prayer',
  };
}

// ==========================================
// Prayer list screen (for categories with sub-prayers)
// ==========================================

class _PrayerListScreen extends StatefulWidget {
  final PrayerCategory category;
  const _PrayerListScreen({required this.category});

  @override
  State<_PrayerListScreen> createState() => _PrayerListScreenState();
}

class _PrayerListScreenState extends State<_PrayerListScreen> {
  final SefariaService _sefaria = SefariaService();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _tabScrollController = ScrollController();

  // Modified prayer list (after decision tree filtering)
  List<PrayerItem> _filteredItems = [];
  int _currentMonth = 0;
  int _currentDay = 0;
  int _currentWeekday = 0;
  bool _isLeapYear = false;
  List<List<String>> _prayerTexts = [];
  List<GlobalKey> _sectionKeys = [];
  int _activeIndex = 0;
  bool _isLoading = true;
  bool _programmaticScroll = false;

  @override
  void initState() {
    super.initState();
    _applyDecisionTree();
    _sectionKeys = List.generate(_filteredItems.length, (_) => GlobalKey());
    _scrollController.addListener(_onScroll);
    _loadAll();
  }

  /// Apply decision tree: filter, add, and reorder prayers for today
  void _applyDecisionTree() {
    final nusach = context.read<AppState>().progress.nusach;

    // Get day info synchronously using cached data or defaults
    final now = DateTime.now();
    final jewishCal = JewishCalendar.fromDateTime(now);
    final month = jewishCal.getJewishMonth();
    final day = jewishCal.getJewishDayOfMonth();

    _currentMonth = month;
    _currentDay = day;
    _currentWeekday = now.weekday;
    _isLeapYear = jewishCal.isJewishLeapYear();

    // Determine tefila type from category name
    final tefilaType = _getTefilaType(widget.category.name);

    // Start with original items
    final items = List<PrayerItem>.from(widget.category.items);

    // === Filter: Remove tachanun on days without ===
    final sayTachanun = _shouldSayTachanun(month, day, now.weekday, tefilaType, jewishCal.isJewishLeapYear());
    if (!sayTachanun) {
      items.removeWhere((p) => _isTachanunPrayer(p.name));
    }

    // === Filter: Remove lamenatzeach when no tachanun ===
    if (!sayTachanun) {
      items.removeWhere((p) => p.name.contains('למנצח'));
    }

    // === Add: Hallel (after Amidah in shacharit) ===
    if (tefilaType == TefilaType.shacharit) {
      final hallelType = _getHallelForToday(month, day);
      if (hallelType != HallelType.none) {
        // Find amidah index and insert hallel after it
        final amidahIdx = items.indexWhere((p) =>
            p.name.contains('עמידה') || p.name.contains('שמונה עשרה') || p.name.contains('אמידה'));
        final hallelName = hallelType == HallelType.full ? 'הלל שלם' : 'חצי הלל';
        final hallelItem = PrayerItem(name: hallelName, ref: _getHallelRef(nusach));
        if (amidahIdx >= 0) {
          items.insert(amidahIdx + 1, hallelItem);
        } else {
          items.add(hallelItem);
        }
      }
    }

    // === Add: Musaf (for Shabbat, R"C, Chol HaMoed, Yom Tov) ===
    if (tefilaType == TefilaType.shacharit && _needsMusaf(month, day, now.weekday)) {
      final musafItem = PrayerItem(name: 'מוסף', ref: _getMusafRef(nusach, month, day, now.weekday));
      items.add(musafItem);
    }

    _filteredItems = items;
  }

  TefilaType _getTefilaType(String categoryName) {
    if (categoryName.contains('שחרית')) return TefilaType.shacharit;
    if (categoryName.contains('מנחה')) return TefilaType.mincha;
    if (categoryName.contains('ערבית') || categoryName.contains('קבלת')) return TefilaType.arvit;
    if (categoryName.contains('מוסף')) return TefilaType.musaf;
    return TefilaType.shacharit;
  }

  bool _isTachanunPrayer(String name) {
    final lower = name.toLowerCase();
    return name.contains('תחנון') || name.contains('נפילת אפים') ||
        name.contains('וידוי') || lower.contains('tachanun');
  }

  bool _shouldSayTachanun(int month, int day, int dayOfWeek, TefilaType tefila, bool isLeapYear) {
    if (tefila == TefilaType.arvit) return false;
    if (dayOfWeek == 6) return false; // Shabbat
    if (month == 7) return false; // All Tishrei
    if (month == 1) return false; // All Nisan
    if (month == 2 && day == 18) return false; // Lag BaOmer
    if (month == 3 && day >= 1 && day <= 8) return false; // Sivan
    if (month == 5 && day == 15) return false; // Tu B'Av
    if (month == 6 && day == 29) return false; // Erev RH
    if (month == 9 && day >= 25) return false; // Chanukah
    if (month == 10 && day <= 3) return false;
    if (month == 11 && day == 15) return false; // Tu BiShvat
    if (month == 12 && (day == 14 || day == 15)) return false; // Purim
    if (isLeapYear && month == 13 && (day == 14 || day == 15)) return false;
    if (month == 2 && day == 14) return false; // Pesach Sheni
    if (day == 1 || day == 30) return false; // Rosh Chodesh
    return true;
  }

  HallelType _getHallelForToday(int month, int day) {
    if (month == 7 && day >= 15 && day <= 22) return HallelType.full;
    if (month == 9 && day >= 25) return HallelType.full;
    if (month == 10 && day <= 3) return HallelType.full;
    if (month == 3 && day == 6) return HallelType.full;
    if (month == 1 && day == 15) return HallelType.full;
    if (month == 1 && day >= 16 && day <= 21) return HallelType.half;
    if (day == 1 || day == 30) return HallelType.half;
    return HallelType.none;
  }

  String _getHallelRef(String nusach) {
    // Hallel is in Shacharit section - use Sefaria refs
    return switch (nusach) {
      'ashkenaz' => 'Siddur_Ashkenaz,_Weekday,_Shacharit,_Hallel',
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Weekday_Shacharit,_Hallel',
      _ => 'Siddur_Sefard,_Weekday_Shacharit,_Hallel',
    };
  }

  bool _needsMusaf(int month, int day, int dayOfWeek) {
    if (dayOfWeek == 6) return true; // Shabbat
    if (day == 1 || day == 30) return true; // Rosh Chodesh
    if (month == 7 && day >= 15 && day <= 22) return true; // Sukkot
    if (month == 1 && day >= 15 && day <= 21) return true; // Pesach
    if (month == 3 && day == 6) return true; // Shavuot
    return false;
  }

  String _getMusafRef(String nusach, int month, int day, int dayOfWeek) {
    // Try to load musaf from Sefaria
    if (dayOfWeek == 6) {
      return switch (nusach) {
        'ashkenaz' => 'Siddur_Ashkenaz,_Shabbat,_Musaf_LeShabbat',
        'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Shabbat_Mussaf',
        _ => 'Siddur_Sefard,_Musaf',
      };
    }
    // Default musaf
    return switch (nusach) {
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Shabbat_Mussaf',
      _ => 'Siddur_Sefard,_Musaf',
    };
  }

  bool _isMashivSeason(int month, int day) {
    if (month == 7 && day >= 22) return true;
    if (month >= 8 && month <= 13) return true;
    if (month == 1 && day < 15) return true;
    return false;
  }

  /// Strip all Hebrew nikud/diacritics for comparison
  String _stripNikud(String text) {
    // Remove Unicode nikud range (0x0591-0x05C7)
    return text.replaceAll(RegExp(r'[\u0591-\u05C7]'), '');
  }

  /// Apply seasonal text modifications to prayer segments
  List<String> _applyTextModifications(List<String> segments, String prayerName,
      bool isMashiv, bool isYaaleh, String yaalehOccasion, String nusach) {
    final result = <String>[];

    for (final segment in segments) {
      var modified = segment;
      final stripped = _stripNikud(modified);

      // === Handle Sefaria's dual-season format ===
      // Sefaria shows BOTH options with <small>בחורף:</small> and <small>בקיץ:</small>
      if (stripped.contains('בחורף') || stripped.contains('בקיץ')) {
        if (isMashiv) {
          // Winter: remove summer option (מוריד הטל line with בקיץ)
          modified = modified.replaceAll(RegExp(r'<small>בקיץ:?</small>[^<]*'), '');
          modified = modified.replaceAll(RegExp(r'בקיץ:?\s*מוריד הטל'), '');
        } else {
          // Summer: remove winter option (משיב הרוח line with בחורף)
          modified = modified.replaceAll(RegExp(r'<small>בחורף:?</small>[^<]*'), '');
          modified = modified.replaceAll(RegExp(r'בחורף:?\s*משיב הרוח ומוריד הגשם:?'), '');
        }
        // Also remove the season labels themselves
        modified = modified.replaceAll(RegExp(r'<small>בקיץ:?</small>\s*'), '');
        modified = modified.replaceAll(RegExp(r'<small>בחורף:?</small>\s*'), '');
      }

      // === Direct text swap (for texts without season labels) ===
      if (!isMashiv && stripped.contains('משיב הרוח ומוריד הגשם')) {
        if (nusach == 'ashkenaz') {
          // Ashkenaz: remove entirely
          modified = modified.replaceAll(RegExp(r'מ[ַּ]*שִּׁ?יב\s+ה[ָ]*ר[ֽ]*וּ?ח[ַ]*\s+וּ?מוֹ?רִיד\s+ה[ַ]*גּ[ֶּֽ]*שׁ?[ֶ]*ם:?'), '');
        } else {
          // Sefard/Edot HaMizrach: swap to morid hatal
          modified = modified.replaceAll(RegExp(r'מ[ַּ]*שִּׁ?יב\s+ה[ָ]*ר[ֽ]*וּ?ח[ַ]*\s+וּ?מוֹ?רִיד\s+ה[ַ]*גּ[ֶּֽ]*שׁ?[ֶ]*ם:?'), 'מוֹרִיד הַטָּל');
        }
      }

      // === Remove viduy/tachanun sections from text ===
      // Sefaria embeds these as text segments - remove segments containing viduy markers
      if (!_shouldSayTachanun(_currentMonth, _currentDay, _currentWeekday,
          _getTefilaType(widget.category.name), _isLeapYear)) {
        if (stripped.contains('וידוי') || stripped.contains('נפילת אפים') ||
            stripped.contains('אבינו מלכנו') || stripped.contains('סלח לנו') ||
            stripped.contains('ואנחנו לא נדע')) {
          // Skip this segment entirely (it's tachanun-related)
          continue;
        }
      }

      if (modified.trim().isNotEmpty) {
        result.add(modified);
      }
    }

    // === Insert יעלה ויבוא after רצה (if needed) ===
    if (isYaaleh && yaalehOccasion.isNotEmpty) {
      final yaalehText =
          'אֱלֹהֵינוּ וֵאלֹהֵי אֲבוֹתֵינוּ, יַעֲלֶה וְיָבֹא וְיַגִּיעַ, וְיֵרָאֶה וְיֵרָצֶה וְיִשָּׁמַע, '
          'וְיִפָּקֵד וְיִזָּכֵר זִכְרוֹנֵנוּ וּפִקְדוֹנֵנוּ, וְזִכְרוֹן אֲבוֹתֵינוּ, '
          'וְזִכְרוֹן מָשִׁיחַ בֶּן דָּוִד עַבְדֶּךָ, וְזִכְרוֹן יְרוּשָׁלַיִם עִיר קָדְשֶׁךָ, '
          'וְזִכְרוֹן כָּל עַמְּךָ בֵּית יִשְׂרָאֵל לְפָנֶיךָ, לִפְלֵטָה לְטוֹבָה, '
          'לְחֵן וּלְחֶסֶד וּלְרַחֲמִים, לְחַיִּים וּלְשָׁלוֹם, $yaalehOccasion. '
          'זָכְרֵנוּ ה\' אֱלֹהֵינוּ בּוֹ לְטוֹבָה, וּפָקְדֵנוּ בוֹ לִבְרָכָה, '
          'וְהוֹשִׁיעֵנוּ בוֹ לְחַיִּים טוֹבִים. וּבִדְבַר יְשׁוּעָה וְרַחֲמִים חוּס וְחָנֵּנוּ '
          'וְרַחֵם עָלֵינוּ וְהוֹשִׁיעֵנוּ, כִּי אֵלֶיךָ עֵינֵינוּ, כִּי אֵל מֶלֶךְ חַנּוּן וְרַחוּם אָתָּה.';

      // Find a segment containing רצה or עבודה and insert after it
      bool inserted = false;
      for (int i = 0; i < result.length; i++) {
        if ((result[i].contains('רְצֵה') || result[i].contains('רצה') ||
            result[i].contains('וְתֶחֱזֶינָה') || result[i].contains('ותחזינה')) && !inserted) {
          result.insert(i + 1, '【יעלה ויבוא - $yaalehOccasion】\n$yaalehText');
          inserted = true;
          break;
        }
      }
      // If not found in text, add as separate block at end
      if (!inserted) {
        result.add('【יעלה ויבוא - $yaalehOccasion】\n$yaalehText');
      }
    }

    return result;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final nusach = context.read<AppState>().progress.nusach;
    final now = DateTime.now();
    final jewishCal = JewishCalendar.fromDateTime(now);
    final month = jewishCal.getJewishMonth();
    final day = jewishCal.getJewishDayOfMonth();

    // Determine seasonal text swaps
    final isMashivHaruach = _isMashivSeason(month, day);
    final isYaalehVyavo = (day == 1 || day == 30) || // Rosh Chodesh
        (month == 1 && day >= 16 && day <= 21) || // Chol HaMoed Pesach
        (month == 7 && day >= 16 && day <= 21); // Chol HaMoed Sukkot

    // Ya'aleh v'Yavo occasion
    String yaalehOccasion = '';
    if (day == 1 || day == 30) yaalehOccasion = 'בְּיוֹם רֹאשׁ הַחֹדֶשׁ הַזֶּה';
    if (month == 1 && day >= 15 && day <= 22) yaalehOccasion = 'בְּיוֹם חַג הַמַּצּוֹת הַזֶּה';
    if (month == 7 && day >= 15 && day <= 22) yaalehOccasion = 'בְּיוֹם חַג הַסֻּכּוֹת הַזֶּה';
    if (month == 3 && (day == 6 || day == 7)) yaalehOccasion = 'בְּיוֹם חַג הַשָּׁבֻעוֹת הַזֶּה';

    final texts = <List<String>>[];
    for (final prayer in _filteredItems) {
      try {
        final data = await _sefaria.getText(prayer.ref);
        List<String> segments = [];
        if (data.containsKey('error') && data['error'].toString().contains('complex')) {
          segments = await _fetchComplex(prayer.ref);
        } else {
          final versions = data['versions'] as List?;
          if (versions != null) {
            for (final version in versions) {
              if (version['actualLanguage'] == 'he' && version['text'] != null) {
                final text = version['text'];
                if (text is List) {
                  segments = _flatten(text);
                } else if (text is String) {
                  segments = [text];
                }
                break;
              }
            }
          }
        }

        // === Text modifications based on decision tree ===
        segments = _applyTextModifications(segments, prayer.name,
            isMashivHaruach, isYaalehVyavo, yaalehOccasion, nusach);

        texts.add(segments);
      } catch (_) {
        texts.add([]);
      }
    }

    if (mounted) setState(() { _prayerTexts = texts; _isLoading = false; });
  }

  Future<List<String>> _fetchComplex(String ref) async {
    final parts = [
      'Patriarchs', 'Divine_Might', 'Holiness_of_God', 'Knowledge',
      'Repentance', 'Forgiveness', 'Redemption', 'Healing', 'Prosperity',
      'Gathering_the_Exiles', 'Justice', 'Against_Enemies', 'The_Righteous',
      'Rebuilding_Jerusalem', 'Kingdom_of_David', 'Response_to_Prayer',
      'Temple_Service', 'Thanksgiving', 'Peace', 'Concluding_Passage',
      'Sanctity_of_the_Day', 'Birkat_Kohanim', 'Kedushah',
    ];
    final result = <String>[];
    for (final part in parts) {
      try {
        final data = await _sefaria.getText('$ref,_$part');
        if (!data.containsKey('error')) {
          final versions = data['versions'] as List?;
          if (versions != null) {
            for (final version in versions) {
              if (version['actualLanguage'] == 'he' && version['text'] != null) {
                final text = version['text'];
                if (text is List) {
                  result.addAll(_flatten(text));
                } else if (text is String && text.isNotEmpty) {
                  result.add(text);
                }
                break;
              }
            }
          }
        }
      } catch (_) {}
    }
    return result;
  }

  List<String> _flatten(List<dynamic> list) {
    final result = <String>[];
    for (final item in list) {
      if (item is String && item.isNotEmpty) result.add(item);
      if (item is List) result.addAll(_flatten(item));
    }
    return result;
  }

  void _onScroll() {
    if (_programmaticScroll) return;
    // Find which section is currently visible
    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final key = _sectionKeys[i];
      final ctx = key.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) {
          final pos = box.localToGlobal(Offset.zero);
          if (pos.dy <= 150) { // Header area height
            if (_activeIndex != i) {
              setState(() => _activeIndex = i);
              _scrollTabToIndex(i);
            }
            return;
          }
        }
      }
    }
  }

  void _scrollTabToIndex(int index) {
    // Approximate: each tab ~100px wide
    final offset = (index * 110.0 - 50).clamp(0.0, _tabScrollController.position.maxScrollExtent);
    _tabScrollController.animateTo(offset,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    final ctx = key.currentContext;
    if (ctx == null) return;

    _programmaticScroll = true;
    setState(() => _activeIndex = index);
    _scrollTabToIndex(index);

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.0, // scroll to top of viewport
    ).then((_) {
      _programmaticScroll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  SizedBox(height: 16),
                  Text('...טוען תפילות'),
                ],
              ),
            )
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  // Top slider - prayer titles
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.05),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      controller: _tabScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final isActive = index == _activeIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: GestureDetector(
                            onTap: () => _scrollToSection(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF1B5E20)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF1B5E20).withValues(
                                      alpha: isActive ? 1 : 0.3),
                                ),
                              ),
                              child: Text(
                                _filteredItems[index].name,
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  color: isActive ? Colors.white : const Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Continuous prayer text - all items built eagerly for slider navigation
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: List.generate(_filteredItems.length, (index) {
                        final prayer = _filteredItems[index];
                        final texts = index < _prayerTexts.length
                            ? _prayerTexts[index]
                            : <String>[];

                        return Container(
                          key: _sectionKeys[index],
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section title
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF1B5E20).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  prayer.name,
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Prayer text
                              if (texts.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('לא ניתן לטעון',
                                      style: GoogleFonts.rubik(
                                          color: Colors.grey, fontSize: 14)),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: texts.map((s) {
                                      final clean = TorahTextViewer.stripHtml(s);
                                      if (clean.isEmpty) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Text(
                                          clean,
                                          style: const TextStyle(
                                            fontFamily: 'Frank Ruhl Libre',
                                            fontSize: 22,
                                            height: 2.0,
                                            color: Color(0xFF2C1810),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        );
                      }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ==========================================
// Siddur text screen - beautiful large font
// ==========================================

// ==========================================
// Omer today - show only today's count
// ==========================================

class _OmerTodayScreen extends StatelessWidget {
  final int omerDay;
  const _OmerTodayScreen({required this.omerDay});

  static const _omerHebrew = [
    '', 'יום אחד', 'שני ימים', 'שלושה ימים', 'ארבעה ימים',
    'חמישה ימים', 'שישה ימים', 'שבעה ימים שהם שבוע אחד',
    'שמונה ימים שהם שבוע אחד ויום אחד',
    'תשעה ימים שהם שבוע אחד ושני ימים',
    'עשרה ימים שהם שבוע אחד ושלושה ימים',
    'אחד עשר יום שהם שבוע אחד וארבעה ימים',
    'שנים עשר יום שהם שבוע אחד וחמישה ימים',
    'שלושה עשר יום שהם שבוע אחד ושישה ימים',
    'ארבעה עשר יום שהם שני שבועות',
    'חמישה עשר יום שהם שני שבועות ויום אחד',
    'שישה עשר יום שהם שני שבועות ושני ימים',
    'שבעה עשר יום שהם שני שבועות ושלושה ימים',
    'שמונה עשר יום שהם שני שבועות וארבעה ימים',
    'תשעה עשר יום שהם שני שבועות וחמישה ימים',
    'עשרים יום שהם שני שבועות ושישה ימים',
    'אחד ועשרים יום שהם שלושה שבועות',
    'שנים ועשרים יום שהם שלושה שבועות ויום אחד',
    'שלושה ועשרים יום שהם שלושה שבועות ושני ימים',
    'ארבעה ועשרים יום שהם שלושה שבועות ושלושה ימים',
    'חמישה ועשרים יום שהם שלושה שבועות וארבעה ימים',
    'שישה ועשרים יום שהם שלושה שבועות וחמישה ימים',
    'שבעה ועשרים יום שהם שלושה שבועות ושישה ימים',
    'שמונה ועשרים יום שהם ארבעה שבועות',
    'תשעה ועשרים יום שהם ארבעה שבועות ויום אחד',
    'שלושים יום שהם ארבעה שבועות ושני ימים',
    'אחד ושלושים יום שהם ארבעה שבועות ושלושה ימים',
    'שנים ושלושים יום שהם ארבעה שבועות וארבעה ימים',
    'שלושה ושלושים יום שהם ארבעה שבועות וחמישה ימים',
    'ארבעה ושלושים יום שהם ארבעה שבועות ושישה ימים',
    'חמישה ושלושים יום שהם חמישה שבועות',
    'שישה ושלושים יום שהם חמישה שבועות ויום אחד',
    'שבעה ושלושים יום שהם חמישה שבועות ושני ימים',
    'שמונה ושלושים יום שהם חמישה שבועות ושלושה ימים',
    'תשעה ושלושים יום שהם חמישה שבועות וארבעה ימים',
    'ארבעים יום שהם חמישה שבועות וחמישה ימים',
    'אחד וארבעים יום שהם חמישה שבועות ושישה ימים',
    'שנים וארבעים יום שהם שישה שבועות',
    'שלושה וארבעים יום שהם שישה שבועות ויום אחד',
    'ארבעה וארבעים יום שהם שישה שבועות ושני ימים',
    'חמישה וארבעים יום שהם שישה שבועות ושלושה ימים',
    'שישה וארבעים יום שהם שישה שבועות וארבעה ימים',
    'שבעה וארבעים יום שהם שישה שבועות וחמישה ימים',
    'שמונה וארבעים יום שהם שישה שבועות ושישה ימים',
    'תשעה וארבעים יום שהם שבעה שבועות',
  ];

  @override
  Widget build(BuildContext context) {
    final dayText = omerDay > 0 && omerDay < _omerHebrew.length
        ? _omerHebrew[omerDay]
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ספירת העומר'),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🌾', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 16),
                  Text(
                    'ספירת העומר',
                    style: GoogleFonts.rubik(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // לשם יחוד
                  Text(
                    'לְשֵׁם יִחוּד קוּדְשָׁא בְּרִיךְ הוּא וּשְׁכִינְתֵּהּ, בִּדְחִילוּ וּרְחִימוּ, לְיַחֵד שֵׁם יוֹ"ד הֵ"א בְּוָא"ו הֵ"א בְּיִחוּדָא שְׁלִים, בְּשֵׁם כָּל יִשְׂרָאֵל.\nהִנְנִי מוּכָן וּמְזוּמָּן לְקַיֵּם מִצְוַת עֲשֵׂה שֶׁל סְפִירַת הָעוֹמֶר.',
                    style: GoogleFonts.frankRuhlLibre(
                      fontSize: 18,
                      height: 1.8,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // ברכה
                  Text(
                    'בָּרוּךְ אַתָּה ה\' אֱלֹקֵינוּ מֶלֶךְ הָעוֹלָם, אֲשֶׁר קִדְּשָׁנוּ בְּמִצְוֹתָיו, וְצִוָּנוּ עַל סְפִירַת הָעוֹמֶר.',
                    style: GoogleFonts.frankRuhlLibre(
                      fontSize: 22,
                      height: 2.0,
                      color: const Color(0xFF2C1810),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1B5E20).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'הַיּוֹם $dayText לָעוֹמֶר.',
                      style: GoogleFonts.frankRuhlLibre(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.8,
                        color: const Color(0xFF1B5E20),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // יהי רצון after counting
                  Text(
                    'יְהִי רָצוֹן מִלְּפָנֶיךָ ה\' אֱלֹקֵינוּ וֵאלֹקֵי אֲבוֹתֵינוּ, שֶׁבִּזְכוּת סְפִירַת הָעוֹמֶר שֶׁסָּפַרְתִּי הַיּוֹם, יְתֻקַּן מַה שֶׁפָּגַמְתִּי בִּסְפִירָה, וְאֶטָּהֵר וְאֶתְקַדֵּשׁ בִּקְדֻשָּׁה שֶׁל מַעְלָה, וְעַל יְדֵי זֶה יֻשְׁפַּע שֶׁפַע רַב בְּכָל הָעוֹלָמוֹת, וּלְתַקֵּן אֶת נַפְשׁוֹתֵינוּ וְרוּחוֹתֵינוּ וְנִשְׁמוֹתֵינוּ מִכָּל סִיג וּפְגָם, וּלְטַהֲרֵנוּ וּלְקַדְּשֵׁנוּ בִּקְדֻשָּׁתְךָ הָעֶלְיוֹנָה, אָמֵן סֶלָה.',
                    style: GoogleFonts.frankRuhlLibre(
                      fontSize: 18,
                      height: 1.8,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'הָרַחֲמָן הוּא יַחֲזִיר לָנוּ עֲבוֹדַת בֵּית הַמִּקְדָּשׁ לִמְקוֹמָהּ, בִּמְהֵרָה בְיָמֵינוּ אָמֵן סֶלָה.',
                    style: GoogleFonts.frankRuhlLibre(
                      fontSize: 20,
                      height: 2.0,
                      color: Color(0xFF2C1810),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _SiddurTextScreen extends StatefulWidget {
  final String title;
  final String ref;

  const _SiddurTextScreen({required this.title, required this.ref});

  @override
  State<_SiddurTextScreen> createState() => _SiddurTextScreenState();
}

class _SiddurTextScreenState extends State<_SiddurTextScreen> {
  final SefariaService _sefaria = SefariaService();
  List<String> _segments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _sefaria.getText(widget.ref);
      if (data.containsKey('error') &&
          data['error'].toString().contains('complex')) {
        _segments = await _fetchComplex(widget.ref);
      } else {
        final versions = data['versions'] as List?;
        if (versions != null) {
          for (final version in versions) {
            if (version['actualLanguage'] == 'he' && version['text'] != null) {
              final text = version['text'];
              if (text is List) {
                _segments = _flatten(text);
              } else if (text is String) {
                _segments = [text];
              }
              break;
            }
          }
        }
      }
    } catch (_) {}

    if (_segments.isEmpty) {
      _segments = ['לא ניתן לטעון את התפילה. נסה שוב מאוחר יותר.'];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<List<String>> _fetchComplex(String ref) async {
    final parts = [
      'Patriarchs', 'Divine_Might', 'Holiness_of_God', 'Knowledge',
      'Repentance', 'Forgiveness', 'Redemption', 'Healing', 'Prosperity',
      'Gathering_the_Exiles', 'Justice', 'Against_Enemies', 'The_Righteous',
      'Rebuilding_Jerusalem', 'Kingdom_of_David', 'Response_to_Prayer',
      'Temple_Service', 'Thanksgiving', 'Peace', 'Concluding_Passage',
      'Sanctity_of_the_Day', 'Birkat_Kohanim', 'Kedushah',
    ];
    final result = <String>[];
    for (final part in parts) {
      try {
        final data = await _sefaria.getText('$ref,_$part');
        if (!data.containsKey('error')) {
          final versions = data['versions'] as List?;
          if (versions != null) {
            for (final version in versions) {
              if (version['actualLanguage'] == 'he' && version['text'] != null) {
                final text = version['text'];
                if (text is List) {
                  result.addAll(_flatten(text));
                } else if (text is String && text.isNotEmpty) {
                  result.add(text);
                }
                break;
              }
            }
          }
        }
      } catch (_) {}
    }
    return result;
  }

  List<String> _flatten(List<dynamic> list) {
    final result = <String>[];
    for (final item in list) {
      if (item is String && item.isNotEmpty) result.add(item);
      if (item is List) result.addAll(_flatten(item));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  SizedBox(height: 16),
                  Text('...טוען תפילה'),
                ],
              ),
            )
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _segments.map((segment) {
                        final clean = TorahTextViewer.stripHtml(segment);
                        if (clean.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            clean,
                            style: const TextStyle(
                              fontFamily: 'Frank Ruhl Libre',
                              fontSize: 26,
                              height: 2.0,
                              color: Color(0xFF2C1810),
                              letterSpacing: 0.3,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ==========================================
// Azkara screen - Tehillim by name letters
// ==========================================

class _AzkaraScreen extends StatefulWidget {
  const _AzkaraScreen();

  @override
  State<_AzkaraScreen> createState() => _AzkaraScreenState();
}

class _AzkaraScreenState extends State<_AzkaraScreen> {
  final _nameController = TextEditingController();
  final SefariaService _sefaria = SefariaService();
  List<String> _loadedText = [];
  bool _isLoading = false;
  String _displayName = '';

  // Tehillim 119: 22 sections of 8 verses, one per Hebrew letter
  // Letter → start verse in Psalms 119
  static const _letterToVerseStart = {
    'א': 1, 'ב': 9, 'ג': 17, 'ד': 25, 'ה': 33, 'ו': 41, 'ז': 49, 'ח': 57,
    'ט': 65, 'י': 73, 'כ': 81, 'ך': 81, 'ל': 89, 'מ': 97, 'ם': 97,
    'נ': 105, 'ן': 105, 'ס': 113, 'ע': 121, 'פ': 129, 'ף': 129,
    'צ': 137, 'ץ': 137, 'ק': 145, 'ר': 153, 'ש': 161, 'ת': 169,
  };

  List<String> _nameLetters = [];

  List<String> _nameOnlyLetters = [];
  List<String> _neshmaLetters = [];
  String _normalize(String char) => switch (char) {
    'ך' => 'כ', 'ם' => 'מ', 'ן' => 'נ', 'ף' => 'פ', 'ץ' => 'צ',
    _ => char,
  };

  void _calculate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final nameLetters = <String>[];
    for (final char in name.split('')) {
      final n = _normalize(char);
      if (_letterToVerseStart.containsKey(n) && !nameLetters.contains(n)) {
        nameLetters.add(n);
      }
    }

    final neshmaLetters = <String>[];
    for (final char in 'נשמה'.split('')) {
      final n = _normalize(char);
      if (_letterToVerseStart.containsKey(n) && !neshmaLetters.contains(n)) {
        neshmaLetters.add(n);
      }
    }

    setState(() {
      _nameOnlyLetters = nameLetters;
      _neshmaLetters = neshmaLetters;
      _nameLetters = [...nameLetters, ...neshmaLetters];
      _displayName = name;
    });
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() { _isLoading = true; _loadedText = []; });

    final texts = <String>[];

    texts.add('--- תהילים קי"ט - אותיות שם $_displayName ---');
    for (final letter in _nameOnlyLetters) {
      await _loadLetterSection(texts, letter);
    }

    texts.add('--- תהילים קי"ט - אותיות נשמה ---');
    for (final letter in _neshmaLetters) {
      await _loadLetterSection(texts, letter);
    }

    if (mounted) setState(() { _loadedText = texts; _isLoading = false; });
  }

  Future<void> _loadLetterSection(List<String> texts, String letter) async {
    final startVerse = _letterToVerseStart[letter];
    if (startVerse == null) return;
    final endVerse = startVerse + 7;
    texts.add('--- אות $letter ---');
    try {
      final data = await _sefaria.getText('Psalms.119.$startVerse-$endVerse');
      final versions = data['versions'] as List?;
      if (versions != null) {
        for (final version in versions) {
          if (version['actualLanguage'] == 'he' && version['text'] != null) {
            final text = version['text'];
            if (text is List) {
              for (final item in text) {
                if (item is String && item.isNotEmpty) texts.add(item);
                if (item is List) {
                  for (final sub in item) {
                    if (sub is String && sub.isNotEmpty) texts.add(sub);
                  }
                }
              }
            }
            break;
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('נוסח לאזכרה'),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('שם הנפטר/ת',
                      style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.rubik(fontSize: 18),
                          decoration: InputDecoration(
                            hintText: 'הכנס שם בעברית',
                            hintStyle: GoogleFonts.rubik(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _calculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('חפש', style: GoogleFonts.rubik(fontSize: 16)),
                      ),
                    ],
                  ),
                  if (_nameLetters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('תהילים קי"ט לעילוי נשמת $_displayName:',
                        style: GoogleFonts.rubik(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B5E20))),
                    Text('אותיות השם: ${_nameOnlyLetters.join(", ")}',
                        style: GoogleFonts.rubik(
                            fontSize: 13, color: Colors.grey.shade600)),
                    Text('אותיות נשמה: ${_neshmaLetters.join(", ")}',
                        style: GoogleFonts.rubik(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                  : _loadedText.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('נוסח לאזכרה',
                                      style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1B5E20)),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'אָנָּא ה\' אֱלֹקֵי הָרוּחוֹת לְכָל בָּשָׂר, יְהִי רָצוֹן מִלְּפָנֶיךָ שֶׁתְּהֵא נִשְׁמַת הַנִּפְטָר/ת צְרוּרָה בִּצְרוֹר הַחַיִּים. ה\' הוּא נַחֲלָתוֹ, וְיָנוּחַ בְּשָׁלוֹם עַל מִשְׁכָּבוֹ/ה. וְנֹאמַר אָמֵן.',
                                    style: TextStyle(fontFamily: 'Frank Ruhl Libre', fontSize: 24, height: 2.0, color: Color(0xFF2C1810)),
                                  ),
                                  const SizedBox(height: 20),
                                  Text('הכנס את שם הנפטר/ת למעלה לקבלת פרקי תהילים לפי אותיות השם',
                                      style: GoogleFonts.rubik(fontSize: 14, color: Colors.grey),
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _loadedText.map((segment) {
                                  if (segment.startsWith('---')) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 16, bottom: 8),
                                      child: Text(
                                        segment.replaceAll('---', '').trim(),
                                        style: GoogleFonts.rubik(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1B5E20),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                                  final clean = TorahTextViewer.stripHtml(segment);
                                  if (clean.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      clean,
                                      style: const TextStyle(
                                        fontFamily: 'Frank Ruhl Libre',
                                        fontSize: 26,
                                        height: 2.0,
                                        color: Color(0xFF2C1810),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// חנוכת הבית - hardcoded nusach
// ==========================================

class _ChanukatHabayitScreen extends StatelessWidget {
  const _ChanukatHabayitScreen();

  static const _text = [
    'סדר חנוכת הבית',
    '',
    'קובעים מזוזה בפתח ומברכים:',
    'בָּרוּךְ אַתָּה ה\' אֱלֹקֵינוּ מֶלֶךְ הָעוֹלָם, אֲשֶׁר קִדְּשָׁנוּ בְּמִצְוֹתָיו, וְצִוָּנוּ לִקְבֹּעַ מְזוּזָה.',
    '',
    'בָּרוּךְ אַתָּה ה\' אֱלֹקֵינוּ מֶלֶךְ הָעוֹלָם, שֶׁהֶחֱיָנוּ וְקִיְּמָנוּ וְהִגִּיעָנוּ לַזְּמַן הַזֶּה.',
    '',
    'מזמור שיר חנוכת הבית לדוד (תהילים ל):',
    '',
    'אֲרוֹמִמְךָ ה\' כִּי דִלִּיתָנִי, וְלֹא שִׂמַּחְתָּ אֹיְבַי לִי.',
    'ה\' אֱלֹקָי, שִׁוַּעְתִּי אֵלֶיךָ וַתִּרְפָּאֵנִי.',
    'ה\', הֶעֱלִיתָ מִן שְׁאוֹל נַפְשִׁי, חִיִּיתַנִי מִיָּרְדִי בוֹר.',
    'זַמְּרוּ לַה\' חֲסִידָיו, וְהוֹדוּ לְזֵכֶר קָדְשׁוֹ.',
    'כִּי רֶגַע בְּאַפּוֹ, חַיִּים בִּרְצוֹנוֹ, בָּעֶרֶב יָלִין בֶּכִי, וְלַבֹּקֶר רִנָּה.',
    'וַאֲנִי אָמַרְתִּי בְשַׁלְוִי, בַּל אֶמּוֹט לְעוֹלָם.',
    'ה\', בִּרְצוֹנְךָ הֶעֱמַדְתָּה לְהַרְרִי עֹז, הִסְתַּרְתָּ פָנֶיךָ הָיִיתִי נִבְהָל.',
    'אֵלֶיךָ ה\' אֶקְרָא, וְאֶל אֲדֹנָי אֶתְחַנָּן.',
    'מַה בֶּצַע בְּדָמִי בְּרִדְתִּי אֶל שָׁחַת, הֲיוֹדְךָ עָפָר הֲיַגִּיד אֲמִתֶּךָ.',
    'שְׁמַע ה\' וְחָנֵּנִי, ה\' הֱיֵה עֹזֵר לִי.',
    'הָפַכְתָּ מִסְפְּדִי לְמָחוֹל לִי, פִּתַּחְתָּ שַׂקִּי וַתְּאַזְּרֵנִי שִׂמְחָה.',
    'לְמַעַן יְזַמֶּרְךָ כָבוֹד וְלֹא יִדֹּם, ה\' אֱלֹקַי לְעוֹלָם אוֹדֶךָּ.',
    '',
    'יהי רצון מלפניך ה\' אלוקינו ואלוקי אבותינו, שתשרה שכינתך בבית הזה, ותשלח ברכה והצלחה בכל מעשה ידינו. ויקוים בנו מקרא שכתוב: "וידעת כי שלום אהלך, ופקדת נוך ולא תחטא". ותן לנו ולכל יושבי ביתנו חיים טובים ושלום, ותשמרנו מכל צרה ויגון, ותמלא ביתנו אורה ושמחה. אמן כן יהי רצון.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('חנוכת הבית'),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _text.map((line) {
                  if (line.isEmpty) return const SizedBox(height: 12);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontFamily: 'Frank Ruhl Libre',
                        fontSize: 26,
                        height: 2.0,
                        color: Color(0xFF2C1810),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// משניות לעילוי נשמה - by letters of name
// ==========================================

class _MishnayotAzkaraScreen extends StatefulWidget {
  const _MishnayotAzkaraScreen();

  @override
  State<_MishnayotAzkaraScreen> createState() => _MishnayotAzkaraScreenState();
}

class _MishnayotAzkaraScreenState extends State<_MishnayotAzkaraScreen> {
  final _nameController = TextEditingController();
  final SefariaService _sefaria = SefariaService();
  List<String> _loadedText = [];
  bool _isLoading = false;
  String _displayName = '';

  // Mishnayot whose TEXT starts with each Hebrew letter (standard azkara list)
  static const _letterToMishna = {
    'א': ('Mishnah_Peah.1.1', 'פאה א:א - "אלו דברים"'),          // אלו
    'ב': ('Mishnah_Ketubot.1.1', 'כתובות א:א - "בתולה"'),        // בתולה
    'ג': ('Mishnah_Peah.5.1', 'פאה ה:א - "גדיש"'),               // גדיש
    'ד': ('Mishnah_Sanhedrin.1.1', 'סנהדרין א:א - "דיני"'),       // דיני
    'ה': ('Mishnah_Kilayim.1.1', 'כלאים א:א - "החטים"'),          // החטים
    'ו': ('Mishnah_Berakhot.1.1', 'ברכות א:א (אין משנה המתחילה בו\')'),
    'ז': ('Mishnah_Berakhot.3.6', 'ברכות ג:ו - "זב"'),            // זב
    'ח': ('Mishnah_Terumot.1.1', 'תרומות א:א - "חמשה"'),          // חמשה
    'ט': ('Mishnah_Shabbat.4.2', 'שבת ד:ב - "טומנין"'),           // טומנין
    'י': ('Mishnah_Shabbat.1.1', 'שבת א:א - "יציאות"'),           // יציאות
    'כ': ('Mishnah_Makkot.1.1', 'מכות א:א - "כיצד"'),             // כיצד
    'ך': ('Mishnah_Makkot.1.1', 'מכות א:א - "כיצד"'),
    'ל': ('Mishnah_Peah.1.6', 'פאה א:ו - "לעולם"'),               // לעולם
    'מ': ('Mishnah_Berakhot.1.1', 'ברכות א:א - "מאימתי"'),        // מאימתי
    'ם': ('Mishnah_Berakhot.1.1', 'ברכות א:א - "מאימתי"'),
    'נ': ('Mishnah_Berakhot.3.3', 'ברכות ג:ג - "נשים"'),          // נשים
    'ן': ('Mishnah_Berakhot.3.3', 'ברכות ג:ג - "נשים"'),
    'ס': ('Mishnah_Sukkah.1.1', 'סוכה א:א - "סוכה"'),             // סוכה
    'ע': ('Mishnah_Sheviit.1.1', 'שביעית א:א - "עד"'),            // עד
    'פ': ('Mishnah_Peah.4.4', 'פאה ד:ד - "פאה"'),                  // פאה
    'ף': ('Mishnah_Peah.4.4', 'פאה ד:ד - "פאה"'),
    'צ': ('Mishnah_Moed_Katan.1.4', 'מועד קטן א:ד - "צדין"'),     // צדין
    'ץ': ('Mishnah_Moed_Katan.1.4', 'מועד קטן א:ד - "צדין"'),
    'ק': ('Mishnah_Berakhot.3.2', 'ברכות ג:ב - "קברו"'),          // קברו
    'ר': ('Mishnah_Parah.1.1', 'פרה א:א - "רבי"'),                // רבי
    'ש': ('Mishnah_Yoma.1.1', 'יומא א:א - "שבעת"'),               // שבעת
    'ת': ('Mishnah_Berakhot.4.1', 'ברכות ד:א - "תפלת"'),          // תפלת
  };

  List<(String, String, String)> _nameMishnayot = []; // (letter, ref, desc)
  List<(String, String, String)> _neshamaMishnayot = [];

  String _norm(String c) => switch (c) {
    'ך' => 'כ', 'ם' => 'מ', 'ן' => 'נ', 'ף' => 'פ', 'ץ' => 'צ', _ => c,
  };

  void _calculate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final nameMish = <(String, String, String)>[];
    final seen = <String>{};
    for (final char in name.split('')) {
      final n = _norm(char);
      final entry = _letterToMishna[n];
      if (entry != null && !seen.contains(n)) {
        seen.add(n);
        nameMish.add((n, entry.$1, entry.$2));
      }
    }

    final neshamaMish = <(String, String, String)>[];
    final seenN = <String>{};
    for (final char in 'נשמה'.split('')) {
      final n = _norm(char);
      final entry = _letterToMishna[n];
      if (entry != null && !seenN.contains(n)) {
        seenN.add(n);
        neshamaMish.add((n, entry.$1, entry.$2));
      }
    }

    setState(() {
      _nameMishnayot = nameMish;
      _neshamaMishnayot = neshamaMish;
      _displayName = name;
    });
    _loadMishnayot();
  }

  Future<void> _loadMishnayot() async {
    setState(() { _isLoading = true; _loadedText = []; });
    final texts = <String>[];

    texts.add('--- משניות לאותיות שם $_displayName ---');
    for (final (letter, ref, desc) in _nameMishnayot) {
      await _loadOneMishna(texts, letter, ref, desc);
    }

    texts.add('--- משניות לאותיות נשמה ---');
    for (final (letter, ref, desc) in _neshamaMishnayot) {
      await _loadOneMishna(texts, letter, ref, desc);
    }

    if (mounted) setState(() { _loadedText = texts; _isLoading = false; });
  }

  Future<void> _loadOneMishna(List<String> texts, String letter, String ref, String desc) async {
    texts.add('--- אות $letter - $desc ---');
    try {
      final data = await _sefaria.getText(ref);
      final versions = data['versions'] as List?;
      if (versions != null) {
        for (final version in versions) {
          if (version['actualLanguage'] == 'he' && version['text'] != null) {
            final text = version['text'];
            if (text is String && text.isNotEmpty) {
              texts.add(text);
            } else if (text is List) {
              for (final item in text) {
                if (item is String && item.isNotEmpty) texts.add(item);
              }
            }
            break;
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('משניות לעילוי נשמה'),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('שם הנפטר/ת',
                      style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.rubik(fontSize: 18),
                          decoration: InputDecoration(
                            hintText: 'הכנס שם בעברית',
                            hintStyle: GoogleFonts.rubik(color: Colors.grey.shade400),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _calculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('חפש', style: GoogleFonts.rubik(fontSize: 16)),
                      ),
                    ],
                  ),
                  if (_nameMishnayot.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('משניות לעילוי נשמת $_displayName:',
                        style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1B5E20))),
                    Text(
                      'אותיות השם: ${_nameMishnayot.map((m) => m.$1).join(", ")}',
                      style: GoogleFonts.rubik(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    Text(
                      'אותיות נשמה: ${_neshamaMishnayot.map((m) => m.$1).join(", ")}',
                      style: GoogleFonts.rubik(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                  : _loadedText.isEmpty
                      ? Center(child: Text('הכנס את שם הנפטר/ת לקבלת משניות',
                          style: GoogleFonts.rubik(fontSize: 14, color: Colors.grey)))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _loadedText.map((segment) {
                                  if (segment.startsWith('---')) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                                      child: Text(
                                        segment.replaceAll('---', '').trim(),
                                        style: GoogleFonts.rubik(
                                          fontSize: 18, fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1B5E20)),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                                  final clean = TorahTextViewer.stripHtml(segment);
                                  if (clean.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(clean,
                                        style: const TextStyle(
                                          fontFamily: 'Frank Ruhl Libre', fontSize: 24,
                                          height: 2.0, color: Color(0xFF2C1810))),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
