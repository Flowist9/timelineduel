import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../battle/battle_models.dart';
import '../battle/battle_session.dart';
import '../battle/battle_targets.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../models/person_rarity.dart';
import '../widgets/person_portrait.dart';
import 'battle_reveal_host_widgets.dart';
import '../maps/map_tile_config.dart';

class BattleRoundRevealContent extends StatelessWidget {
  final BattleRoundResult result;
  final bool wrapInStage;

  const BattleRoundRevealContent({
    super.key,
    required this.result,
    this.wrapInStage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (result.isDirectGuessRound) {
      final child = _DirectGuessReveal(result: result);
      if (!wrapInStage) return child;
      return BattleResultStage(result: result, child: child);
    }
    final child = switch (result.definition.type) {
      BattleRoundType.bornEarlier => _YearTimelineResult(
        result: result,
        targetYear: null,
        title: 'Birth years compared',
      ),
      BattleRoundType.closerToYear => _YearTimelineResult(
        result: result,
        targetYear: result.definition.yearTarget!.year,
        title: result.definition.yearTarget!.label,
      ),
      BattleRoundType.longerLife => _LifespanResult(result: result),
      BattleRoundType.closerToLocation => _LocationMapResult(result: result),
    };

    if (!wrapInStage) return child;
    return BattleResultStage(result: result, child: child);
  }
}

class _DirectGuessReveal extends StatefulWidget {
  final BattleRoundResult result;

  const _DirectGuessReveal({required this.result});

  @override
  State<_DirectGuessReveal> createState() => _DirectGuessRevealState();
}

class _DirectGuessRevealState extends State<_DirectGuessReveal> {
  bool _showWinner = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) {
        setState(() => _showWinner = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    final result = widget.result;
    final accent = result.isDraw
        ? const Color(0xFFD4B06A)
        : result.playerWon
        ? const Color(0xFF5CCB8A)
        : const Color(0xFFE39063);
    final eventTarget = result.definition.historicalEventTarget;
    final targetText =
        result.definition.inputMode == BattleRoundInputMode.yearLockGuess
        ? eventTarget == null
              ? '${result.definition.yearTarget!.label} (${result.definition.yearTarget!.year})'
              : '${eventTarget.title}\n${formatBattleEventDate(eventTarget.date)}'
        : eventTarget == null
        ? result.definition.locationTarget!.label
        : '${eventTarget.title}\n${eventTarget.locationLabel}, ${eventTarget.regionLabel}';
    final playerValue =
        result.definition.inputMode == BattleRoundInputMode.yearLockGuess
        ? result.playerGuessedDate == null
              ? '${result.playerGuessedYear ?? '--'}'
              : formatBattleEventDateCompact(result.playerGuessedDate!)
        : '${result.playerMetric.toStringAsFixed(0)} km';
    final botValue =
        result.definition.inputMode == BattleRoundInputMode.yearLockGuess
        ? result.botGuessedDate == null
              ? '${result.botGuessedYear ?? '--'}'
              : formatBattleEventDateCompact(result.botGuessedDate!)
        : '${result.botMetric.toStringAsFixed(0)} km';

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 30),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.03),
            Colors.black.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            result.definition.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              fontSize: compact ? 16 : 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            targetText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _MetricCapsule(
                    label: 'Your guess',
                    value: playerValue,
                    color: result.playerWon && !result.isDraw
                        ? const Color(0xFF5CCB8A)
                        : const Color(0xFFD4B06A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCapsule(
                    label: 'Bot',
                    value: botValue,
                    color: !result.playerWon && !result.isDraw
                        ? const Color(0xFF5CCB8A)
                        : const Color(0xFFE39063),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            opacity: _showWinner ? 1 : 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              offset: _showWinner ? Offset.zero : const Offset(0, 0.08),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black.withValues(alpha: 0.22),
                  border: Border.all(color: accent.withValues(alpha: 0.34)),
                ),
                child: Text(
                  result.isDraw
                      ? 'Draw in the tiebreak'
                      : result.playerWon
                      ? 'Your guess is closer'
                      : 'The bot is closer',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearTimelineResult extends StatefulWidget {
  final BattleRoundResult result;
  final int? targetYear;
  final String title;

  const _YearTimelineResult({
    required this.result,
    required this.targetYear,
    required this.title,
  });

  @override
  State<_YearTimelineResult> createState() => _YearTimelineResultState();
}

class _YearTimelineResultState extends State<_YearTimelineResult> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _queueReveal();
  }

  void _queueReveal() {
    final hasTarget = widget.targetYear != null;
    final sequence = <MapEntry<Duration, int>>[
      const MapEntry(Duration(milliseconds: 180), 1),
      const MapEntry(Duration(milliseconds: 800), 2),
      if (hasTarget) const MapEntry(Duration(milliseconds: 1400), 3),
      MapEntry(
        Duration(milliseconds: hasTarget ? 2100 : 1500),
        hasTarget ? 4 : 3,
      ),
    ];

    for (final entry in sequence) {
      Future.delayed(entry.key, () {
        if (mounted) {
          setState(() => _step = entry.value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    final player = widget.result.playerCard!;
    final bot = widget.result.botCard!;
    final playerColor = _rarityColor(player.rarity);
    final botColor = _rarityColor(bot.rarity);
    final hasTarget = widget.targetYear != null;
    final showTarget = hasTarget && _step >= 3;
    final showDistances = _step >= (hasTarget ? 4 : 3);

    final years = [
      player.birthYear,
      bot.birthYear,
      if (widget.targetYear != null) widget.targetYear!,
    ];
    final minYear = years.reduce(min) - 18;
    final maxYear = years.reduce(max) + 18;

    return _TimeRevealStage(
      title: widget.title,
      subtitle: '',
      leftPerson: player,
      rightPerson: bot,
      leftLabel: 'You',
      rightLabel: 'Bot',
      leftColor: playerColor,
      rightColor: botColor,
      center: _VerticalYearScene(
        minYear: minYear,
        maxYear: maxYear,
        playerPerson: player,
        botPerson: bot,
        playerYear: player.birthYear,
        botYear: bot.birthYear,
        targetYear: widget.targetYear,
        playerColor: playerColor,
        botColor: botColor,
        showPlayer: _step >= 1,
        showBot: _step >= 2,
        showTarget: showTarget,
        showDistances: showDistances,
        playerWon: widget.result.playerWon,
        isDraw: widget.result.isDraw,
      ),
      highlightedPerson: showDistances
          ? (widget.result.isDraw
                ? null
                : widget.result.playerWon
                ? player
                : bot)
          : null,
      highlightedColor: showDistances
          ? (widget.result.isDraw ? null : const Color(0xFF5CCB8A))
          : null,
      winnerText: showDistances
          ? (widget.result.isDraw
                ? 'Draw'
                : '${widget.result.playerWon ? player.name : bot.name} wins')
          : null,
      hideSidePortraits: true,
      footer: null,
    );
  }
}

class _TimeRevealStage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Person leftPerson;
  final Person rightPerson;
  final String leftLabel;
  final String rightLabel;
  final Color leftColor;
  final Color rightColor;
  final Widget center;
  final Widget? footer;
  final Person? highlightedPerson;
  final Color? highlightedColor;
  final String? winnerText;
  final bool hideSidePortraits;

  const _TimeRevealStage({
    required this.title,
    required this.subtitle,
    required this.leftPerson,
    required this.rightPerson,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftColor,
    required this.rightColor,
    required this.center,
    this.footer,
    this.highlightedPerson,
    this.highlightedColor,
    this.winnerText,
    this.hideSidePortraits = false,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    final compact = MediaQuery.sizeOf(context).width < 430;
    final showSubtitle = subtitle.isNotEmpty && !compact;
    final topPortraitLayout = mobile && !hideSidePortraits;
    final baseStageHeight = compact
        ? (hideSidePortraits ? 252.0 : 166.0)
        : mobile
        ? (hideSidePortraits ? 324.0 : 236.0)
        : (hideSidePortraits ? 404.0 : 350.0);
    final reservedFooterHeight = footer == null
        ? 0.0
        : compact
        ? 56.0
        : mobile
        ? 64.0
        : 72.0;
    final reservedWinnerHeight = winnerText == null
        ? 0.0
        : compact
        ? 36.0
        : 42.0;
    final stageHeight = max(
      compact ? 120.0 : 156.0,
      baseStageHeight - reservedFooterHeight - reservedWinnerHeight,
    );

    Widget sidePortrait({
      required Person person,
      required String label,
      required Color color,
      required Alignment alignment,
    }) {
      final isHighlighted = highlightedPerson?.id == person.id;
      final centered = topPortraitLayout;
      return SizedBox(
        width: compact
            ? 72
            : mobile
            ? 96
            : 164,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : alignment == Alignment.centerLeft
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Text(
              label,
              textAlign: centered
                  ? TextAlign.center
                  : alignment == Alignment.centerLeft
                  ? TextAlign.left
                  : TextAlign.right,
              style: TextStyle(
                color: color.withValues(alpha: 0.70),
                fontWeight: FontWeight.w800,
                fontSize: compact ? 10 : 11,
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 16 : 22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 16 : 22),
                  border: Border.all(
                    color: (isHighlighted ? (highlightedColor ?? color) : color)
                        .withValues(alpha: isHighlighted ? 0.72 : 0.12),
                    width: isHighlighted ? 2 : 1,
                  ),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: (highlightedColor ?? color).withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : null,
                ),
                child: Opacity(
                  opacity: isHighlighted ? 0.92 : 0.24,
                  child: SizedBox(
                    height: compact ? 74 : null,
                    child: AspectRatio(
                      aspectRatio: 0.78,
                      child: PersonPortrait(
                        person: person,
                        variant: isHighlighted
                            ? PersonImageVariant.portrait
                            : PersonImageVariant.vs,
                        borderRadius: compact ? 16 : 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            Text(
              person.name,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: centered
                  ? TextAlign.center
                  : alignment == Alignment.centerLeft
                  ? TextAlign.left
                  : TextAlign.right,
              style: TextStyle(
                color:
                    (isHighlighted
                            ? const Color(0xFFF7ECDD)
                            : const Color(0xFFD8CBB8))
                        .withValues(alpha: isHighlighted ? 0.94 : 0.52),
                fontWeight: FontWeight.w800,
                fontSize: compact
                    ? 10.5
                    : mobile
                    ? 14
                    : 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact
            ? 8
            : mobile
            ? 12
            : 18,
        compact
            ? 8
            : mobile
            ? 12
            : 18,
        compact
            ? 8
            : mobile
            ? 12
            : 18,
        compact
            ? 10
            : mobile
            ? 14
            : 18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 30),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4B06A).withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.02),
            Colors.black.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: compact
                  ? 14
                  : mobile
                  ? 18
                  : 22,
              height: 1.05,
            ),
          ),
          if (showSubtitle) ...[
            SizedBox(height: compact ? 3 : 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFD8CBB8).withValues(alpha: 0.86),
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11.5 : null,
                height: 1.35,
              ),
            ),
          ],
          SizedBox(height: compact ? 8 : 14),
          if (hideSidePortraits) ...[
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: compact ? 2 : 4,
                  bottom: compact ? 2 : 4,
                ),
                child: SizedBox.expand(child: center),
              ),
            ),
          ] else if (topPortraitLayout) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: sidePortrait(
                    person: leftPerson,
                    label: leftLabel,
                    color: leftColor,
                    alignment: Alignment.centerLeft,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: compact ? 24 : 28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.24),
                      border: Border.all(
                        color: const Color(0xFFD4B06A).withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: Color(0xFFD4B06A),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: sidePortrait(
                    person: rightPerson,
                    label: rightLabel,
                    color: rightColor,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: stageHeight,
              child: Center(child: center),
            ),
          ] else
            SizedBox(
              height: stageHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: sidePortrait(
                            person: leftPerson,
                            label: leftLabel,
                            color: leftColor,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        SizedBox(width: mobile ? 14 : 28),
                        Expanded(
                          child: sidePortrait(
                            person: rightPerson,
                            label: rightLabel,
                            color: rightColor,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(alignment: Alignment.center, child: center),
                ],
              ),
            ),
          if (winnerText != null) ...[
            SizedBox(height: compact ? 8 : 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withValues(alpha: 0.22),
                border: Border.all(
                  color: (highlightedColor ?? const Color(0xFFD4B06A))
                      .withValues(alpha: 0.34),
                ),
              ),
              child: Text(
                winnerText!,
                maxLines: compact ? 2 : 3,
                softWrap: true,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFF7ECDD),
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ),
          ],
          if (footer != null) ...[SizedBox(height: compact ? 8 : 12), footer!],
        ],
      ),
    );
  }
}

class _VerticalYearScene extends StatelessWidget {
  final int minYear;
  final int maxYear;
  final Person playerPerson;
  final Person botPerson;
  final int playerYear;
  final int botYear;
  final int? targetYear;
  final Color playerColor;
  final Color botColor;
  final bool showPlayer;
  final bool showBot;
  final bool showTarget;
  final bool showDistances;
  final bool playerWon;
  final bool isDraw;

  const _VerticalYearScene({
    required this.minYear,
    required this.maxYear,
    required this.playerPerson,
    required this.botPerson,
    required this.playerYear,
    required this.botYear,
    required this.targetYear,
    required this.playerColor,
    required this.botColor,
    required this.showPlayer,
    required this.showBot,
    required this.showTarget,
    required this.showDistances,
    required this.playerWon,
    required this.isDraw,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSceneWidth = compact ? 248.0 : 292.0;
        final sceneWidth = constraints.maxWidth.isFinite
            ? min(maxSceneWidth, constraints.maxWidth)
            : maxSceneWidth;
        final sceneHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (compact ? 242.0 : 344.0);
        final railCenter = sceneWidth / 2;
        final railTop = targetYear != null
            ? (compact ? 48.0 : 56.0)
            : (compact ? 16.0 : 18.0);
        final railBottom = compact ? 4.0 : 6.0;
        final railWidth = compact ? 10.0 : 12.0;
        final portraitSize = compact ? 44.0 : 54.0;
        final markerSize = compact ? 12.0 : 14.0;
        final sideInset = compact ? 12.0 : 16.0;

        double positionFor(int year) {
          if (maxYear == minYear) return 0.5;
          return ((year - minYear) / (maxYear - minYear)).clamp(0.0, 1.0);
        }

        double yFor(int year) {
          final usable = sceneHeight - railTop - railBottom - markerSize;
          return railTop + (positionFor(year) * usable);
        }

        double clampTop(double top, double height) {
          return top.clamp(railTop, sceneHeight - railBottom - height);
        }

        Widget edgeLabel({required String label, required bool top}) {
          return Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: railCenter - 28,
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
                fontWeight: FontWeight.w800,
                fontSize: compact ? 11 : 12,
              ),
            ),
          );
        }

        Widget portraitMarker({
          required Person person,
          required String title,
          required int year,
          required Color color,
          required double top,
          required bool left,
          required bool visible,
        }) {
          final connectorReach = max(
            18.0,
            (sceneWidth / 2) - sideInset - portraitSize - (markerSize / 2),
          );
          final titleHeight = compact ? 11.0 : 12.0;
          final titleGap = compact ? 3.0 : 4.0;
          final yearGap = compact ? 3.0 : 4.0;
          final yearHeight = compact ? 12.0 : 13.0;
          final portraitTop = titleHeight + titleGap;
          final blockHeight = portraitTop + portraitSize + yearGap + yearHeight;
          final markerTop = clampTop(
            top - portraitTop - (portraitSize / 2) + (markerSize / 2),
            blockHeight,
          );
          final connectorTop = portraitTop + (portraitSize / 2) - 1;
          return Positioned(
            left: left ? sideInset : null,
            right: left ? null : sideInset,
            top: markerTop,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 420),
              opacity: visible ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                offset: visible ? Offset.zero : Offset(left ? -0.08 : 0.08, 0),
                child: SizedBox(
                  width: portraitSize + connectorReach,
                  height: blockHeight,
                  child: Stack(
                    children: [
                      Positioned(
                        left: left ? portraitSize : 0,
                        right: left ? 0 : portraitSize,
                        top: connectorTop,
                        child: Container(
                          width: connectorReach,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: color.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                      Positioned(
                        left: left ? 0 : null,
                        right: left ? null : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: titleHeight,
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: compact ? 10 : 11,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            SizedBox(height: titleGap),
                            Container(
                              width: portraitSize,
                              height: portraitSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.18),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: PersonPortrait(
                                  person: person,
                                  width: portraitSize,
                                  height: portraitSize,
                                  borderRadius: 999,
                                  variant: PersonImageVariant.portrait,
                                ),
                              ),
                            ),
                            SizedBox(height: yearGap),
                            SizedBox(
                              height: yearHeight,
                              child: Text(
                                _formatYear(year),
                                style: TextStyle(
                                  color: const Color(0xFFF7ECDD),
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 12 : 13,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        Widget targetMarker({
          required int year,
          required double top,
          required bool visible,
        }) {
          final titleHeight = compact ? 11.0 : 12.0;
          final titleGap = compact ? 3.0 : 4.0;
          final yearGap = compact ? 3.0 : 4.0;
          final yearHeight = compact ? 12.0 : 13.0;
          final targetSize = compact ? 32.0 : 36.0;
          final connectorReach = max(
            18.0,
            (sceneWidth / 2) - sideInset - targetSize - (markerSize / 2),
          );
          final iconTop = titleHeight + titleGap;
          final blockHeight = iconTop + targetSize + yearGap + yearHeight;
          final markerTop = clampTop(
            top - iconTop - (targetSize / 2) + (markerSize / 2),
            blockHeight,
          );
          final connectorTop = iconTop + (targetSize / 2) - 1;

          return Positioned(
            right: sideInset,
            top: markerTop,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 420),
              opacity: visible ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                offset: visible ? Offset.zero : const Offset(0.08, 0),
                child: SizedBox(
                  width: targetSize + connectorReach,
                  height: blockHeight,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: targetSize,
                        top: connectorTop,
                        child: Container(
                          width: connectorReach,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(
                              0xFFD4B06A,
                            ).withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: titleHeight,
                              child: Text(
                                'Target',
                                style: TextStyle(
                                  color: const Color(0xFFD4B06A),
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 10 : 11,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            SizedBox(height: titleGap),
                            Container(
                              width: targetSize,
                              height: targetSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFD4B06A),
                                border: Border.all(
                                  color: const Color(0xFFF7ECDD),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4B06A,
                                    ).withValues(alpha: 0.26),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.place_rounded,
                                color: Color(0xFF1B100A),
                                size: 18,
                              ),
                            ),
                            SizedBox(height: yearGap),
                            SizedBox(
                              height: yearHeight,
                              child: Text(
                                _formatYear(year),
                                style: TextStyle(
                                  color: const Color(0xFFF7ECDD),
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 12 : 13,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        Widget markerDot({
          required double top,
          required Color color,
          required bool visible,
          bool target = false,
        }) {
          return Positioned(
            top: top,
            left: railCenter - (markerSize / 2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 420),
              opacity: visible ? 1 : 0,
              child: Container(
                width: markerSize,
                height: markerSize,
                decoration: BoxDecoration(
                  shape: target ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: target ? BorderRadius.circular(4) : null,
                  color: color,
                  border: Border.all(color: const Color(0xFFF7ECDD), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.24),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                transform: target
                    ? (Matrix4.identity()..rotateZ(pi / 4))
                    : null,
              ),
            ),
          );
        }

        Widget distanceBar({
          required double fromTop,
          required double toTop,
          required Color color,
          required bool visible,
          required bool left,
          required String value,
        }) {
          final top = min(fromTop, toTop) + (markerSize / 2);
          final height = max(0.0, (fromTop - toTop).abs());
          final labelWidth = compact ? 42.0 : 48.0;
          final labelHeight = compact ? 20.0 : 22.0;
          final lineLeft = left
              ? railCenter - (compact ? 28 : 32)
              : railCenter + (compact ? 20 : 24);
          return Positioned(
            top: top,
            left: lineLeft,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 320),
              opacity: visible ? 1 : 0,
              child: SizedBox(
                width: labelWidth,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: left
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 4,
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: color.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                    Positioned(
                      top: (height / 2) - (labelHeight / 2),
                      left: left ? null : 8,
                      right: left ? 8 : null,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: compact ? 34 : 38,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 6 : 7,
                          vertical: compact ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(
                            0xFF1A100C,
                          ).withValues(alpha: 0.92),
                          border: Border.all(
                            color: color.withValues(alpha: 0.42),
                          ),
                        ),
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: compact ? 10.5 : 11.5,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final playerTop = yFor(playerYear);
        final botTop = yFor(botYear);
        final targetTop = targetYear == null ? null : yFor(targetYear!);
        final tickYears = <int>{
          minYear,
          maxYear,
          playerYear,
          botYear,
          minYear + ((maxYear - minYear) ~/ 2),
          ?targetYear,
        }.toList()..sort();

        return Center(
          child: SizedBox(
            width: sceneWidth,
            height: sceneHeight,
            child: Stack(
              children: [
                edgeLabel(label: 'Early', top: true),
                edgeLabel(label: 'Late', top: false),
                Positioned(
                  top: railTop,
                  bottom: railBottom,
                  left: railCenter - (compact ? 16 : 20),
                  child: Container(
                    width: compact ? 32 : 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0x33D4B06A),
                          const Color(0x12F7ECDD),
                          const Color(0x33D4B06A),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: railTop,
                  bottom: railBottom,
                  left: railCenter - (railWidth / 2),
                  child: Container(
                    width: railWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x44D4B06A),
                          Color(0xFFF7ECDD),
                          Color(0x44D4B06A),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD4B06A,
                          ).withValues(alpha: 0.22),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                for (final year in tickYears)
                  Positioned(
                    top: yFor(year) + (markerSize / 2) - 1,
                    left: railCenter - (compact ? 12 : 14),
                    child: Row(
                      children: [
                        Container(
                          width: compact ? 10 : 12,
                          height: 2,
                          color: const Color(0x44F7ECDD),
                        ),
                        SizedBox(width: compact ? 6 : 8),
                        Container(
                          width: compact ? 10 : 12,
                          height: 2,
                          color: const Color(0x44F7ECDD),
                        ),
                      ],
                    ),
                  ),
                portraitMarker(
                  title: 'Bot',
                  person: botPerson,
                  year: botYear,
                  color: botColor,
                  top: botTop,
                  left: false,
                  visible: showBot,
                ),
                portraitMarker(
                  title: 'You',
                  person: playerPerson,
                  year: playerYear,
                  color: playerColor,
                  top: playerTop,
                  left: true,
                  visible: showPlayer,
                ),
                markerDot(top: botTop, color: botColor, visible: showBot),
                markerDot(
                  top: playerTop,
                  color: playerColor,
                  visible: showPlayer,
                ),
                if (targetYear != null)
                  targetMarker(
                    year: targetYear!,
                    top: targetTop!,
                    visible: showTarget,
                  ),
                if (targetYear != null)
                  markerDot(
                    top: targetTop!,
                    color: const Color(0xFFD4B06A),
                    visible: showTarget,
                    target: true,
                  ),
                if (showDistances && targetYear != null && targetTop != null)
                  distanceBar(
                    fromTop: botTop,
                    toTop: targetTop,
                    color: !playerWon && !isDraw
                        ? const Color(0xFF5CCB8A)
                        : const Color(0xFFE96C5B),
                    visible: showDistances,
                    left: false,
                    value: '${(botYear - targetYear!).abs()} J',
                  ),
                if (showDistances && targetYear != null && targetTop != null)
                  distanceBar(
                    fromTop: playerTop,
                    toTop: targetTop,
                    color: playerWon && !isDraw
                        ? const Color(0xFF5CCB8A)
                        : const Color(0xFFE96C5B),
                    visible: showDistances,
                    left: true,
                    value: '${(playerYear - targetYear!).abs()} J',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResolutionBeat extends StatelessWidget {
  final bool visible;
  final Color accent;
  final Widget child;

  const _ResolutionBeat({
    required this.visible,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 0.14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.black.withValues(alpha: 0.16),
            border: Border.all(color: accent.withValues(alpha: 0.32)),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 18),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ResolutionFigureLine extends StatelessWidget {
  final String label;
  final Person person;
  final Color color;
  final String detail;

  const _ResolutionFigureLine({
    required this.label,
    required this.person,
    required this.color,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.3),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 16),
            ],
          ),
          child: ClipOval(
            child: PersonPortrait(
              person: person,
              width: 54,
              height: 54,
              borderRadius: 999,
              variant: PersonImageVariant.portrait,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                person.name,
                style: const TextStyle(
                  color: Color(0xFFF7ECDD),
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResolutionEventLine extends StatelessWidget {
  final String label;
  final int year;

  const _ResolutionEventLine({required this.label, required this.year});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD4B06A).withValues(alpha: 0.16),
            border: Border.all(
              color: const Color(0xFFD4B06A).withValues(alpha: 0.40),
              width: 2,
            ),
          ),
          child: const Icon(Icons.timeline_rounded, color: Color(0xFFD4B06A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The event was',
                style: TextStyle(
                  color: Color(0xFFD4B06A),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFF7ECDD),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'in ${_formatYear(year)}',
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineActorPin extends StatelessWidget {
  final double position;
  final Color color;
  final Person person;
  final String label;
  final int year;
  final double topAlignment;
  final bool highlighted;

  const _TimelineActorPin({
    required this.position,
    required this.color,
    required this.person,
    required this.label,
    required this.year,
    required this.topAlignment,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment((position * 2) - 1, topAlignment),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.black.withValues(alpha: 0.38),
              border: Border.all(color: color.withValues(alpha: 0.82)),
            ),
            child: Text(
              '$label - ${_formatYear(year)}',
              style: const TextStyle(
                color: Color(0xFFF7ECDD),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: highlighted ? 58 : 52,
            height: highlighted ? 58 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: highlighted ? 2.8 : 2.1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: highlighted ? 0.24 : 0.14),
                  blurRadius: 18,
                ),
              ],
            ),
            child: ClipOval(
              child: PersonPortrait(
                person: person,
                width: highlighted ? 58 : 52,
                height: highlighted ? 58 : 52,
                borderRadius: 999,
                variant: PersonImageVariant.portrait,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.45)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTargetBadge extends StatelessWidget {
  final double position;
  final int year;
  final String label;

  const _TimelineTargetBadge({
    required this.position,
    required this.year,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment((position * 2) - 1, -0.90),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black.withValues(alpha: 0.42),
              border: Border.all(
                color: const Color(0xFFD4B06A).withValues(alpha: 0.84),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_formatYear(year)} - Target',
                  style: const TextStyle(
                    color: Color(0xFFD4B06A),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            Icons.arrow_drop_down_rounded,
            color: const Color(0xFFD4B06A).withValues(alpha: 0.90),
            size: 34,
          ),
        ],
      ),
    );
  }
}

class _TimelineMeasureChip extends StatelessWidget {
  final Color color;
  final String label;
  final String? value;
  final bool wide;

  const _TimelineMeasureChip({
    required this.color,
    required this.label,
    this.value,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 38 : 48,
        maxWidth: wide ? (compact ? 220 : 520) : (compact ? 168 : 220),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: value == null ? 0.10 : 0.18),
            Colors.black.withValues(alpha: 0.28),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: value == null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: wide ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            textAlign: value == null ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              color: value == null ? const Color(0xFFF7ECDD) : color,
              fontWeight: FontWeight.w800,
              height: 1.15,
              fontSize: compact ? 10.5 : 12,
            ),
          ),
          if (value != null) ...[
            const SizedBox(height: 3),
            Text(
              value!,
              style: TextStyle(
                color: const Color(0xFFF7ECDD),
                fontWeight: FontWeight.w900,
                height: 1.0,
                fontSize: compact ? 15 : 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final double playerPosition;
  final double botPosition;
  final double? targetPosition;
  final bool showTarget;
  final bool showPlayer;
  final bool showBot;
  final bool showDistances;
  final double lineProgress;
  final bool playerWon;
  final bool isDraw;
  final Color playerLineColor;
  final Color botLineColor;

  const _TimelinePainter({
    required this.playerPosition,
    required this.botPosition,
    required this.targetPosition,
    required this.showTarget,
    required this.showPlayer,
    required this.showBot,
    required this.showDistances,
    required this.lineProgress,
    required this.playerWon,
    required this.isDraw,
    required this.playerLineColor,
    required this.botLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.72;
    final startX = 28.0;
    final endX = size.width - 28.0;
    final haloPaint = Paint()
      ..color = const Color(0xFFD4B06A).withValues(alpha: 0.14)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x66F7ECDD), Color(0xFFF7ECDD), Color(0x66F7ECDD)],
      ).createShader(Rect.fromLTWH(startX, y - 10, endX - startX, 20))
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(startX, y), Offset(endX, y), haloPaint);
    canvas.drawLine(Offset(startX, y), Offset(endX, y), basePaint);

    final playerX = lerpDouble(startX, endX, playerPosition)!;
    final botX = lerpDouble(startX, endX, botPosition)!;
    final targetX = targetPosition == null
        ? null
        : lerpDouble(startX, endX, targetPosition!)!;

    if (showDistances && targetX != null) {
      final playerEnd = lerpDouble(playerX, targetX, lineProgress)!;
      final botEnd = lerpDouble(botX, targetX, lineProgress)!;
      final playerPaint = Paint()
        ..color = playerLineColor.withValues(alpha: 0.96)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final playerGlow = Paint()
        ..color = playerLineColor.withValues(alpha: 0.22)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final botPaint = Paint()
        ..color = botLineColor.withValues(alpha: 0.96)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final botGlow = Paint()
        ..color = botLineColor.withValues(alpha: 0.22)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawLine(
        Offset(playerX, y - 22),
        Offset(playerEnd, y - 22),
        playerGlow,
      );
      canvas.drawLine(
        Offset(playerX, y - 22),
        Offset(playerEnd, y - 22),
        playerPaint,
      );
      canvas.drawLine(Offset(botX, y - 6), Offset(botEnd, y - 6), botGlow);
      canvas.drawLine(Offset(botX, y - 6), Offset(botEnd, y - 6), botPaint);
    }

    if (showTarget && targetX != null) {
      final targetPaint = Paint()..color = const Color(0xFFD4B06A);
      final targetGlow = Paint()
        ..color = const Color(0xFFD4B06A).withValues(alpha: 0.16)
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawLine(
        Offset(targetX, y + 8),
        Offset(targetX, y - 46),
        targetGlow,
      );
      canvas.drawLine(
        Offset(targetX, y + 8),
        Offset(targetX, y - 46),
        targetPaint..strokeWidth = 2.6,
      );
      canvas.drawCircle(Offset(targetX, y), 7, targetPaint);
    }

    void drawAnchor(double x, Color color, bool active, {double radius = 9}) {
      if (!active) return;
      final glow = Paint()
        ..color = color.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final paint = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), radius + 8, glow);
      canvas.drawCircle(Offset(x, y), radius, paint);
      canvas.drawCircle(
        Offset(x, y),
        radius - 3,
        Paint()..color = const Color(0xFF1B100A),
      );
    }

    drawAnchor(
      playerX,
      const Color(0xFFD4B06A),
      showPlayer,
      radius: playerWon && !isDraw ? 10 : 8,
    );
    drawAnchor(
      botX,
      const Color(0xFFE39063),
      showBot,
      radius: !playerWon && !isDraw ? 10 : 8,
    );
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.playerPosition != playerPosition ||
        oldDelegate.botPosition != botPosition ||
        oldDelegate.targetPosition != targetPosition ||
        oldDelegate.showTarget != showTarget ||
        oldDelegate.showPlayer != showPlayer ||
        oldDelegate.showBot != showBot ||
        oldDelegate.showDistances != showDistances ||
        oldDelegate.lineProgress != lineProgress ||
        oldDelegate.playerWon != playerWon ||
        oldDelegate.isDraw != isDraw ||
        oldDelegate.playerLineColor != playerLineColor ||
        oldDelegate.botLineColor != botLineColor;
  }
}

class _LifespanResult extends StatefulWidget {
  final BattleRoundResult result;

  const _LifespanResult({required this.result});

  @override
  State<_LifespanResult> createState() => _LifespanResultState();
}

class _LifespanResultState extends State<_LifespanResult> {
  bool _animate = false;
  bool _showWinner = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        setState(() => _animate = true);
        Future.delayed(const Duration(milliseconds: 1450), () {
          if (mounted) {
            setState(() => _showWinner = true);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = max(
      widget.result.playerMetric,
      widget.result.botMetric,
    ).clamp(1, 1000).toDouble();
    final playerColor = widget.result.playerWon && !widget.result.isDraw
        ? const Color(0xFF5CCB8A)
        : _rarityColor(widget.result.playerCard!.rarity);
    final botColor = !widget.result.playerWon && !widget.result.isDraw
        ? const Color(0xFF5CCB8A)
        : _rarityColor(widget.result.botCard!.rarity);

    final compact = MediaQuery.sizeOf(context).width < 430;

    return _TimeRevealStage(
      title: 'Lifespans compared',
      subtitle: '',
      leftPerson: widget.result.playerCard!,
      rightPerson: widget.result.botCard!,
      leftLabel: 'You',
      rightLabel: 'Bot',
      leftColor: playerColor,
      rightColor: botColor,
      center: _VerticalLifespanScene(
        playerYears: widget.result.playerMetric,
        botYears: widget.result.botMetric,
        maxYears: maxValue,
        playerColor: playerColor,
        botColor: botColor,
        animate: _animate,
      ),
      highlightedPerson: _showWinner
          ? (widget.result.isDraw
                ? null
                : widget.result.playerWon
                ? widget.result.playerCard!
                : widget.result.botCard!)
          : null,
      highlightedColor: _showWinner ? const Color(0xFF5CCB8A) : null,
      winnerText: _showWinner
          ? (widget.result.isDraw
                ? 'Draw'
                : '${widget.result.playerWon ? widget.result.playerCard!.name : widget.result.botCard!.name} wins')
          : null,
      footer: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          _TimelineMeasureChip(
            color: playerColor,
            label: widget.result.playerCard!.name,
            value: '${widget.result.playerMetric.toStringAsFixed(0)} J',
          ),
          _TimelineMeasureChip(
            color: botColor,
            label: widget.result.botCard!.name,
            value: '${widget.result.botMetric.toStringAsFixed(0)} J',
          ),
          if (!compact)
            _TimelineMeasureChip(
              color: const Color(0xFFD4B06A),
              label: widget.result.explanation,
              wide: true,
            ),
        ],
      ),
    );
  }
}

class _VerticalLifespanScene extends StatelessWidget {
  final double playerYears;
  final double botYears;
  final double maxYears;
  final Color playerColor;
  final Color botColor;
  final bool animate;

  const _VerticalLifespanScene({
    required this.playerYears,
    required this.botYears,
    required this.maxYears,
    required this.playerColor,
    required this.botColor,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    final playerRatio = maxYears <= 0
        ? 0.0
        : (playerYears / maxYears).clamp(0.0, 1.0);
    final botRatio = maxYears <= 0
        ? 0.0
        : (botYears / maxYears).clamp(0.0, 1.0);

    Widget bar({
      required double years,
      required double ratio,
      required Color color,
      required String label,
    }) {
      return Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: animate ? 1 : 0),
          duration: const Duration(milliseconds: 1600),
          curve: Curves.easeInOutCubic,
          builder: (context, progress, child) {
            final animatedYears = years * progress;
            final animatedRatio = ratio * progress;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  animatedYears.toStringAsFixed(0),
                  style: TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 15 : 18,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: compact ? 22 : 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: animatedRatio,
                          child: Container(
                            width: compact ? 22 : 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.70),
                                  color,
                                  Color.lerp(color, Colors.white, 0.28)!,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return SizedBox(
      width: compact ? 196 : 236,
      height: compact ? 228 : 292,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: compact ? 18 : 24,
            right: compact ? 18 : 24,
            top: 0,
            bottom: compact ? 22 : 26,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    const Color(0x16D4B06A),
                    Colors.transparent,
                    const Color(0x10F7ECDD),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bar(
                years: playerYears,
                ratio: playerRatio,
                color: playerColor,
                label: 'You',
              ),
              SizedBox(width: compact ? 18 : 26),
              bar(
                years: botYears,
                ratio: botRatio,
                color: botColor,
                label: 'Bot',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationMapResult extends StatefulWidget {
  final BattleRoundResult result;

  const _LocationMapResult({required this.result});

  @override
  State<_LocationMapResult> createState() => _LocationMapResultState();
}

class _LocationMapResultState extends State<_LocationMapResult> {
  final MapController _mapController = MapController();
  final List<Timer> _timers = [];
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runSequence();
    });
  }

  void _runSequence() {
    final target = widget.result.definition.locationTarget!;
    final playerPoint = LatLng(
      widget.result.playerCard!.birthLat ?? target.lat,
      widget.result.playerCard!.birthLng ?? target.lng,
    );
    final botPoint = LatLng(
      widget.result.botCard!.birthLat ?? target.lat,
      widget.result.botCard!.birthLng ?? target.lng,
    );
    final targetPoint = LatLng(target.lat, target.lng);
    final finalCenter = LatLng(
      (targetPoint.latitude + playerPoint.latitude + botPoint.latitude) / 3,
      (targetPoint.longitude + playerPoint.longitude + botPoint.longitude) / 3,
    );

    void schedule(Duration delay, VoidCallback callback) {
      _timers.add(
        Timer(delay, () {
          if (mounted) {
            callback();
          }
        }),
      );
    }

    if (!mounted) return;
    _mapController.move(finalCenter, 2.45);
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _phase = 6);
      return;
    }
    schedule(const Duration(milliseconds: 800), () {
      setState(() => _phase = 3);
    });
    schedule(const Duration(milliseconds: 2100), () {
      setState(() => _phase = 5);
    });
    schedule(const Duration(milliseconds: 3800), () {
      setState(() => _phase = 6);
    });
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.result.definition.locationTarget!;
    final tiebreakMysteryMap = widget.result.definition.isTiebreaker;
    final playerHasLocation =
        widget.result.playerCard!.birthLat != null &&
        widget.result.playerCard!.birthLng != null;
    final botHasLocation =
        widget.result.botCard!.birthLat != null &&
        widget.result.botCard!.birthLng != null;
    final maxValue = max(
      widget.result.playerMetric,
      widget.result.botMetric,
    ).clamp(1, 30000).toDouble();

    if (!playerHasLocation || !botHasLocation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _DistanceBar(
            name: widget.result.playerCard!.name,
            value: widget.result.playerMetric,
            maxValue: maxValue,
            color: _rarityColor(widget.result.playerCard!.rarity),
            animate: true,
            winner: widget.result.playerWon && !widget.result.isDraw,
            suffix: ' km',
          ),
          const SizedBox(height: 12),
          _DistanceBar(
            name: widget.result.botCard!.name,
            value: widget.result.botMetric,
            maxValue: maxValue,
            color: _rarityColor(widget.result.botCard!.rarity),
            animate: true,
            winner: !widget.result.playerWon && !widget.result.isDraw,
            suffix: ' km',
          ),
        ],
      );
    }

    final playerColor = widget.result.playerWon && !widget.result.isDraw
        ? const Color(0xFF5CCB8A)
        : _rarityColor(widget.result.playerCard!.rarity);
    final botColor = !widget.result.playerWon && !widget.result.isDraw
        ? const Color(0xFF5CCB8A)
        : _rarityColor(widget.result.botCard!.rarity);
    final targetPoint = LatLng(target.lat, target.lng);
    final playerPoint = LatLng(
      widget.result.playerCard!.birthLat!,
      widget.result.playerCard!.birthLng!,
    );
    final botPoint = LatLng(
      widget.result.botCard!.birthLat!,
      widget.result.botCard!.birthLng!,
    );

    final showBotPin = _phase >= 3;
    final showPlayerPin = _phase >= 5;
    final showBotLine = _phase >= 3;
    final showPlayerLine = _phase >= 5;
    final showResolution = _phase >= 6;
    final statusText = switch (_phase) {
      0 => tiebreakMysteryMap ? 'Historical target' : target.label,
      1 =>
        tiebreakMysteryMap ? 'Borders without place names' : 'Target in focus',
      2 => widget.result.botCard!.name,
      3 => 'Tracing the opponent route',
      4 => widget.result.playerCard!.name,
      5 => 'Tracing your route',
      _ =>
        'Reveal: ${widget.result.playerWon
            ? widget.result.playerCard!.name
            : widget.result.isDraw
            ? 'Both'
            : widget.result.botCard!.name} ${widget.result.isDraw ? 'are tied' : 'is closer'}.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).width < 430 ? 244 : 292,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: targetPoint,
                    initialZoom: 5.2,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: tiebreakMysteryMap
                          ? MapTileConfig.mysteryNoLabelsUrlTemplate
                          : MapTileConfig.standardRasterUrlTemplate,
                      subdomains: tiebreakMysteryMap
                          ? MapTileConfig.mysterySubdomains
                          : const [],
                      userAgentPackageName: MapTileConfig.userAgentPackageName,
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 900),
                      opacity: showBotLine ? 1 : 0,
                      child: PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [targetPoint, botPoint],
                            strokeWidth: 4,
                            color: botColor.withValues(alpha: 0.92),
                          ),
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 900),
                      opacity: showPlayerLine ? 1 : 0,
                      child: PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [targetPoint, playerPoint],
                            strokeWidth: 4,
                            color: playerColor.withValues(alpha: 0.92),
                          ),
                        ],
                      ),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: targetPoint,
                          width: 64,
                          height: 64,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeInOutCubic,
                            scale: _phase >= 0 ? 1 : 0.84,
                            child: const _TargetMarker(),
                          ),
                        ),
                        Marker(
                          point: playerPoint,
                          width: 86,
                          height: 98,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 900),
                            opacity: showPlayerPin ? 1 : 0,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeInOutCubic,
                              scale: showPlayerPin ? 1 : 0.72,
                              child: _PortraitPin(
                                person: widget.result.playerCard!,
                                highlighted:
                                    showResolution &&
                                    widget.result.playerWon &&
                                    !widget.result.isDraw,
                              ),
                            ),
                          ),
                        ),
                        Marker(
                          point: botPoint,
                          width: 86,
                          height: 98,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 900),
                            opacity: showBotPin ? 1 : 0,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeInOutCubic,
                              scale: showBotPin ? 1 : 0.72,
                              child: _PortraitPin(
                                person: widget.result.botCard!,
                                highlighted:
                                    showResolution &&
                                    !widget.result.playerWon &&
                                    !widget.result.isDraw,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.18),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.28),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 8,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 520),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _MapStatusBanner(
                      key: ValueKey(_phase),
                      title: _phase <= 1
                          ? 'Target'
                          : _phase <= 3
                          ? 'Opponent'
                          : _phase <= 5
                          ? 'You'
                          : 'Reveal',
                      text: statusText,
                      color: _phase <= 1
                          ? const Color(0xFFD4B06A)
                          : _phase <= 3
                          ? botColor
                          : _phase <= 5
                          ? playerColor
                          : const Color(0xFFD4B06A),
                    ),
                  ),
                ),
                Positioned(
                  top: 54,
                  left: 10,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 900),
                    opacity: _phase == 4 || _phase == 5 ? 1 : 0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOutCubic,
                      scale: _phase == 4 ? 1 : 0.84,
                      child: _MapPlayCard(
                        person: widget.result.playerCard!,
                        label: 'You played',
                        detail:
                            '${widget.result.playerMetric.toStringAsFixed(0)} km away',
                        color: playerColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 54,
                  right: 10,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 900),
                    opacity: _phase == 2 || _phase == 3 ? 1 : 0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOutCubic,
                      scale: _phase == 2 ? 1 : 0.84,
                      child: _MapPlayCard(
                        person: widget.result.botCard!,
                        label: 'Opponent played',
                        detail:
                            '${widget.result.botMetric.toStringAsFixed(0)} km away',
                        color: botColor,
                        alignRight: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showResolution) ...[
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 430 ? 152 : 184,
                child: _MetricCapsule(
                  label: widget.result.playerCard!.name,
                  value: '${widget.result.playerMetric.toStringAsFixed(0)} km',
                  color: playerColor,
                ),
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 430 ? 152 : 184,
                child: _MetricCapsule(
                  label: widget.result.botCard!.name,
                  value: '${widget.result.botMetric.toStringAsFixed(0)} km',
                  color: botColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black.withValues(alpha: 0.22),
              border: Border.all(
                color: const Color(0xFF5CCB8A).withValues(alpha: 0.34),
              ),
            ),
            child: Text(
              widget.result.isDraw
                  ? 'Draw'
                  : '${widget.result.playerWon ? widget.result.playerCard!.name : widget.result.botCard!.name} wins',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF7ECDD),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MapStatusBanner extends StatelessWidget {
  final String title;
  final String text;
  final Color color;

  const _MapStatusBanner({
    super.key,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        color: Colors.black.withValues(alpha: 0.48),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 10 : 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w700,
              height: 1.25,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlayCard extends StatelessWidget {
  final Person person;
  final String label;
  final String detail;
  final Color color;
  final bool alignRight;

  const _MapPlayCard({
    required this.person,
    required this.label,
    required this.detail,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      width: compact ? 124 : 156,
      padding: EdgeInsets.all(compact ? 7 : 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.22),
            Colors.black.withValues(alpha: 0.34),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 10 : 11,
            ),
          ),
          SizedBox(height: compact ? 5 : 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            child: SizedBox(
              width: compact ? 52 : 64,
              height: compact ? 66 : 80,
              child: PersonPortrait(
                person: person,
                variant: PersonImageVariant.portrait,
                borderRadius: compact ? 12 : 14,
              ),
            ),
          ),
          SizedBox(height: compact ? 5 : 7),
          Text(
            person.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: compact ? 11 : 13,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PseudoMapPainter extends CustomPainter {
  final Offset player;
  final Offset bot;
  final Offset target;
  final Color playerColor;
  final Color botColor;
  final double revealProgress;

  const _PseudoMapPainter({
    required this.player,
    required this.bot,
    required this.target,
    required this.playerColor,
    required this.botColor,
    required this.revealProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final dx = size.width * i / 6;
      final dy = size.height * i / 6;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final landPaint = Paint()
      ..color = const Color(0xFFD4B06A).withValues(alpha: 0.07);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.18,
        size.width * 0.28,
        size.height * 0.20,
      ),
      landPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.36,
        size.height * 0.14,
        size.width * 0.22,
        size.height * 0.16,
      ),
      landPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.58,
        size.height * 0.16,
        size.width * 0.24,
        size.height * 0.18,
      ),
      landPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.30,
        size.height * 0.48,
        size.width * 0.18,
        size.height * 0.24,
      ),
      landPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.72,
        size.height * 0.52,
        size.width * 0.14,
        size.height * 0.10,
      ),
      landPaint,
    );

    void drawConnection(
      Offset from,
      Offset to,
      Color color,
      double verticalOffset,
    ) {
      final glow = Paint()
        ..color = color.withValues(alpha: 0.22)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.96)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final end = Offset(
        lerpDouble(from.dx, to.dx, revealProgress)!,
        lerpDouble(
          from.dy - verticalOffset,
          to.dy - verticalOffset,
          revealProgress,
        )!,
      );
      canvas.drawLine(Offset(from.dx, from.dy - verticalOffset), end, glow);
      canvas.drawLine(Offset(from.dx, from.dy - verticalOffset), end, paint);
    }

    drawConnection(player, target, playerColor, 8);
    drawConnection(bot, target, botColor, -8);
  }

  @override
  bool shouldRepaint(covariant _PseudoMapPainter oldDelegate) {
    return oldDelegate.player != player ||
        oldDelegate.bot != bot ||
        oldDelegate.target != target ||
        oldDelegate.playerColor != playerColor ||
        oldDelegate.botColor != botColor ||
        oldDelegate.revealProgress != revealProgress;
  }
}

class _DistanceBar extends StatelessWidget {
  final String name;
  final double value;
  final double maxValue;
  final Color color;
  final bool animate;
  final bool winner;
  final String suffix;

  const _DistanceBar({
    required this.name,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.animate,
    required this.winner,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(
          color: color.withValues(alpha: winner ? 0.60 : 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name - ${value.toStringAsFixed(0)}$suffix',
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 14,
              value: animate ? ratio : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitPin extends StatelessWidget {
  final Person person;
  final bool highlighted;

  const _PortraitPin({required this.person, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    final color = highlighted
        ? const Color(0xFFD4B06A)
        : _rarityColor(person.rarity);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: highlighted ? 3 : 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 16),
            ],
          ),
          child: ClipOval(
            child: PersonPortrait(
              person: person,
              width: 58,
              height: 58,
              borderRadius: 999,
              variant: PersonImageVariant.portrait,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TargetMarker extends StatelessWidget {
  const _TargetMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD4B06A),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4B06A).withValues(alpha: 0.28),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(Icons.place_rounded, color: Color(0xFF1B100A)),
        ),
        const SizedBox(height: 2),
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: const Color(0xFFD4B06A),
          ),
        ),
      ],
    );
  }
}

class _MetricCapsule extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCapsule({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 14,
        compact ? 8 : 12,
        compact ? 10 : 14,
        compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 10 : 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              fontSize: compact ? 16 : 20,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

Color _rarityColor(PersonRarity rarity) {
  switch (rarity) {
    case PersonRarity.common:
      return const Color(0xFFBEC3CD);
    case PersonRarity.rare:
      return const Color(0xFF54A5FF);
    case PersonRarity.epic:
      return const Color(0xFFC06CFF);
    case PersonRarity.legendary:
      return const Color(0xFFF0C45A);
  }
}

String _categoryLabel(Category category) {
  switch (category) {
    case Category.politician:
      return 'Politics';
    case Category.scientist:
      return 'Science';
    case Category.artist:
      return 'Art';
    case Category.athlete:
      return 'Sports';
  }
}

IconData _categoryIcon(Category category) {
  switch (category) {
    case Category.politician:
      return Icons.account_balance_rounded;
    case Category.scientist:
      return Icons.science_rounded;
    case Category.artist:
      return Icons.palette_rounded;
    case Category.athlete:
      return Icons.emoji_events_rounded;
  }
}

String _roundLabel(BattleRoundType type) {
  switch (type) {
    case BattleRoundType.closerToYear:
      return 'Closer to the year';
    case BattleRoundType.closerToLocation:
      return 'Closer to the place';
    case BattleRoundType.longerLife:
      return 'Longer lifespan';
    case BattleRoundType.bornEarlier:
      return 'Born earlier';
  }
}

String _resultMetricLabel(BattleRoundType type, double value) {
  switch (type) {
    case BattleRoundType.closerToYear:
      return '${value.toStringAsFixed(0)} years away';
    case BattleRoundType.closerToLocation:
      return '${value.toStringAsFixed(0)} km away';
    case BattleRoundType.longerLife:
      return '${value.toStringAsFixed(0)} years lifespan';
    case BattleRoundType.bornEarlier:
      return 'Birth year ${value.toStringAsFixed(0)}';
  }
}

String _formatYear(int year) {
  if (year < 0) {
    return '${year.abs()} BC';
  }
  return '$year';
}
