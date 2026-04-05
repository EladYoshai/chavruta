import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CalendarInfo {
  final String parshaName;
  final String parshaHeName;
  final String parshaRef;
  final String haftarahRef;
  final String dafYomiRef;
  final String halachaYomitRef;
  final String mishnaYomitRef;
  final String tanyaYomiRef;
  final List<String> aliyot;

  CalendarInfo({
    required this.parshaName,
    required this.parshaHeName,
    required this.parshaRef,
    required this.haftarahRef,
    required this.dafYomiRef,
    required this.halachaYomitRef,
    required this.mishnaYomitRef,
    required this.tanyaYomiRef,
    required this.aliyot,
  });
}

class SefariaService {
  static const String baseUrl = 'https://www.sefaria.org/api';
  static const Duration _timeout = Duration(seconds: 15);

  // Singleton
  static final SefariaService instance = SefariaService._internal();
  factory SefariaService() => instance;
  SefariaService._internal();

  CalendarInfo? _cachedCalendar;
  String? _cachedCalendarDate;

  // Simple in-memory cache for texts
  final Map<String, Map<String, dynamic>> _textCache = {};
  static const int _maxCacheSize = 50;

  /// HTTP GET with timeout and retry
  Future<http.Response> _getWithRetry(Uri url, {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        final response = await http.get(url).timeout(_timeout);
        if (response.statusCode == 200) return response;
        if (i < retries && response.statusCode >= 500) {
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
          continue;
        }
        return response;
      } on TimeoutException {
        if (i < retries) {
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
          continue;
        }
        return http.Response('{"error": "timeout"}', 408);
      } catch (e) {
        if (i < retries) {
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
          continue;
        }
        rethrow;
      }
    }
    return http.Response('{"error": "failed"}', 500);
  }

  /// Fetch a text by reference
  Future<Map<String, dynamic>> getText(String ref) async {
    // Check cache first
    if (_textCache.containsKey(ref)) return _textCache[ref]!;

    // Use Uri.parse to preserve commas in Sefaria refs (Uri.https encodes them)
    final url = Uri.parse('https://www.sefaria.org/api/v3/texts/$ref');
    final response = await _getWithRetry(url);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      // Cache the result
      if (_textCache.length >= _maxCacheSize) {
        _textCache.remove(_textCache.keys.first);
      }
      _textCache[ref] = data;
      return data;
    } else if (data.containsKey('error')) {
      // Return error data (e.g., "complex" book-level refs) so caller can handle
      return data;
    } else {
      throw Exception('Failed to load text: $ref (${response.statusCode})');
    }
  }

  /// Fetch today's calendar and cache it
  Future<CalendarInfo> getCalendarInfo() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_cachedCalendar != null && _cachedCalendarDate == today) {
      return _cachedCalendar!;
    }

    final url = Uri.parse('https://www.sefaria.org/api/calendars');
    final response = await _getWithRetry(url);
    if (response.statusCode != 200) throw Exception('Failed to load calendars');

    final data = json.decode(response.body);
    final items = data['calendar_items'] as List;

    String parshaName = '';
    String parshaHeName = '';
    String parshaRef = 'Genesis.1';
    String haftarahRef = '';
    String dafYomiRef = '';
    String halachaYomitRef = '';
    String mishnaYomitRef = '';
    String tanyaYomiRef = '';
    List<String> aliyot = [];

    for (final item in items) {
      final title = item['title']?['en'] ?? '';
      if (title == 'Parashat Hashavua') {
        parshaName = item['displayValue']?['en'] ?? '';
        parshaHeName = item['displayValue']?['he'] ?? '';
        parshaRef = (item['url'] ?? item['ref'] ?? 'Genesis.1')
            .toString()
            .replaceAll(' ', '_');
        final details = item['extraDetails'];
        if (details != null && details['aliyot'] != null) {
          aliyot = List<String>.from(details['aliyot']);
        }
      } else if (title == 'Haftarah') {
        haftarahRef = (item['url'] ?? item['ref'] ?? '').toString();
      } else if (title == 'Daf Yomi') {
        dafYomiRef = (item['url'] ?? item['ref'] ?? '').toString().replaceAll(' ', '_');
      } else if (title == 'Halakhah Yomit') {
        halachaYomitRef = (item['url'] ?? item['ref'] ?? '').toString().replaceAll(' ', '_');
      } else if (title == 'Daily Mishnah') {
        mishnaYomitRef = (item['url'] ?? item['ref'] ?? '').toString().replaceAll(' ', '_');
      } else if (title == 'Tanya Yomi') {
        tanyaYomiRef = (item['url'] ?? item['ref'] ?? '').toString().replaceAll(' ', '_');
      }
    }

    _cachedCalendar = CalendarInfo(
      parshaName: parshaName,
      parshaHeName: parshaHeName,
      parshaRef: parshaRef,
      haftarahRef: haftarahRef,
      dafYomiRef: dafYomiRef,
      halachaYomitRef: halachaYomitRef,
      mishnaYomitRef: mishnaYomitRef,
      tanyaYomiRef: tanyaYomiRef,
      aliyot: aliyot,
    );
    _cachedCalendarDate = today;
    return _cachedCalendar!;
  }

  /// Get the daily Tehillim chapter based on the day of the Hebrew month
  Future<Map<String, dynamic>> getDailyTehillim(int dayOfMonth) async {
    final ref = _tehillimDayRanges[dayOfMonth] ?? 'Psalms.1';
    return getText(ref);
  }

  /// Get individual tehillim chapters for the day, each with its own perek number
  Future<List<Map<String, dynamic>>> getDailyTehillimByChapter(int dayOfMonth) async {
    final range = _tehillimDayChapters[dayOfMonth] ?? [1];
    final results = <Map<String, dynamic>>[];
    for (final chapter in range) {
      try {
        final data = await getText('Psalms.$chapter');
        results.add({
          'chapter': chapter,
          'heRef': data['heRef']?.toString() ?? 'פרק $chapter',
          'text': _extractHebrewText(data),
        });
      } catch (_) {
        // Skip failed chapters
      }
    }
    return results;
  }

  /// Fetch one amud of Gemara with Rashi, Tosafot, Steinsaltz
  Future<Map<String, dynamic>> getAmudFull(String amudRef) async {
    final cleanRef = amudRef.replaceAll(' ', '_');

    final gemaraData = await getText(cleanRef);
    if (gemaraData.containsKey('error')) {
      return {'gemara': <String>[], 'rashi': <String>[], 'tosafot': <String>[], 'steinsaltz': <String>[], 'heRef': amudRef};
    }

    final rashiData = await _safeGetText('Rashi_on_$cleanRef');
    final tosafotData = await _safeGetText('Tosafot_on_$cleanRef');
    final steinsaltzData = await _safeGetText('Steinsaltz_on_$cleanRef');

    return {
      'gemara': _extractHebrewText(gemaraData),
      'rashi': rashiData != null ? _extractHebrewText(rashiData) : <String>[],
      'tosafot': tosafotData != null ? _extractHebrewText(tosafotData) : <String>[],
      'steinsaltz': steinsaltzData != null ? _extractHebrewText(steinsaltzData) : <String>[],
      'heRef': gemaraData['heRef']?.toString() ?? amudRef,
    };
  }

  /// Get both amudim refs for a daf ref (e.g., "Menachot.83" -> ["Menachot.83a", "Menachot.83b"])
  List<String> getDafAmudim(String ref) {
    final cleanRef = ref.replaceAll(' ', '_');
    if (cleanRef.endsWith('a') || cleanRef.endsWith('b')) {
      // Already a specific amud
      return [cleanRef];
    }
    // Full daf - return both amudim
    return ['${cleanRef}a', '${cleanRef}b'];
  }

  /// Fetch Daily Mishnah with Bartenura commentary
  Future<Map<String, dynamic>> getMishnaYomit(String mishnaRef) async {
    final cleanRef = mishnaRef.replaceAll(' ', '_').replaceAll(':', '.');
    final mishnaData = await getText(cleanRef);
    final heRef = mishnaData['heRef']?.toString() ?? mishnaRef;

    // Extract masechet + chapter for Bartenura ref
    // e.g., "Mishnah_Tamid.3.8-9" -> "Bartenura_on_Mishnah_Tamid.3"
    final bartenuraRef = cleanRef.replaceFirst('Mishnah_', 'Bartenura_on_Mishnah_');
    final bartenuraData = await _safeGetText(bartenuraRef);

    return {
      'mishna': _extractHebrewText(mishnaData),
      'bartenura': bartenuraData != null ? _extractHebrewText(bartenuraData) : <String>[],
      'heRef': heRef,
    };
  }

  /// Fetch Shnayim Mikra: returns {mikra, onkelos, rashi} for a given aliyah/parsha ref
  Future<Map<String, List<String>>> getShnayimMikra(String parshaRef) async {
    // Convert ref format: "Exodus 33:12-34:26" -> "Exodus.33.12-34.26"
    final cleanRef = parshaRef.replaceAll(' ', '_').replaceAll(':', '.');

    final mikraData = await getText(cleanRef);
    final onkelosData = await _safeGetText('Onkelos_$cleanRef');
    final rashiData = await _safeGetText('Rashi_on_$cleanRef');

    return {
      'mikra': _extractHebrewText(mikraData),
      'onkelos': onkelosData != null ? _extractHebrewText(onkelosData) : [],
      'rashi': rashiData != null ? _extractHebrewText(rashiData) : [],
    };
  }

  /// Fetch Halacha Yomit from Shulchan Aruch + commentary
  /// If [useSefardi] is true, uses Kaf HaChaim instead of Mishna Brura
  Future<Map<String, List<String>>> getHalachaYomit(
    String halachaRef, {
    bool useSefardi = false,
  }) async {
    final cleanRef = halachaRef.replaceAll(' ', '_').replaceAll(':', '.');
    // Get the Shulchan Aruch text
    final saData = await getText(cleanRef);
    final saText = _extractHebrewText(saData);
    final heRef = saData['heRef'] ?? halachaRef;

    // Extract siman number from ref like "Shulchan_Arukh,_Orach_Chayim.170.3-5"
    final simanMatch = RegExp(r'(\d+)\.(\d+)').firstMatch(cleanRef);
    List<String> commentaryText = [];
    if (simanMatch != null) {
      final siman = simanMatch.group(1);
      if (useSefardi) {
        // Kaf HaChaim for Sefardi users
        final kafData = await _safeGetText(
            'Kaf_HaChayim_on_Shulchan_Arukh,_Orach_Chayim.$siman');
        if (kafData != null) {
          commentaryText = _extractHebrewText(kafData);
        }
      }
      if (commentaryText.isEmpty) {
        // Mishna Brura (default or fallback)
        final mbData = await _safeGetText('Mishnah_Berurah.$siman');
        if (mbData != null) {
          commentaryText = _extractHebrewText(mbData);
        }
      }
    }

    return {
      'shulchan_aruch': saText,
      'commentary': commentaryText,
      'heRef': [heRef.toString()],
    };
  }

  /// Fetch Gemara with Rashi and Tosafot
  Future<Map<String, List<String>>> getGemaraWithCommentary(String ref) async {
    final cleanRef = ref.replaceAll(' ', '_');
    final gemaraData = await getText(cleanRef);
    final rashiData = await _safeGetText('Rashi_on_$cleanRef');
    final tosafotData = await _safeGetText('Tosafot_on_$cleanRef');

    return {
      'gemara': _extractHebrewText(gemaraData),
      'rashi': rashiData != null ? _extractHebrewText(rashiData) : [],
      'tosafot': tosafotData != null ? _extractHebrewText(tosafotData) : [],
      'heRef': [gemaraData['heRef']?.toString() ?? ref],
    };
  }

  /// Fetch Chassidut text related to parsha
  Future<Map<String, dynamic>> getChassidutOnParsha(String parshaName) async {
    // Try Sfat Emet first, then other sources
    final cleanName = parshaName.replaceAll(' ', '_');
    // Try different formats
    for (final prefix in [
      'Sefat_Emet,_Genesis,_$cleanName',
      'Sefat_Emet,_Exodus,_$cleanName',
      'Sefat_Emet,_Leviticus,_$cleanName',
      'Sefat_Emet,_Numbers,_$cleanName',
      'Sefat_Emet,_Deuteronomy,_$cleanName',
    ]) {
      final data = await _safeGetText(prefix);
      if (data != null) return data;
    }
    // Fallback
    return getText('Sefat_Emet,_Genesis,_Bereshit.1');
  }

  Future<Map<String, dynamic>?> _safeGetText(String ref) async {
    try {
      return await getText(ref);
    } catch (e) {
      // 404 is expected for missing commentary, don't log
      if (!e.toString().contains('404')) {
        debugPrint('SefariaService: Failed to fetch $ref: $e');
      }
      return null;
    }
  }

  /// Extract Hebrew text from Sefaria API response
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

  // Tehillim daily divisions (day of Hebrew month -> Psalms reference)
  static final Map<int, String> _tehillimDayRanges = {
    1: 'Psalms.1-9',
    2: 'Psalms.10-17',
    3: 'Psalms.18-22',
    4: 'Psalms.23-28',
    5: 'Psalms.29-34',
    6: 'Psalms.35-38',
    7: 'Psalms.39-43',
    8: 'Psalms.44-48',
    9: 'Psalms.49-54',
    10: 'Psalms.55-59',
    11: 'Psalms.60-65',
    12: 'Psalms.66-68',
    13: 'Psalms.69-71',
    14: 'Psalms.72-76',
    15: 'Psalms.77-78',
    16: 'Psalms.79-82',
    17: 'Psalms.83-87',
    18: 'Psalms.88-89',
    19: 'Psalms.90-96',
    20: 'Psalms.97-103',
    21: 'Psalms.104-105',
    22: 'Psalms.106-107',
    23: 'Psalms.108-112',
    24: 'Psalms.113-118',
    25: 'Psalms.119.1-119.88',
    26: 'Psalms.119.89-119.176',
    27: 'Psalms.120-134',
    28: 'Psalms.135-139',
    29: 'Psalms.140-144',
    30: 'Psalms.145-150',
  };

  // Tehillim daily divisions - individual chapters per day
  static final Map<int, List<int>> _tehillimDayChapters = {
    1: [1, 2, 3, 4, 5, 6, 7, 8, 9],
    2: [10, 11, 12, 13, 14, 15, 16, 17],
    3: [18, 19, 20, 21, 22],
    4: [23, 24, 25, 26, 27, 28],
    5: [29, 30, 31, 32, 33, 34],
    6: [35, 36, 37, 38],
    7: [39, 40, 41, 42, 43],
    8: [44, 45, 46, 47, 48],
    9: [49, 50, 51, 52, 53, 54],
    10: [55, 56, 57, 58, 59],
    11: [60, 61, 62, 63, 64, 65],
    12: [66, 67, 68],
    13: [69, 70, 71],
    14: [72, 73, 74, 75, 76],
    15: [77, 78],
    16: [79, 80, 81, 82],
    17: [83, 84, 85, 86, 87],
    18: [88, 89],
    19: [90, 91, 92, 93, 94, 95, 96],
    20: [97, 98, 99, 100, 101, 102, 103],
    21: [104, 105],
    22: [106, 107],
    23: [108, 109, 110, 111, 112],
    24: [113, 114, 115, 116, 117, 118],
    25: [119], // Just chapter 119 first half
    26: [119], // Chapter 119 second half
    27: [120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134],
    28: [135, 136, 137, 138, 139],
    29: [140, 141, 142, 143, 144],
    30: [145, 146, 147, 148, 149, 150],
  };
}
