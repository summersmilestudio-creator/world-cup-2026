import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'i18n/app_strings.dart';
import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsService.instance.init();
  await AdsService.instance.init();
  runApp(const FootballLiveApp());
}

class FootballLiveApp extends StatelessWidget {
  const FootballLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PrefsService.instance,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (ctx) => AppStrings.of(ctx).t('appName'),
          debugShowCheckedModeBanner: false,
          locale: PrefsService.instance.locale, // null => follow device, fallback en
          supportedLocales: AppStrings.supported,
          localizationsDelegates: const [
            AppStringsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF1B8A4B), // football green
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF1B8A4B),
            brightness: Brightness.dark,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
