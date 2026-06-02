/// Data models. Shapes mirror the backend cache JSON (normalized from API-Football),
/// so the app never talks to the football API directly.

class Competition {
  final String code;
  final String name;
  const Competition(this.code, this.name);

  factory Competition.fromJson(Map<String, dynamic> j) =>
      Competition((j['code'] ?? '') as String, (j['name'] ?? '') as String);

  /// Built-in fallback list (matches backend COMPETITIONS) so the picker works
  /// even before the competitions endpoint responds.
  static const List<Competition> fallback = [
    Competition('WC', 'World Cup'),
    Competition('CL', 'Champions League'),
    Competition('PL', 'Premier League'),
    Competition('PD', 'La Liga'),
    Competition('BL1', 'Bundesliga'),
    Competition('SA', 'Serie A'),
    Competition('FL1', 'Ligue 1'),
    Competition('DED', 'Eredivisie'),
    Competition('PPL', 'Primeira Liga'),
    Competition('ELC', 'Championship'),
    Competition('BSA', 'Série A (Brazil)'),
    Competition('EC', 'European Championship'),
  ];
}

class MatchInfo {
  final int id;
  final String homeName;
  final String awayName;
  final String? homeLogo;
  final String? awayLogo;
  final int? homeGoals;
  final int? awayGoals;
  final String statusShort; // NS, 1H, HT, 2H, FT, etc.
  final int? elapsed; // minutes for live
  final DateTime? kickoff; // UTC
  final String? round;

  MatchInfo({
    required this.id,
    required this.homeName,
    required this.awayName,
    this.homeLogo,
    this.awayLogo,
    this.homeGoals,
    this.awayGoals,
    required this.statusShort,
    this.elapsed,
    this.kickoff,
    this.round,
  });

  bool get isLive => const ['1H', '2H', 'HT', 'ET', 'P', 'LIVE', 'BT'].contains(statusShort);
  bool get isFinished => const ['FT', 'AET', 'PEN'].contains(statusShort);
  bool get isUpcoming => statusShort == 'NS' || statusShort == 'TBD';

  factory MatchInfo.fromJson(Map<String, dynamic> j) => MatchInfo(
        id: (j['id'] ?? 0) as int,
        homeName: (j['homeName'] ?? '') as String,
        awayName: (j['awayName'] ?? '') as String,
        homeLogo: j['homeLogo'] as String?,
        awayLogo: j['awayLogo'] as String?,
        homeGoals: j['homeGoals'] as int?,
        awayGoals: j['awayGoals'] as int?,
        statusShort: (j['status'] ?? 'NS') as String,
        elapsed: j['elapsed'] as int?,
        kickoff: j['kickoff'] != null ? DateTime.tryParse(j['kickoff'] as String) : null,
        round: j['round'] as String?,
      );
}

class StandingRow {
  final int rank;
  final String teamName;
  final String? teamLogo;
  final int played;
  final int win;
  final int draw;
  final int lose;
  final int goalsDiff;
  final int points;
  final String? group;

  StandingRow({
    required this.rank,
    required this.teamName,
    this.teamLogo,
    required this.played,
    required this.win,
    required this.draw,
    required this.lose,
    required this.goalsDiff,
    required this.points,
    this.group,
  });

  factory StandingRow.fromJson(Map<String, dynamic> j) => StandingRow(
        rank: (j['rank'] ?? 0) as int,
        teamName: (j['teamName'] ?? '') as String,
        teamLogo: j['teamLogo'] as String?,
        played: (j['played'] ?? 0) as int,
        win: (j['win'] ?? 0) as int,
        draw: (j['draw'] ?? 0) as int,
        lose: (j['lose'] ?? 0) as int,
        goalsDiff: (j['goalsDiff'] ?? 0) as int,
        points: (j['points'] ?? 0) as int,
        group: j['group'] as String?,
      );
}

class NewsItem {
  final String title;
  final String link;
  final String? source;
  final DateTime? published;
  final String? image;

  NewsItem({
    required this.title,
    required this.link,
    this.source,
    this.published,
    this.image,
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        title: (j['title'] ?? '') as String,
        link: (j['link'] ?? '') as String,
        source: j['source'] as String?,
        published: j['published'] != null ? DateTime.tryParse(j['published'] as String) : null,
        image: j['image'] as String?,
      );
}
