import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/web_install_service.dart';
import '../utils/constants.dart';

/// Shows a dismissible banner prompting the user to install the PWA.
/// Only renders on web, when not already standalone, and not recently dismissed.
class InstallBanner extends StatefulWidget {
  const InstallBanner({super.key});

  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  static const _dismissKey = 'install_banner_dismissed_at';
  static const _reshowAfterDays = 3;

  bool _show = false;
  bool _showIOSInstructions = false;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    if (!WebInstallService.isSupported) return;
    if (WebInstallService.isStandalone()) return;

    final prefs = await SharedPreferences.getInstance();
    final dismissedAt = prefs.getInt(_dismissKey) ?? 0;
    if (dismissedAt > 0) {
      final age = DateTime.now().millisecondsSinceEpoch - dismissedAt;
      if (age < Duration(days: _reshowAfterDays).inMilliseconds) return;
    }

    if (mounted) setState(() => _show = true);
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissKey, DateTime.now().millisecondsSinceEpoch);
    if (mounted) setState(() => _show = false);
  }

  Future<void> _onInstallTap() async {
    if (WebInstallService.isIOS()) {
      setState(() => _showIOSInstructions = true);
      return;
    }
    if (WebInstallService.canPromptInstall()) {
      final outcome = await WebInstallService.promptInstall();
      if (outcome == 'accepted' && mounted) {
        setState(() => _show = false);
      }
      return;
    }
    // Chrome hasn't fired beforeinstallprompt yet: show manual instructions.
    setState(() => _showIOSInstructions = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.install_mobile, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'הוסף למסך הבית',
                    style: GoogleFonts.rubik(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _dismiss,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'תלמד יותר בקלות - ה-חברותא יהיה זמין בלחיצה אחת.',
              style: GoogleFonts.rubik(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            if (_showIOSInstructions) ...[
              const SizedBox(height: 8),
              _instructionBlock(),
            ] else ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _onInstallTap,
                  icon: const Icon(Icons.add_to_home_screen, size: 18),
                  label: Text(
                    'התקן',
                    style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _instructionBlock() {
    final isIOS = WebInstallService.isIOS();
    final lines = isIOS
        ? const [
            '1. לחץ על כפתור השיתוף למטה בספארי',
            '2. בחר "הוסף למסך הבית"',
            '3. אשר כדי להוסיף את חברותא',
          ]
        : const [
            '1. לחץ על תפריט שלוש הנקודות ⋮ בדפדפן',
            '2. בחר "הוסף למסך הבית" / "התקן אפליקציה"',
            '3. אשר כדי להוסיף את חברותא',
          ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    l,
                    style: GoogleFonts.rubik(fontSize: 13, color: AppColors.darkBrown),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
