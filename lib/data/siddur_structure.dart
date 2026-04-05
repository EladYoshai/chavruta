import 'dart:convert';
import 'package:http/http.dart' as http;

class PrayerItem {
  final String name;
  final String ref; // Sefaria ref for this nusach
  final bool isComplex; // needs sub-section fetching

  const PrayerItem({
    required this.name,
    required this.ref,
    this.isComplex = false,
  });
}

class PrayerCategory {
  final String name;
  final String icon;
  final List<PrayerItem> items;

  const PrayerCategory({
    required this.name,
    required this.icon,
    required this.items,
  });
}

/// Maps Sefaria section groups to our display categories
class _CategoryDef {
  final String name;
  final String icon;
  final Map<String, List<String>> groupNames; // nusach -> Sefaria group names
  const _CategoryDef(this.name, this.icon, this.groupNames);
}

class SiddurStructure {
  static List<PrayerCategory>? _cachedCategories;
  static String? _cachedNusach;

  static const _siddurBooks = {
    'ashkenaz': 'Siddur_Ashkenaz',
    'sefard': 'Siddur_Sefard',
    'edot_hamizrach': 'Siddur_Edot_HaMizrach',
  };

  static const List<_CategoryDef> _categoryDefs = [
    _CategoryDef('שחרית', '🌅', {
      'sefard': ['Upon Arising', 'Weekday Shacharit'],
      'edot_hamizrach': ['Preparatory Prayers', 'Weekday Shacharit'],
      'ashkenaz': ['Weekday/Shacharit'],
    }),
    _CategoryDef('מנחה', '☀️', {
      'sefard': ['Weekday Mincha'],
      'edot_hamizrach': ['Weekday Mincha'],
      'ashkenaz': ['Weekday/Minchah'],
    }),
    _CategoryDef('ערבית', '🌙', {
      'sefard': ['Weekday Maariv'],
      'edot_hamizrach': ['Weekday Arvit'],
      'ashkenaz': ['Weekday/Maariv'],
    }),
    _CategoryDef('קבלת שבת', '✡️', {
      'sefard': ['Kabbalat Shabbat', 'Shabbat Eve Maariv'],
      'edot_hamizrach': ['Kabbalat Shabbat', 'Shabbat Arvit'],
      'ashkenaz': ['Shabbat/Kabbalat Shabbat', 'Shabbat/Maariv'],
    }),
    _CategoryDef('סעודת ליל שבת', '🕯️', {
      'sefard': ['Shabbat Evening Meal'],
      'edot_hamizrach': ['Shabbat Evening'],
      'ashkenaz': ['Shabbat/Shabbat Evening'],
    }),
    _CategoryDef('שחרית שבת', '📖', {
      'sefard': ['Shabbat Morning Services'],
      'edot_hamizrach': ['Shabbat Shacharit'],
      'ashkenaz': ['Shabbat/Shacharit'],
    }),
    _CategoryDef('מוסף שבת', '📜', {
      'sefard': ['Musaf'],
      'edot_hamizrach': ['Shabbat Mussaf'],
      'ashkenaz': ['Shabbat/Musaf LeShabbat'],
    }),
    _CategoryDef('סעודת יום שבת', '🍷', {
      'sefard': ['Shabbat Day Meal'],
      'edot_hamizrach': ['Daytime Meal'],
      'ashkenaz': ['Shabbat/Daytime Meal'],
    }),
    _CategoryDef('מנחה שבת', '🌤️', {
      'sefard': ['Shabbat Mincha'],
      'edot_hamizrach': ['Shabbat Mincha'],
      'ashkenaz': ['Shabbat/Minchah'],
    }),
    _CategoryDef('סעודה שלישית', '🕊️', {
      'sefard': ['Third Meal'],
      'edot_hamizrach': ['Third Meal'],
      'ashkenaz': ['Shabbat/Third Meal'],
    }),
    _CategoryDef('הבדלה', '🔥', {
      'sefard': ['Motzaei Shabbat '],
      'edot_hamizrach': ['Havdalah'],
      'ashkenaz': ['Shabbat/Shabbat'],
    }),
    _CategoryDef('ברכת המזון', '🍞', {
      'sefard': ['Birchat HaMazon'],
      'edot_hamizrach': ['Post Meal Blessing', 'Al Hamihya'],
      'ashkenaz': ['Berachot/Berachot'],
    }),
    _CategoryDef('ברכות', '🙏', {
      'sefard': ['Blessings'],
      'edot_hamizrach': ['Blessings on Enjoyments', 'Assorted Blessings and Prayers'],
      'ashkenaz': ['Berachot/Birkat Hanehenin'],
    }),
    _CategoryDef('קריאת שמע על המיטה', '🛏️', {
      'sefard': ['Bedtime Shema'],
      'edot_hamizrach': ['Bedtime Shema'],
      'ashkenaz': ['Weekday/Maariv'],
    }),
  ];

  /// Load categories from Sefaria index API for a given nusach
  static Future<List<PrayerCategory>> loadCategories(String nusach) async {
    if (_cachedCategories != null && _cachedNusach == nusach) {
      return _cachedCategories!;
    }

    final book = _siddurBooks[nusach] ?? 'Siddur_Sefard';

    try {
      final url = Uri.parse('https://www.sefaria.org/api/v2/index/$book');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return _fallbackCategories(nusach);

      final data = json.decode(response.body);
      final nodes = (data['schema']?['nodes'] as List?) ?? [];

      // Build a flat list of all leaves grouped by top-level section
      final Map<String, List<PrayerItem>> groupedItems = {};
      _walkNodes(nodes, book, [], groupedItems);

      // Map to our display categories
      final categories = <PrayerCategory>[];
      for (final def in _categoryDefs) {
        final groupNames = def.groupNames[nusach] ?? [];
        final items = <PrayerItem>[];
        for (final gn in groupNames) {
          items.addAll(groupedItems[gn] ?? []);
        }
        if (items.isNotEmpty) {
          categories.add(PrayerCategory(
            name: def.name,
            icon: def.icon,
            items: items,
          ));
        }
      }

      // Insert ספירת העומר after ערבית
      final omerRefs = {
        'sefard': 'Siddur_Sefard,_Weekday_Maariv,_Sefirat_HaOmer',
        'edot_hamizrach': 'Siddur_Edot_HaMizrach,_Counting_of_the_Omer',
        'ashkenaz': 'Siddur_Ashkenaz,_Weekday,_Maariv,_Sefirat_HaOmer',
      };
      final omerRef = omerRefs[nusach] ?? omerRefs['sefard']!;
      final omerCategory = PrayerCategory(
        name: 'ספירת העומר',
        icon: '🌾',
        items: [PrayerItem(name: 'ספירת העומר', ref: omerRef)],
      );
      // Find ערבית index and insert after it
      final arvitIndex = categories.indexWhere((c) => c.name == 'ערבית');
      if (arvitIndex >= 0) {
        categories.insert(arvitIndex + 1, omerCategory);
      } else {
        categories.add(omerCategory);
      }

      _cachedCategories = categories;
      _cachedNusach = nusach;
      return categories;
    } catch (_) {
      return _fallbackCategories(nusach);
    }
  }

  static void _walkNodes(
    List<dynamic> nodes,
    String book,
    List<String> pathParts,
    Map<String, List<PrayerItem>> grouped,
  ) {
    for (final node in nodes) {
      final title = node['title']?.toString() ?? '';
      final heTitle = node['heTitle']?.toString() ?? '';
      final sub = node['nodes'] as List?;
      final currentPath = [...pathParts, title];

      if (sub != null && sub.isNotEmpty) {
        _walkNodes(sub, book, currentPath, grouped);
      } else {
        // Leaf node
        final ref = '$book, ${currentPath.join(', ')}'
            .replaceAll(' ', '_')
            .replaceAll(',_,', ',');

        // Group by top-level, and also by top/second-level for Ashkenaz
        final topGroup = pathParts.isNotEmpty ? pathParts[0] : title;
        final level2Group = pathParts.length > 1
            ? '${pathParts[0]}/${pathParts[1]}'
            : topGroup;

        // Add to both grouping keys so both Sefard (level 1) and Ashkenaz (level 1/2) work
        grouped.putIfAbsent(topGroup, () => []);
        grouped[topGroup]!.add(PrayerItem(name: heTitle, ref: ref));

        if (level2Group != topGroup) {
          grouped.putIfAbsent(level2Group, () => []);
          grouped[level2Group]!.add(PrayerItem(name: heTitle, ref: ref));
        }
      }
    }
  }

  /// Ashkenaz special handling: some sections are "complex" book-level refs
  /// For Ashkenaz, the Weekday section is nested under "Weekday" then "Shacharit"/"Minchah"/"Maariv"
  /// We need special mapping

  static List<PrayerCategory> _fallbackCategories(String nusach) {
    // Minimal fallback if API fails
    return [
      PrayerCategory(name: 'שחרית', icon: '🌅', items: [
        PrayerItem(name: 'שחרית', ref: nusach == 'sefard'
            ? 'Siddur_Sefard,_Weekday_Shacharit,_Amidah'
            : nusach == 'edot_hamizrach'
                ? 'Siddur_Edot_HaMizrach,_Weekday_Shacharit,_Amida'
                : 'Siddur_Ashkenaz,_Weekday,_Shacharit,_Amidah,_Patriarchs'),
      ]),
    ];
  }

  static String getNusachDisplayName(String nusach) {
    switch (nusach) {
      case 'ashkenaz': return 'אשכנז';
      case 'sefard': return 'ספרד (חסידי)';
      case 'edot_hamizrach': return 'עדות המזרח';
      default: return 'אשכנז';
    }
  }
}
