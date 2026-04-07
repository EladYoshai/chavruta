class UserProgress {
  int zuzim;
  int streakDays;
  DateTime? lastStudyDate;
  int totalDaysStudied;
  int totalSectionsCompleted;
  String currentLevel;
  int streakShields;
  Map<String, bool> todayCompleted;

  // User profile
  String userName;
  String gender;
  int age;
  String city;

  // Nusach for siddur
  String nusach; // 'ashkenaz', 'sefard', 'edot_hamizrach'
  String subNusach; // '', 'moroccan', 'iraqi', 'syrian', 'yemenite', 'jerusalem'

  // Minhag overrides (user can customize)
  Map<String, bool> minhagOverrides; // e.g. 'hallel_yom_haatzmaut': true

  // Daily goal
  int dailyGoalSections; // how many sections to complete per day (1-5)

  // Quiz
  int totalQuizCorrect;
  int totalQuizAnswered;
  String? lastQuizDate;

  // Notifications
  bool notificationsEnabled;
  String notificationTime; // 'HH:mm' format
  List<int> reminderDays; // 0=Sun, 1=Mon, ..., 6=Sat (which days to remind)

  // Web push notification preferences
  bool omerReminderPush;           // תזכורת ספירת העומר
  bool streakReminderPush;         // תזכורת רצף לימוד
  bool meatDairyReminderPush;      // תזכורת סוף זמן בשר-חלב
  String encouragementLevel;       // 'none', 'low', 'medium', 'high'

  // Marital status (for women - mikvah feature)
  String maritalStatus; // '', 'single', 'married'

  // Dedication
  String iluiNeshama; // לעילוי נשמת text

  // Omer reminder
  bool omerReminderEnabled;
  String omerReminderTime; // 'HH:mm' format

  // Candle lighting reminder (women)
  bool candleLightingEnabled;

  // Meat/Dairy timer
  double meatDairyHours; // hours to wait (1, 3, 4, 5.5, 6)
  String? lastMeatTime; // ISO datetime when user last ate meat

  // Daily tracker (מעקב יומי)
  Map<String, bool> dailyTracker; // target key -> checked today
  List<String> customTargets; // user-added custom target names
  String? lastTrackerDate; // ISO date of last tracker reset

  // Shop & Achievements
  List<String> purchasedAvatars;
  String activeAvatar; // emoji or ID
  List<String> purchasedBackgrounds;
  String activeBackground;
  List<String> purchasedTitles;
  String? activeTitle; // custom title override
  List<String> earnedBadges;

  UserProgress({
    this.zuzim = 0,
    this.streakDays = 0,
    this.lastStudyDate,
    this.totalDaysStudied = 0,
    this.totalSectionsCompleted = 0,
    this.currentLevel = 'תלמיד',
    this.streakShields = 0,
    this.userName = '',
    this.gender = '',
    this.age = 0,
    this.city = '',
    this.nusach = 'ashkenaz',
    this.subNusach = '',
    Map<String, bool>? minhagOverrides,
    this.dailyGoalSections = 5,
    this.totalQuizCorrect = 0,
    this.totalQuizAnswered = 0,
    this.lastQuizDate,
    this.notificationsEnabled = true,
    this.notificationTime = '08:00',
    List<int>? reminderDays,
    this.omerReminderPush = true,
    this.streakReminderPush = true,
    this.meatDairyReminderPush = true,
    this.encouragementLevel = 'medium',
    this.maritalStatus = '',
    this.iluiNeshama = '',
    this.omerReminderEnabled = false,
    this.omerReminderTime = '20:00',
    this.candleLightingEnabled = false,
    this.meatDairyHours = 6.0,
    this.lastMeatTime,
    Map<String, bool>? dailyTracker,
    List<String>? customTargets,
    this.lastTrackerDate,
    List<String>? purchasedAvatars,
    this.activeAvatar = '',
    List<String>? purchasedBackgrounds,
    this.activeBackground = '',
    List<String>? purchasedTitles,
    this.activeTitle,
    List<String>? earnedBadges,
    Map<String, bool>? todayCompleted,
  })  : todayCompleted = todayCompleted ??
            {
              'tehillim': false,
              'shnayim_mikra': false,
              'halacha': false,
              'mishna': false,
              'emunah': false,
              'gemara': false,
              'rambam': false,
              'shmirat_halashon': false,
              'pirkei_avot': false,
              'nach_yomi': false,
              'peninei_halacha': false,
            },
        minhagOverrides = minhagOverrides ?? {},
        reminderDays = reminderDays ?? [0, 1, 2, 3, 4], // Sun-Thu default
        dailyTracker = dailyTracker ?? _defaultDailyTracker(),
        customTargets = customTargets ?? [],
        purchasedAvatars = purchasedAvatars ?? [],
        purchasedBackgrounds = purchasedBackgrounds ?? [],
        purchasedTitles = purchasedTitles ?? [],
        earnedBadges = earnedBadges ?? [];

  static const List<String> defaultTrackerTargets = [
    'התפללתי שלוש תפילות',
    'התפללתי במניין',
    'הגעתי בזמן לתפילה',
    'כיוונתי בתפילה',
    'קבעתי עיתים לתורה',
  ];

  static Map<String, bool> _defaultDailyTracker() {
    final map = <String, bool>{};
    for (final t in defaultTrackerTargets) {
      map[t] = false;
    }
    return map;
  }

  /// Rebuild tracker map with all targets (default + custom), preserving today's checks
  void rebuildTracker() {
    final allTargets = [...defaultTrackerTargets, ...customTargets];
    final newMap = <String, bool>{};
    for (final t in allTargets) {
      newMap[t] = dailyTracker[t] ?? false;
    }
    dailyTracker = newMap;
  }

  int get dailyTrackerChecked => dailyTracker.values.where((v) => v).length;
  int get dailyTrackerTotal => dailyTracker.length;

  bool get hasProfile => userName.isNotEmpty;
  bool get isFemale => gender == 'נקבה';

  bool get didQuizToday =>
      lastQuizDate == DateTime.now().toIso8601String().substring(0, 10);

  String get greeting {
    if (userName.isEmpty) return '';
    return 'שלום $userName';
  }

  String get displayTitle {
    if (activeTitle != null && activeTitle!.isNotEmpty) return activeTitle!;
    return levelTitle;
  }

  String get levelTitle {
    if (totalDaysStudied >= 365) return isFemale ? 'גאונית' : 'גאון';
    if (totalDaysStudied >= 180) return isFemale ? 'תלמידה חכמה' : 'תלמיד חכם';
    if (totalDaysStudied >= 90) return isFemale ? 'חברה' : 'חבר';
    if (totalDaysStudied >= 30) return isFemale ? 'תלמידה ותיקה' : 'תלמיד ותיק';
    if (totalDaysStudied >= 7) return isFemale ? 'תלמידה' : 'תלמיד';
    return isFemale ? 'מתחילה' : 'מתחיל';
  }

  int get todayCompletedCount =>
      todayCompleted.values.where((v) => v).length;

  bool get allTodayCompleted =>
      todayCompleted.values.every((v) => v);

  bool get dailyGoalMet => todayCompletedCount >= dailyGoalSections;

  String get avatarEmoji {
    if (activeAvatar.isNotEmpty) return activeAvatar;
    return isFemale ? '👩' : '🧔';
  }

  /// Whether to show mikvah feature (married woman)
  bool get showMikvah => isFemale && maritalStatus == 'married';

  /// Whether user is Sefardi (sefard or edot hamizrach)
  bool get isSefardi => nusach == 'sefard' || nusach == 'edot_hamizrach';

  /// Meat/dairy timer: remaining duration (null if not active or expired)
  Duration? get meatDairyRemaining {
    if (lastMeatTime == null) return null;
    final meatTime = DateTime.parse(lastMeatTime!);
    final endTime = meatTime.add(Duration(minutes: (meatDairyHours * 60).round()));
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Whether the meat/dairy timer is currently active
  bool get isMeatDairyActive => meatDairyRemaining != null;

  Map<String, dynamic> toJson() => {
        'zuzim': zuzim,
        'streakDays': streakDays,
        'lastStudyDate': lastStudyDate?.toIso8601String(),
        'totalDaysStudied': totalDaysStudied,
        'totalSectionsCompleted': totalSectionsCompleted,
        'currentLevel': currentLevel,
        'streakShields': streakShields,
        'todayCompleted': todayCompleted,
        'userName': userName,
        'gender': gender,
        'age': age,
        'city': city,
        'nusach': nusach,
        'subNusach': subNusach,
        'minhagOverrides': minhagOverrides,
        'dailyGoalSections': dailyGoalSections,
        'totalQuizCorrect': totalQuizCorrect,
        'totalQuizAnswered': totalQuizAnswered,
        'lastQuizDate': lastQuizDate,
        'notificationsEnabled': notificationsEnabled,
        'notificationTime': notificationTime,
        'reminderDays': reminderDays,
        'omerReminderPush': omerReminderPush,
        'streakReminderPush': streakReminderPush,
        'meatDairyReminderPush': meatDairyReminderPush,
        'encouragementLevel': encouragementLevel,
        'maritalStatus': maritalStatus,
        'iluiNeshama': iluiNeshama,
        'omerReminderEnabled': omerReminderEnabled,
        'omerReminderTime': omerReminderTime,
        'candleLightingEnabled': candleLightingEnabled,
        'meatDairyHours': meatDairyHours,
        'lastMeatTime': lastMeatTime,
        'dailyTracker': dailyTracker,
        'customTargets': customTargets,
        'lastTrackerDate': lastTrackerDate,
        'purchasedAvatars': purchasedAvatars,
        'activeAvatar': activeAvatar,
        'purchasedBackgrounds': purchasedBackgrounds,
        'activeBackground': activeBackground,
        'purchasedTitles': purchasedTitles,
        'activeTitle': activeTitle,
        'earnedBadges': earnedBadges,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        zuzim: json['zuzim'] ?? 0,
        streakDays: json['streakDays'] ?? 0,
        lastStudyDate: json['lastStudyDate'] != null
            ? DateTime.parse(json['lastStudyDate'])
            : null,
        totalDaysStudied: json['totalDaysStudied'] ?? 0,
        totalSectionsCompleted: json['totalSectionsCompleted'] ?? 0,
        currentLevel: json['currentLevel'] ?? 'תלמיד',
        streakShields: json['streakShields'] ?? 0,
        todayCompleted: json['todayCompleted'] != null
            ? Map<String, bool>.from(json['todayCompleted'])
            : null,
        userName: json['userName'] ?? '',
        gender: json['gender'] ?? '',
        age: json['age'] ?? 0,
        city: json['city'] ?? '',
        nusach: json['nusach'] ?? 'ashkenaz',
        subNusach: json['subNusach'] ?? '',
        minhagOverrides: json['minhagOverrides'] != null
            ? Map<String, bool>.from(json['minhagOverrides'])
            : null,
        dailyGoalSections: json['dailyGoalSections'] ?? 5,
        totalQuizCorrect: json['totalQuizCorrect'] ?? 0,
        totalQuizAnswered: json['totalQuizAnswered'] ?? 0,
        lastQuizDate: json['lastQuizDate'],
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        notificationTime: json['notificationTime'] ?? '08:00',
        reminderDays: json['reminderDays'] != null
            ? List<int>.from(json['reminderDays'])
            : null,
        omerReminderPush: json['omerReminderPush'] ?? true,
        streakReminderPush: json['streakReminderPush'] ?? true,
        meatDairyReminderPush: json['meatDairyReminderPush'] ?? true,
        encouragementLevel: json['encouragementLevel'] ?? 'medium',
        maritalStatus: json['maritalStatus'] ?? '',
        iluiNeshama: json['iluiNeshama'] ?? '',
        omerReminderEnabled: json['omerReminderEnabled'] ?? false,
        omerReminderTime: json['omerReminderTime'] ?? '20:00',
        candleLightingEnabled: json['candleLightingEnabled'] ?? false,
        meatDairyHours: (json['meatDairyHours'] ?? 6).toDouble(),
        lastMeatTime: json['lastMeatTime'],
        dailyTracker: json['dailyTracker'] != null
            ? Map<String, bool>.from(json['dailyTracker'])
            : null,
        customTargets: json['customTargets'] != null
            ? List<String>.from(json['customTargets'])
            : null,
        lastTrackerDate: json['lastTrackerDate'],
        purchasedAvatars: json['purchasedAvatars'] != null
            ? List<String>.from(json['purchasedAvatars'])
            : null,
        activeAvatar: json['activeAvatar'] ?? '',
        purchasedBackgrounds: json['purchasedBackgrounds'] != null
            ? List<String>.from(json['purchasedBackgrounds'])
            : null,
        activeBackground: json['activeBackground'] ?? '',
        purchasedTitles: json['purchasedTitles'] != null
            ? List<String>.from(json['purchasedTitles'])
            : null,
        activeTitle: json['activeTitle'],
        earnedBadges: json['earnedBadges'] != null
            ? List<String>.from(json['earnedBadges'])
            : null,
      );
}
