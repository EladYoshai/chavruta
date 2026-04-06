import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/app_state.dart';
import 'app/theme.dart';
import 'screens/home_screen.dart';
import 'services/daf_summary_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Init daf summary cache
  await DafSummaryService.init();

  // Init Firebase (cloud sync)
  await FirebaseService.init();

  // Init notifications (mobile only)
  if (!kIsWeb) {
    await NotificationService.init();
  }

  runApp(const TorahDailyApp());
}

class TorahDailyApp extends StatelessWidget {
  const TorahDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'חברותא',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
