import '../models/late_game_fact.dart';

// Prepared for future late-game image questions. Not wired into gameplay yet.
final Map<String, List<PersonImageClue>> imageClues = {
  'ali': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/ali.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/ali.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'austen': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/austen.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/austen.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'beethoven': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/beethoven.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/beethoven.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'biles': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/biles.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/biles.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'bolt': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/bolt.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/bolt.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'caesar': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/caesar.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/caesar.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'churchill': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/churchill.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/churchill.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'cleopatra': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/cleopatra.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/cleopatra.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'comaneci': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/comaneci.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/comaneci.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'curie': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/curie.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/curie.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'darwin': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/darwin.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/darwin.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'einstein': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/einstein.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/einstein.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'federer': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/federer.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/federer.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'franklin': const [
    PersonImageClue(
      assetPath: 'assets/persons/vs/franklin.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'galileo': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/galileo.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/galileo.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'gandhi': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/gandhi.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/gandhi.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'hawking': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/hawking.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/hawking.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'hemingway': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/hemingway.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/hemingway.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'jordan': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/jordan.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/jordan.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'kahlo': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/kahlo.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/kahlo.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'katherine_johnson': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/katherine_johnson.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/katherine_johnson.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'leonardo': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/leonardo.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/leonardo.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'lincoln': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/lincoln.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/lincoln.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'lovelace': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/lovelace.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/lovelace.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'mandela': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/mandela.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/mandela.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'merkel': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/merkel.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/merkel.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'messi': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/messi.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/messi.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'michelangelo': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/michelangelo.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/michelangelo.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'mozart': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/mozart.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/mozart.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'napoleon': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/napoleon.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/napoleon.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'newton': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/newton.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/newton.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'obama': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/obama.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/obama.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'owens': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/owens.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/owens.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'pele': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/pele.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/pele.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'picasso': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/picasso.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/picasso.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'rembrandt': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/rembrandt.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/rembrandt.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'ronaldo': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/ronaldo.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/ronaldo.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'roosevelt': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/roosevelt.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/roosevelt.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'serena': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/serena.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/serena.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'shakespeare': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/shakespeare.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/shakespeare.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'tesla': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/tesla.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/tesla.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'turing': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/turing.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/turing.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
  'vangogh': const [
    PersonImageClue(
      assetPath: 'assets/persons/portrait/vangogh.jpg',
      description: 'Portrait clue usable in recognition rounds.',
    ),
    PersonImageClue(
      assetPath: 'assets/persons/vs/vangogh.jpg',
      description: 'Full card clue usable in harder image rounds.',
    ),
  ],
};
