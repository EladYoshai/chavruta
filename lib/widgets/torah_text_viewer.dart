import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// A single content block with a label and text segments
class TextBlock {
  final String label;
  final List<String> segments;
  final bool isBold;
  final Color? labelColor;

  const TextBlock({
    required this.label,
    required this.segments,
    this.isBold = false,
    this.labelColor,
  });
}

class TorahTextViewer extends StatelessWidget {
  final String title;
  final String hebrewRef;
  final List<TextBlock> blocks;
  final bool isLoading;
  final String? errorMessage;

  const TorahTextViewer({
    super.key,
    required this.title,
    required this.hebrewRef,
    required this.blocks,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.deepBlue),
            SizedBox(height: 16),
            Text('...טוען'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // Title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBlue,
                  ),
                ),
                if (hebrewRef.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    hebrewRef,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: AppColors.darkBrown.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content blocks
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: blocks
                      .where((block) => block.segments.isNotEmpty)
                      .map((block) => _buildBlock(block))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock(TextBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        if (block.label.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8, top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (block.labelColor ?? AppColors.deepBlue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (block.labelColor ?? AppColors.deepBlue).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              block.label,
              style: GoogleFonts.rubik(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: block.labelColor ?? AppColors.deepBlue,
              ),
            ),
          ),
        // Text segments
        ...block.segments.map((segment) {
          final cleanText = stripHtml(segment);
          if (cleanText.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              cleanText,
              style: GoogleFonts.rubik(
                fontSize: block.isBold ? 22 : 20,
                fontWeight: block.isBold ? FontWeight.w600 : FontWeight.normal,
                height: 2.0,
                color: AppColors.darkBrown,
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Divider(color: AppColors.gold.withValues(alpha: 0.2)),
        const SizedBox(height: 8),
      ],
    );
  }

  static String stripHtml(String html) {
    // First decode HTML numeric entities (&#1234;) to preserve nikud/taamim
    var text = html.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) => String.fromCharCode(int.parse(match.group(1)!)),
    );
    // Strip HTML tags but preserve content
    text = text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&thinsp;', '')
        .replaceAll('&ensp;', ' ')
        .replaceAll('&emsp;', ' ')
        .replaceAll('&lrm;', '')
        .replaceAll('&rlm;', '')
        .replaceAll('&zwj;', '')
        .replaceAll('&zwnj;', '')
        .replaceAll(RegExp(r'&\w+;'), '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')  // Only collapse spaces/tabs, not newlines
        .trim();
    return text;
  }
}
