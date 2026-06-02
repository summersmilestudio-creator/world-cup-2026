import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Talks ONLY to our own backend cache proxy (PHP on Hostico), never to the
/// football data provider directly. The backend hides the token and caches
/// responses so the free rate limit is shared across all app users.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // TODO: point to the deployed backend. Path: summer-smile.ro/football/api.php
  static const String _base = 'https://summer-smile.ro/football/api.php';

  Future<List<Competition>> competitions() async {
    final data = await _get('competitions');
    final list = (data['competitions'] as List? ?? const []);
    return list.map((e) => Competition.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MatchInfo>> liveMatches(String comp) => _matches('live', comp);
  Future<List<MatchInfo>> matches(String comp) => _matches('matches', comp);

  Future<List<MatchInfo>> _matches(String action, String comp) async {
    final data = await _get(action, {'comp': comp});
    final list = (data['matches'] as List? ?? const []);
    return list.map((e) => MatchInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<StandingRow>> standings(String comp) async {
    final data = await _get('standings', {'comp': comp});
    final list = (data['standings'] as List? ?? const []);
    return list.map((e) => StandingRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<NewsItem>> news(String lang) async {
    final data = await _get('news', {'lang': lang});
    final list = (data['news'] as List? ?? const []);
    return list.map((e) => NewsItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> _get(String action, [Map<String, String>? extra]) async {
    final uri = Uri.parse(_base).replace(queryParameters: {'action': action, ...?extra});
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
