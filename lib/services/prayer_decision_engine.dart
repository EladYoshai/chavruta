import 'jewish_calendar_service.dart';

/// Decision tree for all prayer modifications.
/// Given a day + tefila + nusach, returns the exact prayer structure.
class PrayerDecisionEngine {

  /// Get the complete prayer flow for a specific tefila on a specific day
  static PrayerFlow getFlow(SiddurDayInfo day, TefilaType tefila, String nusach, MinhagProfile minhag) {
    final flow = PrayerFlow(tefila: tefila, day: day, nusach: nusach);

    // === Step 1: Determine Amidah structure ===
    flow.amidaStructure = DayPrecedence.getAmidaStructure(day, tefila);

    // === Step 2: Determine all insertions ===
    flow.insertions = DayPrecedence.getInsertions(day, tefila, nusach, AmidaMode.silent, minhag);

    // === Step 3: Pre-Amidah elements ===

    // Hallel (shacharit only, after Amidah)
    if (tefila == TefilaType.shacharit) {
      flow.hallelType = day.hallelType;
      // Bracha on hallel
      if (day.hallelType == HallelType.full) {
        flow.hallelBracha = true; // All nusachot say bracha on full hallel
      } else if (day.hallelType == HallelType.half) {
        flow.hallelBracha = nusach != 'edot_hamizrach'; // Edot HaMizrach: no bracha on half
      }
    }

    // === Step 4: Tachanun ===
    if (tefila == TefilaType.shacharit) {
      flow.sayTachanun = day.sayTachanun;
      // Monday/Thursday = long tachanun (with ואנחנו לא נדע)
      flow.longTachanun = day.sayTachanun && (day.dayOfWeek == 1 || day.dayOfWeek == 4);
    } else if (tefila == TefilaType.mincha) {
      flow.sayTachanun = day.sayTachanunAtMincha;
      flow.longTachanun = false; // Never long tachanun at mincha
    } else {
      flow.sayTachanun = false; // Never tachanun at arvit
    }

    // === Step 5: Lamenatzeach (depends on tachanun) ===
    if (tefila == TefilaType.shacharit) {
      flow.sayLamenatzeach = flow.sayTachanun && minhag.sayLamenatzeach;
    }

    // === Step 6: Mizmor Letoda (shacharit, not on Shabbat/YT/erev Pesach) ===
    if (tefila == TefilaType.shacharit && minhag.sayMizmorLetoda) {
      flow.sayMizmorLetoda = !day.isShabbat && !day.isYomTov
          && !(day.jewishMonth == 1 && day.jewishDay == 14); // erev Pesach
    }

    // === Step 7: Avinu Malkeinu ===
    if (tefila == TefilaType.shacharit || tefila == TefilaType.mincha) {
      if (day.isAseretYemeiTshuva && !day.isShabbat) {
        flow.sayAvinuMalkeinu = true;
      }
      if (day.fastDay != FastDayType.none && day.fastDay != FastDayType.yomKippur
          && minhag.avinuMalkeinuOnFasts && !day.isShabbat) {
        flow.sayAvinuMalkeinu = true;
      }
    }

    // === Step 8: Sefirat HaOmer (arvit only) ===
    if (tefila == TefilaType.arvit && day.isOmerSeason) {
      flow.sayOmer = true;
      flow.omerDay = day.omerDay;
    }

    // === Step 9: Ledavid Hashem Ori (Elul through Sukkot/Shmini Atzeret) ===
    if (minhag.sayLedavidHaOri) {
      final m = day.jewishMonth;
      final d = day.jewishDay;
      // Elul (month 6) or Tishrei until stop day
      if (m == 6 || (m == 7 && d <= minhag.ledavidStopDay)) {
        flow.sayLedavidHaOri = true;
      }
    }

    // === Step 10: Musaf ===
    if (tefila == TefilaType.musaf) {
      if (day.isShabbatRoshChodesh) {
        flow.musafType = 'shabbat_rosh_chodesh'; // אתה יצרת
      } else if (day.isShabbatCholHamoed) {
        flow.musafType = 'shabbat_chol_hamoed';
      } else if (day.isShabbat) {
        flow.musafType = 'shabbat'; // תכנת שבת
      } else if (day.isYomTov) {
        flow.musafType = 'yom_tov';
      } else if (day.isRoshChodesh) {
        flow.musafType = 'rosh_chodesh';
      } else if (day.isCholHamoed) {
        flow.musafType = 'chol_hamoed';
      }
    }

    // === Step 11: Kedusha version ===
    if (day.isShabbat || day.isYomTov) {
      flow.kedushaType = (tefila == TefilaType.musaf) ? 'musaf' : 'shabbat';
    } else {
      flow.kedushaType = 'weekday';
    }

    // === Step 12: Torah reading ===
    if (tefila == TefilaType.shacharit) {
      if (day.isShabbat || day.isYomTov || day.isCholHamoed || day.isRoshChodesh
          || day.dayOfWeek == 1 || day.dayOfWeek == 4 // Monday, Thursday
          || day.isChanukah || day.isPurim
          || day.fastDay != FastDayType.none) {
        flow.hasTorahReading = true;
      }
    }
    if (tefila == TefilaType.mincha) {
      if (day.isShabbat || day.fastDay != FastDayType.none) {
        flow.hasTorahReading = true;
      }
    }

    // === Step 13: Shir Shel Yom (after shacharit) ===
    if (tefila == TefilaType.shacharit) {
      flow.shirShelYom = _getShirShelYom(day.dayOfWeek);
    }

    return flow;
  }

  static String _getShirShelYom(int dayOfWeek) {
    // dayOfWeek: 1=Mon, 2=Tue... 6=Sat, 7=Sun
    return switch (dayOfWeek) {
      7 => 'יום ראשון - מזמור כ"ד: "לַה\' הָאָרֶץ וּמְלוֹאָהּ"',
      1 => 'יום שני - מזמור מ"ח: "גָּדוֹל ה\' וּמְהֻלָּל מְאֹד"',
      2 => 'יום שלישי - מזמור פ"ב: "אֱלֹהִים נִצָּב בַּעֲדַת אֵל"',
      3 => 'יום רביעי - מזמור צ"ד: "אֵל נְקָמוֹת ה\'"',
      4 => 'יום חמישי - מזמור פ"א: "הַרְנִינוּ לֵאלֹהִים עוּזֵּנוּ"',
      5 => 'יום שישי - מזמור צ"ג: "ה\' מָלָךְ גֵּאוּת לָבֵשׁ"',
      6 => 'שבת - מזמור צ"ב: "מִזְמוֹר שִׁיר לְיוֹם הַשַּׁבָּת"',
      _ => '',
    };
  }
}

/// Complete prayer flow for a specific tefila
class PrayerFlow {
  final TefilaType tefila;
  final SiddurDayInfo day;
  final String nusach;

  // Amidah
  AmidaStructure amidaStructure = AmidaStructure.weekday;
  List<AmidaInsertion> insertions = [];

  // Hallel
  HallelType hallelType = HallelType.none;
  bool hallelBracha = false;

  // Tachanun
  bool sayTachanun = true;
  bool longTachanun = false; // Monday/Thursday extended version

  // Additional elements
  bool sayLamenatzeach = true;
  bool sayMizmorLetoda = true;
  bool sayAvinuMalkeinu = false;
  bool sayOmer = false;
  int omerDay = 0;
  bool sayLedavidHaOri = false;
  String? musafType;
  String kedushaType = 'weekday';
  bool hasTorahReading = false;
  String shirShelYom = '';

  PrayerFlow({required this.tefila, required this.day, required this.nusach});

  /// Human-readable summary of this tefila's modifications
  List<String> getSummary() {
    final items = <String>[];

    // Amidah type
    items.add('📖 עמידה: ${_amidaName()}');

    // Insertions
    for (final ins in insertions) {
      items.add('  ${_insertionName(ins)}');
    }

    // Hallel
    if (hallelType == HallelType.full) {
      items.add(hallelBracha ? '✅ הלל שלם עם ברכה' : '✅ הלל שלם');
    } else if (hallelType == HallelType.half) {
      items.add(hallelBracha ? '✅ חצי הלל עם ברכה' : '✅ חצי הלל (בלי ברכה)');
    }

    // Tachanun
    if (!sayTachanun) {
      items.add('❌ אין תחנון');
    } else if (longTachanun) {
      items.add('✅ תחנון ארוך (שני/חמישי)');
    } else {
      items.add('✅ תחנון');
    }

    if (!sayLamenatzeach && tefila == TefilaType.shacharit) items.add('❌ אין למנצח');
    if (!sayMizmorLetoda && tefila == TefilaType.shacharit) items.add('❌ אין מזמור לתודה');
    if (sayAvinuMalkeinu) items.add('✅ אבינו מלכנו');
    if (sayOmer) items.add('✅ ספירת העומר - יום $omerDay');
    if (sayLedavidHaOri) items.add('✅ לדוד ה\' אורי');
    if (hasTorahReading) items.add('📜 קריאת התורה');
    if (shirShelYom.isNotEmpty) items.add('🎵 $shirShelYom');
    if (musafType != null) items.add('📌 מוסף: ${_musafName()}');

    return items;
  }

  String _amidaName() => switch (amidaStructure) {
    AmidaStructure.weekday => '19 ברכות (חול)',
    AmidaStructure.shabbat => '7 ברכות (שבת)',
    AmidaStructure.yomTov => '7 ברכות (יו"ט)',
    AmidaStructure.musafShabbat => 'מוסף שבת (תכנת שבת)',
    AmidaStructure.musafRoshChodesh => 'מוסף ר"ח',
    AmidaStructure.musafShabbatRoshChodesh => 'מוסף שבת ר"ח (אתה יצרת)',
    AmidaStructure.musafCholHaMoed => 'מוסף חוה"מ',
    AmidaStructure.musafYomTov => 'מוסף יו"ט',
  };

  String _musafName() => switch (musafType) {
    'shabbat' => 'תכנת שבת',
    'shabbat_rosh_chodesh' => 'אתה יצרת (שבת ר"ח)',
    'shabbat_chol_hamoed' => 'שבת חוה"מ',
    'yom_tov' => 'יו"ט',
    'rosh_chodesh' => 'ר"ח',
    'chol_hamoed' => 'חוה"מ',
    _ => '',
  };

  String _insertionName(AmidaInsertion ins) => switch (ins) {
    AmidaInsertion.zachrenu => '+ זכרנו לחיים (ברכה א)',
    AmidaInsertion.mashivHaruach => '+ משיב הרוח ומוריד הגשם (ברכה ב)',
    AmidaInsertion.moridHatal => '+ מוריד הטל (ברכה ב)',
    AmidaInsertion.miKamocha => '+ מי כמוך (ברכה ב)',
    AmidaInsertion.hamelechHakadosh => '⚠️ המלך הקדוש (ברכה ג)',
    AmidaInsertion.veteinTalUmatar => '+ ותן טל ומטר (ברכה ט)',
    AmidaInsertion.veteinBracha => '+ ותן ברכה (ברכה ט)',
    AmidaInsertion.hamelechHamishpat => '⚠️ המלך המשפט (ברכה יא)',
    AmidaInsertion.aneinuIndividual => '+ עננו (בשמע קולנו)',
    AmidaInsertion.aneinuChazzan => '+ עננו (ברכה בפני עצמה, ש"ץ)',
    AmidaInsertion.yaalehVyavo => '+ יעלה ויבוא (ברכה יז)',
    AmidaInsertion.alHanissim => '+ על הניסים (ברכה יח)',
    AmidaInsertion.ukhtov => '+ וכתוב לחיים (ברכה יח)',
    AmidaInsertion.modimDerabbanan => '+ מודים דרבנן (חזרה)',
    AmidaInsertion.besefer => '+ בספר חיים (ברכה אחרונה)',
    AmidaInsertion.birkatKohanim => '+ ברכת כהנים (חזרה)',
  };
}
