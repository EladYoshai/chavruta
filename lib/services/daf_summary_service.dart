import 'dart:convert';
import 'package:flutter/services.dart';

/// Service to load pre-generated Daf Yomi summaries from bundled JSON.
/// Summaries are generated offline by the generate_summaries.py script
/// and bundled in assets/data/daf_summaries.json
class DafSummaryService {
  static Map<String, Map<String, String>>? _cache;

  /// Load the summary database from assets
  static Future<void> init() async {
    if (_cache != null) return;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/daf_summaries.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      _cache = {};
      for (final entry in data.entries) {
        final value = entry.value as Map<String, dynamic>;
        _cache![entry.key] = {
          'summary': value['summary']?.toString() ?? '',
          'deepDive': value['deepDive']?.toString() ?? '',
        };
      }
    } catch (_) {
      _cache = {};
    }
  }

  /// Normalize a daf ref: "Menachot.83" -> try "Menachot.83a" if no match
  static String _normalizeRef(String dafRef) {
    final clean = dafRef.replaceAll(' ', '_');
    if (_cache!.containsKey(clean)) return clean;
    // Sefaria calendar returns "Menachot.83" without a/b suffix
    // Try appending 'a' (the daf always starts with amud alef)
    if (!clean.endsWith('a') && !clean.endsWith('b')) {
      final withA = '${clean}a';
      if (_cache!.containsKey(withA)) return withA;
    }
    return clean;
  }

  /// Get the Hebrew summary for a specific daf reference
  /// e.g., "Berakhot.2a", "Menachot.79a", "Menachot.83"
  static String? getSummary(String dafRef) {
    if (_cache == null) return null;
    final key = _normalizeRef(dafRef);
    return _cache![key]?['summary'];
  }

  /// Get the deep dive (Tosafot/Rishonim explanation) for a daf
  static String? getDeepDive(String dafRef) {
    if (_cache == null) return null;
    final key = _normalizeRef(dafRef);
    return _cache![key]?['deepDive'];
  }

  /// Check if a summary exists for a daf
  static bool hasSummary(String dafRef) {
    if (_cache == null) return false;
    final key = _normalizeRef(dafRef);
    return _cache!.containsKey(key) &&
        (_cache![key]!['summary']?.isNotEmpty ?? false);
  }
}
