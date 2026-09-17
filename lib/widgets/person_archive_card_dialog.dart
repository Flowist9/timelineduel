import 'package:flutter/material.dart';

import '../battle/legendary_abilities.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../models/person_rarity.dart';
import '../models/person_status.dart';
import 'person_portrait.dart';

Future<void> showPersonArchiveCardDialog({
  required BuildContext context,
  required Person person,
  required PersonStatus status,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        PersonArchiveCardDialog(person: person, status: status),
  );
}

class PersonArchiveCardDialog extends StatefulWidget {
  final Person person;
  final PersonStatus status;

  const PersonArchiveCardDialog({
    super.key,
    required this.person,
    required this.status,
  });

  @override
  State<PersonArchiveCardDialog> createState() =>
      _PersonArchiveCardDialogState();
}

class _PersonArchiveCardDialogState extends State<PersonArchiveCardDialog> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final raritySpec = _raritySpec(person.rarity);
    final isHidden = widget.status == PersonStatus.undiscovered;
    final isDiscovered = widget.status == PersonStatus.discovered;
    final displayName = isHidden ? 'Unknown Figure' : person.name;
    final timeLabel = person.birthYear < 0
        ? '${person.birthYear.abs()} BC'
        : '${person.birthYear}';
    final lifeLabel = isHidden
        ? '???'
        : person.deathYear == null
        ? timeLabel
        : '$timeLabel - ${person.deathYear}';
    final placeLabel = isHidden
        ? '???'
        : person.birthPlaceLabel == null
        ? person.birthCountry
        : '${person.birthPlaceLabel}, ${person.birthCountry}';
    final countryLabel = isHidden ? '???' : person.birthCountry;
    final categoryLabel = isHidden ? '???' : _categoryLabel(person.category);
    final rarityLabel = isHidden ? 'Unknown' : person.rarity.label;
    final knownForText = isHidden
        ? 'Still hidden in your archive.'
        : person.hint;
    final battleAbility = isHidden
        ? null
        : battleLegendaryAbilityForPersonId(person.id);
    final helperText = _showBack
        ? 'Tap again to return to the VS card'
        : isHidden
        ? 'Tap the silhouette to inspect the sealed archive card'
        : isDiscovered
        ? 'Tap the card to flip it and inspect the figure'
        : 'Tap the card to flip it and view the full archive profile';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: GestureDetector(
        onTap: () => setState(() => _showBack = !_showBack),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isHidden
                  ? [const Color(0xFF18100B), const Color(0xFF0E0906)]
                  : raritySpec.dialogColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHidden ? Colors.black : raritySpec.glowColor)
                    .withValues(alpha: 0.24),
                blurRadius: raritySpec.glowBlur + 6,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: isHidden
                  ? Colors.white.withValues(alpha: 0.08)
                  : raritySpec.borderColor.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  transitionBuilder: (child, animation) {
                    final rotate = Tween<double>(
                      begin: 0.04,
                      end: 0,
                    ).animate(animation);
                    return AnimatedBuilder(
                      animation: rotate,
                      child: child,
                      builder: (context, child) {
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateY(rotate.value),
                          child: child,
                        );
                      },
                    );
                  },
                  child: _showBack
                      ? _ArchiveBackCard(
                          key: const ValueKey('back'),
                          person: person,
                          isHidden: isHidden,
                          displayName: displayName,
                          categoryLabel: categoryLabel,
                          rarityColor: raritySpec.borderColor,
                          rarityLabel: rarityLabel,
                          lifeLabel: lifeLabel,
                          placeLabel: placeLabel,
                          countryLabel: countryLabel,
                          knownForText: knownForText,
                          battleAbility: battleAbility,
                        )
                      : _ArchiveFrontCard(
                          key: const ValueKey('front'),
                          person: person,
                          isHidden: isHidden,
                          displayName: displayName,
                          categoryLabel: categoryLabel,
                          rarityColor: raritySpec.borderColor,
                          lifeLabel: lifeLabel,
                          rarityLabel: rarityLabel,
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  helperText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _categoryLabel(Category category) => switch (category) {
    Category.politician => 'Politics',
    Category.scientist => 'Science',
    Category.artist => 'Art',
    Category.athlete => 'Sport',
  };
}

class _ArchiveFrontCard extends StatelessWidget {
  final Person person;
  final bool isHidden;
  final String displayName;
  final String categoryLabel;
  final Color rarityColor;
  final String lifeLabel;
  final String rarityLabel;

  const _ArchiveFrontCard({
    super.key,
    required this.person,
    required this.isHidden,
    required this.displayName,
    required this.categoryLabel,
    required this.rarityColor,
    required this.lifeLabel,
    required this.rarityLabel,
  });

  @override
  Widget build(BuildContext context) {
    final raritySpec = _raritySpec(person.rarity);
    return Container(
      height: 520,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isHidden
              ? [const Color(0xFF21150E), const Color(0xFF17100B)]
              : raritySpec.cardFaceColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: (isHidden ? const Color(0xFFE6D6BF) : raritySpec.borderColor)
              .withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: (isHidden ? Colors.black : raritySpec.glowColor).withValues(
              alpha: 0.18,
            ),
            blurRadius: raritySpec.glowBlur,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PersonPortrait(
                      person: person,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 26,
                      variant: PersonImageVariant.vs,
                      obscured: isHidden,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: isHidden
                              ? [
                                  Colors.black.withValues(alpha: 0.42),
                                  Colors.black.withValues(alpha: 0.28),
                                ]
                              : [
                                  raritySpec.glowColor.withValues(alpha: 0.20),
                                  Colors.black.withValues(alpha: 0.34),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: isHidden
                              ? Colors.white.withValues(alpha: 0.08)
                              : raritySpec.borderColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Color(0xFFF8F0E3),
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: rarityColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$categoryLabel | $lifeLabel',
                                  style: const TextStyle(
                                    color: Color(0xFFF7ECDD),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  label: rarityLabel,
                  color: isHidden ? const Color(0xFFE6D6BF) : rarityColor,
                ),
                _MetaChip(
                  label: categoryLabel,
                  color: isHidden
                      ? const Color(0xFFE6D6BF)
                      : const Color(0xFFD4B06A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveBackCard extends StatelessWidget {
  final Person person;
  final bool isHidden;
  final String displayName;
  final String categoryLabel;
  final Color rarityColor;
  final String rarityLabel;
  final String lifeLabel;
  final String placeLabel;
  final String countryLabel;
  final String knownForText;
  final BattleLegendaryAbility? battleAbility;

  const _ArchiveBackCard({
    super.key,
    required this.person,
    required this.isHidden,
    required this.displayName,
    required this.categoryLabel,
    required this.rarityColor,
    required this.rarityLabel,
    required this.lifeLabel,
    required this.placeLabel,
    required this.countryLabel,
    required this.knownForText,
    required this.battleAbility,
  });

  @override
  Widget build(BuildContext context) {
    final raritySpec = _raritySpec(person.rarity);
    return Container(
      height: 520,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isHidden
              ? [const Color(0xFF1A120D), const Color(0xFF110B08)]
              : raritySpec.cardBackColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: (isHidden ? const Color(0xFFE6D6BF) : raritySpec.borderColor)
              .withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: (isHidden ? Colors.black : raritySpec.glowColor).withValues(
              alpha: 0.16,
            ),
            blurRadius: raritySpec.glowBlur,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Color(0xFFF8F0E3),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _MetaChip(
                                label: rarityLabel,
                                color: isHidden
                                    ? const Color(0xFFE6D6BF)
                                    : rarityColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 64,
                          height: 84,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: isHidden
                                  ? [
                                      Colors.white.withValues(alpha: 0.04),
                                      Colors.white.withValues(alpha: 0.02),
                                    ]
                                  : [
                                      raritySpec.glowColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      Colors.white.withValues(alpha: 0.03),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isHidden
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : raritySpec.borderColor.withValues(
                                      alpha: 0.22,
                                    ),
                            ),
                          ),
                          child: PersonPortrait(
                            person: person,
                            width: 56,
                            height: 76,
                            borderRadius: 14,
                            obscured: isHidden,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Category', value: categoryLabel),
                    _InfoRow(label: 'Years', value: lifeLabel),
                    _InfoRow(label: 'Birthplace', value: placeLabel),
                    _InfoRow(label: 'Country', value: countryLabel),
                    const SizedBox(height: 14),
                    const Text(
                      'Known for',
                      style: TextStyle(
                        color: Color(0xFFD4B06A),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        knownForText,
                        style: TextStyle(
                          color: const Color(
                            0xFFD8CBB8,
                          ).withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (battleAbility != null) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Battle ability',
                        style: TextStyle(
                          color: Color(0xFFD4B06A),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: rarityColor.withValues(alpha: 0.10),
                          border: Border.all(
                            color: rarityColor.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              battleAbility!.name,
                              style: TextStyle(
                                color: rarityColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              battleAbility!.description,
                              style: TextStyle(
                                color: const Color(
                                  0xFFD8CBB8,
                                ).withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Tap to flip back',
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.76),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD4B06A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFF7ECDD),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_RarityCardSpec _raritySpec(PersonRarity rarity) {
  switch (rarity) {
    case PersonRarity.common:
      return const _RarityCardSpec(
        dialogColors: [Color(0xFF1B130E), Color(0xFF0F0A07)],
        cardFaceColors: [Color(0xFF2A1A11), Color(0xFF18100B)],
        cardBackColors: [Color(0xFF1C140F), Color(0xFF120C09)],
        borderColor: Color(0xFFB6A58C),
        glowColor: Color(0xFF7D6950),
        glowBlur: 20,
      );
    case PersonRarity.rare:
      return const _RarityCardSpec(
        dialogColors: [Color(0xFF131D27), Color(0xFF0B0A08)],
        cardFaceColors: [Color(0xFF1A2F42), Color(0xFF12100B)],
        cardBackColors: [Color(0xFF142430), Color(0xFF100C09)],
        borderColor: Color(0xFF6BB2E4),
        glowColor: Color(0xFF3D82B8),
        glowBlur: 24,
      );
    case PersonRarity.epic:
      return const _RarityCardSpec(
        dialogColors: [Color(0xFF201226), Color(0xFF0D090E)],
        cardFaceColors: [Color(0xFF37184A), Color(0xFF150D18)],
        cardBackColors: [Color(0xFF271536), Color(0xFF110B12)],
        borderColor: Color(0xFFD17FE7),
        glowColor: Color(0xFF9146AE),
        glowBlur: 28,
      );
    case PersonRarity.legendary:
      return const _RarityCardSpec(
        dialogColors: [Color(0xFF2A1B10), Color(0xFF0F0906)],
        cardFaceColors: [Color(0xFF503214), Color(0xFF1B120B)],
        cardBackColors: [Color(0xFF3A2511), Color(0xFF130C07)],
        borderColor: Color(0xFFFFC55E),
        glowColor: Color(0xFFE09A2A),
        glowBlur: 32,
      );
  }
}

class _RarityCardSpec {
  final List<Color> dialogColors;
  final List<Color> cardFaceColors;
  final List<Color> cardBackColors;
  final Color borderColor;
  final Color glowColor;
  final double glowBlur;

  const _RarityCardSpec({
    required this.dialogColors,
    required this.cardFaceColors,
    required this.cardBackColors,
    required this.borderColor,
    required this.glowColor,
    required this.glowBlur,
  });
}
