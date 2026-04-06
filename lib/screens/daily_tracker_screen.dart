import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../utils/constants.dart';

class DailyTrackerScreen extends StatelessWidget {
  const DailyTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מעקב יומי'),
        backgroundColor: const Color(0xFF00838F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final progress = appState.progress;
          // Ensure tracker has all targets
          progress.rebuildTracker();
          final targets = progress.dailyTracker.keys.toList();
          final checked = progress.dailyTrackerChecked;
          final total = progress.dailyTrackerTotal;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header with progress
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00838F).withValues(alpha: 0.12),
                        const Color(0xFF00838F).withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        checked == total ? '🌟' : '📋',
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        checked == total
                            ? 'כל הכבוד! השלמת את כל היעדים!'
                            : 'מעקב יומי',
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00838F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$checked/$total יעדים הושלמו',
                        style: GoogleFonts.rubik(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: total > 0 ? checked / total : 0,
                          backgroundColor: AppColors.parchment,
                          color: checked == total
                              ? AppColors.success
                              : const Color(0xFF00838F),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '5 זוזים לכל יעד שהושלם',
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          color: AppColors.darkGold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Target checklist
                ...targets.map((target) {
                  final isChecked = progress.dailyTracker[target] ?? false;
                  final isCustom = progress.customTargets.contains(target);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => appState.toggleDailyTracker(target),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? AppColors.success.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isChecked
                                ? AppColors.success.withValues(alpha: 0.4)
                                : AppColors.gold.withValues(alpha: 0.2),
                            width: isChecked ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppColors.success
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isChecked
                                      ? AppColors.success
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                target,
                                style: GoogleFonts.rubik(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isChecked
                                      ? AppColors.success
                                      : AppColors.darkBrown,
                                  decoration: isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (isChecked)
                              Text(
                                '+5',
                                style: GoogleFonts.rubik(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGold,
                                ),
                              ),
                            if (isCustom && !isChecked)
                              GestureDetector(
                                onTap: () => _confirmRemove(
                                    context, appState, target),
                                child: Icon(Icons.close,
                                    size: 18, color: Colors.grey.shade400),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Add custom target button
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showAddTargetDialog(context, appState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00838F).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00838F).withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline,
                            color: Color(0xFF00838F), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'יעד חדש',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00838F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddTargetDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'הוסף יעד חדש',
            style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            textDirection: TextDirection.rtl,
            autofocus: true,
            style: GoogleFonts.rubik(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'למשל: חסד יומי, ברכות בכוונה...',
              hintStyle: GoogleFonts.rubik(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  appState.addCustomTarget(name);
                }
                Navigator.pop(context);
              },
              child: Text(
                'הוסף',
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00838F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, AppState appState, String target) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('הסר יעד', style: GoogleFonts.rubik(fontWeight: FontWeight.bold)),
          content: Text('להסיר את "$target"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () {
                appState.removeCustomTarget(target);
                Navigator.pop(context);
              },
              child: Text(
                'הסר',
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
