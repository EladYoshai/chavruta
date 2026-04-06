import 'package:flutter/foundation.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:geolocator/geolocator.dart';

/// Complete Jewish calendar service for the smart siddur.
/// Determines the exact halachic day type and all prayer modifications needed.
class JewishCalendarService {
  static Position? _cachedPosition;

  /// Get user's location (with permission request)
  static Future<Position?> getLocation() async {
    if (_cachedPosition != null) return _cachedPosition;

    try {
      if (kIsWeb) {
        // Web: try to get location, fall back to Jerusalem
        try {
          final permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            return null;
          }
          _cachedPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 10),
            ),
          );
          return _cachedPosition;
        } catch (_) {
          return null;
        }
      } else {
        // Mobile
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return null;

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return null;
        }
        if (permission == LocationPermission.deniedForever) return null;

        _cachedPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        );
        return _cachedPosition;
      }
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  /// Get complete day info for the siddur
  static Future<SiddurDayInfo> getDayInfo() async {
    final now = DateTime.now();
    final position = await getLocation();

    // Default to Jerusalem if no location
    final lat = position?.latitude ?? 31.7683;
    final lon = position?.longitude ?? 35.2137;
    final isInIsrael = _isInIsrael(lat, lon);

    // Calculate sunset for halachic day change
    final geoLocation = GeoLocation.setLocation('User', lat, lon, now);
    final zmanimCal = ComplexZmanimCalendar.intGeoLocation(geoLocation);
    final sunset = zmanimCal.getSunset();
    final isAfterShkia = sunset != null && now.isAfter(sunset);

    // Halachic date: after shkia = next day
    final halachicDate = isAfterShkia
        ? now.add(const Duration(days: 1))
        : now;
    final jewishCal = JewishCalendar.fromDateTime(halachicDate);
    final month = jewishCal.getJewishMonth();
    final day = jewishCal.getJewishDayOfMonth();
    final year = jewishCal.getJewishYear();
    final dayOfWeek = halachicDate.weekday; // 1=Mon...7=Sun

    final formatter = HebrewDateFormatter()..hebrewFormat = true;
    final hebrewDateStr = formatter.format(jewishCal);

    // Determine day type
    final isShabbat = dayOfWeek == 6; // Saturday
    final isRoshChodesh = day == 1 || day == 30;
    final isLeapYear = jewishCal.isJewishLeapYear();

    // === Holiday detection ===
    final holiday = _getHoliday(month, day, isInIsrael);
    final isYomTov = holiday.isYomTov;
    final isCholHamoed = holiday.isCholHamoed;
    final isPurim = (month == 12 && day == 14) || (isLeapYear && month == 13 && day == 14);
    // Chanukah exact: 25 Kislev to 2 or 3 Tevet
    final chanukahActive = _isChanukah(month, day, year);

    // === Seasonal insertions ===

    // משיב הרוח: from Musaf Shmini Atzeret (22 Tishrei) to Musaf 1st day Pesach (15 Nisan)
    final mashivHaruach = _isMashivHaruachSeason(month, day);

    // ותן טל ומטר: Israel from 7 Cheshvan, abroad from ~Dec 4
    final veteinTalUmatar = _isVeteinTalUmatarSeason(month, day, now, isInIsrael);

    // === Omer ===
    int omerDay = 0;
    if (month == 1 && day >= 16) omerDay = day - 15;
    if (month == 2) omerDay = day + 15;
    if (month == 3 && day <= 5) omerDay = day + 44;
    final isOmerSeason = omerDay > 0 && omerDay <= 49;

    // === Tachanun ===
    final sayTachanun = _sayTachanun(month, day, dayOfWeek, isLeapYear);

    // === Ya'aleh v'Yavo ===
    final sayYaalehVyavo = isRoshChodesh || isCholHamoed || isYomTov ||
        (month == 7 && (day == 1 || day == 2)) || // Rosh Hashana
        (month == 7 && day == 10); // Yom Kippur

    // === Al HaNissim ===
    final sayAlHanissim = chanukahActive || isPurim;
    final alHanissimType = chanukahActive ? AlHanissimType.chanukah
        : isPurim ? AlHanissimType.purim : AlHanissimType.none;

    // === Hallel ===
    final hallelType = _getHallelType(month, day, isCholHamoed, isInIsrael);

    // === Aseret Yemei Tshuva ===
    final isAseretYemeiTshuva = month == 7 && day >= 1 && day <= 10;

    // === Fast day ===
    final fastDay = _getFastDay(month, day, dayOfWeek);

    // === Ya'aleh v'Yavo occasion text ===
    final yaalehVyavoOccasion = _getYaalehVyavoOccasion(month, day, holiday);

    return SiddurDayInfo(
      hebrewDate: hebrewDateStr,
      jewishMonth: month,
      jewishDay: day,
      jewishYear: year,
      dayOfWeek: dayOfWeek,
      isShabbat: isShabbat,
      isRoshChodesh: isRoshChodesh,
      isYomTov: isYomTov,
      isCholHamoed: isCholHamoed,
      holiday: holiday,
      isInIsrael: isInIsrael,
      sunset: sunset,
      isAfterShkia: isAfterShkia,
      // Seasonal
      mashivHaruach: mashivHaruach,
      veteinTalUmatar: veteinTalUmatar,
      sayYaalehVyavo: sayYaalehVyavo,
      yaalehVyavoOccasion: yaalehVyavoOccasion,
      sayAlHanissim: sayAlHanissim,
      alHanissimType: alHanissimType,
      hallelType: hallelType,
      sayTachanun: sayTachanun,
      // Tachanun at mincha: skip on erev shabbat, erev yom tov, erev rosh chodesh, erev any no-tachanun day
      sayTachanunAtMincha: sayTachanun && dayOfWeek != 5 && !_isTomorrowNoTachanun(month, day, dayOfWeek, isLeapYear),
      isAseretYemeiTshuva: isAseretYemeiTshuva,
      fastDay: fastDay,
      omerDay: omerDay,
      isOmerSeason: isOmerSeason,
      isChanukah: chanukahActive,
      isPurim: isPurim,
      isShabbatRoshChodesh: isShabbat && isRoshChodesh,
      isShabbatCholHamoed: isShabbat && isCholHamoed,
      isYomTovOnShabbat: isShabbat && isYomTov,
    );
  }

  // ==========================================
  // Holiday detection
  // ==========================================

  static HolidayInfo _getHoliday(int month, int day, bool isInIsrael) {
    // Tishrei holidays
    if (month == 7) {
      if (day == 1 || day == 2) return HolidayInfo('ראש השנה', isYomTov: true);
      if (day == 10) return HolidayInfo('יום כיפור', isYomTov: true);
      if (day == 15) return HolidayInfo('סוכות', isYomTov: true);
      if (day == 16 && !isInIsrael) return HolidayInfo('סוכות ב\'', isYomTov: true);
      if (day >= 16 && day <= 21 && isInIsrael) return HolidayInfo('חול המועד סוכות', isCholHamoed: true);
      if (day >= 17 && day <= 21 && !isInIsrael) return HolidayInfo('חול המועד סוכות', isCholHamoed: true);
      if (day == 22) return HolidayInfo('שמיני עצרת', isYomTov: true);
      if (day == 23 && !isInIsrael) return HolidayInfo('שמחת תורה', isYomTov: true);
    }

    // Nisan - Pesach
    if (month == 1) {
      if (day == 15) return HolidayInfo('פסח', isYomTov: true);
      if (day == 16 && !isInIsrael) return HolidayInfo('פסח ב\'', isYomTov: true);
      if (day >= 16 && day <= 20 && isInIsrael) return HolidayInfo('חול המועד פסח', isCholHamoed: true);
      if (day >= 17 && day <= 20 && !isInIsrael) return HolidayInfo('חול המועד פסח', isCholHamoed: true);
      if (day == 21) return HolidayInfo('שביעי של פסח', isYomTov: true);
      if (day == 22 && !isInIsrael) return HolidayInfo('אחרון של פסח', isYomTov: true);
    }

    // Sivan - Shavuot
    if (month == 3) {
      if (day == 6) return HolidayInfo('שבועות', isYomTov: true);
      if (day == 7 && !isInIsrael) return HolidayInfo('שבועות ב\'', isYomTov: true);
    }

    return HolidayInfo('', isYomTov: false, isCholHamoed: false);
  }

  // ==========================================
  // Mashiv Haruach season
  // ==========================================

  static bool _isMashivHaruachSeason(int month, int day) {
    // From 22 Tishrei (Shmini Atzeret) to 15 Nisan (1st Pesach)
    // Months: 7=Tishrei, 8=Cheshvan... 1=Nisan
    if (month == 7 && day >= 22) return true; // Tishrei from Shmini Atzeret
    if (month >= 8) return true; // Cheshvan through Adar
    if (month == 1 && day < 15) return true; // Nisan before Pesach
    return false;
  }

  // ==========================================
  // Vetein Tal Umatar season
  // ==========================================

  static bool _isVeteinTalUmatarSeason(int month, int day, DateTime now, bool isInIsrael) {
    // Stop: before Pesach (15 Nisan)
    if (month == 1 && day >= 15) return false;

    if (isInIsrael) {
      // Israel: from 7 Cheshvan
      if (month == 8 && day >= 7) return true; // Cheshvan from 7th
      if (month >= 9) return true; // Kislev onwards
      if (month <= 1 && day < 15) return true; // through Nisan before Pesach
      // Months 2-6 (Iyar-Elul): summer, no tal umatar
      return false;
    } else {
      // Abroad: from 60 days after Tekufat Tishrei (~Oct 7)
      // This is usually December 4 (or Dec 5 in year before civil leap year)
      // Simplified: use December 4/5
      final civilYear = now.year;
      final isBeforeCivilLeapYear = (civilYear + 1) % 4 == 0;
      final startDay = isBeforeCivilLeapYear ? 5 : 4;
      final startDate = DateTime(civilYear, 12, startDay);

      // If we're past December start date or in Jan-March
      if (now.isAfter(startDate) || now.month <= 3) {
        // But check Hebrew calendar: stop before Pesach
        if (month == 1 && day >= 15) return false;
        return month >= 9 || month <= 1; // Kislev-Nisan
      }
      return false;
    }
  }

  // ==========================================
  // Chanukah detection
  // ==========================================

  static bool _isChanukah(int month, int day, int year) {
    // Chanukah: 25 Kislev to 2 or 3 Tevet
    // If Kislev has 30 days: ends 2 Tevet
    // If Kislev has 29 days: ends 3 Tevet
    if (month == 9 && day >= 25) return true; // Kislev 25-29/30
    if (month == 10) {
      // Check Kislev length by creating a date in Kislev
      final kislevDate = JewishCalendar.initDate(year, 9, 1);
      final kislevLength = kislevDate.getDaysInJewishMonth();
      final lastDay = kislevLength == 30 ? 2 : 3;
      if (day <= lastDay) return true;
    }
    return false;
  }

  // ==========================================
  // Tachanun
  // ==========================================

  static bool _sayTachanun(int month, int day, int dayOfWeek, bool isLeapYear) {
    // No tachanun on Shabbat
    if (dayOfWeek == 6) return false;

    // Tishrei: no tachanun entire month basically
    if (month == 7) return false; // RH, YK, Sukkot, Shmini Atzeret + days between

    // All of Nisan
    if (month == 1) return false;

    // Lag BaOmer (18 Iyar)
    if (month == 2 && day == 18) return false;

    // Yom Yerushalayim (28 Iyar)
    if (month == 2 && day == 28) return false;

    // 1-5 Sivan (before + Shavuot)
    if (month == 3 && day >= 1 && day <= 5) return false;
    // Shavuot itself
    if (month == 3 && (day == 6 || day == 7)) return false;

    // 15 Av
    if (month == 5 && day == 15) return false;

    // Erev Rosh Hashana (29 Elul)
    if (month == 6 && day == 29) return false;

    // Chanukah
    if (month == 9 && day >= 25) return false;
    if (month == 10 && day <= 3) return false; // covers both 29/30 day Kislev

    // 15 Shvat
    if (month == 11 && day == 15) return false;

    // Purim and Shushan Purim
    if (!isLeapYear) {
      if (month == 12 && (day == 14 || day == 15)) return false;
    } else {
      // Leap year: Purim Katan (14-15 Adar I) and Purim (14-15 Adar II)
      if (month == 12 && (day == 14 || day == 15)) return false;
      if (month == 13 && (day == 14 || day == 15)) return false;
    }

    // Pesach Sheni (14 Iyar)
    if (month == 2 && day == 14) return false;

    // Rosh Chodesh
    if (day == 1 || day == 30) return false;

    // Erev Yom Kippur (9 Tishrei) - already covered by month==7

    return true;
  }

  /// Check if tomorrow has no tachanun (for mincha today skip)
  static bool _isTomorrowNoTachanun(int month, int day, int dayOfWeek, bool isLeapYear) {
    // Tomorrow is Shabbat (today is Friday = dayOfWeek 5)
    if (dayOfWeek == 5) return true;
    // Tomorrow is Rosh Chodesh (today is 29th or 30th)
    if (day == 29 || day == 30) return true;
    // Erev Yom Tov / Erev specific days
    // Erev Pesach (14 Nisan)
    if (month == 1 && day == 14) return true;
    // Erev Sukkot (14 Tishrei)
    if (month == 7 && day == 14) return true;
    // Erev Shavuot (5 Sivan)
    if (month == 3 && day == 5) return true;
    // Erev RH (29 Elul)
    if (month == 6 && day == 29) return true;
    // Erev YK (9 Tishrei)
    if (month == 7 && day == 9) return true;
    // Erev Chanukah (24 Kislev)
    if (month == 9 && day == 24) return true;
    return false;
  }

  // ==========================================
  // Hallel type
  // ==========================================

  static HallelType _getHallelType(int month, int day, bool isCholHamoed, bool isInIsrael) {
    // Full Hallel:
    // Sukkot all days (15-22 Tishrei in Israel, 15-23 abroad)
    if (month == 7 && day >= 15 && day <= 23) return HallelType.full;

    // Chanukah all 8 days
    if (month == 9 && day >= 25) return HallelType.full;
    if (month == 10 && day <= 3) return HallelType.full;

    // Shavuot
    if (month == 3 && (day == 6 || day == 7)) return HallelType.full;

    // First day(s) of Pesach
    if (month == 1 && day == 15) return HallelType.full;
    if (month == 1 && day == 16 && !isInIsrael) return HallelType.full;

    // Half Hallel:
    // Rosh Chodesh
    if (day == 1 || day == 30) return HallelType.half;

    // Chol HaMoed Pesach + last days of Pesach
    if (month == 1 && day >= 16 && day <= 22) return HallelType.half;

    return HallelType.none;
  }

  // ==========================================
  // Fast days
  // ==========================================

  static FastDayType _getFastDay(int month, int day, int dayOfWeek) {
    // Tzom Gedaliah: 3 Tishrei (or 4 if 3 is Shabbat)
    if (month == 7) {
      if (day == 3 && dayOfWeek != 6) return FastDayType.tzomGedaliah;
      if (day == 4 && dayOfWeek == 7) return FastDayType.tzomGedaliah; // Sunday after Shabbat
    }

    // 10 Tevet
    if (month == 10 && day == 10) return FastDayType.asaraBeTevet;

    // Taanit Esther: 13 Adar (or 11 if 13 is Shabbat)
    if (month == 12 || month == 13) {
      if (day == 13 && dayOfWeek != 6) return FastDayType.taanitEsther;
      if (day == 11 && dayOfWeek == 4) return FastDayType.taanitEsther; // Thursday before Shabbat
    }

    // 17 Tammuz (or 18 if 17 is Shabbat)
    if (month == 4) {
      if (day == 17 && dayOfWeek != 6) return FastDayType.shivahAsarBeTammuz;
      if (day == 18 && dayOfWeek == 7) return FastDayType.shivahAsarBeTammuz;
    }

    // 9 Av (or 10 if 9 is Shabbat)
    if (month == 5) {
      if (day == 9 && dayOfWeek != 6) return FastDayType.tishaBeAv;
      if (day == 10 && dayOfWeek == 7) return FastDayType.tishaBeAv;
    }

    // Yom Kippur (not a "regular" fast but affects tefila)
    if (month == 7 && day == 10) return FastDayType.yomKippur;

    return FastDayType.none;
  }

  // ==========================================
  // Ya'aleh v'Yavo occasion
  // ==========================================

  static String _getYaalehVyavoOccasion(int month, int day, HolidayInfo holiday) {
    if (day == 1 || day == 30) return 'ראש החודש';
    if (month == 7 && (day == 1 || day == 2)) return 'יום הזכרון'; // Rosh Hashana
    if (month == 7 && day == 10) return 'יום הכפורים';
    if (month == 1 && day >= 15 && day <= 22) return 'חג המצות';
    if (month == 7 && day >= 15 && day <= 22) return 'חג הסוכות';
    if (month == 7 && day == 22) return 'שמיני עצרת';
    if (month == 3 && (day == 6 || day == 7)) return 'חג השבועות';
    return '';
  }

  // ==========================================
  // Israel detection
  // ==========================================

  static bool _isInIsrael(double lat, double lon) {
    // Rough bounding box for Israel
    return lat >= 29.5 && lat <= 33.3 && lon >= 34.2 && lon <= 35.9;
  }
}

// ==========================================
// Data classes
// ==========================================

class SiddurDayInfo {
  final String hebrewDate;
  final int jewishMonth;
  final int jewishDay;
  final int jewishYear;
  final int dayOfWeek;
  final bool isShabbat;
  final bool isRoshChodesh;
  final bool isYomTov;
  final bool isCholHamoed;
  final HolidayInfo holiday;
  final bool isInIsrael;
  final DateTime? sunset;
  final bool isAfterShkia;

  // Seasonal insertions
  final bool mashivHaruach; // true = say משיב הרוח, false = summer (מוריד הטל or nothing)
  final bool veteinTalUmatar; // true = say ותן טל ומטר, false = ותן ברכה
  final bool sayYaalehVyavo;
  final String yaalehVyavoOccasion;
  final bool sayAlHanissim;
  final AlHanissimType alHanissimType;
  final HallelType hallelType;
  final bool sayTachanun;
  final bool sayTachanunAtMincha; // false on erev shabbat/yomtov/rosh chodesh
  final bool isAseretYemeiTshuva;
  final FastDayType fastDay;
  final int omerDay;
  final bool isOmerSeason;
  final bool isChanukah;
  final bool isPurim;
  final bool isShabbatRoshChodesh;
  final bool isShabbatCholHamoed;
  final bool isYomTovOnShabbat;

  const SiddurDayInfo({
    required this.hebrewDate,
    required this.jewishMonth,
    required this.jewishDay,
    required this.jewishYear,
    required this.dayOfWeek,
    required this.isShabbat,
    required this.isRoshChodesh,
    required this.isYomTov,
    required this.isCholHamoed,
    required this.holiday,
    required this.isInIsrael,
    required this.sunset,
    required this.isAfterShkia,
    required this.mashivHaruach,
    required this.veteinTalUmatar,
    required this.sayYaalehVyavo,
    required this.yaalehVyavoOccasion,
    required this.sayAlHanissim,
    required this.alHanissimType,
    required this.hallelType,
    required this.sayTachanun,
    required this.sayTachanunAtMincha,
    required this.isAseretYemeiTshuva,
    required this.fastDay,
    required this.omerDay,
    required this.isOmerSeason,
    required this.isChanukah,
    required this.isPurim,
    required this.isShabbatRoshChodesh,
    required this.isShabbatCholHamoed,
    required this.isYomTovOnShabbat,
  });

  /// Human-readable day description
  String get dayDescription {
    if (holiday.name.isNotEmpty) return holiday.name;
    if (isShabbat && isRoshChodesh) return 'שבת ראש חודש';
    if (isShabbat) return 'שבת קודש';
    if (isRoshChodesh) return 'ראש חודש';
    if (isChanukah) return 'חנוכה';
    if (isPurim) return 'פורים';
    if (fastDay != FastDayType.none) return fastDay.hebrewName;
    return 'יום חול';
  }

  /// List of active prayer modifications for display (nusach-aware)
  List<String> getActiveModifications(String nusach) {
    final mods = <String>[];
    if (mashivHaruach) {
      mods.add('✅ משיב הרוח ומוריד הגשם');
    } else {
      if (nusach == 'ashkenaz') {
        mods.add('✅ ללא תוספת (לא אומרים מוריד הטל)');
      } else {
        mods.add('✅ מוריד הטל');
      }
    }
    if (veteinTalUmatar) {
      mods.add('✅ ותן טל ומטר לברכה');
    } else {
      mods.add('✅ ותן ברכה');
    }
    if (sayYaalehVyavo) mods.add('✅ יעלה ויבוא - $yaalehVyavoOccasion');
    if (sayAlHanissim) mods.add('✅ על הניסים - ${alHanissimType.hebrewName}');
    if (isAseretYemeiTshuva) {
      mods.add('✅ המלך הקדוש (במקום האל הקדוש)');
      mods.add('✅ המלך המשפט (במקום מלך אוהב צדקה ומשפט)');
      mods.add('✅ זכרנו לחיים, מי כמוך, וכתוב, בספר');
    }
    if (hallelType == HallelType.full) {
      mods.add('✅ הלל שלם עם ברכה');
    } else if (hallelType == HallelType.half) {
      if (nusach == 'edot_hamizrach') {
        mods.add('✅ חצי הלל (בלי ברכה)');
      } else {
        mods.add('✅ חצי הלל עם ברכה');
      }
    }
    if (!sayTachanun) mods.add('❌ אין תחנון');
    if (fastDay != FastDayType.none && fastDay != FastDayType.yomKippur) {
      if (nusach == 'ashkenaz') {
        mods.add('✅ עננו (במנחה בלבד)');
      } else {
        mods.add('✅ עננו (בשחרית ובמנחה)');
      }
    }
    if (isOmerSeason) mods.add('✅ ספירת העומר - יום $omerDay');
    if (isShabbatRoshChodesh) mods.add('📌 מוסף מיוחד לשבת ר"ח (אתה יצרת)');
    if (isShabbatCholHamoed) mods.add('📌 שבת חול המועד - יעלה ויבוא בעמידה');
    if (isYomTovOnShabbat) mods.add('📌 יו"ט בשבת - תוספת שבת בעמידת יו"ט');
    return mods;
  }
}

class HolidayInfo {
  final String name;
  final bool isYomTov;
  final bool isCholHamoed;

  const HolidayInfo(this.name, {this.isYomTov = false, this.isCholHamoed = false});
}

enum AlHanissimType {
  none,
  chanukah,
  purim;

  String get hebrewName => switch (this) {
    AlHanissimType.chanukah => 'חנוכה',
    AlHanissimType.purim => 'פורים',
    AlHanissimType.none => '',
  };
}

enum HallelType {
  none,
  half,
  full;

  String get hebrewName => switch (this) {
    HallelType.full => 'הלל שלם',
    HallelType.half => 'חצי הלל',
    HallelType.none => '',
  };
}

enum FastDayType {
  none,
  tzomGedaliah,
  asaraBeTevet,
  taanitEsther,
  shivahAsarBeTammuz,
  tishaBeAv,
  yomKippur;

  String get hebrewName => switch (this) {
    FastDayType.tzomGedaliah => 'צום גדליה',
    FastDayType.asaraBeTevet => 'עשרה בטבת',
    FastDayType.taanitEsther => 'תענית אסתר',
    FastDayType.shivahAsarBeTammuz => 'י"ז בתמוז',
    FastDayType.tishaBeAv => 'תשעה באב',
    FastDayType.yomKippur => 'יום כיפור',
    FastDayType.none => '',
  };
}
