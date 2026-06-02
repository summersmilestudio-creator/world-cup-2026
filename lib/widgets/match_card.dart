import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../i18n/app_strings.dart';
import '../models/models.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match});
  final MatchInfo match;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(child: _team(match.homeName, match.homeLogo, alignEnd: true)),
            _centerScore(context, s, theme),
            Expanded(child: _team(match.awayName, match.awayLogo, alignEnd: false)),
          ],
        ),
      ),
    );
  }

  Widget _centerScore(BuildContext context, AppStrings s, ThemeData theme) {
    final hasScore = match.homeGoals != null && match.awayGoals != null;
    String middle;
    Color? color;
    if (match.isLive) {
      middle = "${match.homeGoals ?? 0} - ${match.awayGoals ?? 0}";
      color = Colors.red;
    } else if (match.isFinished) {
      middle = "${match.homeGoals ?? 0} - ${match.awayGoals ?? 0}";
    } else {
      middle = match.kickoff != null
          ? DateFormat.Hm().format(match.kickoff!.toLocal())
          : '--:--';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
              child: Text(
                match.elapsed != null ? "${match.elapsed}'" : s.t('live'),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          Text(middle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          if (!match.isLive && !hasScore)
            Text(
              match.isFinished ? s.t('finished') : s.t('upcoming'),
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _team(String name, String? logo, {required bool alignEnd}) {
    final children = <Widget>[
      if (logo != null)
        Image.network(logo, width: 28, height: 28,
            errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 24)),
      const SizedBox(width: 8),
      Flexible(
        child: Text(name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ];
    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd ? children.reversed.toList() : children,
    );
  }
}

/// Generic async list with loading / error / empty states and pull-to-refresh.
class AsyncList<T> extends StatefulWidget {
  const AsyncList({
    super.key,
    required this.loader,
    required this.itemBuilder,
    required this.emptyText,
  });
  final Future<List<T>> Function() loader;
  final Widget Function(BuildContext, T) itemBuilder;
  final String emptyText;

  @override
  State<AsyncList<T>> createState() => _AsyncListState<T>();
}

class _AsyncListState<T> extends State<AsyncList<T>> {
  late Future<List<T>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void _refresh() => setState(() => _future = widget.loader());

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _message(s.t('loadError'), action: s.t('retry'));
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) return _message(widget.emptyText, action: s.t('retry'));
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: items.length,
            itemBuilder: (c, i) => widget.itemBuilder(c, items[i]),
          ),
        );
      },
    );
  }

  Widget _message(String text, {required String action}) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: _refresh, child: Text(action)),
          ],
        ),
      );
}
