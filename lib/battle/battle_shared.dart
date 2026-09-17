import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import 'battle_models.dart';

class BattlePanel extends StatelessWidget {
  final Key? panelKey;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const BattlePanel({
    super.key,
    this.panelKey,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: panelKey,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: AppPalette.panelGradient,
        border: Border.all(color: AppPalette.gold.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class BattlePill extends StatelessWidget {
  final String label;

  const BattlePill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            AppPalette.gold.withValues(alpha: 0.22),
            AppPalette.gold.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: AppPalette.gold.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppPalette.goldBright,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class BattleSlimInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const BattleSlimInfoPill({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppPalette.ink.withValues(alpha: 0.34),
        border: Border.all(color: AppPalette.gold.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class BattleRoundSpotlightCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String caption;
  final IconData icon;

  const BattleRoundSpotlightCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    final compactMobile = MediaQuery.sizeOf(context).width < 430;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compactMobile ? 12 : 16,
        compactMobile ? 12 : 16,
        compactMobile ? 12 : 16,
        compactMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compactMobile ? 18 : 24),
        gradient: LinearGradient(
          colors: [
            AppPalette.gold.withValues(alpha: 0.26),
            AppPalette.surfaceRaised.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppPalette.gold.withValues(alpha: 0.42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compactMobile
                ? 34
                : mobile
                ? 42
                : 48,
            height: compactMobile
                ? 34
                : mobile
                ? 42
                : 48,
            decoration: BoxDecoration(
              color: AppPalette.ink.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(compactMobile ? 12 : 16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(
              icon,
              color: AppPalette.goldBright,
              size: compactMobile ? 18 : null,
            ),
          ),
          SizedBox(width: compactMobile ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: AppPalette.goldBright.withValues(alpha: 0.96),
                    fontWeight: FontWeight.w800,
                    fontSize: compactMobile ? 10 : 11,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: compactMobile ? 4 : 6),
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w900,
                    fontSize: compactMobile
                        ? 15
                        : mobile
                        ? 18
                        : 22,
                    height: 1.1,
                  ),
                ),
                if (!compactMobile && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFFF7ECDD).withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
                SizedBox(height: compactMobile ? 4 : 8),
                Text(
                  caption,
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.86),
                    fontWeight: FontWeight.w600,
                    fontSize: compactMobile ? 11.5 : null,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BattleRoundTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingLabel;

  const BattleRoundTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.90),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        BattlePill(label: trailingLabel),
      ],
    );
  }
}

class BattleStateChips extends StatelessWidget {
  final String leftLabel;
  final String middleLabel;
  final String rightLabel;

  const BattleStateChips({
    super.key,
    required this.leftLabel,
    required this.middleLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        BattleSlimInfoPill(icon: Icons.style_rounded, label: leftLabel),
        BattleSlimInfoPill(
          icon: Icons.help_outline_rounded,
          label: middleLabel,
        ),
        BattleSlimInfoPill(icon: Icons.scoreboard_rounded, label: rightLabel),
      ],
    );
  }
}

class BattleLineupStrip extends StatelessWidget {
  final int totalSlots;
  final List<Widget> filledCards;

  const BattleLineupStrip({
    super.key,
    required this.totalSlots,
    required this.filledCards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppPalette.ink.withValues(alpha: 0.32),
        border: Border.all(color: AppPalette.gold.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lineup',
                  style: TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${filledCards.length}/$totalSlots',
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.86),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(totalSlots, (index) {
                final filled = index < filledCards.length
                    ? filledCards[index]
                    : null;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == totalSlots - 1 ? 0 : 10,
                  ),
                  child:
                      filled ??
                      Container(
                        width: 60,
                        height: 86,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFFD4B06A),
                        ),
                      ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

IconData battleRoundIcon(BattleRoundType type) {
  switch (type) {
    case BattleRoundType.closerToYear:
      return Icons.event_rounded;
    case BattleRoundType.closerToLocation:
      return Icons.public_rounded;
    case BattleRoundType.longerLife:
      return Icons.hourglass_bottom_rounded;
    case BattleRoundType.bornEarlier:
      return Icons.history_edu_rounded;
  }
}

String battleRoundHelperText(BattleRoundType type) {
  switch (type) {
    case BattleRoundType.closerToLocation:
      return 'Play the figure whose birthplace is closest to the target.';
    case BattleRoundType.closerToYear:
      return 'Play the figure whose birth year is closest to the event.';
    case BattleRoundType.longerLife:
      return 'Play the figure with the longer lifespan.';
    case BattleRoundType.bornEarlier:
      return 'Play the figure who was born earlier.';
  }
}
