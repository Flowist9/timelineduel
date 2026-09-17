import 'person.dart';

enum QuestionType {
  overlap,
  birthYear,
  birthCentury,
  earlierPerson,
  era,
  meetingCandidate,
  orderSequence,
  beforeAfterEvent,
  closestPair,
  longestLife,
  birthCountry,
  birthPlace,
  birthplaceMap,
  mapEventLocation,
  northernmostBirthplace,
  southernmostBirthplace,
  scientistTheory,
  scientistFormula,
  scientistDiscovery,
  artistWork,
  artistQuote,
  workDescription,
  athleteAchievement,
  sportStatline,
  politicianRole,
  politicianEventMatch,
  twoCluesOnePerson,
  multiClueExpert,
}

class QuestionTypeDetails {
  final String title;
  final String description;
  final int minUnlockedPeople;

  const QuestionTypeDetails({
    required this.title,
    required this.description,
    this.minUnlockedPeople = 2,
  });
}

const Map<QuestionType, QuestionTypeDetails> questionTypeDetails = {
  QuestionType.overlap: QuestionTypeDetails(
    title: 'Lived at the same time?',
    description: 'Decide whether two people were alive at the same time.',
  ),
  QuestionType.birthYear: QuestionTypeDetails(
    title: 'Birth year',
    description:
        'Choose the correct birth year of a person from multiple options.',
  ),
  QuestionType.birthCentury: QuestionTypeDetails(
    title: 'Closest birthplace',
    description: 'Choose which person was born closest to the target person.',
    minUnlockedPeople: 4,
  ),
  QuestionType.earlierPerson: QuestionTypeDetails(
    title: 'Who came earlier?',
    description: 'Decide which of two people was born earlier.',
  ),
  QuestionType.era: QuestionTypeDetails(
    title: 'Who fits this era best?',
    description: 'Use broader historical context to pick the best era match.',
  ),
  QuestionType.birthCountry: QuestionTypeDetails(
    title: 'Birth country',
    description: 'Choose the country where a person was born.',
  ),
  QuestionType.birthPlace: QuestionTypeDetails(
    title: 'Birth city',
    description: 'Choose the correct birthplace label of a person.',
  ),
  QuestionType.birthplaceMap: QuestionTypeDetails(
    title: 'Birthplace map',
    description: 'Tap the approximate birthplace on a borders-only world map.',
  ),
  QuestionType.mapEventLocation: QuestionTypeDetails(
    title: 'Map event location',
    description: 'Tap the approximate location of a major historical event.',
  ),
  QuestionType.beforeAfterEvent: QuestionTypeDetails(
    title: 'Before or after an event',
    description: "Compare a person's birth year with a historical event.",
  ),
  QuestionType.meetingCandidate: QuestionTypeDetails(
    title: 'Possible meeting',
    description:
        'Figure out which person could realistically have met the subject in time.',
    minUnlockedPeople: 3,
  ),
  QuestionType.orderSequence: QuestionTypeDetails(
    title: 'Chronological order',
    description:
        'Choose the correct order of several people from earliest to latest.',
    minUnlockedPeople: 3,
  ),
  QuestionType.closestPair: QuestionTypeDetails(
    title: 'Closest in time',
    description: 'Find the pair whose birth years are closest together.',
    minUnlockedPeople: 3,
  ),
  QuestionType.longestLife: QuestionTypeDetails(
    title: 'Longest lifespan',
    description: 'Determine which person out of several lived the longest.',
    minUnlockedPeople: 3,
  ),
  QuestionType.northernmostBirthplace: QuestionTypeDetails(
    title: 'Farthest north',
    description: 'Pick the person whose birthplace lies farthest north.',
    minUnlockedPeople: 3,
  ),
  QuestionType.southernmostBirthplace: QuestionTypeDetails(
    title: 'Farthest south',
    description: 'Pick the person whose birthplace lies farthest south.',
    minUnlockedPeople: 3,
  ),
  QuestionType.scientistTheory: QuestionTypeDetails(
    title: 'Whose theory is this?',
    description: 'Match a formula, theory, or law to the right scientist.',
    minUnlockedPeople: 4,
  ),
  QuestionType.scientistFormula: QuestionTypeDetails(
    title: 'Whose formula is this?',
    description: 'Match an iconic formula or law clue to the right scientist.',
    minUnlockedPeople: 4,
  ),
  QuestionType.scientistDiscovery: QuestionTypeDetails(
    title: 'Whose discovery is this?',
    description:
        'Identify the scientist behind a discovery or breakthrough clue.',
    minUnlockedPeople: 4,
  ),
  QuestionType.artistWork: QuestionTypeDetails(
    title: 'Who made this work?',
    description: 'Match a famous work to the right artist or author.',
    minUnlockedPeople: 4,
  ),
  QuestionType.artistQuote: QuestionTypeDetails(
    title: 'Whose text clue is this?',
    description:
        'Use a text-style clue to identify the right artist or author.',
    minUnlockedPeople: 4,
  ),
  QuestionType.workDescription: QuestionTypeDetails(
    title: 'Work by description',
    description: 'Recognize a famous work from a stronger descriptive clue.',
    minUnlockedPeople: 4,
  ),
  QuestionType.athleteAchievement: QuestionTypeDetails(
    title: 'Whose achievement?',
    description: 'Match a major career achievement to the right athlete.',
    minUnlockedPeople: 4,
  ),
  QuestionType.sportStatline: QuestionTypeDetails(
    title: 'Whose statline is this?',
    description:
        'Use a record or stat-style clue to identify the right athlete.',
    minUnlockedPeople: 4,
  ),
  QuestionType.politicianRole: QuestionTypeDetails(
    title: 'Which leader fits?',
    description:
        'Match a historic role or leadership clue to the right politician.',
    minUnlockedPeople: 4,
  ),
  QuestionType.politicianEventMatch: QuestionTypeDetails(
    title: 'Which leader fits this event?',
    description:
        'Match a major event or turning-point clue to the right leader.',
    minUnlockedPeople: 4,
  ),
  QuestionType.twoCluesOnePerson: QuestionTypeDetails(
    title: 'Two clues, one person',
    description: 'Combine two clues to identify the correct person.',
    minUnlockedPeople: 4,
  ),
  QuestionType.multiClueExpert: QuestionTypeDetails(
    title: 'Multi-clue expert',
    description:
        'Solve an expert question that layers multiple clues together.',
    minUnlockedPeople: 4,
  ),
};

extension QuestionTypeX on QuestionType {
  QuestionTypeDetails get details => questionTypeDetails[this]!;

  String get title => details.title;

  String get description => details.description;

  int get minUnlockedPeople => details.minUnlockedPeople;

  bool hasEnoughUnlockedPeople(int unlockedPeople) {
    return unlockedPeople >= minUnlockedPeople;
  }
}

class Question {
  final QuestionType type;
  final String prompt;
  final List<String> options;
  final String correctOption;
  final Person? a;
  final Person? b;
  final Person? subject;
  final List<Person> figures;
  final String? supportingLabel;
  final int? supportingYear;
  final double? supportingLat;
  final double? supportingLng;

  const Question({
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctOption,
    this.a,
    this.b,
    this.subject,
    this.figures = const [],
    this.supportingLabel,
    this.supportingYear,
    this.supportingLat,
    this.supportingLng,
  });

  bool isCorrect(String selectedOption) => selectedOption == correctOption;

  /// The solution shown after an answer, including a precise map target.
  String get correctAnswerLabel {
    if (type == QuestionType.birthplaceMap ||
        type == QuestionType.mapEventLocation) {
      final place = type == QuestionType.birthplaceMap
          ? <String>{
              if (subject?.birthPlaceLabel?.isNotEmpty == true)
                subject!.birthPlaceLabel!,
              if (subject?.birthCountry.isNotEmpty == true)
                subject!.birthCountry,
            }.join(', ')
          : supportingLabel ?? correctOption;
      final lat = supportingLat ?? subject?.birthLat;
      final lng = supportingLng ?? subject?.birthLng;
      final coordinates = lat == null || lng == null
          ? ''
          : '\n${lat.abs().toStringAsFixed(2)}° ${lat < 0 ? 'S' : 'N'}, ${lng.abs().toStringAsFixed(2)}° ${lng < 0 ? 'W' : 'E'}';
      return '${place.isEmpty ? correctOption : place}$coordinates';
    }
    return correctOption.replaceAll(' -> ', ' → ');
  }
}
