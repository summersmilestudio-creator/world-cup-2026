import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../services/ads_service.dart';
import '../services/api_service.dart';
import '../services/prefs_service.dart';
import 'tabs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Set false only to capture clean store screenshots; true for production.
const bool kShowBanner = true;

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  BannerAd? _banner;
  List<Competition> _comps = Competition.fallback;

  @override
  void initState() {
    super.initState();
    if (kShowBanner) _banner = AdsService.instance.createBanner();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    try {
      final list = await ApiService.instance.competitions();
      if (list.isNotEmpty && mounted) setState(() => _comps = list);
    } catch (_) {/* keep fallback */}
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  Competition get _currentComp => _comps.firstWhere(
        (c) => c.code == PrefsService.instance.comp,
        orElse: () => _comps.first,
      );

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final tabs = [const LiveTab(), const MatchesTab(), const StandingsTab(), const NewsTab()];
    final isNews = _index == 3;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appName')),
        actions: [
          IconButton(
            tooltip: s.t('language'),
            icon: const Icon(Icons.language),
            onPressed: _pickLanguage,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isNews) _competitionBar(),
          Expanded(child: tabs[_index]),
          if (_banner != null)
            SizedBox(
              width: _banner!.size.width.toDouble(),
              height: _banner!.size.height.toDouble(),
              child: AdWidget(ad: _banner!),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.sports_soccer), label: s.t('tabLive')),
          NavigationDestination(icon: const Icon(Icons.calendar_today), label: s.t('tabMatches')),
          NavigationDestination(icon: const Icon(Icons.leaderboard), label: s.t('tabStandings')),
          NavigationDestination(icon: const Icon(Icons.article), label: s.t('tabNews')),
        ],
      ),
    );
  }

  Widget _competitionBar() {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: _pickCompetition,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_currentComp.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCompetition() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _comps.map((comp) {
            final selected = comp.code == PrefsService.instance.comp;
            return ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: Text(comp.name),
              trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                PrefsService.instance.setCompetition(comp.code);
                Navigator.pop(c);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickLanguage() async {
    final s = AppStrings.of(context);
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(s.t('language'), style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: AppStrings.supported.map((loc) {
                  final code = loc.languageCode;
                  return ListTile(
                    title: Text(AppStrings.languageNames[code] ?? code),
                    trailing: Localizations.localeOf(context).languageCode == code
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      PrefsService.instance.setLanguage(code);
                      Navigator.pop(c);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
