import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../services/sefaria_service.dart';
import '../utils/constants.dart';
import '../widgets/torah_text_viewer.dart';

/// Redesigned Siddur with context-aware categories and beautiful typography
class SiddurScreen extends StatelessWidget {
  const SiddurScreen({super.key});

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
      body: Directionality(
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

            // Main prayers
            _buildSectionHeader('תפילות'),
            _buildPrayerCard(
              context, '🌅', 'שחרית', 'תפילת שחרית',
              _getShacharitRefs(nusach, dayInfo),
            ),
            _buildPrayerCard(
              context, '☀️', 'מנחה', 'תפילת מנחה',
              _getMinchaRefs(nusach, dayInfo),
            ),
            _buildPrayerCard(
              context, '🌙', 'ערבית', 'תפילת ערבית',
              _getArvitRefs(nusach, dayInfo),
            ),

            // Seasonal
            if (dayInfo.isOmerSeason) ...[
              const SizedBox(height: 8),
              _buildPrayerCard(
                context, '🌾', 'ספירת העומר', 'נוסח ספירת העומר',
                [_getOmerRef(nusach)],
              ),
            ],

            _buildPrayerCard(
              context, '🌙', 'קידוש לבנה', 'ברכת הלבנה',
              [_getKiddushLevanaRef(nusach)],
            ),

            const SizedBox(height: 16),
            _buildSectionHeader('קריאת שמע'),
            _buildPrayerCard(
              context, '🛏️', 'קריאת שמע על המיטה', 'לפני השינה',
              [_getBedtimeShemaRef(nusach)],
            ),

            const SizedBox(height: 16),
            _buildSectionHeader('ברכות'),
            _buildPrayerCard(
              context, '🍞', 'ברכת המזון', 'ברכה אחרי סעודה עם לחם',
              [_getBirkatHamazonRef(nusach)],
            ),
            _buildPrayerCard(
              context, '🍎', 'ברכה מעין שלוש', 'על המחיה / על הגפן / על העץ',
              [_getMeeinShaloshRef(nusach)],
            ),
            _buildPrayerCard(
              context, '💧', 'בורא נפשות', 'ברכה אחרונה',
              [_getBoreiNefashot(nusach)],
            ),
            _buildPrayerCard(
              context, '🚿', 'אשר יצר', 'ברכת אשר יצר',
              [_getAsherYatzarRef(nusach)],
            ),

            const SizedBox(height: 16),
            _buildSectionHeader('תפילות מיוחדות'),
            _buildPrayerCard(
              context, '🚗', 'תפילת הדרך', 'לפני נסיעה',
              [_getTefilatHaderechRef(nusach)],
            ),
            _buildAzkaraCard(context),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.rubik(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.darkBrown,
        ),
      ),
    );
  }

  Widget _buildPrayerCard(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    List<String> refs,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SiddurPrayerScreen(
              title: title,
              refs: refs,
            ),
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
                    Text(
                      title,
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios,
                  size: 14, color: Color(0xFF1B5E20)),
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
          MaterialPageRoute(builder: (_) => const AzkaraScreen()),
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
                    Text(
                      'נוסח לאזכרה',
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    Text(
                      'תהילים לפי אותיות שם הנפטר/ת',
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios,
                  size: 14, color: Color(0xFF1B5E20)),
            ],
          ),
        ),
      ),
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
    final dayOfWeek = now.weekday; // 1=Mon...7=Sun

    // Check Shabbat
    if (dayOfWeek == 6) { // Saturday
      return _DayInfo('שבת קודש', '✡️', isShabbat: true);
    }

    // Omer season: 16 Nisan - 5 Sivan
    bool isOmer = (month == 1 && day >= 16) || month == 2 || (month == 3 && day <= 5);

    // Chol HaMoed Pesach: 16-20 Nisan (in Israel)
    if (month == 1 && day >= 16 && day <= 20) {
      return _DayInfo('חול המועד פסח', '🫓', isOmerSeason: isOmer, isCholHamoed: true, isYaalehVyavo: true);
    }
    // Pesach Yom Tov
    if (month == 1 && (day == 15 || day == 21)) {
      return _DayInfo('פסח', '🫓', isYomTov: true, isYaalehVyavo: true);
    }

    // Chol HaMoed Sukkot: 16-20 Tishrei
    if (month == 7 && day >= 16 && day <= 20) {
      return _DayInfo('חול המועד סוכות', '🏗️', isCholHamoed: true, isYaalehVyavo: true);
    }
    // Sukkot Yom Tov
    if (month == 7 && (day == 15 || day == 22)) {
      return _DayInfo('סוכות', '🏗️', isYomTov: true, isYaalehVyavo: true);
    }

    // Rosh Chodesh
    if (day == 1 || day == 30) {
      return _DayInfo('ראש חודש', '🌙', isRoshChodesh: true, isYaalehVyavo: true, isOmerSeason: isOmer);
    }

    // Regular weekday
    return _DayInfo('יום חול', '📖', isOmerSeason: isOmer);
  }

  // ==========================================
  // Nusach-specific refs
  // ==========================================

  String _getNusachName(String nusach) {
    switch (nusach) {
      case 'ashkenaz': return 'אשכנז';
      case 'sefard': return 'ספרד';
      case 'edot_hamizrach': return 'עדות המזרח';
      default: return 'אשכנז';
    }
  }

  List<String> _getShacharitRefs(String nusach, _DayInfo day) {
    if (day.isShabbat) {
      return switch (nusach) {
        'ashkenaz' => ['Siddur_Ashkenaz,_Shabbat,_Shacharit'],
        'edot_hamizrach' => ['Siddur_Edot_HaMizrach,_Shabbat_Shacharit'],
        _ => ['Siddur_Sefard,_Shabbat_Morning_Services'],
      };
    }
    return switch (nusach) {
      'ashkenaz' => ['Siddur_Ashkenaz,_Weekday,_Shacharit'],
      'edot_hamizrach' => ['Siddur_Edot_HaMizrach,_Preparatory_Prayers', 'Siddur_Edot_HaMizrach,_Weekday_Shacharit'],
      _ => ['Siddur_Sefard,_Upon_Arising', 'Siddur_Sefard,_Weekday_Shacharit'],
    };
  }

  List<String> _getMinchaRefs(String nusach, _DayInfo day) {
    if (day.isShabbat) {
      return switch (nusach) {
        'ashkenaz' => ['Siddur_Ashkenaz,_Shabbat,_Minchah'],
        'edot_hamizrach' => ['Siddur_Edot_HaMizrach,_Shabbat_Mincha'],
        _ => ['Siddur_Sefard,_Shabbat_Mincha'],
      };
    }
    return switch (nusach) {
      'ashkenaz' => ['Siddur_Ashkenaz,_Weekday,_Minchah'],
      'edot_hamizrach' => ['Siddur_Edot_HaMizrach,_Weekday_Mincha'],
      _ => ['Siddur_Sefard,_Weekday_Mincha'],
    };
  }

  List<String> _getArvitRefs(String nusach, _DayInfo day) {
    if (day.isShabbat) {
      // Friday night = Kabbalat Shabbat + Maariv
      return switch (nusach) {
        'ashkenaz' => ['Siddur_Ashkenaz,_Shabbat,_Kabbalat_Shabbat', 'Siddur_Ashkenaz,_Shabbat,_Maariv'],
        'edot_hamizrach' => ['Siddur_Edot_HaMizrach,_Kabbalat_Shabbat', 'Siddur_Edot_HaMizrach,_Shabbat_Arvit'],
        _ => ['Siddur_Sefard,_Kabbalat_Shabbat', 'Siddur_Sefard,_Shabbat_Eve_Maariv'],
      };
    }
    return switch (nusach) {
      'ashkenaz' => ['Siddur_Ashkenaz,_Weekday,_Maariv'],
      'edot_hamizrach' => ['Siddur_Edot_HaMizrach,_Weekday_Arvit'],
      _ => ['Siddur_Sefard,_Weekday_Maariv'],
    };
  }

  String _getOmerRef(String nusach) {
    return switch (nusach) {
      'ashkenaz' => 'Siddur_Ashkenaz,_Weekday,_Maariv,_Sefirat_HaOmer',
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Counting_of_the_Omer',
      _ => 'Siddur_Sefard,_Weekday_Maariv,_Sefirat_HaOmer',
    };
  }

  String _getKiddushLevanaRef(String nusach) {
    return switch (nusach) {
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Kiddush_Levanah',
      _ => 'Siddur_Sefard,_Kiddush_Levanah',
    };
  }

  String _getBedtimeShemaRef(String nusach) {
    return switch (nusach) {
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Bedtime_Shema',
      _ => 'Siddur_Sefard,_Bedtime_Shema',
    };
  }

  String _getBirkatHamazonRef(String nusach) {
    return switch (nusach) {
      'ashkenaz' => 'Siddur_Ashkenaz,_Berachot,_Birkat_HaMazon',
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Post_Meal_Blessing',
      _ => 'Siddur_Sefard,_Birchat_HaMazon,_Birchat_HaMazon',
    };
  }

  String _getMeeinShaloshRef(String nusach) {
    return switch (nusach) {
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Al_Hamihya',
      _ => 'Siddur_Sefard,_Birchat_HaMazon,_Al_HaMichya',
    };
  }

  String _getBoreiNefashot(String nusach) {
    return switch (nusach) {
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Al_Hamihya',
      _ => 'Siddur_Sefard,_Birchat_HaMazon,_Borei_Nefashot',
    };
  }

  String _getAsherYatzarRef(String nusach) {
    return switch (nusach) {
      'ashkenaz' => 'Siddur_Ashkenaz,_Weekday,_Shacharit,_Preparatory_Prayers,_Asher_Yatzar',
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Preparatory_Prayers,_Morning_Blessings',
      _ => 'Siddur_Sefard,_Upon_Arising,_Morning_Blessings',
    };
  }

  String _getTefilatHaderechRef(String nusach) {
    return switch (nusach) {
      'ashkenaz' => 'Siddur_Ashkenaz,_Berachot,_Tefillat_HaDerech',
      'edot_hamizrach' => 'Siddur_Edot_HaMizrach,_Assorted_Blessings_and_Prayers,_Traveler%27s_Prayer',
      _ => 'Siddur_Sefard,_Blessings,_Traveler%27s_Prayer',
    };
  }
}

class _DayInfo {
  final String label;
  final String emoji;
  final bool isShabbat;
  final bool isYomTov;
  final bool isCholHamoed;
  final bool isRoshChodesh;
  final bool isOmerSeason;
  final bool isYaalehVyavo;

  const _DayInfo(
    this.label,
    this.emoji, {
    this.isShabbat = false,
    this.isYomTov = false,
    this.isCholHamoed = false,
    this.isRoshChodesh = false,
    this.isOmerSeason = false,
    this.isYaalehVyavo = false,
  });
}

/// Shows prayer text with large, beautiful font and clear nikud
class SiddurPrayerScreen extends StatefulWidget {
  final String title;
  final List<String> refs;

  const SiddurPrayerScreen({
    super.key,
    required this.title,
    required this.refs,
  });

  @override
  State<SiddurPrayerScreen> createState() => _SiddurPrayerScreenState();
}

class _SiddurPrayerScreenState extends State<SiddurPrayerScreen> {
  final SefariaService _sefaria = SefariaService();
  List<String> _segments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  Future<void> _loadPrayer() async {
    final allSegments = <String>[];

    for (final ref in widget.refs) {
      try {
        final data = await _sefaria.getText(ref);
        if (data.containsKey('error') &&
            data['error'].toString().contains('complex')) {
          // Complex ref - try known sub-sections
          allSegments.addAll(await _fetchComplex(ref));
        } else {
          final versions = data['versions'] as List?;
          if (versions != null) {
            for (final version in versions) {
              if (version['actualLanguage'] == 'he' &&
                  version['text'] != null) {
                final text = version['text'];
                if (text is List) {
                  allSegments.addAll(_flatten(text));
                } else if (text is String) {
                  allSegments.add(text);
                }
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

    if (allSegments.isEmpty) {
      allSegments.add('לא ניתן לטעון את התפילה. נסה שוב מאוחר יותר.');
    }

    if (mounted) {
      setState(() {
        _segments = allSegments;
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _fetchComplex(String ref) async {
    // Try common Amidah sub-sections
    final parts = [
      'Patriarchs', 'Divine_Might', 'Holiness_of_God',
      'Knowledge', 'Repentance', 'Forgiveness', 'Redemption',
      'Healing', 'Prosperity', 'Gathering_the_Exiles', 'Justice',
      'Against_Enemies', 'The_Righteous', 'Rebuilding_Jerusalem',
      'Kingdom_of_David', 'Response_to_Prayer', 'Temple_Service',
      'Thanksgiving', 'Peace', 'Concluding_Passage',
      'Sanctity_of_the_Day', 'Birkat_Kohanim', 'Kedushah',
    ];
    final result = <String>[];

    // First try direct sub-nodes from index
    for (final part in parts) {
      try {
        final data = await _sefaria.getText('$ref,_$part');
        if (data.containsKey('error')) continue;
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
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _segments.map((segment) {
                        final clean = TorahTextViewer.stripHtml(segment);
                        if (clean.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            clean,
                            style: GoogleFonts.rubik(
                              fontSize: 24,
                              height: 2.2,
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.w400,
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

/// Azkara screen - Tehillim by letters of the niftar's name
class AzkaraScreen extends StatefulWidget {
  const AzkaraScreen({super.key});

  @override
  State<AzkaraScreen> createState() => _AzkaraScreenState();
}

class _AzkaraScreenState extends State<AzkaraScreen> {
  final _nameController = TextEditingController();
  final SefariaService _sefaria = SefariaService();
  List<int> _chapters = [];
  List<String> _loadedText = [];
  bool _isLoading = false;
  String _displayName = '';

  // Map Hebrew letters to Tehillim chapters (by acrostic / traditional association)
  static const _letterToChapters = {
    'א': [1, 111], 'ב': [2, 112], 'ג': [3, 113], 'ד': [4, 114],
    'ה': [5, 115], 'ו': [6, 116], 'ז': [7, 117], 'ח': [8, 118],
    'ט': [9, 119], 'י': [10, 120], 'כ': [11, 121], 'ך': [11, 121],
    'ל': [12, 122], 'מ': [13, 123], 'ם': [13, 123], 'נ': [14, 124],
    'ן': [14, 124], 'ס': [15, 125], 'ע': [16, 126], 'פ': [17, 127],
    'ף': [17, 127], 'צ': [18, 128], 'ץ': [18, 128], 'ק': [19, 129],
    'ר': [20, 130], 'ש': [21, 131], 'ת': [22, 132],
  };

  void _calculateChapters() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final chapters = <int>{};
    for (final char in name.split('')) {
      final ch = _letterToChapters[char];
      if (ch != null) chapters.add(ch[0]);
    }
    // Also add נשמה chapters (the word נשמה)
    for (final char in 'נשמה'.split('')) {
      final ch = _letterToChapters[char];
      if (ch != null) chapters.add(ch[0]);
    }

    setState(() {
      _chapters = chapters.toList()..sort();
      _displayName = name;
    });

    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _loadedText = [];
    });

    final texts = <String>[];
    for (final chapter in _chapters) {
      try {
        final data = await _sefaria.getText('Psalms.$chapter');
        final versions = data['versions'] as List?;
        if (versions != null) {
          for (final version in versions) {
            if (version['actualLanguage'] == 'he' && version['text'] != null) {
              final text = version['text'];
              texts.add('--- פרק $chapter ---');
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

    if (mounted) {
      setState(() {
        _loadedText = texts;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
                  Text(
                    'שם הנפטר/ת',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _calculateChapters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('חפש', style: GoogleFonts.rubik(fontSize: 16)),
                      ),
                    ],
                  ),
                  if (_chapters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'תהילים לעילוי נשמת $_displayName:',
                      style: GoogleFonts.rubik(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'פרקים: ${_chapters.join(", ")}',
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
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
                          child: Text(
                            'הכנס את שם הנפטר/ת לקבלת פרקי תהילים',
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3),
                                ),
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
                                  final clean =
                                      TorahTextViewer.stripHtml(segment);
                                  if (clean.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      clean,
                                      style: GoogleFonts.rubik(
                                        fontSize: 24,
                                        height: 2.2,
                                        color: AppColors.darkBrown,
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
