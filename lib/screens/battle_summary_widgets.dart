import 'package:flutter/material.dart';

import '../battle/battle_session.dart';
import '../design/app_theme.dart';
import '../models/person_rarity.dart';
import '../widgets/person_portrait.dart';

class BattleSummaryScoreTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const BattleSummaryScoreTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            AppPalette.ink.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class BattleSummaryHero extends StatelessWidget {
  final BattleSession session;
  final Color Function(PersonRarity rarity) rarityColor;

  const BattleSummaryHero({
    super.key,
    required this.session,
    required this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    final playerWon = session.playerScore > session.botScore;
    final draw = session.playerScore == session.botScore;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            (draw
                    ? Colors.white
                    : playerWon
                    ? AppPalette.gold
                    : AppPalette.ember)
                .withValues(alpha: 0.24),
            AppPalette.ink.withValues(alpha: 0.26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color:
              (draw
                      ? Colors.white
                      : playerWon
                      ? AppPalette.gold
                      : AppPalette.ember)
                  .withValues(alpha: 0.48),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draw
                ? 'This battle stays unresolved'
                : playerWon
                ? 'Your knowledge came through'
                : 'The bot was more efficient this time',
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This summary shows which card worked in which round. That keeps battle as a learning mirror for your quiz knowledge, not just a stat comparison.',
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: BattleSummaryScoreTile(
                  label: 'Your rounds',
                  value: '${session.playerScore}',
                  color: AppPalette.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BattleSummaryScoreTile(
                  label: 'Bot rounds',
                  value: '${session.botScore}',
                  color: AppPalette.ember,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: session.playerDeck.map((person) {
                final used = session.history.any(
                  (entry) => entry.playerCard?.id == person.id,
                );
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Opacity(
                      opacity: used ? 1 : 0.45,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: rarityColor(
                              person.rarity,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: PersonPortrait(
                            person: person,
                            variant: PersonImageVariant.vs,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class BattleResultBadge extends StatelessWidget {
  final String label;
  final bool playerWon;
  final bool isDraw;

  const BattleResultBadge({
    super.key,
    required this.label,
    required this.playerWon,
    required this.isDraw,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDraw
        ? const Color(0xFFD8CBB8)
        : playerWon
        ? const Color(0xFFD4B06A)
        : const Color(0xFFE39063);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class BattleSummaryHistory extends StatelessWidget {
  final BattleSession session;

  const BattleSummaryHistory({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Round log',
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: session.history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final result = session.history[index];
                final outcome = result.isDraw
                    ? 'Draw'
                    : result.playerWon
                    ? 'Win'
                    : 'Loss';
                final color = result.isDraw
                    ? const Color(0xFFD8CBB8)
                    : result.playerWon
                    ? const Color(0xFFD4B06A)
                    : const Color(0xFFE39063);

                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.black.withValues(alpha: 0.14),
                    border: Border.all(color: color.withValues(alpha: 0.28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Round ${result.roundNumber} - ${result.definition.title}',
                              style: const TextStyle(
                                color: Color(0xFFF7ECDD),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            outcome,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.isDirectGuessRound
                            ? 'Tiebreak without cards'
                            : '${result.playerCard!.name} vs ${result.botCard!.name}',
                        style: TextStyle(
                          color: const Color(
                            0xFFD8CBB8,
                          ).withValues(alpha: 0.88),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
