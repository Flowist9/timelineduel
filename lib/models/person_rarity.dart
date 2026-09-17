enum PersonRarity {
  common,
  rare,
  epic,
  legendary;

  String get label => switch (this) {
    PersonRarity.common => 'Common',
    PersonRarity.rare => 'Rare',
    PersonRarity.epic => 'Epic',
    PersonRarity.legendary => 'Legendary',
  };

  int get weight => switch (this) {
    PersonRarity.common => 60,
    PersonRarity.rare => 28,
    PersonRarity.epic => 9,
    PersonRarity.legendary => 3,
  };
}
