import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../online/online_battle_controller.dart';
import '../online/online_models.dart';

class LeaderboardScreen extends StatelessWidget {
  final OnlineBattleController onlineController;

  const LeaderboardScreen({super.key, required this.onlineController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: onlineController,
      builder: (context, _) {
        final profile = onlineController.profile;
        final leaderboard = onlineController.leaderboard;
        final rank = onlineController.leaderboardRank;
        final stats = onlineController.overallStats;

        return Scaffold(
          backgroundColor: const Color(0xFF120B07),
          appBar: AppBar(
            title: Text(context.tr('Leaderboard', 'Leaderboard')),
            backgroundColor: const Color(0xFF1E120D),
            foregroundColor: const Color(0xFFF7ECDD),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF26170F), Color(0xFF120B07)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                children: [
                  _HeroCard(
                    title: context.tr(
                      'Globales Elo-Ranking',
                      'Global Elo Ranking',
                    ),
                    subtitle: context.tr(
                      'Sieh die staerksten Spieler insgesamt und verfolge deinen aktuellen Rang.',
                      'See the strongest players overall and track your current standing.',
                    ),
                    pills: [
                      _Pill(
                        rank == null
                            ? context.tr('Unranked', 'Unranked')
                            : '#$rank',
                      ),
                      _Pill('Elo ${stats.rating}'),
                      _Pill(
                        '${stats.wins}-${stats.draws}-${stats.losses} ${context.tr('WDL', 'WDL')}',
                      ),
                    ],
                  ),
                  if (profile != null) ...[
                    const SizedBox(height: 14),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Dein Standing', 'Your standing'),
                            style: const TextStyle(
                              color: Color(0xFFF7ECDD),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${profile.displayName}#${profile.friendCode}',
                            style: const TextStyle(
                              color: Color(0xFFF7ECDD),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Pill(
                                rank == null
                                    ? context.tr('Unranked', 'Unranked')
                                    : '#$rank',
                              ),
                              _Pill('Elo ${stats.rating}'),
                              _Pill(
                                '${stats.completedMatches} ${context.tr('Matches', 'Matches')}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _SectionHeader(
                    title: context.tr('Top Spieler', 'Top Players'),
                    count: leaderboard.length,
                  ),
                  const SizedBox(height: 8),
                  if (leaderboard.isEmpty)
                    _Card(
                      child: Text(
                        context.tr(
                          'Noch keine Spieler im Leaderboard.',
                          'No players in the leaderboard yet.',
                        ),
                        style: TextStyle(
                          color: const Color(
                            0xFFD8CBB8,
                          ).withValues(alpha: 0.86),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    _Card(
                      child: Column(
                        children: [
                          for (var i = 0; i < leaderboard.length; i++) ...[
                            _LeaderboardRow(
                              rank: i + 1,
                              profile: leaderboard[i],
                              highlight:
                                  profile != null &&
                                  leaderboard[i].userId == profile.userId,
                            ),
                            if (i != leaderboard.length - 1)
                              Divider(
                                height: 18,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> pills;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.pills,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4B06A).withValues(alpha: 0.18),
            const Color(0xFF2A180F),
            const Color(0xFF170D09),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: pills),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B2418).withValues(alpha: 0.88),
            const Color(0xFF21120B).withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.20),
        ),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        _Pill('$count'),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD4B06A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final OnlineBattleProfile profile;
  final bool highlight;

  const _LeaderboardRow({
    required this.rank,
    required this.profile,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight
        ? const Color(0xFF5CCB8A)
        : const Color(0xFFD4B06A);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: highlight
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withValues(alpha: 0.10),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Text(
              '$rank',
              style: TextStyle(color: accent, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '#${profile.friendCode}',
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${profile.rating}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
