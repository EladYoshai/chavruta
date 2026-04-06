import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final String sectionKey; // e.g. 'gemara', 'tehillim'
  final String sectionTitle; // e.g. 'דף יומי'
  final String hebrewRef; // e.g. 'מנחות דף פג עמוד א'
  final String? sefariaRef; // e.g. 'Menachot.83a' (for navigation)
  final DateTime savedAt;

  Bookmark({
    required this.sectionKey,
    required this.sectionTitle,
    required this.hebrewRef,
    this.sefariaRef,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'sectionKey': sectionKey,
        'sectionTitle': sectionTitle,
        'hebrewRef': hebrewRef,
        'sefariaRef': sefariaRef,
        'savedAt': savedAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        sectionKey: json['sectionKey'] ?? '',
        sectionTitle: json['sectionTitle'] ?? '',
        hebrewRef: json['hebrewRef'] ?? '',
        sefariaRef: json['sefariaRef'],
        savedAt: DateTime.parse(json['savedAt']),
      );
}

class BookmarkService {
  static const String _key = 'bookmarks';
  static const int _maxBookmarks = 50;

  static Future<List<Bookmark>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final list = json.decode(data) as List;
    return list.map((e) => Bookmark.fromJson(e)).toList();
  }

  static Future<void> addBookmark(Bookmark bookmark) async {
    final bookmarks = await loadBookmarks();
    // Remove duplicate (same section + ref)
    bookmarks.removeWhere((b) =>
        b.sectionKey == bookmark.sectionKey &&
        b.hebrewRef == bookmark.hebrewRef);
    bookmarks.insert(0, bookmark);
    // Limit
    if (bookmarks.length > _maxBookmarks) {
      bookmarks.removeRange(_maxBookmarks, bookmarks.length);
    }
    await _save(bookmarks);
  }

  static Future<void> removeBookmark(int index) async {
    final bookmarks = await loadBookmarks();
    if (index < bookmarks.length) {
      bookmarks.removeAt(index);
      await _save(bookmarks);
    }
  }

  static Future<void> _save(List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(bookmarks.map((b) => b.toJson()).toList()));
  }
}
