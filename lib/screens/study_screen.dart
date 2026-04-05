import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../models/study_section.dart';
import '../services/sefaria_service.dart';
import '../utils/constants.dart';
import '../widgets/torah_text_viewer.dart';
import '../services/daf_summary_service.dart';
// DafSummaryService is initialized once in main.dart

class StudyScreen extends StatefulWidget {
  final StudySection section;

  const StudyScreen({super.key, required this.section});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final SefariaService _sefaria = SefariaService();
  List<TextBlock> _blocks = [];
  String _hebrewRef = '';
  bool _isLoading = true;
  String? _errorMessage;
  bool _showCompletionDialog = false;
  String? _currentGemaraRef; // Track current daf for navigation

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      switch (widget.section.type) {
        case StudySectionType.tehillim:
          await _loadTehillim();
        case StudySectionType.shnayimMikra:
          await _loadShnayimMikra();
        case StudySectionType.halacha:
          await _loadHalacha();
        case StudySectionType.mishna:
          await _loadMishna();
        case StudySectionType.emunah:
          await _loadEmunah();
        case StudySectionType.gemara:
          await _loadGemara();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'לא ניתן לטעון את התוכן\n$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTehillim() async {
    final jewishDate = JewishDate();
    final dayOfMonth = jewishDate.getJewishDayOfMonth();

    // Fetch each chapter individually for clear perek headers
    final chapters = await _sefaria.getDailyTehillimByChapter(dayOfMonth);

    if (chapters.isEmpty) {
      // Fallback to single fetch
      final data = await _sefaria.getDailyTehillim(dayOfMonth);
      _hebrewRef = data['heRef']?.toString() ?? 'תהילים יומי';
      _blocks = [
        TextBlock(
          label: 'תהילים - יום $dayOfMonth לחודש',
          segments: _extractHebrewText(data),
          labelColor: AppColors.deepBlue,
        ),
      ];
      return;
    }

    _hebrewRef = 'תהילים - יום $dayOfMonth לחודש';
    _blocks = chapters.map((ch) {
      final chapterNum = ch['chapter'] as int;
      final heRef = ch['heRef'] as String;
      final text = ch['text'] as List<String>;

      // Hebrew chapter number
      return TextBlock(
        label: '📖 פרק $chapterNum - $heRef',
        segments: text,
        isBold: false,
        labelColor: AppColors.deepBlue,
      );
    }).toList();
  }

  static const _aliyahNames = [
    '', // 0 - unused
    'ראשון',
    'שני',
    'שלישי',
    'רביעי',
    'חמישי',
    'שישי',
    'שביעי',
  ];

  Future<void> _loadShnayimMikra() async {
    final calendar = await _sefaria.getCalendarInfo();

    // Determine which aliyah based on day of week
    // Sunday=1 (rishon), Monday=2 (sheni), ... Friday=6 (shishi), Shabbat=whole parsha
    final now = DateTime.now();
    final jewishDay = now.weekday % 7; // 0=Sunday
    final aliyahIndex = jewishDay == 6 ? 0 : jewishDay + 1; // Shabbat = whole parsha

    String aliyahRef;
    String aliyahLabel;

    if (aliyahIndex > 0 && aliyahIndex <= 7 && calendar.aliyot.length >= aliyahIndex) {
      // Use the specific aliyah for today
      aliyahRef = calendar.aliyot[aliyahIndex - 1];
      aliyahLabel = 'עליית ${_aliyahNames[aliyahIndex]}';
      _hebrewRef = '${calendar.parshaHeName} - $aliyahLabel';
    } else {
      // Shabbat or no aliyot data - use full parsha
      aliyahRef = calendar.parshaRef;
      aliyahLabel = 'כל הפרשה';
      _hebrewRef = calendar.parshaHeName;
    }

    final texts = await _sefaria.getShnayimMikra(aliyahRef);

    _blocks = [
      TextBlock(
        label: '📖 מקרא - ${calendar.parshaHeName} ($aliyahLabel)',
        segments: texts['mikra'] ?? [],
        isBold: true,
        labelColor: AppColors.darkGold,
      ),
      if ((texts['onkelos'] ?? []).isNotEmpty)
        TextBlock(
          label: '📜 תרגום אונקלוס',
          segments: texts['onkelos'] ?? [],
          isBold: false,
          labelColor: const Color(0xFF5D4037),
        ),
      if ((texts['rashi'] ?? []).isNotEmpty)
        TextBlock(
          label: '🔍 פירוש רש"י',
          segments: texts['rashi'] ?? [],
          isBold: false,
          labelColor: const Color(0xFF1565C0),
        ),
    ];
  }

  Future<void> _loadHalacha() async {
    final isSefardi = context.read<AppState>().progress.isSefardi;
    final calendar = await _sefaria.getCalendarInfo();

    if (calendar.halachaYomitRef.isNotEmpty) {
      final texts = await _sefaria.getHalachaYomit(
        calendar.halachaYomitRef,
        useSefardi: isSefardi,
      );
      _hebrewRef = (texts['heRef']?.isNotEmpty == true)
          ? texts['heRef']!.first
          : 'הלכה יומית';

      final commentaryLabel = isSefardi
          ? '📘 כף החיים - ביאור והסבר'
          : '📘 משנה ברורה - ביאור והסבר';

      _blocks = [
        TextBlock(
          label: '⚖️ שולחן ערוך',
          segments: texts['shulchan_aruch'] ?? [],
          isBold: true,
          labelColor: AppColors.success,
        ),
        if ((texts['commentary'] ?? []).isNotEmpty)
          TextBlock(
            label: commentaryLabel,
            segments: texts['commentary'] ?? [],
            isBold: false,
            labelColor: const Color(0xFF2E7D32),
          ),
      ];
    } else {
      final fallbackRef = isSefardi
          ? 'Kaf_HaChayim_on_Shulchan_Arukh,_Orach_Chayim.1'
          : 'Mishnah_Berurah.1';
      final fallbackLabel = isSefardi ? 'כף החיים' : 'משנה ברורה';
      final data = await _sefaria.getText(fallbackRef);
      _hebrewRef = data['heRef']?.toString() ?? fallbackLabel;
      _blocks = [
        TextBlock(
          label: '📘 $fallbackLabel',
          segments: _extractHebrewText(data),
          labelColor: AppColors.success,
        ),
      ];
    }
  }

  Future<void> _loadMishna() async {
    final calendar = await _sefaria.getCalendarInfo();

    if (calendar.mishnaYomitRef.isEmpty) {
      _hebrewRef = 'משנה יומית';
      _blocks = [
        TextBlock(
          label: '📖 משנה',
          segments: ['לא נמצאה משנה יומית להיום'],
          labelColor: const Color(0xFF00838F),
        ),
      ];
      return;
    }

    final data = await _sefaria.getMishnaYomit(calendar.mishnaYomitRef);
    _hebrewRef = data['heRef']?.toString() ?? 'משנה יומית';

    final mishna = data['mishna'] as List<String>? ?? [];
    final bartenura = data['bartenura'] as List<String>? ?? [];

    _blocks = [
      TextBlock(
        label: '📖 משנה - $_hebrewRef',
        segments: mishna,
        isBold: true,
        labelColor: const Color(0xFF00838F),
      ),
      if (bartenura.isNotEmpty)
        TextBlock(
          label: '🔍 פירוש ברטנורא',
          segments: bartenura,
          isBold: false,
          labelColor: const Color(0xFF00695C),
        ),
    ];
  }

  Future<void> _loadEmunah() async {
    final calendar = await _sefaria.getCalendarInfo();

    String tanyaRef;
    if (calendar.tanyaYomiRef.isNotEmpty) {
      tanyaRef = calendar.tanyaYomiRef.replaceAll(' ', '_');
    } else {
      // Fallback: one chapter per day (53 chapters in Likkutei Amarim)
      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1;
      final chapter = (dayOfYear % 53) + 1;
      tanyaRef = 'Tanya,_Part_I;_Likkutei_Amarim.$chapter';
    }

    // Extract chapter ref (e.g., "Tanya,_Part_I;_Likkutei_Amarim.41.5" -> "...41")
    final chapterMatch = RegExp(r'^(.+\.\d+)\.\d+$').firstMatch(tanyaRef);
    final chapterRef = chapterMatch?.group(1) ?? tanyaRef;

    // Fetch the full chapter (the daily segment is usually just 1 paragraph)
    final chapterData = await _sefaria.getText(chapterRef);
    final chapterHeRef = chapterData['heRef']?.toString() ?? 'תניא יומי';
    final chapterText = _extractHebrewText(chapterData);

    _hebrewRef = chapterHeRef;

    _blocks = [
      TextBlock(
        label: '📖 תניא יומי - $chapterHeRef',
        segments: chapterText,
        isBold: false,
        labelColor: const Color(0xFF6A1B9A),
      ),
    ];
  }

  Future<void> _loadGemara({String? overrideRef}) async {
    String gemaraRef;
    if (overrideRef != null) {
      gemaraRef = overrideRef;
    } else {
      final calendar = await _sefaria.getCalendarInfo();
      gemaraRef = calendar.dafYomiRef;
      if (gemaraRef.isEmpty) gemaraRef = 'Berakhot.2a';
    }

    _currentGemaraRef = gemaraRef;

    // Get both amudim for the daf
    final amudim = _sefaria.getDafAmudim(gemaraRef);

    _blocks = [];
    String mainHeRef = '';

    // Fetch each amud with all commentaries
    for (final amudRef in amudim) {
      final data = await _sefaria.getAmudFull(amudRef);
      final heRef = data['heRef']?.toString() ?? amudRef;
      if (mainHeRef.isEmpty) mainHeRef = heRef;

      final gemara = data['gemara'] as List<String>? ?? [];
      final rashi = data['rashi'] as List<String>? ?? [];
      final tosafot = data['tosafot'] as List<String>? ?? [];
      final steinsaltz = data['steinsaltz'] as List<String>? ?? [];

      final amudLabel = amudRef.endsWith('a') ? 'ע"א' : 'ע"ב';

      if (gemara.isNotEmpty) {
        // Gemara text for this amud
        _blocks.add(TextBlock(
          label: '📚 גמרא - $heRef ($amudLabel)',
          segments: gemara,
          isBold: true,
          labelColor: const Color(0xFFC62828),
        ));

        // Rashi on this amud
        if (rashi.isNotEmpty) {
          _blocks.add(TextBlock(
            label: '🔍 רש"י - $amudLabel',
            segments: rashi,
            isBold: false,
            labelColor: const Color(0xFF1565C0),
          ));
        }

        // Tosafot on this amud
        if (tosafot.isNotEmpty) {
          _blocks.add(TextBlock(
            label: '💬 תוספות - $amudLabel',
            segments: tosafot,
            isBold: false,
            labelColor: const Color(0xFF4E342E),
          ));
        }

        // Steinsaltz on this amud
        if (steinsaltz.isNotEmpty) {
          _blocks.add(TextBlock(
            label: '📝 ביאור שטיינזלץ - $amudLabel',
            segments: steinsaltz,
            isBold: false,
            labelColor: const Color(0xFF00695C),
          ));
        }
      }
    }

    // Summary and deep dive at the END (covers the full daf)
    final preGenSummary = DafSummaryService.getSummary(gemaraRef);
    final preGenDeepDive = DafSummaryService.getDeepDive(gemaraRef);

    if (preGenSummary != null && preGenSummary.isNotEmpty) {
      _blocks.add(TextBlock(
        label: '📝 סיכום הדף היומי',
        segments: [preGenSummary],
        isBold: false,
        labelColor: const Color(0xFF006064),
      ));
    }

    if (preGenDeepDive != null && preGenDeepDive.isNotEmpty) {
      _blocks.add(TextBlock(
        label: '💎 הרחבות - ביאור הראשונים בשפה פשוטה',
        segments: [preGenDeepDive],
        isBold: false,
        labelColor: const Color(0xFF4E342E),
      ));
    }

    _hebrewRef = mainHeRef;
  }

  /// Extract the daf number from a ref (handles "Menachot.83", "Menachot.83a", "Menachot.83b")
  int? _getDafNum(String ref) {
    final match = RegExp(r'\.(\d+)[ab]?$').firstMatch(ref);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  String? _getMasechet(String ref) {
    final match = RegExp(r'^(.+)\.\d+[ab]?$').firstMatch(ref);
    return match?.group(1);
  }

  /// Get the previous full daf ref (navigate by daf, not amud)
  String? _getPrevDaf(String ref) {
    final masechet = _getMasechet(ref);
    final num = _getDafNum(ref);
    if (masechet == null || num == null || num <= 2) return null;
    return '$masechet.${num - 1}';
  }

  /// Get the next full daf ref
  String? _getNextDaf(String ref) {
    final masechet = _getMasechet(ref);
    final num = _getDafNum(ref);
    if (masechet == null || num == null) return null;
    return '$masechet.${num + 1}';
  }

  /// Navigate to a different daf
  void _navigateToDaf(String ref) {
    setState(() {
      _isLoading = true;
      _blocks = [];
      _errorMessage = null;
    });
    _loadGemara(overrideRef: ref).then((_) {
      if (mounted) setState(() => _isLoading = false);
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'לא ניתן לטעון את הדף\n$e';
          _isLoading = false;
        });
      }
    });
  }

  List<String> _extractHebrewText(Map<String, dynamic> data) {
    final versions = data['versions'] as List?;
    if (versions == null) return [];
    for (final version in versions) {
      if (version['actualLanguage'] == 'he' && version['text'] != null) {
        final text = version['text'];
        if (text is List) return _flattenText(text);
        if (text is String) return [text];
      }
    }
    return [];
  }

  List<String> _flattenText(List<dynamic> textList) {
    final result = <String>[];
    for (final item in textList) {
      if (item is String && item.isNotEmpty) {
        result.add(item);
      } else if (item is List) {
        result.addAll(_flattenText(item));
      }
    }
    return result;
  }

  void _markComplete() {
    final appState = context.read<AppState>();
    appState.completeSection(widget.section.key, widget.section.zuzimReward);

    setState(() {
      _showCompletionDialog = true;
    });

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                AppStrings.wellDone,
                style: GoogleFonts.rubik(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'סיימת את ${widget.section.title}',
                style: GoogleFonts.rubik(fontSize: 16, color: AppColors.darkBrown),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.section.zuzimReward} ${AppStrings.zuzim}',
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                'חזרה לתפריט',
                style: GoogleFonts.rubik(fontSize: 16, color: AppColors.deepBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.title),
        backgroundColor: widget.section.color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Prev/Next daf navigation for Gemara
            if (widget.section.type == StudySectionType.gemara &&
                _currentGemaraRef != null &&
                !_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_getPrevDaf(_currentGemaraRef!) != null)
                        TextButton.icon(
                          onPressed: () =>
                              _navigateToDaf(_getPrevDaf(_currentGemaraRef!)!),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(
                            'דף קודם',
                            style: GoogleFonts.rubik(fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: widget.section.color,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        _hebrewRef,
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _navigateToDaf(_getNextDaf(_currentGemaraRef!)!),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(
                          'דף הבא',
                          style: GoogleFonts.rubik(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: widget.section.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: TorahTextViewer(
                title: widget.section.title,
                hebrewRef: _hebrewRef,
                blocks: _blocks,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
              ),
            ),
            const SizedBox(height: 16),
            if (!_isLoading && _errorMessage == null && !_showCompletionDialog)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _markComplete,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'סיימתי ללמוד! +${widget.section.zuzimReward} 🪙',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.section.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
