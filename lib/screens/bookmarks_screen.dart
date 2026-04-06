import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/study_section.dart';
import '../services/bookmark_service.dart';
import '../utils/constants.dart';
import 'study_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _bookmarks = await BookmarkService.loadBookmarks();
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  StudySection? _findSection(String key) {
    try {
      return StudySection.dailySections.firstWhere((s) => s.key == key);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('סימניות'),
        backgroundColor: AppColors.darkGold,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkGold))
          : _bookmarks.isEmpty
              ? Center(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔖', style: TextStyle(fontSize: 50)),
                        const SizedBox(height: 16),
                        Text(
                          'אין סימניות שמורות',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'לחצו על 🔖 בזמן לימוד כדי לשמור את המקום',
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final bm = _bookmarks[index];
                      final section = _findSection(bm.sectionKey);

                      return Dismissible(
                        key: Key('${bm.sectionKey}_${bm.hebrewRef}_${bm.savedAt}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        onDismissed: (_) async {
                          await BookmarkService.removeBookmark(index);
                          setState(() => _bookmarks.removeAt(index));
                        },
                        child: GestureDetector(
                          onTap: () {
                            if (section != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudyScreen(
                                    section: section,
                                    initialRef: bm.sefariaRef,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (section?.color ?? AppColors.gold)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (section?.color ?? AppColors.gold)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    section?.icon ?? Icons.bookmark,
                                    color: section?.color ?? AppColors.gold,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bm.sectionTitle,
                                        style: GoogleFonts.rubik(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: section?.color ??
                                              AppColors.darkBrown,
                                        ),
                                      ),
                                      Text(
                                        bm.hebrewRef,
                                        style: GoogleFonts.rubik(
                                          fontSize: 13,
                                          color: AppColors.darkBrown,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(bm.savedAt),
                                        style: GoogleFonts.rubik(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_back_ios,
                                    size: 14, color: AppColors.darkGold),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
