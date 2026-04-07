import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sefaria_service.dart';
import '../utils/constants.dart';
import '../widgets/torah_text_viewer.dart';

class TehillimScreen extends StatelessWidget {
  const TehillimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('תהילים'),
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
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('📖', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    'ספר תהילים',
                    style: GoogleFonts.rubik(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  Text(
                    'ק"נ פרקים',
                    style: GoogleFonts.rubik(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Full Tehillim (all 150 chapters divided into 5 books)
            _buildOption(
              context,
              icon: '📚',
              title: 'ספר תהילים מלא',
              subtitle: 'כל ק"נ פרקים מחולקים לחמשה ספרים',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _FullTehillimScreen())),
            ),

            // Choose chapter
            _buildOption(
              context,
              icon: '🔢',
              title: 'בחירת פרק',
              subtitle: 'בחר פרק ספציפי לקריאה',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _ChapterPickerScreen())),
            ),

            // Tikkun HaKlali
            _buildOption(
              context,
              icon: '✨',
              title: 'התיקון הכללי',
              subtitle: 'עשרה פרקי תהילים של רבי נחמן מברסלב',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _TikkunKlaliScreen())),
            ),

            // Random chapter
            _buildOption(
              context,
              icon: '🎲',
              title: 'פרק אקראי',
              subtitle: 'פרק תהילים אקראי',
              onTap: () {
                final chapter = Random().nextInt(150) + 1;
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => _TehillimChapterScreen(chapter: chapter)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
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
            border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.rubik(
                            fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
                    Text(subtitle,
                        style: GoogleFonts.rubik(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF1565C0)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Full Tehillim - 5 books
// ==========================================

class _FullTehillimScreen extends StatelessWidget {
  const _FullTehillimScreen();

  // 5 books of Tehillim
  static const _books = [
    ('ספר ראשון', 1, 41),
    ('ספר שני', 42, 72),
    ('ספר שלישי', 73, 89),
    ('ספר רביעי', 90, 106),
    ('ספר חמישי', 107, 150),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ספר תהילים מלא'),
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
            for (final (bookName, start, end) in _books) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  '$bookName (פרקים $start-$end)',
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1565C0),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(end - start + 1, (i) {
                  final chapter = start + i;
                  return GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => _TehillimChapterScreen(chapter: chapter))),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Chapter picker
// ==========================================

class _ChapterPickerScreen extends StatefulWidget {
  const _ChapterPickerScreen();

  @override
  State<_ChapterPickerScreen> createState() => _ChapterPickerScreenState();
}

class _ChapterPickerScreenState extends State<_ChapterPickerScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('בחירת פרק'),
        backgroundColor: const Color(0xFF1565C0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('הכנס מספר פרק (1-150)',
                  style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkBrown)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      style: GoogleFonts.rubik(fontSize: 20),
                      decoration: InputDecoration(
                        hintText: '1-150',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final ch = int.tryParse(_controller.text) ?? 0;
                      if (ch >= 1 && ch <= 150) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => _TehillimChapterScreen(chapter: ch)));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('פתח', style: GoogleFonts.rubik(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Tikkun HaKlali - 10 specific chapters
// ==========================================

class _TikkunKlaliScreen extends StatefulWidget {
  const _TikkunKlaliScreen();

  @override
  State<_TikkunKlaliScreen> createState() => _TikkunKlaliScreenState();
}

class _TikkunKlaliScreenState extends State<_TikkunKlaliScreen> {
  final SefariaService _sefaria = SefariaService();
  // The 10 chapters of Tikkun HaKlali (Rabbi Nachman of Breslov)
  static const _chapters = [16, 32, 41, 42, 59, 77, 90, 105, 137, 150];
  List<String> _texts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final texts = <String>[];
    for (final ch in _chapters) {
      texts.add('--- פרק $ch ---');
      try {
        final data = await _sefaria.getText('Psalms.$ch');
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
    if (mounted) setState(() { _texts = texts; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('התיקון הכללי'),
        backgroundColor: const Color(0xFF1565C0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'עשרה פרקי תהילים שתיקן רבי נחמן מברסלב:\nט"ז, ל"ב, מ"א, מ"ב, נ"ט, ע"ז, צ\', ק"ה, קל"ז, ק"נ',
                      style: GoogleFonts.rubik(fontSize: 14, color: const Color(0xFF1565C0), height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _texts.map((segment) {
                        if (segment.startsWith('---')) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              segment.replaceAll('---', '').trim(),
                              style: GoogleFonts.rubik(
                                fontSize: 18, fontWeight: FontWeight.bold,
                                color: const Color(0xFF1565C0)),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final clean = TorahTextViewer.stripHtml(segment);
                        if (clean.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            clean,
                            style: GoogleFonts.frankRuhlLibre(
                              fontSize: 22, height: 2.0, color: const Color(0xFF2C1810)),
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
// Single Tehillim chapter
// ==========================================

class _TehillimChapterScreen extends StatefulWidget {
  final int chapter;
  const _TehillimChapterScreen({required this.chapter});

  @override
  State<_TehillimChapterScreen> createState() => _TehillimChapterScreenState();
}

class _TehillimChapterScreenState extends State<_TehillimChapterScreen> {
  final SefariaService _sefaria = SefariaService();
  List<String> _text = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _sefaria.getText('Psalms.${widget.chapter}');
      final versions = data['versions'] as List?;
      if (versions != null) {
        for (final version in versions) {
          if (version['actualLanguage'] == 'he' && version['text'] != null) {
            final text = version['text'];
            if (text is List) {
              for (final item in text) {
                if (item is String && item.isNotEmpty) _text.add(item);
                if (item is List) {
                  for (final sub in item) {
                    if (sub is String && sub.isNotEmpty) _text.add(sub);
                  }
                }
              }
            }
            break;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('תהילים פרק ${widget.chapter}'),
        backgroundColor: const Color(0xFF1565C0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Navigate to prev/next chapter
          if (widget.chapter > 1)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => _TehillimChapterScreen(chapter: widget.chapter - 1))),
            ),
          if (widget.chapter < 150)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => _TehillimChapterScreen(chapter: widget.chapter + 1))),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
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
                        Center(
                          child: Text(
                            'פרק ${widget.chapter}',
                            style: GoogleFonts.rubik(
                              fontSize: 20, fontWeight: FontWeight.bold,
                              color: const Color(0xFF1565C0)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._text.asMap().entries.map((entry) {
                          final clean = TorahTextViewer.stripHtml(entry.value);
                          if (clean.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${_hebrewNum(entry.key + 1)} $clean',
                              style: GoogleFonts.frankRuhlLibre(
                                fontSize: 22, height: 2.0, color: const Color(0xFF2C1810)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _hebrewNum(int n) {
    const letters = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט',
      'י', 'יא', 'יב', 'יג', 'יד', 'טו', 'טז', 'יז', 'יח', 'יט',
      'כ', 'כא', 'כב', 'כג', 'כד', 'כה', 'כו', 'כז', 'כח', 'כט',
      'ל', 'לא', 'לב', 'לג', 'לד', 'לה', 'לו', 'לז', 'לח', 'לט', 'מ'];
    return n < letters.length ? '(${letters[n]})' : '($n)';
  }
}
