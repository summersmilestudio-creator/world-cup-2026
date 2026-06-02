import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/ads_service.dart';
import '../services/prefs_service.dart';
import '../widgets/match_card.dart';

class LiveTab extends StatelessWidget {
  const LiveTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final comp = PrefsService.instance.comp;
    return AsyncList<MatchInfo>(
      key: ValueKey('live_$comp'),
      loader: () => ApiService.instance.liveMatches(comp),
      emptyText: s.t('noLiveMatches'),
      itemBuilder: (c, m) => GestureDetector(
        onTap: () => AdsService.instance.maybeShowInterstitial(),
        child: MatchCard(match: m),
      ),
    );
  }
}

class MatchesTab extends StatelessWidget {
  const MatchesTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final comp = PrefsService.instance.comp;
    return AsyncList<MatchInfo>(
      key: ValueKey('matches_$comp'),
      loader: () => ApiService.instance.matches(comp),
      emptyText: s.t('loadError'),
      itemBuilder: (c, m) => GestureDetector(
        onTap: () => AdsService.instance.maybeShowInterstitial(),
        child: MatchCard(match: m),
      ),
    );
  }
}

class StandingsTab extends StatelessWidget {
  const StandingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final comp = PrefsService.instance.comp;
    return AsyncList<StandingRow>(
      key: ValueKey('standings_$comp'),
      loader: () => ApiService.instance.standings(comp),
      emptyText: s.t('loadError'),
      itemBuilder: (c, row) => _standingTile(row),
    );
  }

  Widget _standingTile(StandingRow r) => ListTile(
        dense: true,
        leading: SizedBox(
          width: 30,
          child: Center(
            child: Text('${r.rank}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        title: Row(
          children: [
            if (r.teamLogo != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.network(r.teamLogo!, width: 22, height: 22,
                    errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 18)),
              ),
            Expanded(child: Text(r.teamName, overflow: TextOverflow.ellipsis)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stat('${r.played}'),
            _stat(r.goalsDiff >= 0 ? '+${r.goalsDiff}' : '${r.goalsDiff}'),
            _stat('${r.points}', bold: true),
          ],
        ),
      );

  Widget _stat(String v, {bool bold = false}) => SizedBox(
        width: 34,
        child: Text(v,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      );
}

class NewsTab extends StatelessWidget {
  const NewsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return AsyncList<NewsItem>(
      loader: () => ApiService.instance.news(lang),
      emptyText: s.t('loadError'),
      itemBuilder: (c, n) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: ListTile(
          leading: n.image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(n.image!, width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.article_outlined)),
                )
              : const Icon(Icons.article_outlined, size: 36),
          title: Text(n.title, maxLines: 3, overflow: TextOverflow.ellipsis),
          subtitle: Text([
            if (n.source != null) n.source!,
            if (n.published != null) DateFormat.MMMd().add_Hm().format(n.published!.toLocal()),
          ].join(' · ')),
          onTap: () async {
            final uri = Uri.tryParse(n.link);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }
}
