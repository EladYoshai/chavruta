import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../app/app_state.dart';
import '../utils/constants.dart';

/// Siyum Masechet Tracker
class SiyumTrackerScreen extends StatefulWidget {
  const SiyumTrackerScreen({super.key});

  @override
  State<SiyumTrackerScreen> createState() => _SiyumTrackerScreenState();
}

class _SiyumTrackerScreenState extends State<SiyumTrackerScreen> {
  Map<String, int> _progress = {}; // masechet name -> current daf
  bool _isLoading = true;

  // All Bavli masechet with their total dapim
  static const List<_Masechet> _masechetList = [
    _Masechet('ברכות', 'Berakhot', 64),
    _Masechet('שבת', 'Shabbat', 157),
    _Masechet('עירובין', 'Eruvin', 105),
    _Masechet('פסחים', 'Pesachim', 121),
    _Masechet('שקלים', 'Shekalim', 22),
    _Masechet('יומא', 'Yoma', 88),
    _Masechet('סוכה', 'Sukkah', 56),
    _Masechet('ביצה', 'Beitzah', 40),
    _Masechet('ראש השנה', 'Rosh Hashanah', 35),
    _Masechet('תענית', 'Taanit', 31),
    _Masechet('מגילה', 'Megillah', 32),
    _Masechet('מועד קטן', 'Moed Katan', 29),
    _Masechet('חגיגה', 'Chagigah', 27),
    _Masechet('יבמות', 'Yevamot', 122),
    _Masechet('כתובות', 'Ketubot', 112),
    _Masechet('נדרים', 'Nedarim', 91),
    _Masechet('נזיר', 'Nazir', 66),
    _Masechet('סוטה', 'Sotah', 49),
    _Masechet('גיטין', 'Gittin', 90),
    _Masechet('קידושין', 'Kiddushin', 82),
    _Masechet('בבא קמא', 'Bava Kamma', 119),
    _Masechet('בבא מציעא', 'Bava Metzia', 119),
    _Masechet('בבא בתרא', 'Bava Batra', 176),
    _Masechet('סנהדרין', 'Sanhedrin', 113),
    _Masechet('מכות', 'Makkot', 24),
    _Masechet('שבועות', 'Shevuot', 49),
    _Masechet('עבודה זרה', 'Avodah Zarah', 76),
    _Masechet('הוריות', 'Horayot', 14),
    _Masechet('זבחים', 'Zevachim', 120),
    _Masechet('מנחות', 'Menachot', 110),
    _Masechet('חולין', 'Chullin', 142),
    _Masechet('בכורות', 'Bekhorot', 61),
    _Masechet('ערכין', 'Arakhin', 34),
    _Masechet('תמורה', 'Temurah', 34),
    _Masechet('כריתות', 'Keritot', 28),
    _Masechet('מעילה', 'Meilah', 22),
    _Masechet('נידה', 'Niddah', 73),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('siyum_progress');
    if (saved != null) {
      _progress = Map<String, int>.from(json.decode(saved));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('siyum_progress', json.encode(_progress));
  }

  Future<void> _updateDaf(String masechet, int daf) async {
    setState(() => _progress[masechet] = daf);
    await _saveProgress();
  }

  Future<void> _completeSiyum(String masechet) async {
    // Award zuzim for siyum
    final appState = context.read<AppState>();
    await appState.earnBadge('siyum_$masechet', 50);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              '🎉 סיום מסכת $masechet!',
              style: GoogleFonts.rubik(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 12),
                Text(
                  'הדרן עלך מסכת $masechet!\nקיבלת 50 זוזים בונוס!',
                  style: GoogleFonts.rubik(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'אמן!',
                  style: GoogleFonts.rubik(
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('סיום מסכת'),
        backgroundColor: const Color(0xFFC62828),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _masechetList.length,
                itemBuilder: (context, index) {
                  final m = _masechetList[index];
                  final currentDaf = _progress[m.name] ?? 0;
                  final progress = currentDaf / m.totalDapim;
                  final isComplete = currentDaf >= m.totalDapim;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppColors.success.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isComplete
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.gold.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isComplete)
                              const Text('🏆 ', style: TextStyle(fontSize: 18)),
                            Expanded(
                              child: Text(
                                'מסכת ${m.name}',
                                style: GoogleFonts.rubik(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isComplete
                                      ? AppColors.success
                                      : AppColors.darkBrown,
                                ),
                              ),
                            ),
                            Text(
                              '$currentDaf/${m.totalDapim} דפים',
                              style: GoogleFonts.rubik(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: AppColors.parchment,
                            color: isComplete
                                ? AppColors.success
                                : const Color(0xFFC62828),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isComplete) ...[
                              _buildDafButton(
                                '-1',
                                currentDaf > 0
                                    ? () => _updateDaf(m.name, currentDaf - 1)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              _buildDafButton(
                                '+1',
                                () {
                                  final newDaf = currentDaf + 1;
                                  _updateDaf(m.name, newDaf);
                                  if (newDaf >= m.totalDapim) {
                                    _completeSiyum(m.name);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildDafButton(
                                'הגדר',
                                () => _showDafPicker(m),
                              ),
                            ] else
                              Text(
                                'הדרן עלך! 🎉',
                                style: GoogleFonts.rubik(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildDafButton(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFFC62828).withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null
                ? const Color(0xFFC62828).withValues(alpha: 0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: onTap != null ? const Color(0xFFC62828) : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _showDafPicker(_Masechet m) {
    final controller = TextEditingController(
      text: (_progress[m.name] ?? 0).toString(),
    );
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'מסכת ${m.name}',
            style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('הכנס את מספר הדף הנוכחי (מתוך ${m.totalDapim})'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '0',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () {
                final daf = int.tryParse(controller.text) ?? 0;
                final clamped = daf.clamp(0, m.totalDapim);
                _updateDaf(m.name, clamped);
                Navigator.pop(context);
                if (clamped >= m.totalDapim) {
                  _completeSiyum(m.name);
                }
              },
              child: Text(
                'שמור',
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    // Dispose controller when dialog is closed
  }
}

class _Masechet {
  final String name;
  final String englishName;
  final int totalDapim;
  const _Masechet(this.name, this.englishName, this.totalDapim);
}

/// Yahrzeit Calculator
class YahrzeitScreen extends StatefulWidget {
  const YahrzeitScreen({super.key});

  @override
  State<YahrzeitScreen> createState() => _YahrzeitScreenState();
}

class _YahrzeitScreenState extends State<YahrzeitScreen> {
  DateTime? _selectedDate;
  int _yearsAhead = 5;
  List<_YahrzeitResult> _results = [];

  void _calculate() {
    if (_selectedDate == null) return;

    final jewishDate = JewishCalendar.fromDateTime(_selectedDate!);
    final hebrewMonth = jewishDate.getJewishMonth();
    final hebrewDay = jewishDate.getJewishDayOfMonth();

    final formatter = HebrewDateFormatter()..hebrewFormat = true;
    final results = <_YahrzeitResult>[];

    // Calculate yahrzeit for the next N years
    final currentYear = JewishCalendar.fromDateTime(DateTime.now()).getJewishYear();
    for (int i = 0; i <= _yearsAhead; i++) {
      final year = currentYear + i;
      try {
        final yahrzeitDate = JewishCalendar.initDate(
          year, hebrewMonth, hebrewDay);
        final gregorianDate = yahrzeitDate.getGregorianCalendar();
        results.add(_YahrzeitResult(
          hebrewDate: formatter.format(yahrzeitDate),
          gregorianDate: gregorianDate,
          jewishYear: year,
        ));
      } catch (_) {
        // Skip invalid dates (e.g., 30 Cheshvan in a year without it)
      }
    }

    setState(() => _results = results);
  }

  String _formatGregorian(DateTime date) {
    const dayNames = ['יום ראשון', 'יום שני', 'יום שלישי', 'יום רביעי',
      'יום חמישי', 'יום שישי', 'שבת'];
    final dayName = dayNames[date.weekday % 7];
    return '$dayName ${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מחשבון יארצייט'),
        backgroundColor: AppColors.deepBlue,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.deepBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('🕯️', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    'חישוב תאריך יארצייט',
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'הכנס את תאריך הפטירה לחישוב ימי היארצייט',
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date picker
            Text(
              'תאריך פטירה (לועזי)',
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.deepBlue,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _results = [];
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.deepBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.deepBlue, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'בחר תאריך',
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        color: _selectedDate != null
                            ? AppColors.darkBrown
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_selectedDate != null) ...[
              const SizedBox(height: 16),
              // Show Hebrew date of passing
              Builder(builder: (_) {
                final jewishDate = JewishCalendar.fromDateTime(_selectedDate!);
                final formatter = HebrewDateFormatter()..hebrewFormat = true;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(
                        'תאריך עברי: ${formatter.format(jewishDate)}',
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              // Years ahead selector
              Row(
                children: [
                  Text(
                    'שנים קדימה:',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...List.generate(4, (i) {
                    final years = [3, 5, 10, 20][i];
                    final isSelected = _yearsAhead == years;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _yearsAhead = years),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.deepBlue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.deepBlue
                                  : AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '$years',
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkBrown,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 16),
              // Calculate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate),
                  label: Text(
                    'חשב יארצייט',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // Results
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'ימי יארצייט',
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 10),
              ..._results.map((r) {
                final isPast = r.gregorianDate.isBefore(DateTime.now());
                final isThisYear = r.gregorianDate.year == DateTime.now().year &&
                    r.gregorianDate.month >= DateTime.now().month;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isThisYear && !isPast
                        ? AppColors.deepBlue.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isThisYear && !isPast
                          ? AppColors.deepBlue.withValues(alpha: 0.3)
                          : AppColors.gold.withValues(alpha: 0.15),
                      width: isThisYear && !isPast ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isPast ? '🕯️' : '📅',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.hebrewDate,
                              style: GoogleFonts.rubik(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBrown,
                              ),
                            ),
                            Text(
                              _formatGregorian(r.gregorianDate),
                              style: GoogleFonts.rubik(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isThisYear && !isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.deepBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'הקרוב',
                            style: GoogleFonts.rubik(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _YahrzeitResult {
  final String hebrewDate;
  final DateTime gregorianDate;
  final int jewishYear;
  const _YahrzeitResult({
    required this.hebrewDate,
    required this.gregorianDate,
    required this.jewishYear,
  });
}
