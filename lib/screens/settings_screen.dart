import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart' show omerHebrew;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  String _selectedGender = '';
  String _selectedNusach = 'ashkenaz';
  int _dailyGoal = 5;
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);
  List<int> _reminderDays = [0, 1, 2, 3, 4];
  bool _omerReminderEnabled = false;
  TimeOfDay _omerReminderTime = const TimeOfDay(hour: 20, minute: 0);
  double _meatDairyHours = 6;

  @override
  void initState() {
    super.initState();
    final progress = context.read<AppState>().progress;
    _nameController.text = progress.userName;
    _ageController.text = progress.age > 0 ? progress.age.toString() : '';
    _cityController.text = progress.city;
    _selectedGender = progress.gender;
    _selectedNusach = progress.nusach;
    _dailyGoal = progress.dailyGoalSections;
    _notificationsEnabled = progress.notificationsEnabled;
    final timeParts = progress.notificationTime.split(':');
    _notificationTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 8,
      minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
    );
    _reminderDays = List<int>.from(progress.reminderDays);
    _omerReminderEnabled = progress.omerReminderEnabled;
    final omerParts = progress.omerReminderTime.split(':');
    _omerReminderTime = TimeOfDay(
      hour: int.tryParse(omerParts[0]) ?? 20,
      minute: int.tryParse(omerParts.length > 1 ? omerParts[1] : '0') ?? 0,
    );
    _meatDairyHours = progress.meatDairyHours.toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _save() async {
    final appState = context.read<AppState>();
    final timeStr = '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}';
    await appState.updateProfile(
      name: _nameController.text.trim(),
      gender: _selectedGender,
      age: int.tryParse(_ageController.text) ?? 0,
      city: _cityController.text.trim(),
      nusach: _selectedNusach,
      dailyGoalSections: _dailyGoal,
      notificationsEnabled: _notificationsEnabled,
      notificationTime: timeStr,
      reminderDays: _reminderDays,
      omerReminderEnabled: _omerReminderEnabled,
      omerReminderTime: '${_omerReminderTime.hour.toString().padLeft(2, '0')}:${_omerReminderTime.minute.toString().padLeft(2, '0')}',
      meatDairyHours: _meatDairyHours,
    );

    // Update notification schedule
    if (!kIsWeb) {
      if (_notificationsEnabled) {
        NotificationService.scheduleDailyReminder(
          hour: _notificationTime.hour,
          minute: _notificationTime.minute,
        );
        NotificationService.scheduleStreakWarning();
      } else {
        NotificationService.cancelAll();
      }

      // Omer reminder
      if (_omerReminderEnabled) {
        final omerDay = _getOmerDay();
        if (omerDay > 0 && omerDay <= 49) {
          NotificationService.scheduleOmerReminder(
            hour: _omerReminderTime.hour,
            minute: _omerReminderTime.minute,
            omerText: _getOmerText(omerDay),
          );
        }
      } else {
        NotificationService.cancelOmerReminder();
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'ההגדרות נשמרו בהצלחה',
              style: GoogleFonts.rubik(),
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
        backgroundColor: AppColors.deepBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.deepBlue, AppColors.warmBlue],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _selectedGender == 'נקבה' ? '👩' : '🧔',
                          style: const TextStyle(fontSize: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'פרטים אישיים',
                      style: GoogleFonts.rubik(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Name field
              _buildLabel('שם'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'הכנס את שמך',
                icon: Icons.person,
              ),
              const SizedBox(height: 20),

              // Gender selection
              _buildLabel('מין'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderButton('זכר', '🧔', _selectedGender == 'זכר'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderButton('נקבה', '👩', _selectedGender == 'נקבה'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nusach selection
              _buildLabel('נוסח תפילה'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildNusachButton('ashkenaz', 'אשכנז')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNusachButton('sefard', 'ספרד')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNusachButton('edot_hamizrach', 'עדות המזרח')),
                ],
              ),
              const SizedBox(height: 20),

              // Age field
              _buildLabel('גיל'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _ageController,
                hint: 'הכנס גיל',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // City field
              _buildLabel('עיר / מיקום'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _cityController,
                hint: 'לדוגמה: ירושלים',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 20),

              // Daily goal
              _buildLabel('יעד לימוד יומי'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_dailyGoal פרקים ביום',
                      style: GoogleFonts.rubik(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dailyGoal <= 2
                          ? 'קל - מתאים להתחלה'
                          : _dailyGoal <= 3
                              ? 'בינוני - קצב נוח'
                              : _dailyGoal <= 4
                                  ? 'טוב - לימוד רציני'
                                  : 'מלא - כל הלימודים!',
                      style: GoogleFonts.rubik(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    Slider(
                      value: _dailyGoal.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: AppColors.deepBlue,
                      label: '$_dailyGoal',
                      onChanged: (v) =>
                          setState(() => _dailyGoal = v.round()),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1', style: GoogleFonts.rubik(
                            fontSize: 12, color: Colors.grey)),
                        Text('5', style: GoogleFonts.rubik(
                            fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),

              // Notification settings (mobile only)
              if (!kIsWeb) ...[
                const SizedBox(height: 20),
                _buildLabel('התראות'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'תזכורת יומית',
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              color: AppColors.darkBrown,
                            ),
                          ),
                          Switch(
                            value: _notificationsEnabled,
                            activeTrackColor: AppColors.deepBlue,
                            onChanged: (v) =>
                                setState(() => _notificationsEnabled = v),
                          ),
                        ],
                      ),
                      if (_notificationsEnabled) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _notificationTime,
                              builder: (context, child) {
                                return Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _notificationTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.parchment,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'שעת תזכורת',
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                                Text(
                                  '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.rubik(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Reminder days
              if (!kIsWeb && _notificationsEnabled) ...[
                const SizedBox(height: 12),
                _buildLabel('ימי תזכורת'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildDayChip(0, 'א׳'),
                    _buildDayChip(1, 'ב׳'),
                    _buildDayChip(2, 'ג׳'),
                    _buildDayChip(3, 'ד׳'),
                    _buildDayChip(4, 'ה׳'),
                    _buildDayChip(5, 'ו׳'),
                    _buildDayChip(6, 'ש׳'),
                  ],
                ),
              ],

              // Omer reminder
              if (!kIsWeb) ...[
                const SizedBox(height: 20),
                _buildLabel('תזכורת לספירת העומר'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'תזכורת ספירת העומר',
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              color: AppColors.darkBrown,
                            ),
                          ),
                          Switch(
                            value: _omerReminderEnabled,
                            activeTrackColor: AppColors.deepBlue,
                            onChanged: (v) =>
                                setState(() => _omerReminderEnabled = v),
                          ),
                        ],
                      ),
                      if (_omerReminderEnabled) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _omerReminderTime,
                              builder: (context, child) {
                                return Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _omerReminderTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.parchment,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'שעת תזכורת',
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                                Text(
                                  '${_omerReminderTime.hour.toString().padLeft(2, '0')}:${_omerReminderTime.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.rubik(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Show today's omer count
                        Builder(builder: (_) {
                          final day = _getOmerDay();
                          if (day > 0 && day <= 49) {
                            return Text(
                              'היום: ${_getOmerText(day)}',
                              style: GoogleFonts.rubik(
                                fontSize: 13,
                                color: AppColors.darkGold,
                              ),
                              textAlign: TextAlign.center,
                            );
                          }
                          return Text(
                            'ספירת העומר אינה פעילה כעת',
                            style: GoogleFonts.rubik(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],

              // Meat/dairy timer
              const SizedBox(height: 20),
              _buildLabel('זמן בין בשר לחלב'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      (_meatDairyHours - 5.0167).abs() < 0.01
                          ? 'תחילת שעה שישית (5:01)'
                          : '${_meatDairyHours == _meatDairyHours.roundToDouble() ? _meatDairyHours.toInt().toString() : _meatDairyHours.toString()} שעות',
                      style: GoogleFonts.rubik(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildHoursButton(1, null),
                        _buildHoursButton(3, null),
                        _buildHoursButton(4, null),
                        _buildHoursButton(5, 'תחילת שעה שישית'),
                        _buildHoursButton(5.5, null),
                        _buildHoursButton(6, null),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(
                    'שמור הגדרות',
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Stats summary
              Consumer<AppState>(
                builder: (context, appState, _) {
                  final p = appState.progress;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'סטטיסטיקה',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow('ימי לימוד', '${p.totalDaysStudied}'),
                        _buildStatRow('פרקים שהושלמו', '${p.totalSectionsCompleted}'),
                        _buildStatRow('רצף נוכחי', '${p.streakDays} ימים'),
                        _buildStatRow('זוזים', '${p.zuzim}'),
                        _buildStatRow('דרגה', p.levelTitle),
                        _buildStatRow('מגני רצף', '${p.streakShields}'),
                      ],
                    ),
                  );
                },
              ),
            // About / Credits
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'אודות',
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'חברותא - לימוד תורה יומי\n'
                    'גרסה 1.0.0\n\n'
                    'טקסטים מקודשים באדיבות Sefaria.org\n'
                    'ספרייה פתוחה של טקסטים יהודיים\n\n'
                    'להצלחת עם ישראל 🇮🇱',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.rubik(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBrown,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.rubik(fontSize: 16, color: AppColors.darkBrown),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.rubik(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppColors.deepBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String label, String emoji, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.deepBlue : AppColors.gold.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.deepBlue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.darkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNusachButton(String value, String label) {
    final isSelected = _selectedNusach == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedNusach = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : AppColors.gold.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.darkBrown,
            ),
          ),
        ),
      ),
    );
  }

  int _getOmerDay() {
    final jewishCal = JewishCalendar.fromDateTime(DateTime.now());
    final month = jewishCal.getJewishMonth();
    final day = jewishCal.getJewishDayOfMonth();
    if (month == 1 && day >= 16) return day - 15;
    if (month == 2) return day + 15;
    if (month == 3 && day <= 5) return day + 44;
    return 0;
  }

  String _getOmerText(int day) {
    if (day > 0 && day <= 49 && day < omerHebrew.length) {
      return omerHebrew[day];
    }
    return '';
  }

  Widget _buildDayChip(int dayIndex, String label) {
    final isSelected = _reminderDays.contains(dayIndex);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.deepBlue.withValues(alpha: 0.2),
      checkmarkColor: AppColors.deepBlue,
      labelStyle: GoogleFonts.rubik(
        fontSize: 14,
        color: isSelected ? AppColors.deepBlue : Colors.grey,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _reminderDays.add(dayIndex);
          } else {
            _reminderDays.remove(dayIndex);
          }
        });
      },
    );
  }

  Widget _buildHoursButton(double hours, String? customLabel) {
    // 5 hours = "תחילת שעה שישית" = 5 hours and 1 minute (stored as 5.0167)
    final storeValue = hours == 5 ? 5.0167 : hours;
    final isSelected = (_meatDairyHours - storeValue).abs() < 0.01;
    final label = customLabel ?? (hours == hours.roundToDouble()
        ? '${hours.toInt()} שעות'
        : '$hours שעות');
    return GestureDetector(
      onTap: () => setState(() => _meatDairyHours = storeValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepBlue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.deepBlue : AppColors.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.darkBrown,
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.rubik(fontSize: 14, color: AppColors.darkBrown)),
          Text(
            value,
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.deepBlue,
            ),
          ),
        ],
      ),
    );
  }
}
