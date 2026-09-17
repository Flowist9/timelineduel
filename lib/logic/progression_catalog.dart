import '../models/question.dart';

enum AppFeature { battle, collection, map }

enum ProgressionMilestoneKind { question, feature, capsule }

class ProgressionMilestone {
  final int level;
  final ProgressionMilestoneKind kind;
  final String title;
  final String description;
  final QuestionType? questionType;
  final AppFeature? feature;
  final int rewardDrops;

  const ProgressionMilestone.question({
    required this.level,
    required this.title,
    required this.description,
    this.questionType,
  }) : kind = ProgressionMilestoneKind.question,
       feature = null,
       rewardDrops = 0;

  const ProgressionMilestone.feature({
    required this.level,
    required this.title,
    required this.description,
    required this.feature,
  }) : kind = ProgressionMilestoneKind.feature,
       questionType = null,
       rewardDrops = 0;

  const ProgressionMilestone.capsule({
    required this.level,
    required this.title,
    required this.description,
    this.rewardDrops = 3,
  }) : kind = ProgressionMilestoneKind.capsule,
       questionType = null,
       feature = null;
}

class ProgressionCatalog {
  static const int maxLevel = 200;

  static const List<ProgressionMilestone> milestones = [
    ProgressionMilestone.question(
      level: 5,
      title: 'Closest birthplace',
      description: 'Choose which person was born closest to the target person.',
      questionType: QuestionType.birthCentury,
    ),
    ProgressionMilestone.feature(
      level: 10,
      title: 'Battle unlocked',
      description:
          'Battle mode opens and turns your collection into tactical duels.',
      feature: AppFeature.battle,
    ),
    ProgressionMilestone.question(
      level: 15,
      title: 'Birth year',
      description:
          'Choose the correct birth year of a person from multiple options.',
      questionType: QuestionType.birthYear,
    ),
    ProgressionMilestone.feature(
      level: 20,
      title: 'Collection unlocked',
      description:
          'Your collection opens so you can inspect every unlocked figure.',
      feature: AppFeature.collection,
    ),
    ProgressionMilestone.question(
      level: 25,
      title: 'Who came earlier?',
      description: 'Decide which of two people was born earlier.',
      questionType: QuestionType.earlierPerson,
    ),
    ProgressionMilestone.feature(
      level: 30,
      title: 'Map unlocked',
      description:
          'The world map opens and lets you explore people by place and era.',
      feature: AppFeature.map,
    ),
    ProgressionMilestone.question(
      level: 35,
      title: 'Birth country',
      description: 'Find the country where a person was born.',
      questionType: QuestionType.birthCountry,
    ),
    ProgressionMilestone.question(
      level: 40,
      title: 'Before or after an event',
      description: "Compare a person's birth year with a historical event.",
      questionType: QuestionType.beforeAfterEvent,
    ),
    ProgressionMilestone.question(
      level: 45,
      title: 'Possible meeting',
      description: 'Figure out who could realistically have met the subject.',
      questionType: QuestionType.meetingCandidate,
    ),
    ProgressionMilestone.question(
      level: 50,
      title: 'Birth city',
      description: 'Choose the correct birthplace label of a person.',
      questionType: QuestionType.birthPlace,
    ),
    ProgressionMilestone.question(
      level: 55,
      title: 'Chronological order',
      description: 'Choose the correct order from earliest to latest.',
      questionType: QuestionType.orderSequence,
    ),
    ProgressionMilestone.capsule(
      level: 60,
      title: 'Rare capsule',
      description:
          'Open a milestone capsule with 3 guaranteed collection drops.',
    ),
    ProgressionMilestone.question(
      level: 65,
      title: 'Closest in time',
      description: 'Find the pair whose birth years are closest together.',
      questionType: QuestionType.closestPair,
    ),
    ProgressionMilestone.question(
      level: 70,
      title: 'Scientist theory',
      description: 'Match a formula, theory, or law to the right scientist.',
      questionType: QuestionType.scientistTheory,
    ),
    ProgressionMilestone.question(
      level: 75,
      title: 'Longest lifespan',
      description: 'Determine which person lived the longest.',
      questionType: QuestionType.longestLife,
    ),
    ProgressionMilestone.capsule(
      level: 80,
      title: 'Epic capsule',
      description:
          'Open a milestone capsule with 3 guaranteed collection drops.',
    ),
    ProgressionMilestone.question(
      level: 85,
      title: 'Birthplace map',
      description: 'Tap the approximate birthplace on a world map.',
      questionType: QuestionType.birthplaceMap,
    ),
    ProgressionMilestone.question(
      level: 90,
      title: 'Artist work',
      description: 'Match a famous work to the right artist or author.',
      questionType: QuestionType.artistWork,
    ),
    ProgressionMilestone.question(
      level: 95,
      title: 'Farthest north',
      description: 'Pick the person whose birthplace lies farthest north.',
      questionType: QuestionType.northernmostBirthplace,
    ),
    ProgressionMilestone.question(
      level: 100,
      title: 'Athlete achievement',
      description: 'Match a major career achievement to the right athlete.',
      questionType: QuestionType.athleteAchievement,
    ),
    ProgressionMilestone.question(
      level: 105,
      title: 'Politician role',
      description:
          'Match a historic role or leadership clue to the right politician.',
      questionType: QuestionType.politicianRole,
    ),
    ProgressionMilestone.capsule(
      level: 110,
      title: 'Leader capsule',
      description:
          'Open a milestone capsule with 3 guaranteed collection drops.',
    ),
    ProgressionMilestone.question(
      level: 115,
      title: 'Southernmost birthplace',
      description: 'Decide whose birthplace lies farther south.',
      questionType: QuestionType.southernmostBirthplace,
    ),
    ProgressionMilestone.question(
      level: 120,
      title: 'Scientist formula',
      description: 'Match an iconic formula to the right scientist.',
      questionType: QuestionType.scientistFormula,
    ),
    ProgressionMilestone.question(
      level: 125,
      title: 'Artist quote / text clue',
      description: 'Identify the right artist or author from a textual clue.',
      questionType: QuestionType.artistQuote,
    ),
    ProgressionMilestone.capsule(
      level: 130,
      title: 'Historical event capsule',
      description:
          'Open a milestone capsule with 3 guaranteed collection drops.',
    ),
    ProgressionMilestone.question(
      level: 135,
      title: 'Sport statline',
      description: 'Match a statline or record to the right athlete.',
      questionType: QuestionType.sportStatline,
    ),
    ProgressionMilestone.question(
      level: 140,
      title: 'Politician event match',
      description: 'Match a major event or turning point to the right leader.',
      questionType: QuestionType.politicianEventMatch,
    ),
    ProgressionMilestone.question(
      level: 145,
      title: 'Scientist invention / discovery',
      description: 'Identify the scientist behind a discovery or invention.',
      questionType: QuestionType.scientistDiscovery,
    ),
    ProgressionMilestone.capsule(
      level: 150,
      title: 'Legend capsule',
      description:
          'Open a milestone capsule with 3 guaranteed collection drops.',
    ),
    ProgressionMilestone.question(
      level: 155,
      title: 'Work by description',
      description: 'Recognize a famous work from a stronger descriptive clue.',
      questionType: QuestionType.workDescription,
    ),
    ProgressionMilestone.capsule(
      level: 160,
      title: 'Women in history capsule',
      description:
          'Open a milestone capsule with 3 guaranteed collection drops.',
    ),
    ProgressionMilestone.question(
      level: 165,
      title: 'Map event location',
      description: 'Place a major historical event on the map.',
      questionType: QuestionType.mapEventLocation,
    ),
    ProgressionMilestone.capsule(
      level: 170,
      title: 'Ancient world capsule',
      description:
          'Open a milestone capsule with 3 guaranteed collection drops.',
    ),
    ProgressionMilestone.question(
      level: 175,
      title: 'Who fits this era best?',
      description:
          'Use broader historical context to choose the best fit for an era.',
      questionType: QuestionType.era,
    ),
    ProgressionMilestone.capsule(
      level: 180,
      title: 'Global icons capsule',
      description:
          'Open a milestone capsule with 3 guaranteed collection drops.',
    ),
    ProgressionMilestone.question(
      level: 185,
      title: 'Two clues, one person',
      description: 'Combine two clues to identify the correct person.',
      questionType: QuestionType.twoCluesOnePerson,
    ),
    ProgressionMilestone.capsule(
      level: 190,
      title: 'Master capsule',
      description:
          'Open a milestone capsule with 3 guaranteed collection drops.',
    ),
    ProgressionMilestone.question(
      level: 195,
      title: 'Multi-clue expert question',
      description:
          'Solve an expert question that layers multiple clues together.',
      questionType: QuestionType.multiClueExpert,
    ),
    ProgressionMilestone.capsule(
      level: 200,
      title: 'Champion capsule',
      description:
          'Open the endgame capsule with 3 guaranteed collection drops.',
    ),
  ];

  static const Map<QuestionType, int> _questionUnlockLevels = {
    QuestionType.birthCentury: 5,
    QuestionType.birthYear: 15,
    QuestionType.earlierPerson: 25,
    QuestionType.birthCountry: 35,
    QuestionType.beforeAfterEvent: 40,
    QuestionType.meetingCandidate: 45,
    QuestionType.birthPlace: 50,
    QuestionType.orderSequence: 55,
    QuestionType.closestPair: 65,
    QuestionType.scientistTheory: 70,
    QuestionType.longestLife: 75,
    QuestionType.birthplaceMap: 85,
    QuestionType.artistWork: 90,
    QuestionType.northernmostBirthplace: 95,
    QuestionType.athleteAchievement: 100,
    QuestionType.politicianRole: 105,
    QuestionType.southernmostBirthplace: 115,
    QuestionType.scientistFormula: 120,
    QuestionType.artistQuote: 125,
    QuestionType.sportStatline: 135,
    QuestionType.politicianEventMatch: 140,
    QuestionType.scientistDiscovery: 145,
    QuestionType.workDescription: 155,
    QuestionType.mapEventLocation: 165,
    QuestionType.era: 175,
    QuestionType.twoCluesOnePerson: 185,
    QuestionType.multiClueExpert: 195,
  };

  static int? questionUnlockLevel(QuestionType type) =>
      _questionUnlockLevels[type];

  static bool isQuestionUnlocked(QuestionType type, int level) {
    final unlockLevel = questionUnlockLevel(type);
    if (unlockLevel == null) {
      return type == QuestionType.overlap;
    }
    return level >= unlockLevel;
  }

  static int? featureUnlockLevel(AppFeature feature) {
    for (final milestone in milestones) {
      if (milestone.feature == feature) {
        return milestone.level;
      }
    }
    return null;
  }

  static bool isFeatureUnlocked(AppFeature feature, int level) {
    final unlockLevel = featureUnlockLevel(feature);
    return unlockLevel != null && level >= unlockLevel;
  }

  static int levelsUntilFeature(AppFeature feature, int level) {
    final unlockLevel = featureUnlockLevel(feature);
    if (unlockLevel == null) return 0;
    return level >= unlockLevel ? 0 : unlockLevel - level;
  }

  static List<ProgressionMilestone> milestonesBetween(
    int previousLevel,
    int currentLevel,
  ) {
    return milestones
        .where(
          (milestone) =>
              previousLevel < milestone.level &&
              currentLevel >= milestone.level,
        )
        .toList(growable: false);
  }

  static List<QuestionType> implementedQuestionTypesUnlockedBetween(
    int previousLevel,
    int currentLevel,
  ) {
    return milestonesBetween(previousLevel, currentLevel)
        .where((milestone) => milestone.questionType != null)
        .map((milestone) => milestone.questionType!)
        .toList(growable: false);
  }
}
