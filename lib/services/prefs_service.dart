import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen language + competition and notifies rebuilds.
class PrefsService extends ChangeNotifier {
  PrefsService._();
  static final PrefsService instance = PrefsService._();

  static const _kLang = 'lang_code';
  static const _kComp = 'comp_code';

  Locale? _locale;
  String _comp = 'CL'; // default: Champions League
  Locale? get locale => _locale;
  String get comp => _comp;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_kLang);
    if (code != null) _locale = Locale(code);
    _comp = p.getString(_kComp) ?? 'CL';
    if (_comp == 'WC') _comp = 'CL'; // migrate away from removed World Cup
  }

  Future<void> setLanguage(String code) async {
    _locale = Locale(code);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, code);
    notifyListeners();
  }

  Future<void> setCompetition(String code) async {
    _comp = code;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kComp, code);
    notifyListeners();
  }
}
