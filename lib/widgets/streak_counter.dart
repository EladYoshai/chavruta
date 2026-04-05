import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class StreakCounter extends StatelessWidget {
  final int streakDays;

  const StreakCounter({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: streakDays > 0
              ? [AppColors.streak, const Color(0xFFFF9100)]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (streakDays > 0)
            BoxShadow(
              color: AppColors.streak.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            streakDays > 0 ? Icons.local_fire_department : Icons.whatshot,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(
            '$streakDays',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            AppStrings.days,
            style: GoogleFonts.rubik(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
