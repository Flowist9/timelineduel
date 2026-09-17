import 'package:flutter/material.dart';

import '../battle/battle_models.dart';
import '../battle/battle_shared.dart';
import '../battle/battle_session.dart';

class BattleRoundHeader extends StatelessWidget {
  final BattleSession session;

  const BattleRoundHeader({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return BattleRoundTopBar(
      title:
          'Round ${session.currentRoundIndex + 1} of ${session.rounds.length}',
      subtitle: session.currentRound.title,
      trailingLabel: '${session.playerScore}:${session.botScore}',
    );
  }
}

class BattleRoundFocusPanel extends StatelessWidget {
  final BattleRoundDefinition round;

  const BattleRoundFocusPanel({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final yearTarget = round.yearTarget;
    final locationTarget = round.locationTarget;

    if (round.type == BattleRoundType.closerToYear && yearTarget != null) {
      return BattleRoundSpotlightCard(
        eyebrow: 'Target year',
        title: '${yearTarget.year}',
        subtitle: '',
        caption: 'Smaller difference wins.',
        icon: Icons.event_available_rounded,
      );
    }

    if (round.type == BattleRoundType.bornEarlier) {
      return const BattleRoundSpotlightCard(
        eyebrow: 'Time rule',
        title: 'Birth year',
        subtitle: '',
        caption: 'Earlier wins.',
        icon: Icons.history_edu_rounded,
      );
    }

    if (round.type == BattleRoundType.closerToLocation &&
        locationTarget != null) {
      return BattleRoundSpotlightCard(
        eyebrow: round.isTiebreaker ? 'Historical target' : 'Target place',
        title: round.isTiebreaker ? 'Mystery map' : locationTarget.label,
        subtitle: '',
        caption: round.isTiebreaker
            ? 'Shorter distance wins. Borders only, no place names.'
            : 'Shorter distance wins.',
        icon: Icons.place_rounded,
      );
    }

    return const BattleRoundSpotlightCard(
      eyebrow: 'Comparison',
      title: 'Longer lifespan wins',
      subtitle: '',
      caption: 'Today counts as the end.',
      icon: Icons.hourglass_bottom_rounded,
    );
  }
}

class BattleStateChipsPanel extends StatelessWidget {
  final BattleSession session;

  const BattleStateChipsPanel({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return BattleStateChips(
      leftLabel: '${session.remainingPlayerCards.length} cards',
      middleLabel: 'Bot ${session.remainingBotCards.length}',
      rightLabel: '${session.playerScore}:${session.botScore}',
    );
  }
}

class BattleScorePanelWidget extends StatelessWidget {
  final BattleSession session;

  const BattleScorePanelWidget({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Battle state',
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _BattleStatLine(
            label: 'Your remaining cards',
            value: '${session.remainingPlayerCards.length}',
          ),
          _BattleStatLine(
            label: 'Bot cards left',
            value: '${session.remainingBotCards.length}',
          ),
          _BattleStatLine(
            label: 'Round score',
            value: '${session.playerScore}:${session.botScore}',
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            minHeight: 10,
            value: (session.currentRoundIndex / session.rounds.length).clamp(
              0.0,
              1.0,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFD4B06A)),
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}

class _BattleStatLine extends StatelessWidget {
  final String label;
  final String value;

  const _BattleStatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
