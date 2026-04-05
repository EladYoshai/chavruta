import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../services/sefaria_service.dart';
import '../utils/constants.dart';
import '../widgets/torah_text_viewer.dart';

/// Women's features hub screen - shown for users with gender=נקבה
class WomenScreen extends StatelessWidget {
  const WomenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<AppState>().progress;
    final isMarried = progress.maritalStatus == 'married';

    return Scaffold(
      appBar: AppBar(
        title: const Text('עולם האישה'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                    const Color(0xFF8E24AA).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('👩', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    'תפילות ומצוות לאישה',
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // תפילת חנה - Women's prayers
            _buildFeatureCard(
              context,
              icon: '🙏',
              title: 'תפילת חנה',
              subtitle: 'תפילות מיוחדות לנשים',
              color: const Color(0xFF6A1B9A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TefilatChanaScreen()),
              ),
            ),

            // הפרשת חלה
            _buildFeatureCard(
              context,
              icon: '🍞',
              title: 'הפרשת חלה',
              subtitle: 'נוסח הפרשת חלה מלא',
              color: const Color(0xFF4E342E),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HafrashatChallahScreen()),
              ),
            ),

            // הלכות נידה - only for married women
            if (isMarried) ...[
              _buildFeatureCard(
                context,
                icon: '📖',
                title: 'הלכות טהרת המשפחה',
                subtitle: 'שולחן ערוך יורה דעה',
                color: const Color(0xFF00695C),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NiddahHalachotScreen()),
                ),
              ),
              // מחשבון נידה
              _buildFeatureCard(
                context,
                icon: '📅',
                title: 'מחשבון טהרת המשפחה',
                subtitle: 'חישוב ימי ספירה ומועד טבילה',
                color: const Color(0xFF1565C0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NiddahCalculatorScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// תפילת חנה - Women's prayers collection
class TefilatChanaScreen extends StatefulWidget {
  const TefilatChanaScreen({super.key});

  @override
  State<TefilatChanaScreen> createState() => _TefilatChanaScreenState();
}

class _TefilatChanaScreenState extends State<TefilatChanaScreen> {
  final SefariaService _sefaria = SefariaService();

  // Prayer categories with their Sefaria refs
  static const List<_WomenPrayer> _prayers = [
    _WomenPrayer(
      name: 'תפילת חנה',
      description: 'תפילת חנה מספר שמואל',
      ref: 'I_Samuel.1.10-2.10',
    ),
    _WomenPrayer(
      name: 'תפילה לפני הדלקת נרות',
      description: 'תפילה להדלקת נרות שבת',
      ref: 'Siddur_Sefard,_Blessings,_Shabbat_Candle_Lighting',
    ),
    _WomenPrayer(
      name: 'תפילת הדרך',
      description: 'תפילה לפני יציאה לדרך',
      ref: 'Siddur_Sefard,_Blessings,_Travelers_Prayer',
    ),
    _WomenPrayer(
      name: 'ברכות השחר',
      description: 'ברכות הבוקר',
      ref: 'Siddur_Sefard,_Upon_Arising,_Morning_Blessings',
    ),
    _WomenPrayer(
      name: 'תפילת שמונה עשרה',
      description: 'עמידה - תפילת שחרית',
      ref: 'Siddur_Sefard,_Weekday_Shacharit,_Amidah',
      isComplex: true,
    ),
    _WomenPrayer(
      name: 'נשמת כל חי',
      description: 'תפילת שבת ומועדים',
      ref: 'Siddur_Sefard,_Shabbat_Morning_Services,_Nishmat',
    ),
  ];

  int? _selectedIndex;
  List<String> _loadedText = [];
  bool _isLoading = false;

  Future<void> _loadPrayer(int index) async {
    setState(() {
      _selectedIndex = index;
      _isLoading = true;
      _loadedText = [];
    });

    final prayer = _prayers[index];
    try {
      if (prayer.isComplex) {
        // Complex ref - fetch sub-sections
        final data = await _sefaria.getText(prayer.ref);
        if (data.containsKey('error')) {
          _loadedText = await _fetchAmidahSections(prayer.ref);
        } else {
          _loadedText = _extractText(data);
        }
      } else {
        final data = await _sefaria.getText(prayer.ref);
        _loadedText = _extractText(data);
      }
    } catch (_) {
      _loadedText = ['לא ניתן לטעון את התפילה. נסה שוב מאוחר יותר.'];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAmidahSections(String ref) async {
    final parts = [
      'Patriarchs', 'Divine_Might', 'Holiness_of_God',
      'Knowledge', 'Repentance', 'Forgiveness', 'Redemption',
      'Healing', 'Prosperity', 'Gathering_the_Exiles', 'Justice',
      'Against_Enemies', 'The_Righteous', 'Rebuilding_Jerusalem',
      'Kingdom_of_David', 'Response_to_Prayer', 'Temple_Service',
      'Thanksgiving', 'Peace', 'Concluding_Passage',
    ];
    final result = <String>[];
    for (final part in parts) {
      try {
        final data = await _sefaria.getText('$ref,_$part');
        if (!data.containsKey('error')) {
          result.addAll(_extractText(data));
        }
      } catch (_) {}
    }
    return result;
  }

  List<String> _extractText(Map<String, dynamic> data) {
    final versions = data['versions'] as List?;
    if (versions == null) return [];
    for (final version in versions) {
      if (version['actualLanguage'] == 'he' && version['text'] != null) {
        final text = version['text'];
        if (text is List) return _flatten(text);
        if (text is String) return [text];
      }
    }
    return [];
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
        title: const Text('תפילת חנה'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _selectedIndex == null
            ? _buildPrayerList()
            : _buildPrayerView(),
      ),
    );
  }

  Widget _buildPrayerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prayers.length,
      itemBuilder: (context, index) {
        final prayer = _prayers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _loadPrayer(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book,
                      color: Color(0xFF6A1B9A), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.name,
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        Text(
                          prayer.description,
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios,
                      size: 14, color: Color(0xFF6A1B9A)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerView() {
    final prayer = _prayers[_selectedIndex!];
    return Column(
      children: [
        // Back to list button
        Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedIndex = null;
              _loadedText = [];
            }),
            child: Row(
              children: [
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 6),
                Text(
                  'חזרה לרשימת התפילות',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Prayer title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            prayer.name,
            style: GoogleFonts.rubik(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6A1B9A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Prayer text
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF6A1B9A)),
                      SizedBox(height: 16),
                      Text('...טוען תפילה'),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _loadedText.map((segment) {
                          final clean = TorahTextViewer.stripHtml(segment);
                          if (clean.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              clean,
                              style: GoogleFonts.rubik(
                                fontSize: 22,
                                height: 2.0,
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
    );
  }
}

class _WomenPrayer {
  final String name;
  final String description;
  final String ref;
  final bool isComplex;

  const _WomenPrayer({
    required this.name,
    required this.description,
    required this.ref,
    this.isComplex = false,
  });
}

/// הפרשת חלה - Full nusach
class HafrashatChallahScreen extends StatefulWidget {
  const HafrashatChallahScreen({super.key});

  @override
  State<HafrashatChallahScreen> createState() => _HafrashatChallahScreenState();
}

class _HafrashatChallahScreenState extends State<HafrashatChallahScreen> {
  final SefariaService _sefaria = SefariaService();
  List<String> _text = [];
  bool _isLoading = true;

  // Nusach-specific refs for hafrashat challah
  static const _challahRefs = {
    'sefard': 'Siddur_Sefard,_Blessings,_Separating_Challah',
    'edot_hamizrach': 'Siddur_Edot_HaMizrach,_Assorted_Blessings_and_Prayers,_Separating_Hallah',
    'ashkenaz': 'Siddur_Sefard,_Blessings,_Separating_Challah', // fallback to sefard
  };

  @override
  void initState() {
    super.initState();
    _loadText();
  }

  Future<void> _loadText() async {
    final nusach = context.read<AppState>().progress.nusach;
    final ref = _challahRefs[nusach] ?? _challahRefs['sefard']!;

    try {
      final data = await _sefaria.getText(ref);
      final versions = data['versions'] as List?;
      if (versions != null) {
        for (final version in versions) {
          if (version['actualLanguage'] == 'he' && version['text'] != null) {
            final text = version['text'];
            if (text is List) {
              _text = _flatten(text);
            } else if (text is String) {
              _text = [text];
            }
            break;
          }
        }
      }
    } catch (_) {
      _text = ['לא ניתן לטעון את הנוסח. נסה שוב מאוחר יותר.'];
    }

    if (mounted) setState(() => _isLoading = false);
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
        title: const Text('הפרשת חלה'),
        backgroundColor: const Color(0xFF4E342E),
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
                  CircularProgressIndicator(color: Color(0xFF4E342E)),
                  SizedBox(height: 16),
                  Text('...טוען נוסח הפרשת חלה'),
                ],
              ),
            )
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4E342E).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('🍞', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(
                          'נוסח הפרשת חלה',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4E342E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'מפרישים חלה מעיסה שיש בה לפחות 1.666 ק"ג קמח',
                          style: GoogleFonts.rubik(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Text
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _text.map((segment) {
                        final clean = TorahTextViewer.stripHtml(segment);
                        if (clean.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            clean,
                            style: GoogleFonts.rubik(
                              fontSize: 22,
                              height: 2.0,
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
    );
  }
}

/// הלכות נידה - Discreet halacha reference (SA YD 183-200)
class NiddahHalachotScreen extends StatefulWidget {
  const NiddahHalachotScreen({super.key});

  @override
  State<NiddahHalachotScreen> createState() => _NiddahHalachotScreenState();
}

class _NiddahHalachotScreenState extends State<NiddahHalachotScreen> {
  final SefariaService _sefaria = SefariaService();

  // SA YD simanim 183-200 - main topics of hilchot niddah
  static const List<_NiddahSiman> _simanim = [
    _NiddahSiman(183, 'איסור נידה'),
    _NiddahSiman(184, 'דם מחמת תשמיש'),
    _NiddahSiman(185, 'וסתות'),
    _NiddahSiman(186, 'סוגי וסתות'),
    _NiddahSiman(187, 'מראות דמים'),
    _NiddahSiman(188, 'בדיקת מראות'),
    _NiddahSiman(189, 'הפסק טהרה'),
    _NiddahSiman(190, 'ספירת שבעה נקיים'),
    _NiddahSiman(191, 'חפיפה'),
    _NiddahSiman(192, 'טבילה'),
    _NiddahSiman(193, 'חציצה'),
    _NiddahSiman(194, 'דיני מקוה'),
    _NiddahSiman(195, 'הרחקות'),
    _NiddahSiman(196, 'הרחקות נוספות'),
    _NiddahSiman(197, 'דם בתולים'),
    _NiddahSiman(198, 'דם קושי'),
    _NiddahSiman(199, 'יולדת'),
    _NiddahSiman(200, 'דינים שונים'),
  ];

  int? _selectedSiman;
  List<String> _simanText = [];
  bool _isLoading = false;

  Future<void> _loadSiman(int index) async {
    setState(() {
      _selectedSiman = index;
      _isLoading = true;
      _simanText = [];
    });

    final siman = _simanim[index];
    try {
      final ref = 'Shulchan_Arukh,_Yoreh_De\'ah.${siman.number}';
      final data = await _sefaria.getText(ref);
      final versions = data['versions'] as List?;
      if (versions != null) {
        for (final version in versions) {
          if (version['actualLanguage'] == 'he' && version['text'] != null) {
            final text = version['text'];
            if (text is List) {
              _simanText = _flatten(text);
            } else if (text is String) {
              _simanText = [text];
            }
            break;
          }
        }
      }
    } catch (_) {
      _simanText = ['לא ניתן לטעון את ההלכה. נסה שוב מאוחר יותר.'];
    }

    if (mounted) setState(() => _isLoading = false);
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
        title: const Text('הלכות טהרת המשפחה'),
        backgroundColor: const Color(0xFF00695C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            if (_selectedSiman != null) {
              setState(() {
                _selectedSiman = null;
                _simanText = [];
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _selectedSiman == null ? _buildSimanList() : _buildSimanView(),
      ),
    );
  }

  Widget _buildSimanList() {
    return Column(
      children: [
        // Disclaimer
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'הלכות אלו מוצגות לעיון בלבד. לשאלות מעשיות יש לפנות לרב מוסמך.',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _simanim.length,
            itemBuilder: (context, index) {
              final siman = _simanim[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => _loadSiman(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00695C).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00695C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${siman.number}',
                              style: GoogleFonts.rubik(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00695C),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'סימן ${siman.number} - ${siman.topic}',
                            style: GoogleFonts.rubik(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios,
                            size: 14, color: Color(0xFF00695C)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimanView() {
    final siman = _simanim[_selectedSiman!];
    return _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF00695C)),
                SizedBox(height: 16),
                Text('...טוען הלכה'),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'שו"ע יו"ד סימן ${siman.number} - ${siman.topic}',
                  style: GoogleFonts.rubik(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00695C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Text
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _simanText.asMap().entries.map((entry) {
                    final clean = TorahTextViewer.stripHtml(entry.value);
                    if (clean.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'סעיף ${_hebrewNumber(entry.key + 1)}',
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00695C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clean,
                            style: GoogleFonts.rubik(
                              fontSize: 22,
                              height: 2.0,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
  }

  String _hebrewNumber(int n) {
    const letters = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט',
      'י', 'יא', 'יב', 'יג', 'יד', 'טו', 'טז', 'יז', 'יח', 'יט',
      'כ', 'כא', 'כב', 'כג', 'כד', 'כה', 'כו', 'כז', 'כח', 'כט',
      'ל', 'לא', 'לב', 'לג', 'לד', 'לה', 'לו', 'לז', 'לח', 'לט',
      'מ'];
    return n < letters.length ? letters[n] : '$n';
  }
}

class _NiddahSiman {
  final int number;
  final String topic;
  const _NiddahSiman(this.number, this.topic);
}

/// מחשבון נידה - Niddah calculator for tracking clean days and mikvah date
class NiddahCalculatorScreen extends StatefulWidget {
  const NiddahCalculatorScreen({super.key});

  @override
  State<NiddahCalculatorScreen> createState() => _NiddahCalculatorScreenState();
}

class _NiddahCalculatorScreenState extends State<NiddahCalculatorScreen> {
  DateTime? _startDate;
  bool _showResults = false;

  // Standard calculation:
  // Minimum 5 days of niddah
  // Then hefsek tahara
  // Then 7 clean days (shivah nekiim)
  // Mikvah night = evening after 7th clean day

  DateTime get _hefsekDate {
    // Hefsek tahara on day 5 (4 days after start)
    return _startDate!.add(const Duration(days: 4));
  }

  DateTime get _firstCleanDay {
    // First clean day = day after hefsek
    return _hefsekDate.add(const Duration(days: 1));
  }

  DateTime get _mikvahNight {
    // Mikvah on evening after 7th clean day (6 days after first clean day)
    return _firstCleanDay.add(const Duration(days: 6));
  }

  String _formatDate(DateTime date) {
    const dayNames = ['יום ראשון', 'יום שני', 'יום שלישי', 'יום רביעי',
      'יום חמישי', 'יום שישי', 'שבת'];
    final dayName = dayNames[date.weekday % 7];
    return '$dayName ${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מחשבון טהרת המשפחה'),
        backgroundColor: const Color(0xFF1565C0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'מחשבון זה לעיון בלבד ומבוסס על חישוב סטנדרטי. לשאלות מעשיות יש לפנות לרב מוסמך.',
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date picker
            Text(
              'תאריך תחילת הווסת',
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) {
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF1565C0),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                    _showResults = true;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Color(0xFF1565C0), size: 22),
                    const SizedBox(width: 12),
                    Text(
                      _startDate != null
                          ? _formatDate(_startDate!)
                          : 'בחרי תאריך',
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        color: _startDate != null
                            ? AppColors.darkBrown
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showResults && _startDate != null) ...[
              const SizedBox(height: 24),
              // Results
              _buildResultCard(
                icon: '🔴',
                title: 'ימי נידה (מינימום 5 ימים)',
                subtitle: '${_formatDate(_startDate!)} - ${_formatDate(_hefsekDate)}',
                color: Colors.red.shade700,
              ),
              _buildResultCard(
                icon: '🟡',
                title: 'הפסק טהרה',
                subtitle: 'ערב ${_formatDate(_hefsekDate)}',
                detail: 'לפני השקיעה של יום ה-5',
                color: Colors.orange.shade700,
              ),
              _buildResultCard(
                icon: '🟢',
                title: 'שבעה נקיים',
                subtitle: '${_formatDate(_firstCleanDay)} - ${_formatDate(_mikvahNight)}',
                detail: 'בדיקה בוקר וערב ביום הראשון והשביעי, ולפחות פעם אחת באמצע',
                color: Colors.green.shade700,
              ),
              _buildResultCard(
                icon: '🏊‍♀️',
                title: 'ליל טבילה',
                subtitle: 'מוצאי ${_formatDate(_mikvahNight)}',
                detail: 'לאחר צאת הכוכבים',
                color: const Color(0xFF1565C0),
                highlighted: true,
              ),

              const SizedBox(height: 16),
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'סה"כ ${_mikvahNight.difference(_startDate!).inDays + 1} ימים',
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '5 ימי נידה + 7 נקיים = 12 ימים מינימום',
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String icon,
    required String title,
    required String subtitle,
    String? detail,
    required Color color,
    bool highlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: highlighted ? 0.4 : 0.15),
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    color: AppColors.darkBrown,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
