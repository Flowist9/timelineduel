import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../battle/legendary_abilities.dart';
import '../localization/app_language.dart';
import '../models/person.dart';
import 'person_portrait.dart';

/// A selectable hand: inspecting a card never commits the turn.
class BattleCardHand extends StatefulWidget {
  final List<Person> cards;
  final FutureOr<void> Function(Person) onPlay;

  const BattleCardHand({super.key, required this.cards, required this.onPlay});

  @override
  State<BattleCardHand> createState() => _BattleCardHandState();
}

class _BattleCardHandState extends State<BattleCardHand> {
  String? _selectedId;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.cards
        .where((card) => card.id == _selectedId)
        .firstOrNull;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(
            'Deine Hand · ${widget.cards.length} Karten',
            'Your hand · ${widget.cards.length} cards',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr(
            'Antippen zum Anheben · erneut tippen zum Ablegen',
            'Tap to lift · tap again to lower',
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 280,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = widget.cards.length;
              if (count == 0) return const SizedBox.shrink();
              final cardWidth = math.min(168.0, constraints.maxWidth * .44);
              final step = count == 1
                  ? 0.0
                  : math.min(
                      cardWidth * .72,
                      math.max(
                        0.0,
                        (constraints.maxWidth - cardWidth - 28) / (count - 1),
                      ),
                    );
              final left =
                  (constraints.maxWidth - cardWidth - step * (count - 1)) / 2;
              final order = List.generate(count, (index) => index);
              final selectedIndex = widget.cards.indexWhere(
                (card) => card.id == _selectedId,
              );
              if (selectedIndex >= 0) {
                order.remove(selectedIndex);
                order.add(selectedIndex);
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final index in order)
                    AnimatedPositioned(
                      key: ValueKey(widget.cards[index].id),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      left: left + step * index,
                      top: index == selectedIndex
                          ? 12
                          : 40 + (index - (count - 1) / 2).abs() * 9,
                      width: cardWidth,
                      height: 206,
                      child: AnimatedRotation(
                        duration: duration,
                        turns: index == selectedIndex
                            ? 0
                            : (index - (count - 1) / 2) * .018,
                        child: Semantics(
                          button: true,
                          selected: index == selectedIndex,
                          label: widget.cards[index].name,
                          child: Material(
                            elevation: index == selectedIndex ? 16 : 5,
                            color: AppPalette.surfaceRaised,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: _submitted
                                  ? null
                                  : () => setState(() {
                                      _selectedId = index == selectedIndex
                                          ? null
                                          : widget.cards[index].id;
                                    }),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: index == selectedIndex
                                        ? AppPalette.goldBright
                                        : AppPalette.gold.withValues(
                                            alpha: .45,
                                          ),
                                    width: index == selectedIndex ? 3 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: SizedBox.expand(
                                        child: PersonPortrait(
                                          person: widget.cards[index],
                                          width: cardWidth,
                                          height: 145,
                                          borderRadius: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.cards[index].name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (selected != null) ...[
          Text(selected.hint, textAlign: TextAlign.center),
          if (battleLegendaryAbilitiesByPersonId[selected.id]
              case final ability?)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(ability.name),
              leading: const Icon(
                Icons.auto_awesome_rounded,
                color: AppPalette.gold,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(ability.description),
                ),
              ],
            ),
          const SizedBox(height: 10),
        ],
        FilledButton.icon(
          onPressed: selected == null || _submitted
              ? null
              : () async {
                  setState(() => _submitted = true);
                  try {
                    await widget.onPlay(selected);
                  } finally {
                    if (mounted) setState(() => _submitted = false);
                  }
                },
          icon: const Icon(Icons.style_rounded),
          label: Text(
            selected == null
                ? context.tr('Wähle eine Karte', 'Select a card')
                : context.tr(
                    '${selected.name} spielen',
                    'Play ${selected.name}',
                  ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
