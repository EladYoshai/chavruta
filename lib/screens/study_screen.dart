import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../models/study_section.dart';
import '../services/sefaria_service.dart';
import '../utils/constants.dart';
import '../widgets/torah_text_viewer.dart';
import '../services/bookmark_service.dart';
import '../services/daf_summary_service.dart';
// DafSummaryService is initialized once in main.dart

class StudyScreen extends StatefulWidget {
  final StudySection section;
  final String? initialRef; // For bookmark navigation

  const StudyScreen({super.key, required this.section, this.initialRef});

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

  // Structured gemara data for tabbed UI
  Map<String, List<String>> _gemaraAmudA = {}; // gemara, rashi, tosafot, steinsaltz
  Map<String, List<String>> _gemaraAmudB = {};
  String? _dafSummary;
  String? _dafDeepDive;
  int _selectedAmudTab = 0; // 0=amud a, 1=amud b, 2=summary, 3=deep dive
  int _selectedCommentaryTab = 0; // 0=gemara, 1=rashi, 2=tosafot, 3=steinsaltz

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
        case StudySectionType.rambam:
          await _loadRambam();
        case StudySectionType.shmiratHalashon:
          await _loadShmiratHalashon();
        case StudySectionType.pirkeiAvot:
          await _loadPirkeiAvot();
        case StudySectionType.nachYomi:
          await _loadNachYomi();
        case StudySectionType.penineiHalacha:
          await _loadPenineiHalacha();
        case StudySectionType.gemara:
          await _loadGemara(overrideRef: widget.initialRef);
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

    final mikra = texts['mikra'] ?? [];
    final onkelos = texts['onkelos'] ?? [];
    final rashi = texts['rashi'] ?? [];

    // Build שניים מקרא ואחד תרגום: per pasuk - mikra twice, then targum, then rashi
    _blocks = [];
    _blocks.add(TextBlock(
      label: '📖 ${calendar.parshaHeName} - $aliyahLabel',
      segments: ['שניים מקרא ואחד תרגום'],
      isBold: true,
      labelColor: AppColors.darkGold,
    ));

    for (int i = 0; i < mikra.length; i++) {
      final pasukNum = i + 1;
      final pasukSegments = <String>[];

      // מקרא - פעם ראשונה
      if (i < mikra.length) pasukSegments.add(mikra[i]);
      // מקרא - פעם שנייה
      if (i < mikra.length) pasukSegments.add(mikra[i]);
      // תרגום אונקלוס
      if (i < onkelos.length && onkelos[i].isNotEmpty) {
        pasukSegments.add('תרגום: ${onkelos[i]}');
      }
      // רש"י (may be a list of comments per pasuk)
      if (i < rashi.length && rashi[i].isNotEmpty) {
        pasukSegments.add('רש"י: ${rashi[i]}');
      }

      _blocks.add(TextBlock(
        label: 'פסוק $pasukNum',
        segments: pasukSegments,
        isBold: false,
        labelColor: const Color(0xFF5D4037),
      ));
    }
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

  Future<void> _loadRambam() async {
    final calendar = await _sefaria.getCalendarInfo();
    final ref = calendar.rambamYomiRef.isNotEmpty
        ? calendar.rambamYomiRef
        : 'Mishneh_Torah,_Reading_the_Shema.1';

    final data = await _sefaria.getText(ref);
    _hebrewRef = data['heRef']?.toString() ?? 'רמב"ם יומי';
    final text = _extractHebrewText(data);

    _blocks = [
      TextBlock(
        label: '📚 רמב"ם יומי - $_hebrewRef',
        segments: text,
        isBold: false,
        labelColor: const Color(0xFF1565C0),
      ),
    ];
  }

  Future<void> _loadShmiratHalashon() async {
    // Cycle through Chofetz Chaim principles by day of year
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1;
    // 10 principles in Part One, 9 in Part Two
    final totalPrinciples = 19;
    final principleIndex = (dayOfYear % totalPrinciples) + 1;

    String ref;
    if (principleIndex <= 10) {
      ref = 'Chofetz_Chaim,_Part_One,_The_Prohibition_Against_Lashon_Hara,_Principle_$principleIndex';
    } else {
      ref = 'Chofetz_Chaim,_Part_Two,_The_Prohibition_Against_Rechilut,_Principle_${principleIndex - 10}';
    }

    final data = await _sefaria.getText(ref);
    _hebrewRef = data['heRef']?.toString() ?? 'שמירת הלשון';
    final text = _extractHebrewText(data);

    _blocks = [
      TextBlock(
        label: '🗣️ חפץ חיים - $_hebrewRef',
        segments: text,
        isBold: false,
        labelColor: const Color(0xFF00695C),
      ),
    ];
  }

  Future<void> _loadPirkeiAvot() async {
    // Between Pesach and Rosh Hashana, one chapter per Shabbat, cycling 1-6
    final now = DateTime.now();
    final jewishCal = JewishCalendar.fromDateTime(now);
    final month = jewishCal.getJewishMonth();
    final day = jewishCal.getJewishDayOfMonth();

    // Calculate which chapter based on weeks since Pesach
    // Pesach is 15 Nissan (month 1), Shavuot is 6 Sivan (month 3)
    // After Shavuot, continue cycling until Rosh Hashana
    int weeksSincePesach = 0;
    if (month == 1 && day >= 15) {
      weeksSincePesach = ((day - 15) / 7).floor();
    } else if (month > 1 && month <= 6) {
      weeksSincePesach = ((day + (month - 1) * 30 - 15) / 7).floor();
    }
    final chapter = (weeksSincePesach % 6) + 1;

    final ref = 'Pirkei_Avot.$chapter';
    final data = await _sefaria.getText(ref);
    _hebrewRef = data['heRef']?.toString() ?? 'פרקי אבות';
    final text = _extractHebrewText(data);

    _blocks = [
      TextBlock(
        label: '📖 פרקי אבות - $_hebrewRef',
        segments: text,
        isBold: false,
        labelColor: const Color(0xFF4E342E),
      ),
    ];
  }

  // ==========================================
  // Nach Yomi - 2 chapters per day
  // ==========================================

  // All Nach books in order (Nevi'im then Ketuvim) with Sefaria ref names
  static const _nachBooks = [
    // Nevi'im Rishonim
    {'ref': 'Joshua', 'he': 'יהושע', 'chapters': 24},
    {'ref': 'Judges', 'he': 'שופטים', 'chapters': 21},
    {'ref': 'I_Samuel', 'he': 'שמואל א', 'chapters': 31},
    {'ref': 'II_Samuel', 'he': 'שמואל ב', 'chapters': 24},
    {'ref': 'I_Kings', 'he': 'מלכים א', 'chapters': 22},
    {'ref': 'II_Kings', 'he': 'מלכים ב', 'chapters': 25},
    // Nevi'im Acharonim
    {'ref': 'Isaiah', 'he': 'ישעיהו', 'chapters': 66},
    {'ref': 'Jeremiah', 'he': 'ירמיהו', 'chapters': 52},
    {'ref': 'Ezekiel', 'he': 'יחזקאל', 'chapters': 48},
    {'ref': 'Hosea', 'he': 'הושע', 'chapters': 14},
    {'ref': 'Joel', 'he': 'יואל', 'chapters': 4},
    {'ref': 'Amos', 'he': 'עמוס', 'chapters': 9},
    {'ref': 'Obadiah', 'he': 'עובדיה', 'chapters': 1},
    {'ref': 'Jonah', 'he': 'יונה', 'chapters': 4},
    {'ref': 'Micah', 'he': 'מיכה', 'chapters': 7},
    {'ref': 'Nahum', 'he': 'נחום', 'chapters': 3},
    {'ref': 'Habakkuk', 'he': 'חבקוק', 'chapters': 3},
    {'ref': 'Zephaniah', 'he': 'צפניה', 'chapters': 3},
    {'ref': 'Haggai', 'he': 'חגי', 'chapters': 2},
    {'ref': 'Zechariah', 'he': 'זכריה', 'chapters': 14},
    {'ref': 'Malachi', 'he': 'מלאכי', 'chapters': 3},
    // Ketuvim
    {'ref': 'Psalms', 'he': 'תהילים', 'chapters': 150},
    {'ref': 'Proverbs', 'he': 'משלי', 'chapters': 31},
    {'ref': 'Job', 'he': 'איוב', 'chapters': 42},
    {'ref': 'Song_of_Songs', 'he': 'שיר השירים', 'chapters': 8},
    {'ref': 'Ruth', 'he': 'רות', 'chapters': 4},
    {'ref': 'Lamentations', 'he': 'איכה', 'chapters': 5},
    {'ref': 'Ecclesiastes', 'he': 'קהלת', 'chapters': 12},
    {'ref': 'Esther', 'he': 'אסתר', 'chapters': 10},
    {'ref': 'Daniel', 'he': 'דניאל', 'chapters': 12},
    {'ref': 'Ezra', 'he': 'עזרא', 'chapters': 10},
    {'ref': 'Nehemiah', 'he': 'נחמיה', 'chapters': 13},
    {'ref': 'I_Chronicles', 'he': 'דברי הימים א', 'chapters': 29},
    {'ref': 'II_Chronicles', 'he': 'דברי הימים ב', 'chapters': 36},
  ];

  // Anchor: Dec 2, 2025 = day 1 of cycle.
  // April 6, 2026 = day 126 → Jeremiah 39+40.
  static final _nachAnchor = DateTime(2025, 12, 2);

  // Build flat list of (bookRef, heBookName, chapter) tuples
  static List<(String, String, int)> _buildNachList() {
    final list = <(String, String, int)>[];
    for (final book in _nachBooks) {
      final ref = book['ref'] as String;
      final he = book['he'] as String;
      final chapters = book['chapters'] as int;
      for (int ch = 1; ch <= chapters; ch++) {
        list.add((ref, he, ch));
      }
    }
    return list;
  }

  Future<void> _loadNachYomi() async {
    final nachList = _buildNachList();
    // 742 chapters total, 371 days per cycle
    final totalDays = nachList.length ~/ 2;
    final daysSinceAnchor = DateTime.now().difference(_nachAnchor).inDays;
    final dayIndex = daysSinceAnchor % totalDays; // 0-based

    final ch1Index = dayIndex * 2;
    final ch2Index = dayIndex * 2 + 1;

    final (book1Ref, book1He, chapter1) = nachList[ch1Index];
    final (book2Ref, book2He, chapter2) = nachList[ch2Index.clamp(0, nachList.length - 1)];

    _hebrewRef = book1Ref == book2Ref
        ? '$book1He פרקים $chapter1-$chapter2'
        : '$book1He $chapter1 + $book2He $chapter2';

    _blocks = [];

    // Load both chapters with commentaries
    for (final (bookRef, bookHe, chapter) in [(book1Ref, book1He, chapter1), (book2Ref, book2He, chapter2)]) {
      final ref = '$bookRef.$chapter';
      final data = await _sefaria.getText(ref);
      final text = _extractHebrewText(data);
      final heRef = data['heRef']?.toString() ?? '$bookHe פרק $chapter';

      if (text.isNotEmpty) {
        _blocks.add(TextBlock(
          label: '📖 $heRef',
          segments: text,
          isBold: true,
          labelColor: const Color(0xFF5D4037),
        ));
      }

      // Commentaries - try each, skip if not available
      for (final (commRef, commLabel, commColor) in [
        ('Rashi_on_$ref', '🔍 רש"י - $bookHe $chapter', const Color(0xFF1565C0)),
        ('Metzudat_David_on_$ref', '📝 מצודת דוד - $bookHe $chapter', const Color(0xFF00695C)),
        ('Malbim_on_$ref', '💎 מלבי"ם - $bookHe $chapter', const Color(0xFF7B1FA2)),
      ]) {
        try {
          final commData = await _sefaria.getText(commRef);
          if (!commData.containsKey('error')) {
            final commText = _extractHebrewText(commData);
            if (commText.isNotEmpty) {
              _blocks.add(TextBlock(
                label: commLabel,
                segments: commText,
                isBold: false,
                labelColor: commColor,
              ));
            }
          }
        } catch (_) {}
      }
    }
  }

  // Peninei Halacha: volumes with [chapter, sections_per_chapter] pairs
  // Each section is one daily lesson (~5-8 paragraphs)
  static const _penineiSections = [
    {'ref': 'Peninei_Halakhah,_Berakhot', 'name': 'ברכות', 'chapters': 17, 'spc': 8},
    {'ref': 'Peninei_Halakhah,_Prayer', 'name': 'תפילה', 'chapters': 27, 'spc': 7},
    {'ref': 'Peninei_Halakhah,_Shabbat', 'name': 'שבת', 'chapters': 30, 'spc': 8},
    {'ref': 'Peninei_Halakhah,_Pesach', 'name': 'פסח', 'chapters': 16, 'spc': 7},
    {'ref': 'Peninei_Halakhah,_Kashrut', 'name': 'כשרות', 'chapters': 37, 'spc': 6},
    {'ref': 'Peninei_Halakhah,_Festivals', 'name': 'מועדים', 'chapters': 13, 'spc': 7},
    {'ref': 'Peninei_Halakhah,_Zemanim', 'name': 'זמנים', 'chapters': 15, 'spc': 7},
    {'ref': 'Peninei_Halakhah,_Sukkot', 'name': 'סוכות', 'chapters': 8, 'spc': 7},
    {'ref': 'Peninei_Halakhah,_Family', 'name': 'משפחה', 'chapters': 10, 'spc': 8},
    {'ref': 'Peninei_Halakhah,_Women%27s_Prayer', 'name': 'תפילת נשים', 'chapters': 24, 'spc': 6},
  ];

  Future<void> _loadPenineiHalacha() async {
    // Cycle through individual sections (chapter.section) based on day of year
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;

    // Build flat list of all sections across all volumes
    int totalSections = 0;
    for (final v in _penineiSections) {
      totalSections += (v['chapters'] as int) * (v['spc'] as int);
    }

    final dayIndex = dayOfYear % totalSections;
    int cumulative = 0;
    String volumeRef = _penineiSections[0]['ref'] as String;
    String volumeName = _penineiSections[0]['name'] as String;
    int chapter = 1;
    int section = 1;

    for (final v in _penineiSections) {
      final chapters = v['chapters'] as int;
      final spc = v['spc'] as int;
      final volTotal = chapters * spc;
      if (cumulative + volTotal > dayIndex) {
        volumeRef = v['ref'] as String;
        volumeName = v['name'] as String;
        final withinVol = dayIndex - cumulative;
        chapter = (withinVol ~/ spc) + 1;
        section = (withinVol % spc) + 1;
        break;
      }
      cumulative += volTotal;
    }

    // Fetch the specific section (chapter.section)
    final ref = '$volumeRef.$chapter.$section';
    final data = await _sefaria.getText(ref);

    // If section doesn't exist, fall back to chapter.1
    List<String> text;
    if (data.containsKey('error')) {
      final fallbackRef = '$volumeRef.$chapter.1';
      final fallbackData = await _sefaria.getText(fallbackRef);
      _hebrewRef = fallbackData['heRef']?.toString() ?? 'פניני הלכה - $volumeName';
      text = _extractHebrewText(fallbackData);
    } else {
      _hebrewRef = data['heRef']?.toString() ?? 'פניני הלכה - $volumeName';
      text = _extractHebrewText(data);
    }

    _blocks = [
      TextBlock(
        label: '💎 פניני הלכה - $volumeName',
        segments: text,
        isBold: false,
        labelColor: const Color(0xFF7B1FA2),
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
    _selectedAmudTab = 0;
    _selectedCommentaryTab = 0;

    // Get both amudim for the daf
    final amudim = _sefaria.getDafAmudim(gemaraRef);

    _gemaraAmudA = {};
    _gemaraAmudB = {};
    _blocks = []; // Keep for non-gemara fallback
    String mainHeRef = '';

    for (final amudRef in amudim) {
      final data = await _sefaria.getAmudFull(amudRef);
      final heRef = data['heRef']?.toString() ?? amudRef;
      if (mainHeRef.isEmpty) mainHeRef = heRef;

      final amudData = <String, List<String>>{
        'gemara': data['gemara'] as List<String>? ?? [],
        'rashi': data['rashi'] as List<String>? ?? [],
        'tosafot': data['tosafot'] as List<String>? ?? [],
        'steinsaltz': data['steinsaltz'] as List<String>? ?? [],
      };

      if (amudRef.endsWith('a')) {
        _gemaraAmudA = amudData;
      } else {
        _gemaraAmudB = amudData;
      }
    }

    _dafSummary = DafSummaryService.getSummary(gemaraRef);
    _dafDeepDive = DafSummaryService.getDeepDive(gemaraRef);

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
        actions: [
          if (!_isLoading && _hebrewRef.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'שמור סימניה',
              onPressed: _saveBookmark,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // לעילוי נשמת dedication
            Builder(builder: (ctx) {
              final ilui = ctx.read<AppState>().progress.iluiNeshama;
              if (ilui.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'הלימוד מוקדש לעילוי נשמת $ilui',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.darkGold,
                  ),
                ),
              );
            }),
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
              child: widget.section.type == StudySectionType.gemara
                  ? _buildGemaraTabView()
                  : TorahTextViewer(
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

  Future<void> _saveBookmark() async {
    final bookmark = Bookmark(
      sectionKey: widget.section.key,
      sectionTitle: widget.section.title,
      hebrewRef: _hebrewRef,
      sefariaRef: _currentGemaraRef,
      savedAt: DateTime.now(),
    );
    await BookmarkService.addBookmark(bookmark);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              '🔖 סימניה נשמרה: $_hebrewRef',
              style: GoogleFonts.rubik(),
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ==========================================
  // Gemara tabbed UI
  // ==========================================

  Widget _buildGemaraTabView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFC62828)),
            SizedBox(height: 16),
            Text('...טוען דף יומי'),
          ],
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    // Build top-level tabs
    final topTabs = <_GemaraTab>[
      if (_gemaraAmudA.isNotEmpty && (_gemaraAmudA['gemara']?.isNotEmpty ?? false))
        _GemaraTab('עמוד א\'', const Color(0xFFC62828)),
      if (_gemaraAmudB.isNotEmpty && (_gemaraAmudB['gemara']?.isNotEmpty ?? false))
        _GemaraTab('עמוד ב\'', const Color(0xFF6A1B9A)),
      if (_dafSummary != null && _dafSummary!.isNotEmpty)
        _GemaraTab('סיכום הדף', const Color(0xFF006064)),
      if (_dafDeepDive != null && _dafDeepDive!.isNotEmpty)
        _GemaraTab('הרחבות', const Color(0xFF4E342E)),
    ];

    if (topTabs.isEmpty) {
      return const Center(child: Text('אין תוכן זמין'));
    }

    final safeTab = _selectedAmudTab.clamp(0, topTabs.length - 1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'דף יומי',
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBlue,
                  ),
                ),
                if (_hebrewRef.isNotEmpty)
                  Text(
                    _hebrewRef,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: AppColors.darkBrown.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Top-level tab bar: עמוד א | עמוד ב | סיכום | הרחבות
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(topTabs.length, (i) {
                final tab = topTabs[i];
                final isSelected = safeTab == i;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedAmudTab = i;
                      _selectedCommentaryTab = 0;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tab.color
                            : tab.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? tab.color
                              : tab.color.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        tab.label,
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : tab.color,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Content area
          Expanded(
            child: _buildGemaraTabContent(topTabs, safeTab),
          ),
        ],
      ),
    );
  }

  Widget _buildGemaraTabContent(List<_GemaraTab> tabs, int selectedTab) {
    final tab = tabs[selectedTab];

    // Summary tab
    if (tab.label == 'סיכום הדף') {
      return _buildTextContent([_dafSummary!], false, const Color(0xFF006064));
    }
    // Deep dive tab
    if (tab.label == 'הרחבות') {
      return _buildTextContent([_dafDeepDive!], false, const Color(0xFF4E342E));
    }

    // Amud tab - show commentary sub-tabs
    final amudData = tab.label.contains('א') ? _gemaraAmudA : _gemaraAmudB;

    final commentaries = <_CommentaryTab>[
      if (amudData['gemara']?.isNotEmpty ?? false)
        _CommentaryTab('📚 גמרא', 'gemara', const Color(0xFFC62828)),
      if (amudData['rashi']?.isNotEmpty ?? false)
        _CommentaryTab('🔍 רש"י', 'rashi', const Color(0xFF1565C0)),
      if (amudData['tosafot']?.isNotEmpty ?? false)
        _CommentaryTab('💬 תוספות', 'tosafot', const Color(0xFF4E342E)),
      if (amudData['steinsaltz']?.isNotEmpty ?? false)
        _CommentaryTab('📝 שטיינזלץ', 'steinsaltz', const Color(0xFF00695C)),
    ];

    if (commentaries.isEmpty) {
      return const Center(child: Text('אין תוכן זמין'));
    }

    final safeComm = _selectedCommentaryTab.clamp(0, commentaries.length - 1);
    final selectedComm = commentaries[safeComm];
    final text = amudData[selectedComm.key] ?? [];

    return Column(
      children: [
        // Commentary sub-tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(commentaries.length, (i) {
              final comm = commentaries[i];
              final isSelected = safeComm == i;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCommentaryTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? comm.color.withValues(alpha: 0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? comm.color
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      comm.label,
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? comm.color : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildTextContent(
            text,
            selectedComm.key == 'gemara',
            selectedComm.color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextContent(List<String> segments, bool isBold, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: segments.map((segment) {
            final clean = TorahTextViewer.stripHtml(segment);
            if (clean.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                clean,
                style: GoogleFonts.rubik(
                  fontSize: isBold ? 22 : 20,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  height: 2.0,
                  color: AppColors.darkBrown,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GemaraTab {
  final String label;
  final Color color;
  const _GemaraTab(this.label, this.color);
}

class _CommentaryTab {
  final String label;
  final String key;
  final Color color;
  const _CommentaryTab(this.label, this.key, this.color);
}
