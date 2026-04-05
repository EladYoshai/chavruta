import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:kosher_dart/kosher_dart.dart';
import 'package:geolocator/geolocator.dart';
import '../services/sefaria_service.dart';
import '../utils/constants.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isLoading = true;
  String _parshaName = '';
  String _hebrewDate = '';
  String _gregorianDate = '';
  String _holidayName = '';
  String _dayOfWeek = '';
  Map<String, String> _zmanim = {};
  String _locationName = '';
  String? _errorMessage;
  String _dafYomi = '';
  bool _isShabbat = false;
  bool _isHoliday = false;

  // Hebrew day of week names
  static const _hebrewDays = [
    'יום ראשון',
    'יום שני',
    'יום שלישי',
    'יום רביעי',
    'יום חמישי',
    'יום שישי',
    'שבת קודש',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadCalendarInfo(),
        _loadZmanim(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCalendarInfo() async {
    final sefaria = SefariaService();
    final calendar = await sefaria.getCalendarInfo();

    final now = DateTime.now();
    final jewishCalendar = JewishCalendar.fromDateTime(now);
    final formatter = HebrewDateFormatter()..hebrewFormat = true;

    // Day of week
    final dayIndex = now.weekday % 7; // Sunday = 0
    _dayOfWeek = _hebrewDays[dayIndex];
    _isShabbat = now.weekday == 6;

    // Hebrew date
    final hebrewDateStr = formatter.format(jewishCalendar);

    // Gregorian date in Hebrew
    const hebrewMonthNames = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
    ];
    final gregDate = '${now.day} ב${hebrewMonthNames[now.month - 1]} ${now.year}';

    // Get holiday name
    final holiday = _getHolidayName(jewishCalendar);
    _isHoliday = holiday.isNotEmpty;

    // Daf Yomi
    _dafYomi = calendar.dafYomiRef.replaceAll('_', ' ');

    if (mounted) {
      setState(() {
        _parshaName = calendar.parshaHeName;
        _hebrewDate = hebrewDateStr;
        _gregorianDate = gregDate;
        _holidayName = holiday;
      });
    }
  }

  String _getHolidayName(JewishCalendar cal) {
    final month = cal.getJewishMonth();
    final day = cal.getJewishDayOfMonth();

    // Major holidays
    if (month == 7 && day == 1) return 'ראש השנה א׳';
    if (month == 7 && day == 2) return 'ראש השנה ב׳';
    if (month == 7 && day == 3) return 'צום גדליה';
    if (month == 7 && day == 10) return 'יום הכיפורים';
    if (month == 7 && day == 15) return 'סוכות';
    if (month == 7 && day >= 16 && day <= 20) return 'חול המועד סוכות';
    if (month == 7 && day == 21) return 'הושענא רבה';
    if (month == 7 && day == 22) return 'שמיני עצרת / שמחת תורה';

    if (month == 9 && day >= 25) return 'חנוכה';
    if (month == 10 && day <= 2) return 'חנוכה';
    if (month == 10 && day == 10) return 'צום עשרה בטבת';

    if (month == 11 && day == 15) return 'ט"ו בשבט';

    if (month == 12 && day == 13) return 'תענית אסתר';
    if (month == 12 && day == 14) return 'פורים';
    if (month == 12 && day == 15) return 'שושן פורים';

    if (month == 1 && day == 15) return 'פסח';
    if (month == 1 && day == 16) return 'פסח - יום שני';
    if (month == 1 && day >= 17 && day <= 20) return 'חול המועד פסח';
    if (month == 1 && day == 21) return 'שביעי של פסח';
    if (month == 1 && day == 22) return 'אחרון של פסח';

    if (month == 2 && day == 18) return 'ל"ג בעומר';
    if (month == 2 && day == 5) return 'יום העצמאות';
    if (month == 2 && day == 28) return 'יום ירושלים';

    if (month == 3 && day == 6) return 'שבועות';
    if (month == 3 && day == 7) return 'שבועות - יום שני';

    if (month == 4 && day == 17) return 'צום י"ז בתמוז';
    if (month == 5 && day == 9) return 'תשעה באב';
    if (month == 5 && day == 15) return 'ט"ו באב';

    // Omer counting (Pesach to Shavuot)
    if (month == 1 && day >= 16 || (month == 2) || (month == 3 && day <= 5)) {
      final omerDay = _getOmerDay(month, day);
      if (omerDay > 0 && omerDay <= 49) {
        return 'יום $omerDay לעומר';
      }
    }

    return '';
  }

  int _getOmerDay(int month, int day) {
    if (month == 1 && day >= 16) return day - 15;
    if (month == 2) return day + 15;
    if (month == 3 && day <= 5) return day + 44;
    return 0;
  }

  Future<void> _loadZmanim() async {
    try {
      Position position;
      if (kIsWeb) {
        // Web: skip GPS, use Jerusalem default
        position = Position(
          latitude: 31.7683,
          longitude: 35.2137,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 800,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        _locationName = 'ירושלים (ברירת מחדל)';
      } else {
        try {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            final requested = await Geolocator.requestPermission();
            if (requested == LocationPermission.denied ||
                requested == LocationPermission.deniedForever) {
              throw Exception('no permission');
            }
          }
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 10),
            ),
          );
          _locationName = await _reverseGeocode(position.latitude, position.longitude);
        } catch (_) {
          position = Position(
            latitude: 31.7683,
            longitude: 35.2137,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 800,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          _locationName = 'ירושלים (ברירת מחדל)';
        }
      }

      final geoLocation = GeoLocation.setLocation(
        'User Location',
        position.latitude,
        position.longitude,
        DateTime.now(),
      );

      final zmanimCalendar = ComplexZmanimCalendar.intGeoLocation(geoLocation);

      final now = DateTime.now();
      final jewishCal = JewishCalendar.fromDateTime(now);
      final month = jewishCal.getJewishMonth();
      final day = jewishCal.getJewishDayOfMonth();
      final isFriday = now.weekday == 5;
      final isSaturday = now.weekday == 6;
      final isErevPesach = month == 1 && day == 14;
      final isErevYomKippur = month == 7 && day == 9;
      final isErevSukkot = month == 7 && day == 14;
      final isErevShavuot = month == 3 && day == 5;
      final isErevRoshHashana = month == 6 && day == 29;
      final isErevYomTov = isErevSukkot || isErevShavuot || isErevRoshHashana ||
          (month == 1 && day == 14) || (month == 7 && day == 21);
      final isChanukah = (month == 9 && day >= 25) || (month == 10 && day <= 2);
      final isFastDay = (month == 7 && day == 3) || (month == 10 && day == 10) ||
          (month == 12 && day == 13) || (month == 4 && day == 17) || (month == 5 && day == 9);

      final zmanim = <String, String>{};

      // Standard daily zmanim
      _addZman(zmanim, 'עלות השחר', zmanimCalendar.getAlosHashachar());
      _addZman(zmanim, 'הנץ החמה', zmanimCalendar.getSunrise());
      _addZman(zmanim, 'סוף זמן ק"ש (מג"א)', zmanimCalendar.getSofZmanShmaMGA());
      _addZman(zmanim, 'סוף זמן ק"ש (גר"א)', zmanimCalendar.getSofZmanShmaGRA());
      _addZman(zmanim, 'סוף זמן תפילה (מג"א)', zmanimCalendar.getSofZmanTfilaMGA());
      _addZman(zmanim, 'סוף זמן תפילה (גר"א)', zmanimCalendar.getSofZmanTfilaGRA());

      // Erev Pesach - chametz times
      if (isErevPesach) {
        _addZman(zmanim, '⚠️ סוף זמן אכילת חמץ (מג"א)', zmanimCalendar.getSofZmanAchilasChametzMGA72Minutes());
        _addZman(zmanim, '⚠️ סוף זמן אכילת חמץ (גר"א)', zmanimCalendar.getSofZmanAchilasChametzGRA());
        _addZman(zmanim, '🔥 סוף זמן ביעור חמץ (מג"א)', zmanimCalendar.getSofZmanBiurChametzMGA72Minutes());
        _addZman(zmanim, '🔥 סוף זמן ביעור חמץ (גר"א)', zmanimCalendar.getSofZmanBiurChametzGRA());
      }

      _addZman(zmanim, 'חצות היום', zmanimCalendar.getChatzos());
      _addZman(zmanim, 'מנחה גדולה', zmanimCalendar.getMinchaGedola());
      _addZman(zmanim, 'מנחה קטנה', zmanimCalendar.getMinchaKetana());
      _addZman(zmanim, 'פלג המנחה', zmanimCalendar.getPlagHamincha());

      // Friday / Erev Yom Tov - candle lighting
      if (isFriday || isErevYomTov) {
        _addZman(zmanim, '🕯️ הדלקת נרות', zmanimCalendar.getCandleLighting());
      }

      // Erev Yom Kippur
      if (isErevYomKippur) {
        _addZman(zmanim, '🕯️ הדלקת נרות - כניסת יום הכיפורים', zmanimCalendar.getCandleLighting());
      }

      _addZman(zmanim, 'שקיעה', zmanimCalendar.getSunset());

      // Friday - Shabbat entry
      if (isFriday) {
        _addZman(zmanim, '✡️ כניסת שבת', zmanimCalendar.getCandleLighting());
      }

      _addZman(zmanim, 'צאת הכוכבים', zmanimCalendar.getTzais());

      // Motzei Shabbat
      if (isSaturday) {
        _addZman(zmanim, '✡️ יציאת שבת (ר"ת)', zmanimCalendar.getTzais72());
      }

      // Fast day times
      if (isFastDay) {
        if (month == 5 && day == 9) {
          // Tisha B'Av starts at shkia the night before
          _addZman(zmanim, '⚫ תחילת הצום (שקיעה אמש)', zmanimCalendar.getSunset());
        }
        _addZman(zmanim, '⚫ סוף הצום - צאת הכוכבים', zmanimCalendar.getTzais());
      }

      // Chanukah - earliest candle lighting
      if (isChanukah) {
        _addZman(zmanim, '🕎 זמן הדלקת נר חנוכה', zmanimCalendar.getSunset());
      }

      if (mounted) {
        setState(() {
          _zmanim = zmanim;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_zmanim.isEmpty) {
            _errorMessage = 'לא ניתן לטעון זמנים: $e';
          }
        });
      }
    }
  }

  /// Reverse geocode coordinates to city name in Hebrew
  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&accept-language=he');
      final response = await http.get(url, headers: {
        'User-Agent': 'Chavruta-Torah-App/1.0',
      }).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['suburb'] ?? '';
        if (city.toString().isNotEmpty) return city.toString();
      }
    } catch (_) {}
    return 'מיקום נוכחי';
  }

  void _addZman(Map<String, String> map, String name, DateTime? time) {
    if (time != null) {
      final local = time.toLocal();
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      map[name] = '$hour:$minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.deepBlue, AppColors.warmBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.gold),
                    SizedBox(height: 16),
                    Text('...טוען לוח יומי',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            )
          : _errorMessage != null
              ? Scaffold(
                  appBar: AppBar(
                    title: const Text('לוח יומי'),
                    backgroundColor: AppColors.deepBlue,
                  ),
                  body: Center(child: Text(_errorMessage!)),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        slivers: [
          // Fancy header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isShabbat
                      ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                      : _isHoliday
                          ? [const Color(0xFF4A148C), const Color(0xFF6A1B9A)]
                          : [AppColors.deepBlue, AppColors.warmBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    children: [
                      // Back button row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'לוח יומי',
                            style: GoogleFonts.rubik(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Day of week
                      Text(
                        _dayOfWeek,
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Parsha name - big and gold
                      if (_parshaName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _parshaName,
                            style: GoogleFonts.rubik(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Holiday badge
                      if (_holidayName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('✡️',
                                  style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                _holidayName,
                                style: GoogleFonts.rubik(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Dual dates
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hebrew date
                          _buildDateChip(_hebrewDate, Icons.menu_book),
                          const SizedBox(width: 12),
                          // Gregorian date
                          _buildDateChip(_gregorianDate, Icons.calendar_today),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _locationName,
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Daf Yomi
          if (_dafYomi.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school,
                          color: AppColors.darkGold, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'דף יומי: ',
                        style: GoogleFonts.rubik(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _dafYomi,
                          style: GoogleFonts.rubik(
                            fontSize: 15,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Zmanim section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      color: AppColors.deepBlue, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'זמני היום',
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Zmanim list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = _zmanim.entries.toList()[index];
                  final key = entry.key;
                  final isSpecial = key.contains('🕯️') ||
                      key.contains('⚠️') ||
                      key.contains('🔥') ||
                      key.contains('✡️') ||
                      key.contains('🕎') ||
                      key.contains('⚫');
                  final isHighlighted = key == 'הנץ החמה' ||
                      key == 'שקיעה' ||
                      key == 'חצות היום' ||
                      isSpecial;

                  // Determine icon
                  IconData icon;
                  Color? specialColor;
                  if (key.contains('🕯️') || key.contains('הדלקת נרות')) {
                    icon = Icons.local_fire_department;
                    specialColor = const Color(0xFFFF6F00);
                  } else if (key.contains('⚠️') || key.contains('אכילת חמץ')) {
                    icon = Icons.warning_amber;
                    specialColor = Colors.red;
                  } else if (key.contains('🔥') || key.contains('ביעור חמץ')) {
                    icon = Icons.local_fire_department;
                    specialColor = Colors.red;
                  } else if (key.contains('✡️') || key.contains('כניסת שבת') || key.contains('יציאת שבת')) {
                    icon = Icons.auto_awesome;
                    specialColor = AppColors.deepBlue;
                  } else if (key.contains('🕎')) {
                    icon = Icons.celebration;
                    specialColor = AppColors.darkGold;
                  } else if (key.contains('⚫') || key.contains('הצום')) {
                    icon = Icons.do_not_disturb;
                    specialColor = Colors.grey.shade700;
                  } else if (key.contains('הנץ')) {
                    icon = Icons.wb_sunny;
                  } else if (key.contains('שקיעה')) {
                    icon = Icons.nights_stay;
                  } else if (key.contains('חצות')) {
                    icon = Icons.wb_twilight;
                  } else if (key.contains('צאת')) {
                    icon = Icons.star;
                  } else if (key.contains('עלות')) {
                    icon = Icons.light_mode;
                  } else {
                    icon = Icons.schedule;
                  }

                  final highlightColor = specialColor ?? AppColors.gold;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSpecial
                          ? highlightColor.withValues(alpha: 0.08)
                          : isHighlighted
                              ? AppColors.gold.withValues(alpha: 0.12)
                              : (index.isEven ? Colors.white : AppColors.cream),
                      borderRadius: BorderRadius.circular(12),
                      border: isHighlighted
                          ? Border.all(
                              color: highlightColor.withValues(alpha: 0.5),
                              width: isSpecial ? 2 : 1.5)
                          : null,
                      boxShadow: isSpecial
                          ? [
                              BoxShadow(
                                color: highlightColor.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: specialColor ??
                              (isHighlighted
                                  ? AppColors.darkGold
                                  : Colors.grey.shade500),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            key,
                            style: GoogleFonts.rubik(
                              fontSize: isSpecial ? 14 : 15,
                              fontWeight: isHighlighted
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: specialColor ?? AppColors.darkBrown,
                            ),
                          ),
                        ),
                        Text(
                          entry.value,
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: specialColor ??
                                (isHighlighted
                                    ? AppColors.deepBlue
                                    : AppColors.darkBrown),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: _zmanim.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildDateChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.rubik(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
