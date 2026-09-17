import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../logic/game_session.dart';
import '../logic/progression_catalog.dart';

class ProgressionScreen extends StatefulWidget {
  final GameSession session;

  const ProgressionScreen({super.key, required this.session});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  bool _showCompleted = false;
  GameSession get session => widget.session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B100A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B100A),
        foregroundColor: const Color(0xFFF7ECDD),
        title: Text(
          context.tr('Fortschritt', 'Progression'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          final currentLevel = session.level;
          final currentXp = session.xp;
          final xpToNext = session.xpToNext;
          final milestones = ProgressionCatalog.milestones
              .where(
                (milestone) => _showCompleted || milestone.level > currentLevel,
              )
              .toList();
          final nextLevel = milestones
              .where((milestone) => milestone.level > currentLevel)
              .firstOrNull
              ?.level;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: milestones.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LevelHeader(
                      currentLevel: currentLevel,
                      currentXp: currentXp,
                      xpToNext: xpToNext,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(context.tr('Nächste Ziele', 'Upcoming')),
                          selected: !_showCompleted,
                          onSelected: (_) =>
                              setState(() => _showCompleted = false),
                        ),
                        ChoiceChip(
                          label: Text(
                            context.tr('Alle Meilensteine', 'All milestones'),
                          ),
                          selected: _showCompleted,
                          onSelected: (_) =>
                              setState(() => _showCompleted = true),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        nextLevel == null
                            ? context.tr(
                                'Alle Ziele erreicht – stark gemacht!',
                                'All goals reached – well done!',
                              )
                            : context.tr(
                                'Noch ${nextLevel - currentLevel} Level bis zur nächsten Freischaltung.',
                                '${nextLevel - currentLevel} levels to your next unlock.',
                              ),
                      ),
                    ),
                  ],
                );
              }

              final milestone = milestones[index - 1];
              final isUnlocked = currentLevel >= milestone.level;
              final isNext = !isUnlocked && nextLevel == milestone.level;

              return _MilestoneRow(
                milestone: milestone,
                isUnlocked: isUnlocked,
                isNext: isNext,
                isLast: index == milestones.length,
              );
            },
          );
        },
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final int currentLevel;
  final int currentXp;
  final int xpToNext;

  const _LevelHeader({
    required this.currentLevel,
    required this.currentXp,
    required this.xpToNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.25),
        ),
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
                  color: const Color(0xFFD4B06A).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFFD4B06A).withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$currentLevel',
                    style: const TextStyle(
                      color: Color(0xFFD4B06A),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $currentLevel',
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentXp / $xpToNext XP',
                      style: TextStyle(
                        color: const Color(0xFFD8CBB8).withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: xpToNext <= 0 ? 1 : (currentXp / xpToNext).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD4B06A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final ProgressionMilestone milestone;
  final bool isUnlocked;
  final bool isNext;
  final bool isLast;

  const _MilestoneRow({
    required this.milestone,
    required this.isUnlocked,
    required this.isNext,
    required this.isLast,
  });

  IconData get _kindIcon {
    switch (milestone.kind) {
      case ProgressionMilestoneKind.question:
        return Icons.quiz_rounded;
      case ProgressionMilestoneKind.feature:
        return _featureIcon;
      case ProgressionMilestoneKind.capsule:
        return Icons.inventory_2_rounded;
    }
  }

  IconData get _featureIcon {
    switch (milestone.feature) {
      case AppFeature.battle:
        return Icons.sports_kabaddi_rounded;
      case AppFeature.collection:
        return Icons.collections_bookmark_rounded;
      case AppFeature.map:
        return Icons.public_rounded;
      case null:
        return Icons.star_rounded;
    }
  }

  Color get _accentColor {
    if (!isUnlocked && !isNext) return const Color(0xFF5A4A3A);
    switch (milestone.kind) {
      case ProgressionMilestoneKind.question:
        return const Color(0xFF7BC8F2);
      case ProgressionMilestoneKind.feature:
        return const Color(0xFF86E0A0);
      case ProgressionMilestoneKind.capsule:
        return const Color(0xFFD4B06A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimmed = !isUnlocked && !isNext;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line + dot column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 12,
                  color: dimmed
                      ? Colors.white.withValues(alpha: 0.08)
                      : _accentColor.withValues(alpha: 0.35),
                ),
                Container(
                  width: isNext ? 36 : 28,
                  height: isNext ? 36 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked
                        ? _accentColor.withValues(alpha: 0.18)
                        : isNext
                        ? _accentColor.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isUnlocked
                          ? _accentColor.withValues(alpha: 0.8)
                          : isNext
                          ? _accentColor.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.12),
                      width: isNext ? 2 : 1.5,
                    ),
                  ),
                  child: Icon(
                    isUnlocked ? _kindIcon : Icons.lock_outline_rounded,
                    size: isNext ? 18 : 14,
                    color: isUnlocked
                        ? _accentColor
                        : isNext
                        ? _accentColor.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: dimmed
                          ? Colors.white.withValues(alpha: 0.08)
                          : _accentColor.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 4),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isUnlocked
                      ? _accentColor.withValues(alpha: 0.06)
                      : isNext
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.02),
                  border: Border.all(
                    color: isUnlocked
                        ? _accentColor.withValues(alpha: 0.2)
                        : isNext
                        ? _accentColor.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            milestone.title,
                            style: TextStyle(
                              color: dimmed
                                  ? const Color(
                                      0xFFD8CBB8,
                                    ).withValues(alpha: 0.4)
                                  : const Color(0xFFF7ECDD),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: isUnlocked
                                ? _accentColor.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                          child: Text(
                            'Lv ${milestone.level}',
                            style: TextStyle(
                              color: isUnlocked
                                  ? _accentColor
                                  : dimmed
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : _accentColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      milestone.description,
                      style: TextStyle(
                        color: dimmed
                            ? const Color(0xFFD8CBB8).withValues(alpha: 0.3)
                            : const Color(0xFFD8CBB8).withValues(alpha: 0.75),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 12,
                            color: _accentColor.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Next unlock',
                            style: TextStyle(
                              color: _accentColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isUnlocked &&
                        milestone.kind == ProgressionMilestoneKind.capsule) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: _accentColor.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Unlocked',
                            style: TextStyle(
                              color: _accentColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
