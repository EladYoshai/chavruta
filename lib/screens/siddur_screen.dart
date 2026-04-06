import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../data/siddur_structure.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

  Future<void> _loadStructure() async {
    final nusach = context.read<AppState>().progress.nusach;
    final cats = await SiddurStructure.loadCategories(nusach);
    if (mounted) {
      setState(() {
        _mainCategories = cats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nusach = context.watch<AppState>().progress.nusach;
    final nusachName = _getNusachName(nusach);
    final dayInfo = _getDayInfo();

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
                  // Day info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(dayInfo.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dayInfo.label,
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main tefilot from Sefaria index (these work via tree-walking)
                  _buildSectionHeader('תפילות'),
                  ..._buildMainTefilot(context, dayInfo),

                  // Omer - only during season, show today's count
                  if (dayInfo.isOmerSeason) ...[
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
                  _buildSimpleCard(context, '👶', 'ברית יצחק',
                      'סדר ברית מילה', _getBritMilaRef(nusach)),
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
  List<Widget> _buildMainTefilot(BuildContext context, _DayInfo dayInfo) {
    // Map category names to the ones we want to show
    final showOrder = dayInfo.isShabbat
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

  Widget _buildOmerCard(BuildContext context, String nusach, _DayInfo dayInfo) {
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
  // Day detection
  // ==========================================

  _DayInfo _getDayInfo() {
    final now = DateTime.now();
    final jewishCal = JewishCalendar.fromDateTime(now);
    final month = jewishCal.getJewishMonth();
    final day = jewishCal.getJewishDayOfMonth();
    final dayOfWeek = now.weekday;

    // Omer day - shkia aware (after sunset = next day's count)
    final geoLocation = GeoLocation.setLocation('Jerusalem', 31.7683, 35.2137, now);
    final zmanimCal = ComplexZmanimCalendar.intGeoLocation(geoLocation);
    final sunset = zmanimCal.getSunset();
    final isAfterShkia = sunset != null && now.isAfter(sunset);

    final omerDate = isAfterShkia
        ? JewishCalendar.fromDateTime(now.add(const Duration(days: 1)))
        : jewishCal;
    final omerMonth = omerDate.getJewishMonth();
    final omerDayOfMonth = omerDate.getJewishDayOfMonth();
    int omerDay = 0;
    if (omerMonth == 1 && omerDayOfMonth >= 16) omerDay = omerDayOfMonth - 15;
    if (omerMonth == 2) omerDay = omerDayOfMonth + 15;
    if (omerMonth == 3 && omerDayOfMonth <= 5) omerDay = omerDayOfMonth + 44;
    bool isOmer = omerDay > 0 && omerDay <= 49;

    if (dayOfWeek == 6) {
      return _DayInfo('שבת קודש', '✡️', isShabbat: true, isOmerSeason: isOmer, omerDay: omerDay);
    }
    if (month == 1 && day >= 16 && day <= 20) {
      return _DayInfo('חול המועד פסח', '🫓', isOmerSeason: isOmer, omerDay: omerDay);
    }
    if (month == 1 && (day == 15 || day == 21)) {
      return _DayInfo('פסח', '🫓', isShabbat: true, omerDay: omerDay);
    }
    if (month == 7 && day >= 16 && day <= 20) {
      return _DayInfo('חול המועד סוכות', '🏗️', isOmerSeason: isOmer, omerDay: omerDay);
    }
    if (day == 1 || day == 30) {
      return _DayInfo('ראש חודש', '🌙', isOmerSeason: isOmer, omerDay: omerDay);
    }
    return _DayInfo('יום חול', '📖', isOmerSeason: isOmer, omerDay: omerDay);
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

  String _getMeeinShaloshRef(String nusach) => switch (nusach) {
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Al_Hamihya',
    _ => 'Siddur_Sefard,_Birchat_HaMazon,_Birchat_HaMazon', // includes me'ein shalosh
  };

  String _getAsherYatzarRef(String nusach) => switch (nusach) {
    'ashkenaz' => 'Siddur_Ashkenaz,_Weekday,_Shacharit,_Preparatory_Prayers,_Asher_Yatzar',
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Preparatory_Prayers,_Morning_Blessings',
    _ => 'Siddur_Sefard,_Weekday_Shacharit,_Asher_Yatzar',
  };

  String _getBritMilaRef(String nusach) => switch (nusach) {
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Assorted_Blessings_and_Prayers,_Brit_Mila',
    _ => 'Siddur_Sefard,_Various_Blessings,_Circumcision',
  };

  String _getTefilatHaderechRef(String nusach) => switch (nusach) {
    'ashkenaz' => 'Siddur_Ashkenaz,_Berachot,_Tefillat_HaDerech',
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Assorted_Blessings_and_Prayers,_Traveler%27s_Prayer',
    _ => 'Siddur_Sefard,_Blessings,_Traveler%27s_Prayer',
  };
}

class _DayInfo {
  final String label;
  final String emoji;
  final bool isShabbat;
  final bool isOmerSeason;
  final int omerDay;
  const _DayInfo(this.label, this.emoji,
      {this.isShabbat = false, this.isOmerSeason = false, this.omerDay = 0});
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

  // Each prayer's loaded text
  List<List<String>> _prayerTexts = [];
  List<GlobalKey> _sectionKeys = [];
  int _activeIndex = 0;
  bool _isLoading = true;
  bool _programmaticScroll = false;

  @override
  void initState() {
    super.initState();
    _sectionKeys = List.generate(widget.category.items.length, (_) => GlobalKey());
    _scrollController.addListener(_onScroll);
    _loadAll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final texts = <List<String>>[];
    for (final prayer in widget.category.items) {
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

  void _scrollToSection(int index) async {
    final key = _sectionKeys[index];
    final ctx = key.currentContext;
    if (ctx != null) {
      _programmaticScroll = true;
      setState(() => _activeIndex = index);
      await Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit);
      _programmaticScroll = false;
    }
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
                      itemCount: widget.category.items.length,
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
                                widget.category.items[index].name,
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
                        children: List.generate(widget.category.items.length, (index) {
                        final prayer = widget.category.items[index];
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
                                            fontFamily: 'serif',
                                            fontSize: 26,
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(32),
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
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 24),
                  const Text(
                    'בָּרוּךְ אַתָּה ה\' אֱלֹקֵינוּ מֶלֶךְ הָעוֹלָם, אֲשֶׁר קִדְּשָׁנוּ בְּמִצְוֹתָיו, וְצִוָּנוּ עַל סְפִירַת הָעוֹמֶר.',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 26,
                      height: 2.0,
                      color: Color(0xFF2C1810),
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
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.8,
                        color: Color(0xFF1B5E20),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'הָרַחֲמָן הוּא יַחֲזִיר לָנוּ עֲבוֹדַת בֵּית הַמִּקְדָּשׁ לִמְקוֹמָהּ, בִּמְהֵרָה בְיָמֵינוּ אָמֵן סֶלָה.',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
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
                              fontFamily: 'serif',
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

  // Gematria-based: letter value = Tehillim chapter number
  // For values > 150: subtract 150 (ר=200→50, ש=300→150, ת=400→100)
  static const _letterToChapter = {
    'א': 1, 'ב': 2, 'ג': 3, 'ד': 4, 'ה': 5, 'ו': 6, 'ז': 7, 'ח': 8,
    'ט': 9, 'י': 10, 'כ': 20, 'ך': 20, 'ל': 30, 'מ': 40, 'ם': 40,
    'נ': 50, 'ן': 50, 'ס': 60, 'ע': 70, 'פ': 80, 'ף': 80,
    'צ': 90, 'ץ': 90, 'ק': 100, 'ר': 50, 'ש': 150, 'ת': 100,
  };

  // Hebrew chapter names (standard notation with geresh)
  static const _chapterHebrew = {
    1: "א'", 2: "ב'", 3: "ג'", 4: "ד'", 5: "ה'", 6: "ו'", 7: "ז'", 8: "ח'",
    9: "ט'", 10: "י'", 20: "כ'", 30: "ל'", 40: "מ'", 50: "נ'", 60: "ס'",
    70: "ע'", 80: "פ'", 90: "צ'", 100: "ק'", 150: "ק\"נ",
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
      if (_letterToChapter.containsKey(n) && !nameLetters.contains(n)) {
        nameLetters.add(n);
      }
    }

    final neshmaLetters = <String>[];
    for (final char in 'נשמה'.split('')) {
      final n = _normalize(char);
      if (_letterToChapter.containsKey(n) && !neshmaLetters.contains(n)) {
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

    // Name letters - full Tehillim chapters by gematria
    texts.add('--- תהילים לאותיות שם $_displayName ---');
    for (final letter in _nameOnlyLetters) {
      await _loadChapter(texts, letter);
    }

    // נשמה letters - always separate
    texts.add('--- תהילים לאותיות נשמה ---');
    for (final letter in _neshmaLetters) {
      await _loadChapter(texts, letter);
    }

    if (mounted) setState(() { _loadedText = texts; _isLoading = false; });
  }

  Future<void> _loadChapter(List<String> texts, String letter) async {
    final chapter = _letterToChapter[letter];
    if (chapter == null) return;
    final chHe = _chapterHebrew[chapter] ?? '$chapter';
    texts.add('--- אות $letter - פרק $chHe ---');
    try {
      final data = await _sefaria.getText('Psalms.$chapter');
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
                    Text('תהילים לעילוי נשמת $_displayName:',
                        style: GoogleFonts.rubik(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B5E20))),
                    Text('אותיות השם: ${_nameOnlyLetters.map((l) => '$l (פרק ${_chapterHebrew[_letterToChapter[l]] ?? _letterToChapter[l]})').join(", ")}',
                        style: GoogleFonts.rubik(
                            fontSize: 13, color: Colors.grey.shade600)),
                    Text('אותיות נשמה: ${_neshmaLetters.map((l) => '$l (פרק ${_chapterHebrew[_letterToChapter[l]] ?? _letterToChapter[l]})').join(", ")}',
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
                                    style: TextStyle(fontFamily: 'serif', fontSize: 24, height: 2.0, color: Color(0xFF2C1810)),
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
                                        fontFamily: 'serif',
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
                        fontFamily: 'serif',
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
  List<String> _selectedMasechetot = [];
  bool _isLoading = false;
  String _displayName = '';

  // Map Hebrew letters to Mishnah masechetot that start with that letter
  static const _letterToMasechet = {
    'א': ['Mishnah_Avot', 'Mishnah_Eduyot'],
    'ב': ['Mishnah_Berakhot', 'Mishnah_Bikkurim', 'Mishnah_Bava_Kamma'],
    'ג': ['Mishnah_Gittin'],
    'ד': ['Mishnah_Demai'],
    'ה': ['Mishnah_Horayot'],
    'ו': [],
    'ז': ['Mishnah_Zevachim'],
    'ח': ['Mishnah_Chullin', 'Mishnah_Chagigah'],
    'ט': ['Mishnah_Tevul_Yom', 'Mishnah_Tahorot'],
    'י': ['Mishnah_Yevamot', 'Mishnah_Yoma'],
    'כ': ['Mishnah_Ketubot', 'Mishnah_Kelim', 'Mishnah_Keritot'],
    'ך': ['Mishnah_Ketubot'],
    'ל': [],
    'מ': ['Mishnah_Megillah', 'Mishnah_Makkot', 'Mishnah_Menachot', 'Mishnah_Mikvaot'],
    'ם': ['Mishnah_Megillah'],
    'נ': ['Mishnah_Nazir', 'Mishnah_Nedarim', 'Mishnah_Niddah', 'Mishnah_Negaim'],
    'ן': ['Mishnah_Nazir'],
    'ס': ['Mishnah_Sanhedrin', 'Mishnah_Sukkah', 'Mishnah_Sotah'],
    'ע': ['Mishnah_Avodah_Zarah', 'Mishnah_Arakhin', 'Mishnah_Eruvin', 'Mishnah_Orlah'],
    'פ': ['Mishnah_Pesachim', 'Mishnah_Peah', 'Mishnah_Parah'],
    'ף': ['Mishnah_Pesachim'],
    'צ': [],
    'ק': ['Mishnah_Kiddushin'],
    'ר': ['Mishnah_Rosh_Hashanah'],
    'ש': ['Mishnah_Shabbat', 'Mishnah_Sheviit', 'Mishnah_Shekalim', 'Mishnah_Shevuot'],
    'ת': ['Mishnah_Tamid', 'Mishnah_Terumot', 'Mishnah_Taanit'],
  };

  // Hebrew display names
  static const _masechetNames = {
    'Mishnah_Avot': 'אבות',
    'Mishnah_Eduyot': 'עדויות',
    'Mishnah_Berakhot': 'ברכות',
    'Mishnah_Bikkurim': 'ביכורים',
    'Mishnah_Bava_Kamma': 'בבא קמא',
    'Mishnah_Gittin': 'גיטין',
    'Mishnah_Demai': 'דמאי',
    'Mishnah_Horayot': 'הוריות',
    'Mishnah_Zevachim': 'זבחים',
    'Mishnah_Chullin': 'חולין',
    'Mishnah_Chagigah': 'חגיגה',
    'Mishnah_Tevul_Yom': 'טבול יום',
    'Mishnah_Tahorot': 'טהרות',
    'Mishnah_Yevamot': 'יבמות',
    'Mishnah_Yoma': 'יומא',
    'Mishnah_Ketubot': 'כתובות',
    'Mishnah_Kelim': 'כלים',
    'Mishnah_Keritot': 'כריתות',
    'Mishnah_Megillah': 'מגילה',
    'Mishnah_Makkot': 'מכות',
    'Mishnah_Menachot': 'מנחות',
    'Mishnah_Mikvaot': 'מקוואות',
    'Mishnah_Nazir': 'נזיר',
    'Mishnah_Nedarim': 'נדרים',
    'Mishnah_Niddah': 'נידה',
    'Mishnah_Negaim': 'נגעים',
    'Mishnah_Sanhedrin': 'סנהדרין',
    'Mishnah_Sukkah': 'סוכה',
    'Mishnah_Sotah': 'סוטה',
    'Mishnah_Avodah_Zarah': 'עבודה זרה',
    'Mishnah_Arakhin': 'ערכין',
    'Mishnah_Eruvin': 'עירובין',
    'Mishnah_Orlah': 'ערלה',
    'Mishnah_Pesachim': 'פסחים',
    'Mishnah_Peah': 'פאה',
    'Mishnah_Parah': 'פרה',
    'Mishnah_Kiddushin': 'קידושין',
    'Mishnah_Rosh_Hashanah': 'ראש השנה',
    'Mishnah_Shabbat': 'שבת',
    'Mishnah_Sheviit': 'שביעית',
    'Mishnah_Shekalim': 'שקלים',
    'Mishnah_Shevuot': 'שבועות',
    'Mishnah_Tamid': 'תמיד',
    'Mishnah_Terumot': 'תרומות',
    'Mishnah_Taanit': 'תענית',
  };

  List<(String, String)> _namePairs = []; // (letter, ref)
  List<(String, String)> _neshamaPairs = [];

  String _norm(String c) => switch (c) {
    'ך' => 'כ', 'ם' => 'מ', 'ן' => 'נ', 'ף' => 'פ', 'ץ' => 'צ', _ => c,
  };

  void _calculate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final namePairs = <(String, String)>[];
    final seen = <String>{};
    for (final char in name.split('')) {
      final n = _norm(char);
      final list = _letterToMasechet[n];
      if (list != null && list.isNotEmpty && !seen.contains(n)) {
        seen.add(n);
        namePairs.add((n, list.first));
      }
    }

    final neshamaPairs = <(String, String)>[];
    final seenN = <String>{};
    for (final char in 'נשמה'.split('')) {
      final n = _norm(char);
      final list = _letterToMasechet[n];
      if (list != null && list.isNotEmpty && !seenN.contains(n)) {
        seenN.add(n);
        neshamaPairs.add((n, list.first));
      }
    }

    setState(() {
      _namePairs = namePairs;
      _neshamaPairs = neshamaPairs;
      _selectedMasechetot = [...namePairs.map((p) => p.$2), ...neshamaPairs.map((p) => p.$2)];
      _displayName = name;
    });
    _loadMasechetot();
  }

  Future<void> _loadMasechetot() async {
    setState(() { _isLoading = true; _loadedText = []; });

    final texts = <String>[];

    texts.add('--- אותיות שם הנפטר/ת: $_displayName ---');
    for (final (letter, ref) in _namePairs) {
      await _loadOneMasechet(texts, ref, letter);
    }

    texts.add('--- אותיות נשמה: נ, ש, מ, ה ---');
    for (final (letter, ref) in _neshamaPairs) {
      await _loadOneMasechet(texts, ref, letter);
    }

    if (mounted) setState(() { _loadedText = texts; _isLoading = false; });
  }

  Future<void> _loadOneMasechet(List<String> texts, String ref, String letter) async {
      final heName = _masechetNames[ref] ?? ref;
      texts.add('--- אות $letter - משנה $heName פרק א ---');
      try {
        final data = await _sefaria.getText('$ref.1');
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
                  if (_selectedMasechetot.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('משניות לעילוי נשמת $_displayName:',
                        style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1B5E20))),
                    Text(
                      _selectedMasechetot.map((r) => _masechetNames[r] ?? r).join(', '),
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
                                          fontFamily: 'serif', fontSize: 24,
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
