class BattleLegendaryAbility {
  final String personId;
  final String name;
  final String description;

  const BattleLegendaryAbility({
    required this.personId,
    required this.name,
    required this.description,
  });
}

const Map<String, BattleLegendaryAbility> battleLegendaryAbilitiesByPersonId = {
  'einstein': BattleLegendaryAbility(
    personId: 'einstein',
    name: 'Thought Experiment',
    description: 'Shows you the next 2 battle questions in advance.',
  ),
  'alexander_great': BattleLegendaryAbility(
    personId: 'alexander_great',
    name: 'Blitz Campaign',
    description: 'If Alexander wins in round 1, gain +1 bonus point.',
  ),
  'genghis_khan': BattleLegendaryAbility(
    personId: 'genghis_khan',
    name: 'Suppression',
    description: 'The opposing card effect is disabled for this round.',
  ),
  'newton': BattleLegendaryAbility(
    personId: 'newton',
    name: 'Law of Time',
    description: 'On year rounds, Newton counts as correct within +/-20 years.',
  ),
  'caesar': BattleLegendaryAbility(
    personId: 'caesar',
    name: 'Imperium',
    description:
        'If Caesar is played in the tiebreak, you win the tiebreak automatically.',
  ),
  'leonardo': BattleLegendaryAbility(
    personId: 'leonardo',
    name: 'Master of Many Fields',
    description: '+100 km tolerance on all map rounds in this battle.',
  ),
  'jordan': BattleLegendaryAbility(
    personId: 'jordan',
    name: 'Clutch Performer',
    description: 'If Jordan wins the last regular round, gain +1 bonus point.',
  ),
  'napoleon': BattleLegendaryAbility(
    personId: 'napoleon',
    name: 'Last Stand',
    description: 'If Napoleon would lose his round, it becomes a draw instead.',
  ),
  'mandela': BattleLegendaryAbility(
    personId: 'mandela',
    name: 'Comeback Spirit',
    description:
        'If Mandela wins in round 4, the round grants +2 instead of +1.',
  ),
  'mozart': BattleLegendaryAbility(
    personId: 'mozart',
    name: 'Perfect Harmony',
    description:
        'If your card lands within 10% of the correct value, it counts as perfectly correct and grants +1 bonus point.',
  ),
};

BattleLegendaryAbility? battleLegendaryAbilityForPersonId(String personId) {
  return battleLegendaryAbilitiesByPersonId[personId];
}

String battleTagForPersonId(String personId, String fallback) {
  return battleLegendaryAbilityForPersonId(personId)?.name ?? fallback;
}
