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
                  _buildAzkaraCard(context),

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
              Text(
                '${category.items.length} תפילות',
                style: GoogleFonts.rubik(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
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
            builder: (_) => _SiddurTextScreen(
              title: 'ספירת העומר',
              ref: _getOmerRef(nusach),
            ),
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

    // Omer day calculation
    int omerDay = 0;
    if (month == 1 && day >= 16) omerDay = day - 15;
    if (month == 2) omerDay = day + 15;
    if (month == 3 && day <= 5) omerDay = day + 44;
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

  String _getOmerRef(String nusach) => switch (nusach) {
    'ashkenaz' => 'Siddur_Ashkenaz,_Weekday,_Maariv,_Sefirat_HaOmer',
    'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Counting_of_the_Omer',
    _ => 'Siddur_Sefard,_Weekday_Maariv,_Sefirat_HaOmer',
  };

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

class _PrayerListScreen extends StatelessWidget {
  final PrayerCategory category;
  const _PrayerListScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: category.items.length,
          itemBuilder: (context, index) {
            final prayer = category.items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _SiddurTextScreen(
                      title: prayer.name,
                      ref: prayer.ref,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book,
                          color: Color(0xFF1B5E20), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(prayer.name,
                            style: GoogleFonts.rubik(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.darkBrown)),
                      ),
                      const Icon(Icons.arrow_back_ios,
                          size: 14, color: Color(0xFF1B5E20)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// Siddur text screen - beautiful large font
// ==========================================

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

  // Tehillim 119: 22 sections of 8 verses, one per letter
  // Letter -> start verse in Psalms 119
  static const _letterToVerseStart = {
    'א': 1, 'ב': 9, 'ג': 17, 'ד': 25, 'ה': 33, 'ו': 41, 'ז': 49, 'ח': 57,
    'ט': 65, 'י': 73, 'כ': 81, 'ך': 81, 'ל': 89, 'מ': 97, 'ם': 97,
    'נ': 105, 'ן': 105, 'ס': 113, 'ע': 121, 'פ': 129, 'ף': 129,
    'צ': 137, 'ץ': 137, 'ק': 145, 'ר': 153, 'ש': 161, 'ת': 169,
  };

  List<String> _nameLetters = [];

  void _calculate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Collect unique letters from name + נשמה
    final allChars = '$name נשמה'.split('').where((c) => c.trim().isNotEmpty);
    final letters = <String>[];
    for (final char in allChars) {
      // Normalize sofit letters
      final normalized = switch (char) {
        'ך' => 'כ', 'ם' => 'מ', 'ן' => 'נ', 'ף' => 'פ', 'ץ' => 'צ',
        _ => char,
      };
      if (_letterToVerseStart.containsKey(normalized) && !letters.contains(normalized)) {
        letters.add(normalized);
      }
    }

    setState(() {
      _nameLetters = letters;
      _displayName = name;
    });
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() { _isLoading = true; _loadedText = []; });

    final texts = <String>[];
    for (final letter in _nameLetters) {
      final startVerse = _letterToVerseStart[letter]!;
      final endVerse = startVerse + 7;
      final ref = 'Psalms.119.$startVerse-$endVerse';

      texts.add('--- תהילים קי"ט - אות $letter ---');

      try {
        final data = await _sefaria.getText(ref);
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

    if (mounted) setState(() { _loadedText = texts; _isLoading = false; });
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
                    Text('אותיות: ${_nameLetters.join(", ")} + נ,ש,מ,ה',
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
                      ? Center(
                          child: Text('הכנס את שם הנפטר/ת לקבלת פרקי תהילים',
                              style: GoogleFonts.rubik(
                                  fontSize: 14, color: Colors.grey)))
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
