import 'package:flutter/material.dart';

import '../battle/battle_models.dart';
import '../logic/game_session.dart';
import '../models/category.dart';
import '../models/person_rarity.dart';
import '../online/online_models.dart';
import '../online/online_battle_controller.dart';

class BattleStatsScreen extends StatelessWidget {
  final GameSession session;
  final OnlineBattleController onlineController;

  const BattleStatsScreen({
    super.key,
    required this.session,
    required this.onlineController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([session, onlineController]),
      builder: (context, _) {
        final progress = session.progressSnapshot;
        final onlineStats = onlineController.overallStats;

        final offlinePlayed = progress.offlineBattlesPlayed;
        final onlinePlayed = onlineStats.completedMatches;
        final totalPlayed = offlinePlayed + onlinePlayed;
        final totalWins = progress.offlineBattlesWon + onlineStats.wins;
        final totalDraws = progress.offlineBattlesDrawn + onlineStats.draws;
        final totalLosses = progress.offlineBattlesLost + onlineStats.losses;
        final totalDecided = totalWins + totalLosses;
        final totalWinRate = totalDecided == 0 ? 0.0 : totalWins / totalDecided;

        final offlineDecided =
            progress.offlineBattlesWon + progress.offlineBattlesLost;
        final offlineWinRate = offlineDecided == 0
            ? 0.0
            : progress.offlineBattlesWon / offlineDecided;
        final onlineDecided = onlineStats.wins + onlineStats.losses;
        final onlineWinRate = onlineDecided == 0
            ? 0.0
            : onlineStats.wins / onlineDecided;

        final unlocked = session.unlockedPersons;
        final legendaryOwned = unlocked
            .where((person) => person.rarity == PersonRarity.legendary)
            .length;
        final epicOwned = unlocked
            .where((person) => person.rarity == PersonRarity.epic)
            .length;
        final categoryCounts = {
          Category.politician: unlocked
              .where((person) => person.category == Category.politician)
              .length,
          Category.scientist: unlocked
              .where((person) => person.category == Category.scientist)
              .length,
          Category.artist: unlocked
              .where((person) => person.category == Category.artist)
              .length,
          Category.athlete: unlocked
              .where((person) => person.category == Category.athlete)
              .length,
        };
        final coveredCategories = categoryCounts.values
            .where((count) => count > 0)
            .length;

        final preferredArena = onlinePlayed > offlinePlayed
            ? 'Online battles'
            : offlinePlayed > onlinePlayed
            ? 'Offline battles'
            : 'Balanced between both';
        final strongerMode = offlineWinRate > onlineWinRate
            ? 'Offline looks stronger right now'
            : onlineWinRate > offlineWinRate
            ? 'Online looks stronger right now'
            : 'Both modes are performing evenly';
        final onlineRoundStats = _buildOnlineRoundStats(onlineController);
        final totalRoundsWon =
            session.offlineRoundsWon + onlineRoundStats.roundsWon;
        final totalRoundsDrawn =
            session.offlineRoundsDrawn + onlineRoundStats.roundsDrawn;
        final totalRoundsLost =
            session.offlineRoundsLost + onlineRoundStats.roundsLost;
        final roundTypeRows = BattleRoundType.values
            .map(
              (type) => _RoundTypeAggregate(
                type: type,
                wins:
                    (session.offlineRoundWinsByType[type] ?? 0) +
                    (onlineRoundStats.winsByType[type] ?? 0),
                draws:
                    (session.offlineRoundDrawsByType[type] ?? 0) +
                    (onlineRoundStats.drawsByType[type] ?? 0),
                losses:
                    (session.offlineRoundLossesByType[type] ?? 0) +
                    (onlineRoundStats.lossesByType[type] ?? 0),
              ),
            )
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF120B07),
          appBar: AppBar(
            backgroundColor: const Color(0xFF120B07),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Battle stats',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    totalPlayed: totalPlayed,
                    totalWins: totalWins,
                    totalDraws: totalDraws,
                    totalLosses: totalLosses,
                    totalWinRate: totalWinRate,
                    rating: onlineStats.rating,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniValueCard(
                          title: 'Offline',
                          value:
                              '${progress.offlineBattlesWon}-${progress.offlineBattlesDrawn}-${progress.offlineBattlesLost}',
                          subtitle: offlinePlayed == 0
                              ? 'No finished runs yet'
                              : '${(offlineWinRate * 100).round()}% win rate',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniValueCard(
                          title: 'Online',
                          value:
                              '${onlineStats.wins}-${onlineStats.draws}-${onlineStats.losses}',
                          subtitle: onlinePlayed == 0
                              ? 'No finished matches yet'
                              : '${(onlineWinRate * 100).round()}% win rate',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Performance breakdown',
                    children: [
                      _StatLine(
                        label: 'Total completed battles',
                        value: '$totalPlayed',
                      ),
                      _StatLine(
                        label: 'Overall record',
                        value: '$totalWins-$totalDraws-$totalLosses',
                      ),
                      _StatLine(
                        label: 'Overall round score',
                        value:
                            '$totalRoundsWon-$totalRoundsDrawn-$totalRoundsLost',
                      ),
                      _StatLine(
                        label: 'Overall win rate',
                        value: '${(totalWinRate * 100).round()}%',
                      ),
                      _StatLine(
                        label: 'Online rating',
                        value: '${onlineStats.rating} Elo',
                      ),
                      _StatLine(
                        label: 'Open online matches',
                        value: '${onlineStats.openMatches}',
                      ),
                      _StatLine(
                        label: 'Online rounds',
                        value:
                            '${onlineStats.roundsWon} won • ${onlineStats.roundsLost} lost',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Round-type breakdown',
                    children: [
                      for (final row in roundTypeRows)
                        _RoundTypeRow(
                          title: _roundTypeLabel(row.type),
                          record: '${row.wins}-${row.draws}-${row.losses}',
                          insight: row.total == 0
                              ? 'No rounds played yet'
                              : row.wins > row.losses
                              ? 'Positive'
                              : row.losses > row.wins
                              ? 'Needs work'
                              : 'Even',
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Collection for battle',
                    children: [
                      _StatLine(
                        label: 'Owned battle cards',
                        value: '${unlocked.length}',
                      ),
                      _StatLine(
                        label: 'Legendary cards',
                        value: '$legendaryOwned',
                      ),
                      _StatLine(label: 'Epic cards', value: '$epicOwned'),
                      _StatLine(
                        label: 'Category coverage',
                        value: '$coveredCategories / 4 categories',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CategoryPill(
                            label:
                                'Leaders ${categoryCounts[Category.politician]}',
                            icon: Icons.account_balance_rounded,
                          ),
                          _CategoryPill(
                            label:
                                'Scientists ${categoryCounts[Category.scientist]}',
                            icon: Icons.science_rounded,
                          ),
                          _CategoryPill(
                            label: 'Artists ${categoryCounts[Category.artist]}',
                            icon: Icons.palette_rounded,
                          ),
                          _CategoryPill(
                            label:
                                'Athletes ${categoryCounts[Category.athlete]}',
                            icon: Icons.emoji_events_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Quick analysis',
                    children: [
                      _InsightTile(
                        title: 'Preferred arena',
                        body: preferredArena,
                        icon: Icons.explore_rounded,
                      ),
                      _InsightTile(
                        title: 'Mode strength',
                        body: strongerMode,
                        icon: Icons.insights_rounded,
                      ),
                      _InsightTile(
                        title: 'Collection depth',
                        body: legendaryOwned >= 4
                            ? 'You already have a strong legendary core for battle abilities.'
                            : epicOwned + legendaryOwned >= 8
                            ? 'Your higher-rarity pool is growing, but there is still room for a stronger top end.'
                            : 'Your battle roster is still early. More capsules and level rewards will matter a lot.',
                        icon: Icons.workspace_premium_rounded,
                      ),
                      _InsightTile(
                        title: 'Draft flexibility',
                        body: coveredCategories == 4
                            ? 'All four categories are represented, so your draft options are nicely balanced.'
                            : 'Some categories are still thin, which can limit your draft flexibility in battle.',
                        icon: Icons.view_in_ar_rounded,
                      ),
                    ],
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

_OnlineRoundStats _buildOnlineRoundStats(OnlineBattleController controller) {
  final uid = controller.userId;
  if (uid == null) {
    return _OnlineRoundStats.empty();
  }

  final winsByType = {for (final type in BattleRoundType.values) type: 0};
  final drawsByType = {for (final type in BattleRoundType.values) type: 0};
  final lossesByType = {for (final type in BattleRoundType.values) type: 0};

  var roundsWon = 0;
  var roundsDrawn = 0;
  var roundsLost = 0;

  for (final match in controller.matches) {
    if (!match.isCompleted || !match.involvesUser(uid)) continue;
    final amHost = match.roleFor(uid) == AsyncBattleMatchRole.host;
    for (final entry in match.history) {
      if (entry.roundIndex < 0 || entry.roundIndex >= match.rounds.length) {
        continue;
      }
      final type = match.rounds[entry.roundIndex].type;
      if (entry.isDraw) {
        roundsDrawn += 1;
        drawsByType[type] = (drawsByType[type] ?? 0) + 1;
        continue;
      }

      final myWon = amHost ? entry.hostWon : !entry.hostWon;
      final myDelta = myWon ? 1 : 0;
      final opponentDelta = myWon ? 0 : 1;
      roundsWon += myDelta;
      roundsLost += opponentDelta;
      winsByType[type] = (winsByType[type] ?? 0) + myDelta;
      lossesByType[type] = (lossesByType[type] ?? 0) + opponentDelta;
    }
  }

  return _OnlineRoundStats(
    roundsWon: roundsWon,
    roundsDrawn: roundsDrawn,
    roundsLost: roundsLost,
    winsByType: winsByType,
    drawsByType: drawsByType,
    lossesByType: lossesByType,
  );
}

String _roundTypeLabel(BattleRoundType type) {
  switch (type) {
    case BattleRoundType.closerToYear:
      return 'Closer to year';
    case BattleRoundType.closerToLocation:
      return 'Closer to location';
    case BattleRoundType.longerLife:
      return 'Longer lifespan';
    case BattleRoundType.bornEarlier:
      return 'Born earlier';
  }
}

class _OnlineRoundStats {
  final int roundsWon;
  final int roundsDrawn;
  final int roundsLost;
  final Map<BattleRoundType, int> winsByType;
  final Map<BattleRoundType, int> drawsByType;
  final Map<BattleRoundType, int> lossesByType;

  const _OnlineRoundStats({
    required this.roundsWon,
    required this.roundsDrawn,
    required this.roundsLost,
    required this.winsByType,
    required this.drawsByType,
    required this.lossesByType,
  });

  factory _OnlineRoundStats.empty() => _OnlineRoundStats(
    roundsWon: 0,
    roundsDrawn: 0,
    roundsLost: 0,
    winsByType: {for (final type in BattleRoundType.values) type: 0},
    drawsByType: {for (final type in BattleRoundType.values) type: 0},
    lossesByType: {for (final type in BattleRoundType.values) type: 0},
  );
}

class _RoundTypeAggregate {
  final BattleRoundType type;
  final int wins;
  final int draws;
  final int losses;

  const _RoundTypeAggregate({
    required this.type,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  int get total => wins + draws + losses;
}

class _HeroCard extends StatelessWidget {
  final int totalPlayed;
  final int totalWins;
  final int totalDraws;
  final int totalLosses;
  final double totalWinRate;
  final int rating;

  const _HeroCard({
    required this.totalPlayed,
    required this.totalWins,
    required this.totalDraws,
    required this.totalLosses,
    required this.totalWinRate,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF3E2A1A), Color(0xFF22150F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4B06A).withValues(alpha: 0.16),
                  border: Border.all(
                    color: const Color(0xFFD4B06A).withValues(alpha: 0.34),
                  ),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFFD4B06A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Battle command center',
                      style: TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalPlayed == 0
                          ? 'No completed battles yet. Your first runs will define the picture here.'
                          : '$totalWins wins, $totalDraws draws, $totalLosses losses across all finished battles.',
                      style: TextStyle(
                        color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(label: '$totalPlayed completed'),
              _HeroPill(label: '${(totalWinRate * 100).round()}% win rate'),
              _HeroPill(label: '$rating Elo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
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

class _MiniValueCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _MiniValueCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.86),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.80),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFFD8CBB8).withValues(alpha: 0.86),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFFF7ECDD),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFD4B06A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _InsightTile({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: const Color(0xFFD4B06A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: const Color(0xFFD8CBB8).withValues(alpha: 0.84),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundTypeRow extends StatelessWidget {
  final String title;
  final String record;
  final String insight;

  const _RoundTypeRow({
    required this.title,
    required this.record,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight,
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
              record,
              style: const TextStyle(
                color: Color(0xFFD4B06A),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
