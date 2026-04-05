# חברותא - Torah Daily Learning App

## Overview
A gamified Torah learning app (like Duolingo for Torah) built with **Flutter** for Android.
The app encourages daily Torah study with streaks, coins (זוזים), achievements, and an animated character.

## Tech Stack
- **Framework**: Flutter 3.41.6 (Dart)
- **Platform**: Android (APK), also builds for web
- **API**: Sefaria API (free, no key needed) for all Torah texts
- **State**: Provider pattern
- **Local Storage**: SharedPreferences
- **Hebrew Calendar**: kosher_dart package
- **Location/Zmanim**: geolocator + kosher_dart ComplexZmanimCalendar
- **Daf Summaries**: Pre-generated with Gemini API, stored as JSON in assets

## Project Location
```
/home/eyoshai/Projects/torah_app/
```

## Environment Setup
- Flutter SDK: `~/flutter-sdk/`
- Android SDK: `~/android-sdk/`
- Java: OpenJDK 21 at `/usr/lib/jvm/java-21-openjdk-amd64`
- PATH needs: `export PATH="$HOME/flutter-sdk/bin:$HOME/android-sdk/cmdline-tools/latest/bin:$HOME/android-sdk/platform-tools:$PATH"`
- Also: `export ANDROID_HOME="$HOME/android-sdk"` and `export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"`

## Build Commands
```bash
flutter analyze                    # Check for errors
flutter build apk --release        # Build Android APK
flutter build web --release        # Build web version
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`
Windows path: `\\wsl.localhost\Ubuntu\home\eyoshai\Projects\torah_app\build\app\outputs\flutter-apk\app-release.apk`

## Project Structure
```
lib/
├── main.dart                          # Entry point, RTL, Provider setup
├── app/
│   ├── theme.dart                     # Gold/blue parchment theme (Rubik font)
│   └── app_state.dart                 # Central state: progress, quiz, shop, profile
├── models/
│   ├── user_progress.dart             # User data: zuzim, streak, profile, nusach, purchases, badges
│   └── study_section.dart             # 5 study section definitions
├── data/
│   ├── halacha_questions.dart         # 300 sourced halacha quiz questions (easy/medium/hard)
│   └── siddur_structure.dart          # Siddur prayer refs per nusach (Ashkenaz/Sefard/Edot HaMizrach)
├── services/
│   ├── sefaria_service.dart           # Sefaria API: texts, calendar, tehillim, daf yomi, parsha
│   ├── storage_service.dart           # SharedPreferences persistence, streak logic, daily reset
│   └── daf_summary_service.dart       # Loads pre-generated Hebrew daf summaries from JSON
├── screens/
│   ├── home_screen.dart               # Main dashboard: greeting, avatar, parsha, stats, section cards
│   ├── study_screen.dart              # Torah text viewer per section type
│   ├── calendar_screen.dart           # לוח יומי: zmanim, parsha, holidays, dual dates
│   ├── siddur_screen.dart             # Siddur with auto-continue between prayers
│   ├── quiz_screen.dart               # Daily 5-question halacha quiz
│   ├── achievements_screen.dart       # 14 badges with progress tracking
│   ├── shop_screen.dart               # Avatar shop, titles, streak shields
│   ├── settings_screen.dart           # Profile, gender, nusach, daily goal, candle lighting toggle
│   ├── women_screen.dart              # Women's hub: Tefilat Chana, Challah, Niddah halachot + calculator
│   └── siyum_yahrzeit_screen.dart     # Siyum masechet tracker + Yahrzeit calculator
├── widgets/
│   ├── rabbi_avatar.dart              # Animated avatar (rabbi/woman, custom emoji from shop)
│   ├── streak_counter.dart            # Fire streak badge
│   ├── zuzim_counter.dart             # Gold coin counter
│   ├── section_card.dart              # Tappable study section cards
│   └── torah_text_viewer.dart         # RTL Hebrew text with labeled blocks, HTML stripping
└── utils/
    └── constants.dart                 # Colors, strings, rewards, rabbi phrases (male+female)

assets/
├── data/
│   └── daf_summaries.json            # Pre-generated Hebrew daf yomi summaries (13 so far)
├── animations/                        # (placeholder for Lottie)
├── fonts/
└── images/

tools/
└── generate_summaries.py             # Script to generate Hebrew daf summaries using Gemini API
```

## Features Implemented

### 1. Daily Learning Sections (5 sections)
- **תהילים יומי** - Daily Tehillim by Hebrew day of month, each פרק shown with its own header
- **שניים מקרא ואחד תרגום** - Weekly parsha with מקרא (bold), תרגום אונקלוס, פירוש רש"י
- **הלכה יומית** - From Sefaria's Halakha Yomit calendar: Shulchan Aruch + Mishna Brura
- **אמונה וחסידות** - Sfat Emet on the weekly parsha
- **דף יומי** - Full daf with Gemara, Hebrew summary, Rashi, and Tosafot deep dive

### 2. Gamification
- **זוזים** (coins) earned per completed section + bonuses
- **רצף** (streak) tracking with daily reset logic
- **Streak shields** purchasable with זוזים
- **Daily goal** (1-5 sections, configurable in settings)
- **Levels**: מתחיל → תלמיד → חבר → תלמיד חכם → גאון (gender-aware titles)

### 3. Daily Quiz (חידון הלכה)
- 300 real halacha questions from Shulchan Aruch, Mishna Brura, Rambam
- 5 per day (2 easy, 2 medium, 1 hard), seeded by date
- Shows correct answer + explanation + source after each question
- 5 זוזים per correct + 10 bonus for perfect score

### 4. Achievements (הישגים)
- 14 badges: streaks, sections completed, quiz scores, zuzim milestones
- Each awards bonus זוזים when first earned

### 5. Avatar Shop (חנות זוזים)
- **Avatars**: Classic (מורה, חכם, מלך), Animals (אריה, נשר, יונה), Food (ג'חנון, גפילטע פיש, סופגניה, חמין, פלאפל, קובה), Jewish items (תפילין, כיפה שחורה, כיפה סרוגה, שטריימל, חנוכיה, ספר תורה, בית המקדש)
- **Custom titles**: מתמיד, שוקד, למדן, צדיק/צדקת, הגאון, מקובל
- **Streak shields**: single or 3-pack

### 6. Siddur (סידור)
- Full prayer structure: שחרית, מנחה, ערבית, שבת, ברכות, קר"ש על המיטה
- **Nusach-aware**: אשכנז, ספרד (חסידי), עדות המזרח
- Texts from Sefaria with fallback refs per nusach
- **Auto-continue**: scroll to bottom shows "המשך ל: [next prayer]" button

### 7. Calendar (לוח יומי)
- פרשת השבוע name (big gold), Hebrew date + Gregorian date
- Holiday detection with special badges
- **Context-aware zmanim**:
  - Friday: 🕯️ הדלקת נרות, ✡️ כניסת שבת
  - Saturday: ✡️ יציאת שבת (ר"ת)
  - Erev Pesach: ⚠️ סוף זמן אכילת חמץ, 🔥 ביעור חמץ
  - Erev Yom Kippur: 🕯️ כניסת יוה"כ
  - Fast days: ⚫ תחילת/סוף הצום
  - Chanukah: 🕎 זמן הדלקת נר חנוכה
- Location-based (GPS or Jerusalem default)
- Daf Yomi reference shown

### 8. Settings (הגדרות)
- Name, gender (זכר/נקבה), age, city
- **נוסח תפילה**: אשכנז / ספרד / עדות המזרח
- **יעד לימוד יומי**: slider 1-5 sections
- Stats summary
- Gender affects: avatar (🧔/👩), phrases, level titles

### 9. User Profile
- Personalized greeting: "שלום מנחם"
- Gender-aware encouragement phrases
- Custom avatar from shop displayed on home screen

## Daf Yomi Summary Generation
- Script: `tools/generate_summaries.py`
- Uses **Gemini 2.5 Flash** (free tier) to generate original Hebrew summaries
- Sources: Only public domain texts (Gemara, Rashi, Tosafot) - no copyright issues
- Output: `assets/data/daf_summaries.json`
- Currently has 13 summaries (Menachot 2b-9a + 80a), all in Hebrew
- Gemini API key: set `GEMINI_API_KEY` env var
- Rate limit: ~20 req/min on free tier, script handles retries
- Run: `python3 tools/generate_summaries.py --masechet Menachot --start 80b --end 90b`
- Use `--force` flag to regenerate existing entries
- Script auto-detects non-Hebrew summaries and regenerates them
- Hebrew validation: retries if Gemini outputs English
- Saves progress incrementally, skips already-generated dapim

### 10. Push Notifications (התראות)
- Daily learning reminder at configurable time (default 8:00 AM)
- Streak warning at 20:00 if user hasn't studied (auto-cancels on completion)
- Milestone celebrations for streak 7/30/100 and daily completion
- All notification text in Hebrew
- Configurable in settings (toggle + time picker)
- Mobile only (skipped on web via `kIsWeb`)

### 11. Enhanced Avatar Animations
- Golden sparkle particle effects on celebration (CustomPainter)
- Glow pulse when streak is active
- Streak badge overlay on avatar
- `celebrate()` method for section completion effects
- Keeps emoji avatars (fast, cross-platform, charming)

## Web Version (PWA for iPhone)
- Full PWA support: `flutter build web --release`
- Works on iPhone via Safari "Add to Home Screen"
- Standalone mode (no Safari chrome) with `apple-mobile-web-app-capable`
- RTL layout: `<html dir="rtl" lang="he">`
- Theme color: #1A237E (deep blue)
- GPS disabled on web (defaults to Jerusalem for zmanim)
- Notifications disabled on web (uses in-app UI instead)
- Build output: `build/web/`

## Key Dependencies (pubspec.yaml)
- http, shared_preferences, provider
- kosher_dart (Hebrew dates/zmanim)
- google_fonts (Rubik font)
- geolocator (user location for zmanim, mobile only)
- lottie, flutter_local_notifications, timezone, intl

## Architecture Notes
- **SefariaService**: Singleton with HTTP timeout (15s), retry (2x), and in-memory text cache (50 items)
- **DafSummaryService**: Initialized once in `main()`, caches all summaries from JSON
- **NotificationService**: Static methods, mobile-only via `kIsWeb` guards
- **Achievements**: Badge awarding uses `addPostFrameCallback` to avoid infinite rebuilds

## Android Config
- Package: `com.torahdaily.torah_app`
- App name: חברותא
- Permissions: INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION
- Core library desugaring enabled for notifications plugin
- `android/app/build.gradle.kts` has `isCoreLibraryDesugaringEnabled = true`

## Known Issues / TODO
- No user accounts / cloud sync (local only)
- iOS builds need a Mac with Xcode (not available in current WSL setup) - use web version instead
- Daf summary generation needs more dapim (run `generate_summaries.py` with Gemini API key)

### 12. Women's Features (עולם האישה)
- Hub screen for women (shown when gender=נקבה on home screen)
- **תפילת חנה** - Collection of women's prayers from Sefaria (Tefilat Chana, candle lighting, tefilat haderech, birchot hashachar, amidah, nishmat)
- **הפרשת חלה** - Full nusach for hafrashat challah, nusach-aware (Sefard/Edot HaMizrach)
- **הלכות טהרת המשפחה** - SA YD 183-200 (married women only), discreet UI with siman/seif navigation
- **מחשבון טהרת המשפחה** - Niddah calculator: hefsek tahara, 7 clean days, mikvah night (married women only)
- **הדלקת נרות** - Friday candle lighting reminder notification, toggle in settings

### 13. Siyum Masechet Tracker
- All 37 Bavli masechetot with total dapim
- Progress bar per masechet, +1/-1 buttons, manual daf entry
- Siyum celebration dialog with 50 zuzim bonus
- Progress persisted in SharedPreferences

### 14. Yahrzeit Calculator
- Date picker for petira date (Gregorian)
- Converts to Hebrew date, calculates yahrzeit for N years ahead (3/5/10/20)
- Shows Hebrew + Gregorian dates, highlights upcoming yahrzeit

## Remaining TODO Features
These features are planned but not yet implemented:

### Practical Tools
- **ברכון דיגיטלי** - Bracha decision tree ("What bracha on...?")
- **סימניה** - Bookmarks to save place in any text
- **שיתוף הישגים** - Share badges/streaks on WhatsApp

### Additional Learning
- **חק לישראל** - Daily portions (Sefaria has as collections, not direct API)
- **הלכה בהתאמה לעונה** - Seasonal halacha (e.g. הלכות פסח before Pesach)

## GitHub
- Repo: https://github.com/EladYoshai/chavruta
- Auto-deploys to GitHub Pages on push to main
- Live URL: https://eladyoshai.github.io/chavruta/

## Design
- Colors: Gold (#D4A847), Deep Blue (#1A237E), Cream (#FFF8E7), Parchment (#F5E6C8)
- Font: Google Fonts Rubik, 22px for Torah text, height 2.0
- Full RTL layout
- Material 3 design
