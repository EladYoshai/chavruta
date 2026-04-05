import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../data/halacha_questions.dart';
import '../utils/constants.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;
  bool _quizComplete = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    _questions = HalachaQuestionBank.getDailyQuiz(seed);
  }

  QuizQuestion get _currentQuestion => _questions[_currentIndex];

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _currentQuestion.correctIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      setState(() => _quizComplete = true);
      _saveResults();
    }
  }

  void _saveResults() {
    final appState = context.read<AppState>();
    final zuzimEarned = _correctCount * 5 + (_correctCount == 5 ? 10 : 0);
    appState.completeQuiz(_correctCount, _questions.length, zuzimEarned);
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'קל';
      case 2:
        return 'בינוני';
      case 3:
        return 'קשה';
      default:
        return '';
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.darkGold;
      case 3:
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('חידון הלכה'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '${_currentIndex + 1}/${_questions.length}',
                style: GoogleFonts.rubik(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: _quizComplete ? _buildResults() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: AppColors.parchment,
                color: const Color(0xFF6A1B9A),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),

            // Difficulty badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getDifficultyColor(_currentQuestion.difficulty)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getDifficultyColor(_currentQuestion.difficulty)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _getDifficultyLabel(_currentQuestion.difficulty),
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getDifficultyColor(_currentQuestion.difficulty),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Question
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                _currentQuestion.question,
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Options
            ...List.generate(_currentQuestion.options.length, (index) {
              final isSelected = _selectedAnswer == index;
              final isCorrect = index == _currentQuestion.correctIndex;
              Color bgColor = Colors.white;
              Color borderColor = AppColors.gold.withValues(alpha: 0.3);
              IconData? trailingIcon;

              if (_answered) {
                if (isCorrect) {
                  bgColor = AppColors.success.withValues(alpha: 0.1);
                  borderColor = AppColors.success;
                  trailingIcon = Icons.check_circle;
                } else if (isSelected && !isCorrect) {
                  bgColor = Colors.red.withValues(alpha: 0.1);
                  borderColor = Colors.red;
                  trailingIcon = Icons.cancel;
                }
              } else if (isSelected) {
                bgColor = const Color(0xFF6A1B9A).withValues(alpha: 0.1);
                borderColor = const Color(0xFF6A1B9A);
              }

              return GestureDetector(
                onTap: () => _selectAnswer(index),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentQuestion.options[index],
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                      if (trailingIcon != null)
                        Icon(
                          trailingIcon,
                          color: isCorrect ? AppColors.success : Colors.red,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            }),

            // Explanation (shown after answering)
            if (_answered) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedAnswer == _currentQuestion.correctIndex
                              ? Icons.celebration
                              : Icons.lightbulb,
                          color: AppColors.darkGold,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedAnswer == _currentQuestion.correctIndex
                              ? 'כל הכבוד! תשובה נכונה'
                              : 'התשובה הנכונה:',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentQuestion.explanation,
                      style: GoogleFonts.rubik(
                        fontSize: 15,
                        color: AppColors.darkBrown,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'מקור: ${_currentQuestion.source}',
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1
                        ? 'שאלה הבאה'
                        : 'סיום',
                    style: GoogleFonts.rubik(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final zuzimEarned = _correctCount * 5 + (_correctCount == 5 ? 10 : 0);
    final percentage = (_correctCount / _questions.length * 100).round();

    String message;
    String emoji;
    if (_correctCount == 5) {
      message = 'מושלם! ידע מרשים!';
      emoji = '🏆';
    } else if (_correctCount >= 4) {
      message = 'מצוין! כמעט מושלם!';
      emoji = '🌟';
    } else if (_correctCount >= 3) {
      message = 'טוב מאוד! ממשיכים ללמוד!';
      emoji = '👏';
    } else if (_correctCount >= 2) {
      message = 'לא רע! יש מקום לשיפור';
      emoji = '💪';
    } else {
      message = 'תמשיך ללמוד - תצליח בפעם הבאה!';
      emoji = '📚';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$_correctCount / ${_questions.length} תשובות נכונות',
                style: GoogleFonts.rubik(
                    fontSize: 20, color: AppColors.deepBlue),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.rubik(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      '+$zuzimEarned ${AppStrings.zuzim}',
                      style: GoogleFonts.rubik(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_correctCount == 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '(+10 בונוס ציון מושלם!)',
                    style: GoogleFonts.rubik(
                        fontSize: 14, color: AppColors.success),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'חזרה לתפריט',
                    style: GoogleFonts.rubik(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
