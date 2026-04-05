import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../data/siddur_structure.dart';
import '../services/sefaria_service.dart';
import '../utils/constants.dart';
import '../widgets/torah_text_viewer.dart';

class SiddurScreen extends StatefulWidget {
  const SiddurScreen({super.key});

  @override
  State<SiddurScreen> createState() => _SiddurScreenState();
}

class _SiddurScreenState extends State<SiddurScreen> {
  List<PrayerCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

  Future<void> _loadStructure() async {
    final nusach = context.read<AppState>().progress.nusach;
    final cats = await SiddurStructure.loadCategories(nusach);
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nusach = context.watch<AppState>().progress.nusach;
    final nusachName = SiddurStructure.getNusachDisplayName(nusach);

    return Scaffold(
      appBar: AppBar(
        title: const Text('סידור'),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'נוסח $nusachName',
                  style: GoogleFonts.rubik(fontSize: 13, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  SizedBox(height: 16),
                  Text('...טוען סידור'),
                ],
              ),
            )
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, catIndex) {
                  final category = _categories[catIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(category.icon,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text(
                              category.name,
                              style: GoogleFonts.rubik(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(category.items.length, (itemIndex) {
                        final prayer = category.items[itemIndex];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrayerViewScreen(
                                category: category,
                                startIndex: itemIndex,
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF1B5E20)
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book,
                                    color: Color(0xFF1B5E20), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    prayer.name,
                                    style: GoogleFonts.rubik(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.darkBrown,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_back_ios,
                                    size: 14, color: Color(0xFF1B5E20)),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

/// Shows a prayer and auto-continues to the next one in the category
class PrayerViewScreen extends StatefulWidget {
  final PrayerCategory category;
  final int startIndex;

  const PrayerViewScreen({
    super.key,
    required this.category,
    required this.startIndex,
  });

  @override
  State<PrayerViewScreen> createState() => _PrayerViewScreenState();
}

class _PrayerViewScreenState extends State<PrayerViewScreen> {
  final SefariaService _sefaria = SefariaService();
  final ScrollController _scrollController = ScrollController();
  final List<_LoadedSection> _loadedSections = [];
  bool _isLoading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadSection(widget.startIndex);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadNextSection();
    }
  }

  Future<void> _loadSection(int index) async {
    if (index >= widget.category.items.length) return;

    final prayer = widget.category.items[index];
    List<String> segments = [];

    try {
      final data = await _sefaria.getText(prayer.ref);
      // Check for "complex" book-level error
      if (data.containsKey('error') &&
          data['error'].toString().contains('complex')) {
        segments = await _fetchComplexRef(prayer.ref);
      } else {
        final versions = data['versions'] as List?;
        if (versions != null) {
          for (final version in versions) {
            if (version['actualLanguage'] == 'he' &&
                version['text'] != null) {
              final text = version['text'];
              if (text is List) {
                segments = _flattenText(text);
              } else if (text is String) {
                segments = [text];
              }
              break;
            }
          }
        }
      }
    } catch (_) {}

    if (segments.isEmpty) {
      segments = ['לא ניתן לטעון את התפילה. נסה שוב מאוחר יותר.'];
    }

    if (mounted) {
      setState(() {
        _loadedSections.add(_LoadedSection(
          name: prayer.name,
          segments: segments,
        ));
        _isLoading = false;
      });
    }
  }

  /// Fetch all sub-sections for a complex Sefaria ref
  Future<List<String>> _fetchComplexRef(String ref) async {
    final amidahParts = [
      'Patriarchs', 'Divine_Might', 'Holiness_of_God',
      'Knowledge', 'Repentance', 'Forgiveness', 'Redemption',
      'Healing', 'Prosperity', 'Gathering_the_Exiles', 'Justice',
      'Against_Enemies', 'The_Righteous', 'Rebuilding_Jerusalem',
      'Kingdom_of_David', 'Response_to_Prayer', 'Temple_Service',
      'Thanksgiving', 'Peace', 'Concluding_Passage',
      // Shabbat-specific
      'Sanctity_of_the_Day', 'Birkat_Kohanim', 'Kedushah',
    ];

    final allSegments = <String>[];
    for (final part in amidahParts) {
      try {
        final subRef = '$ref,_$part';
        final data = await _sefaria.getText(subRef);
        if (data.containsKey('error')) continue;
        final versions = data['versions'] as List?;
        if (versions != null) {
          for (final version in versions) {
            if (version['actualLanguage'] == 'he' && version['text'] != null) {
              final text = version['text'];
              if (text is List) {
                allSegments.addAll(_flattenText(text));
              } else if (text is String && text.isNotEmpty) {
                allSegments.add(text);
              }
              break;
            }
          }
        }
      } catch (_) {
        continue;
      }
    }
    return allSegments;
  }

  void _autoLoadNext() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _loadNextSection();
    });
  }

  Future<void> _loadNextSection() async {
    if (_loadingMore) return;
    final nextIndex = widget.startIndex + _loadedSections.length;
    if (nextIndex >= widget.category.items.length) return;

    _loadingMore = true;
    await _loadSection(nextIndex);
    _loadingMore = false;
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

  @override
  Widget build(BuildContext context) {
    final currentPrayer = widget.category.items[widget.startIndex];
    final hasNext = widget.startIndex + _loadedSections.length <
        widget.category.items.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.name} - ${currentPrayer.name}'),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  SizedBox(height: 16),
                  Text('...טוען תפילה'),
                ],
              ),
            )
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _loadedSections.length + (hasNext ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _loadedSections.length) {
                    _autoLoadNext();
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    );
                  }

                  final section = _loadedSections[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      if (_loadedSections.length > 1 || index > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12, top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF1B5E20)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            section.name,
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      // Prayer text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: section.segments.map((segment) {
                            final clean =
                                TorahTextViewer.stripHtml(segment);
                            if (clean.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                clean,
                                style: GoogleFonts.rubik(
                                  fontSize: 20,
                                  height: 1.8,
                                  color: AppColors.darkBrown,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _LoadedSection {
  final String name;
  final List<String> segments;

  _LoadedSection({required this.name, required this.segments});
}
