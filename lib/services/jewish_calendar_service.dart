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

  /// List of active prayer modifications for display (nusach + tefila aware)
  List<String> getActiveModifications(String nusach, [TefilaType? tefila]) {
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
    // Hallel only at shacharit (or general view)
    if (tefila == null || tefila == TefilaType.shacharit) {
      if (hallelType == HallelType.full) {
        mods.add('✅ הלל שלם עם ברכה');
      } else if (hallelType == HallelType.half) {
        if (nusach == 'edot_hamizrach') {
          mods.add('✅ חצי הלל (בלי ברכה)');
        } else {
          mods.add('✅ חצי הלל עם ברכה');
        }
      }
    }
    if (tefila == TefilaType.arvit) {
      // Never tachanun at arvit
    } else if (tefila == TefilaType.mincha && !sayTachanunAtMincha) {
      mods.add('❌ אין תחנון (מנחה)');
    } else if (!sayTachanun) {
      mods.add('❌ אין תחנון');
    }
    if (fastDay != FastDayType.none && fastDay != FastDayType.yomKippur) {
      if (tefila != null) {
        // Tefila-specific: show only if relevant for this tefila
        if (nusach == 'ashkenaz') {
          if (tefila == TefilaType.mincha) mods.add('✅ עננו (בשמע קולנו)');
        } else {
          if (tefila == TefilaType.shacharit || tefila == TefilaType.mincha) {
            mods.add('✅ עננו (בשמע קולנו)');
          }
        }
      } else {
        // General: show overview
        if (nusach == 'ashkenaz') {
          mods.add('✅ עננו (במנחה בלבד)');
        } else {
          mods.add('✅ עננו (בשחרית ובמנחה)');
        }
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

// ==========================================
// Tefila type (silent vs chazzan)
// ==========================================

enum TefilaType {
  shacharit,
  mincha,
  arvit,
  musaf;

  String get hebrewName => switch (this) {
    TefilaType.shacharit => 'שחרית',
    TefilaType.mincha => 'מנחה',
    TefilaType.arvit => 'ערבית',
    TefilaType.musaf => 'מוסף',
  };
}

enum AmidaMode {
  silent,    // תפילת לחש
  chazara;   // חזרת הש"ץ

  String get hebrewName => switch (this) {
    AmidaMode.silent => 'תפילת לחש',
    AmidaMode.chazara => 'חזרת הש"ץ',
  };
}

// ==========================================
// Sub-nusach for Edot HaMizrach
// ==========================================

enum EdotHaMizrachSubNusach {
  general,    // ספרדי כללי (default)
  moroccan,   // מרוקאי
  iraqi,      // עיראקי
  syrian,     // סורי / חלבי
  yemenite,   // תימני (בלדי/שאמי)
  jerusalem;  // ירושלמי

  String get hebrewName => switch (this) {
    EdotHaMizrachSubNusach.general => 'ספרדי כללי',
    EdotHaMizrachSubNusach.moroccan => 'מרוקאי',
    EdotHaMizrachSubNusach.iraqi => 'עיראקי',
    EdotHaMizrachSubNusach.syrian => 'סורי / חלבי',
    EdotHaMizrachSubNusach.yemenite => 'תימני',
    EdotHaMizrachSubNusach.jerusalem => 'ירושלמי',
  };
}

// ==========================================
// Minhag Profile - user-customizable overrides
// ==========================================

class MinhagProfile {
  // Hallel on modern holidays
  final bool hallelYomHaatzmaut;      // default: false (user setting)
  final bool hallelYomYerushalayim;   // default: false

  // Morid hatal in summer (Ashkenaz)
  final bool ashkenazSayMoridHatal;   // default: false (GRA/Israeli = true)

  // Tachanun overrides
  final bool tachanunOnIsruChag;      // default: false (most skip)
  final bool tachanunSivan7to12;      // default: false (many skip through 12)

  // Avinu Malkeinu
  final bool avinuMalkeinuOnFasts;    // default: true (Ashkenaz), varies

  // Ledavid Hashem Ori (Elul-Sukkot)
  final bool sayLedavidHaOri;         // default: true
  final int ledavidStopDay;           // 21 (Hoshana Raba) or 22 (Shmini Atzeret)

  // Mizmor Letoda
  final bool sayMizmorLetoda;         // default: true (skip Shabbat/YT/erev Pesach)

  // Lamenatzeach (depends on tachanun)
  final bool sayLamenatzeach;         // default: true (skip when no tachanun)

  const MinhagProfile({
    this.hallelYomHaatzmaut = false,
    this.hallelYomYerushalayim = false,
    this.ashkenazSayMoridHatal = false,
    this.tachanunOnIsruChag = false,
    this.tachanunSivan7to12 = false,
    this.avinuMalkeinuOnFasts = true,
    this.sayLedavidHaOri = true,
    this.ledavidStopDay = 21,
    this.sayMizmorLetoda = true,
    this.sayLamenatzeach = true,
  });

  /// Create from user's saved overrides map
  factory MinhagProfile.fromOverrides(Map<String, bool> overrides) {
    return MinhagProfile(
      hallelYomHaatzmaut: overrides['hallel_yom_haatzmaut'] ?? false,
      hallelYomYerushalayim: overrides['hallel_yom_yerushalayim'] ?? false,
      ashkenazSayMoridHatal: overrides['ashkenaz_morid_hatal'] ?? false,
      tachanunOnIsruChag: overrides['tachanun_isru_chag'] ?? false,
      tachanunSivan7to12: overrides['tachanun_sivan_7_12'] ?? false,
      avinuMalkeinuOnFasts: overrides['avinu_malkeinu_fasts'] ?? true,
      sayLedavidHaOri: overrides['ledavid_ha_ori'] ?? true,
      ledavidStopDay: (overrides['ledavid_stop_shmini'] ?? false) ? 22 : 21,
      sayMizmorLetoda: overrides['mizmor_letoda'] ?? true,
      sayLamenatzeach: overrides['lamenatzeach'] ?? true,
    );
  }
}

// ==========================================
// Precedence Engine - resolves conflicts
// ==========================================

class DayPrecedence {
  /// Returns the precedence level (higher = takes priority)
  /// Complete precedence table for ALL combinations:
  static int getPrecedence(SiddurDayInfo info) {
    // Yom Kippur (highest - overrides everything)
    if (info.fastDay == FastDayType.yomKippur) return 100;
    // Yom Tov on Shabbat (שבת + יו"ט)
    if (info.isYomTovOnShabbat) return 95;
    // Yom Tov (not on Shabbat)
    if (info.isYomTov) return 90;
    // Shabbat + Chol HaMoed (שבת חול המועד)
    if (info.isShabbatCholHamoed) return 85;
    // Shabbat + Rosh Chodesh + Chanukah (שבת ר"ח חנוכה)
    if (info.isShabbatRoshChodesh && info.isChanukah) return 82;
    // Shabbat + Rosh Chodesh (שבת ר"ח)
    if (info.isShabbatRoshChodesh) return 80;
    // Shabbat + Chanukah (שבת חנוכה)
    if (info.isShabbat && info.isChanukah) return 75;
    // Regular Shabbat
    if (info.isShabbat) return 70;
    // Chol HaMoed (not Shabbat)
    if (info.isCholHamoed) return 60;
    // Purim
    if (info.isPurim) return 55;
    // Chanukah + Rosh Chodesh (ר"ח טבת בחנוכה)
    if (info.isChanukah && info.isRoshChodesh) return 52;
    // Chanukah
    if (info.isChanukah) return 50;
    // Rosh Chodesh (both days if 2-day RC)
    if (info.isRoshChodesh) return 45;
    // Fast day (minor fasts)
    if (info.fastDay != FastDayType.none) return 40;
    // Regular weekday
    return 10;
  }

  /// Get day description for complex overlapping days
  static String getComplexDayDescription(SiddurDayInfo info) {
    final parts = <String>[];
    if (info.isShabbat) parts.add('שבת');
    if (info.isRoshChodesh) parts.add('ר"ח');
    if (info.isChanukah) parts.add('חנוכה');
    if (info.isCholHamoed) parts.add('חוה"מ ${info.holiday.name}');
    if (info.isYomTov) parts.add(info.holiday.name);
    if (info.isPurim) parts.add('פורים');
    if (info.fastDay != FastDayType.none && info.fastDay != FastDayType.yomKippur) {
      parts.add(info.fastDay.hebrewName);
    }
    if (parts.isEmpty) return 'יום חול';
    return parts.join(' • ');
  }

  /// Determine which Amidah structure to use
  static AmidaStructure getAmidaStructure(SiddurDayInfo info, TefilaType tefila) {
    // Yom Tov (including Yom Tov on Shabbat)
    if (info.isYomTov) {
      if (tefila == TefilaType.musaf) return AmidaStructure.musafYomTov;
      return AmidaStructure.yomTov; // 7 brachot with holiday middle
    }

    // Shabbat
    if (info.isShabbat) {
      if (info.isShabbatRoshChodesh && tefila == TefilaType.musaf) {
        return AmidaStructure.musafShabbatRoshChodesh; // אתה יצרת
      }
      if (info.isShabbatCholHamoed && tefila == TefilaType.musaf) {
        return AmidaStructure.musafCholHaMoed; // with Shabbat additions
      }
      if (tefila == TefilaType.musaf) return AmidaStructure.musafShabbat;
      return AmidaStructure.shabbat; // 7 brachot with Shabbat middle
    }

    // Rosh Chodesh / Chol HaMoed musaf
    if (tefila == TefilaType.musaf) {
      if (info.isRoshChodesh) return AmidaStructure.musafRoshChodesh;
      if (info.isCholHamoed) return AmidaStructure.musafCholHaMoed;
    }

    // Regular weekday (19 brachot with insertions)
    return AmidaStructure.weekday;
  }

  /// Determine what insertions are needed for weekday amidah
  static List<AmidaInsertion> getInsertions(SiddurDayInfo info, TefilaType tefila,
      String nusach, AmidaMode mode, MinhagProfile minhag) {
    final insertions = <AmidaInsertion>[];

    // === Bracha 1 (Avot) ===
    if (info.isAseretYemeiTshuva) {
      insertions.add(AmidaInsertion.zachrenu);
    }

    // === Bracha 2 (Gvurot) ===
    if (info.mashivHaruach) {
      insertions.add(AmidaInsertion.mashivHaruach);
    } else {
      if (nusach != 'ashkenaz' || minhag.ashkenazSayMoridHatal) {
        insertions.add(AmidaInsertion.moridHatal);
      }
      // Ashkenaz without GRA: nothing (no insertion)
    }
    if (info.isAseretYemeiTshuva) {
      insertions.add(AmidaInsertion.miKamocha);
    }

    // === Bracha 3 (Kedusha) ===
    if (info.isAseretYemeiTshuva) {
      insertions.add(AmidaInsertion.hamelechHakadosh);
    }

    // === Bracha 9 (Birkat Hashanim) ===
    if (info.veteinTalUmatar) {
      insertions.add(AmidaInsertion.veteinTalUmatar);
    } else {
      insertions.add(AmidaInsertion.veteinBracha);
    }

    // === Bracha 11 (Din) ===
    if (info.isAseretYemeiTshuva) {
      insertions.add(AmidaInsertion.hamelechHamishpat);
    }

    // === Bracha 16 (Shma Kolenu) ===
    if (info.fastDay != FastDayType.none && info.fastDay != FastDayType.yomKippur) {
      // Aneinu for individual
      if (nusach == 'ashkenaz') {
        if (tefila == TefilaType.mincha) {
          insertions.add(AmidaInsertion.aneinuIndividual);
        }
      } else {
        // Sefard/Edot HaMizrach: both shacharit and mincha
        if (tefila == TefilaType.shacharit || tefila == TefilaType.mincha) {
          insertions.add(AmidaInsertion.aneinuIndividual);
        }
      }
      // Chazzan: separate bracha between 7 and 8
      if (mode == AmidaMode.chazara) {
        insertions.add(AmidaInsertion.aneinuChazzan);
      }
    }

    // === Bracha 17 (Avoda / Retzeh) ===
    // Ya'aleh v'Yavo - ONLY as insertion in weekday amidah
    // (In Yom Tov amidah it's built-in, not an insertion)
    if (info.sayYaalehVyavo && !info.isYomTov) {
      insertions.add(AmidaInsertion.yaalehVyavo);
    }

    // === Bracha 18 (Hoda'a / Modim) ===
    if (info.sayAlHanissim) {
      insertions.add(AmidaInsertion.alHanissim);
    }
    if (info.isAseretYemeiTshuva) {
      insertions.add(AmidaInsertion.ukhtov);
    }
    // Modim d'Rabbanan for chazara
    if (mode == AmidaMode.chazara) {
      insertions.add(AmidaInsertion.modimDerabbanan);
    }

    // === Last bracha (Shalom) ===
    if (info.isAseretYemeiTshuva) {
      insertions.add(AmidaInsertion.besefer);
    }

    // === Birkat Kohanim (chazara only, Israel: daily, abroad: yom tov) ===
    if (mode == AmidaMode.chazara) {
      if (info.isInIsrael || info.isYomTov) {
        insertions.add(AmidaInsertion.birkatKohanim);
      }
    }

    return insertions;
  }
}

enum AmidaStructure {
  weekday,                    // 19 brachot
  shabbat,                    // 7 brachot - Shabbat middle
  yomTov,                     // 7 brachot - Yom Tov middle
  musafShabbat,               // תכנת שבת
  musafRoshChodesh,           // regular RC musaf
  musafShabbatRoshChodesh,    // אתה יצרת (special!)
  musafCholHaMoed,            // chol hamoed musaf
  musafYomTov,                // yom tov musaf
}

enum AmidaInsertion {
  // Bracha 1
  zachrenu,              // זכרנו לחיים (עשי"ת)
  // Bracha 2
  mashivHaruach,         // משיב הרוח ומוריד הגשם
  moridHatal,            // מוריד הטל
  miKamocha,             // מי כמוך (עשי"ת)
  // Bracha 3
  hamelechHakadosh,      // המלך הקדוש (עשי"ת)
  // Bracha 9
  veteinTalUmatar,       // ותן טל ומטר
  veteinBracha,          // ותן ברכה
  // Bracha 11
  hamelechHamishpat,     // המלך המשפט (עשי"ת)
  // Bracha 16
  aneinuIndividual,      // עננו (יחיד, בשמע קולנו)
  // Between 7 and 8
  aneinuChazzan,         // עננו (ש"ץ, ברכה בפני עצמה)
  // Bracha 17
  yaalehVyavo,           // יעלה ויבוא (ר"ח, חוה"מ)
  // Bracha 18
  alHanissim,            // על הניסים
  ukhtov,                // וכתוב (עשי"ת)
  modimDerabbanan,       // מודים דרבנן (חזרה)
  // Last bracha
  besefer,               // בספר חיים (עשי"ת)
  // Chazara additions
  birkatKohanim,         // ברכת כהנים
}
