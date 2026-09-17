import 'dart:async';

import 'package:flutter/material.dart';

import '../battle/battle_session.dart';
import '../models/person.dart';
import '../localization/app_language.dart';
import '../models/person_rarity.dart';
import '../widgets/person_portrait.dart';

class BattleRevealSequence extends StatefulWidget {
  final BattleRoundResult result;
  final Color Function(PersonRarity rarity) rarityColor;
  final Widget Function(BuildContext context, BattleRoundResult result)
  revealStageBuilder;

  const BattleRevealSequence({
    super.key,
    required this.result,
    required this.rarityColor,
    required this.revealStageBuilder,
  });

  @override
  State<BattleRevealSequence> createState() => _BattleRevealSequenceState();
}

class _BattleRevealSequenceState extends State<BattleRevealSequence> {
  Timer? _timer;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), _showResult);
  }

  void _showResult() {
    _timer?.cancel();
    if (mounted && !_revealed) setState(() => _revealed = true);
  }

  @override
  void didUpdateWidget(covariant BattleRevealSequence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      _timer?.cancel();
      _revealed = false;
      _timer = Timer(const Duration(milliseconds: 1500), _showResult);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_revealed || reduceMotion || widget.result.isDirectGuessRound) {
      return widget.revealStageBuilder(context, widget.result);
    }
    Widget card(Person person) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.rarityColor(person.rarity).withValues(alpha: .7),
              ),
            ),
            child: PersonPortrait(
              person: person,
              width: 112,
              height: 148,
              borderRadius: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            person.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .94, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Row(
                children: [
                  card(widget.result.playerCard!),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('VS'),
                  ),
                  card(widget.result.botCard!),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _showResult,
              child: Text(context.tr('Zum Vergleich', 'Show comparison')),
            ),
          ],
        ),
      ),
    );
  }
}

class BattleResultStage extends StatelessWidget {
  final BattleRoundResult result;
  final Widget child;

  const BattleResultStage({
    super.key,
    required this.result,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 16,
        compact ? 10 : 16,
        compact ? 10 : 16,
        compact ? 10 : 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}
