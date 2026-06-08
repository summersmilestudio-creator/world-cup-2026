import 'package:flutter/widgets.dart';

/// Lightweight, fully-controlled i18n for 10 international languages.
/// Keys are stable identifiers; values are per-language translations.
class AppStrings {
  AppStrings(this.locale);
  final Locale locale;

  static const List<Locale> supported = [
    Locale('en'), Locale('es'), Locale('fr'), Locale('ar'), Locale('pt'),
    Locale('de'), Locale('it'), Locale('ru'), Locale('zh'), Locale('hi'),
  ];

  /// Native language names for the picker.
  static const Map<String, String> languageNames = {
    'en': 'English', 'es': 'Español', 'fr': 'Français', 'ar': 'العربية',
    'pt': 'Português', 'de': 'Deutsch', 'it': 'Italiano', 'ru': 'Русский',
    'zh': '中文', 'hi': 'हिन्दी',
  };

  static bool isRtl(String code) => code == 'ar';

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  String t(String key) {
    final lang = locale.languageCode;
    return (_data[key]?[lang]) ?? _data[key]?['en'] ?? key;
  }

  static const Map<String, Map<String, String>> _data = {
    'appName': {
      'en': 'Football 2026: Live Scores', 'es': 'Fútbol 2026: Resultados en Vivo', 'fr': 'Football 2026: Scores en Direct',
      'ar': 'كرة القدم 2026: نتائج مباشرة', 'pt': 'Futebol 2026: Placar ao Vivo', 'de': 'Fußball 2026: Live-Ergebnisse',
      'it': 'Calcio 2026: Risultati Live', 'ru': 'Футбол 2026: счёт Live', 'zh': '足球2026：实时比分', 'hi': 'फुटबॉल 2026: लाइव स्कोर',
    },
    'tabLive': {
      'en': 'Live', 'es': 'En vivo', 'fr': 'En direct', 'ar': 'مباشر', 'pt': 'Ao vivo',
      'de': 'Live', 'it': 'Diretta', 'ru': 'Лайв', 'zh': '直播', 'hi': 'लाइव',
    },
    'tabMatches': {
      'en': 'Matches', 'es': 'Partidos', 'fr': 'Matchs', 'ar': 'المباريات', 'pt': 'Jogos',
      'de': 'Spiele', 'it': 'Partite', 'ru': 'Матчи', 'zh': '赛程', 'hi': 'मैच',
    },
    'tabStandings': {
      'en': 'Standings', 'es': 'Clasificación', 'fr': 'Classement', 'ar': 'الترتيب', 'pt': 'Classificação',
      'de': 'Tabelle', 'it': 'Classifica', 'ru': 'Таблица', 'zh': '积分榜', 'hi': 'अंक तालिका',
    },
    'tabNews': {
      'en': 'News', 'es': 'Noticias', 'fr': 'Actualités', 'ar': 'الأخبار', 'pt': 'Notícias',
      'de': 'Nachrichten', 'it': 'Notizie', 'ru': 'Новости', 'zh': '新闻', 'hi': 'समाचार',
    },
    'noLiveMatches': {
      'en': 'No live matches right now', 'es': 'No hay partidos en vivo ahora', 'fr': 'Aucun match en direct',
      'ar': 'لا توجد مباريات مباشرة الآن', 'pt': 'Nenhum jogo ao vivo agora', 'de': 'Derzeit keine Live-Spiele',
      'it': 'Nessuna partita in diretta', 'ru': 'Сейчас нет матчей в эфире', 'zh': '当前没有直播比赛', 'hi': 'अभी कोई लाइव मैच नहीं',
    },
    'live': {
      'en': 'LIVE', 'es': 'EN VIVO', 'fr': 'DIRECT', 'ar': 'مباشر', 'pt': 'AO VIVO',
      'de': 'LIVE', 'it': 'LIVE', 'ru': 'ЛАЙВ', 'zh': '直播', 'hi': 'लाइव',
    },
    'finished': {
      'en': 'Finished', 'es': 'Finalizado', 'fr': 'Terminé', 'ar': 'انتهت', 'pt': 'Terminado',
      'de': 'Beendet', 'it': 'Finita', 'ru': 'Завершён', 'zh': '已结束', 'hi': 'समाप्त',
    },
    'upcoming': {
      'en': 'Upcoming', 'es': 'Próximos', 'fr': 'À venir', 'ar': 'القادمة', 'pt': 'Próximos',
      'de': 'Demnächst', 'it': 'In arrivo', 'ru': 'Скоро', 'zh': '即将开始', 'hi': 'आगामी',
    },
    'retry': {
      'en': 'Retry', 'es': 'Reintentar', 'fr': 'Réessayer', 'ar': 'إعادة المحاولة', 'pt': 'Tentar de novo',
      'de': 'Erneut', 'it': 'Riprova', 'ru': 'Повторить', 'zh': '重试', 'hi': 'पुनः प्रयास',
    },
    'loadError': {
      'en': 'Could not load data', 'es': 'No se pudieron cargar los datos', 'fr': 'Chargement impossible',
      'ar': 'تعذّر تحميل البيانات', 'pt': 'Não foi possível carregar', 'de': 'Daten konnten nicht geladen werden',
      'it': 'Impossibile caricare i dati', 'ru': 'Не удалось загрузить данные', 'zh': '无法加载数据', 'hi': 'डेटा लोड नहीं हो सका',
    },
    'language': {
      'en': 'Language', 'es': 'Idioma', 'fr': 'Langue', 'ar': 'اللغة', 'pt': 'Idioma',
      'de': 'Sprache', 'it': 'Lingua', 'ru': 'Язык', 'zh': '语言', 'hi': 'भाषा',
    },
    'today': {
      'en': 'Today', 'es': 'Hoy', 'fr': "Aujourd'hui", 'ar': 'اليوم', 'pt': 'Hoje',
      'de': 'Heute', 'it': 'Oggi', 'ru': 'Сегодня', 'zh': '今天', 'hi': 'आज',
    },
    'readMore': {
      'en': 'Read more', 'es': 'Leer más', 'fr': 'Lire la suite', 'ar': 'اقرأ المزيد', 'pt': 'Ler mais',
      'de': 'Mehr lesen', 'it': 'Leggi di più', 'ru': 'Читать далее', 'zh': '阅读更多', 'hi': 'और पढ़ें',
    },
  };
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();
  @override
  bool isSupported(Locale locale) =>
      AppStrings.supported.any((l) => l.languageCode == locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);
  @override
  bool shouldReload(AppStringsDelegate old) => false;
}
