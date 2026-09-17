import '../models/question.dart';

class StoreCatalog {
  static const String noAdsProductId = 'untitled4_no_ads';
  static const String earlyBattleAccessProductId =
      'untitled4_early_battle_access';
  static const String nextQuestionUnlockProductId =
      'untitled4_question_unlock_next';
  static const String coinPackSmallProductId = 'untitled4_coin_pack_small';
  static const String coinPackMediumProductId = 'untitled4_coin_pack_medium';
  static const String politicsCapsuleProductId = 'untitled4_capsule_politics';
  static const String scienceCapsuleProductId = 'untitled4_capsule_science';
  static const String artCapsuleProductId = 'untitled4_capsule_art';
  static const String sportsCapsuleProductId = 'untitled4_capsule_sports';
  static const String chronicleCapsuleProductId = 'untitled4_capsule_chronicle';

  static const int coinPackSmallAmount = 120;
  static const int coinPackMediumAmount = 350;

  static const List<QuestionType> premiumQuestionUnlockOrder = [
    QuestionType.birthCentury,
    QuestionType.birthYear,
    QuestionType.earlierPerson,
    QuestionType.birthCountry,
    QuestionType.beforeAfterEvent,
    QuestionType.meetingCandidate,
    QuestionType.birthPlace,
    QuestionType.orderSequence,
    QuestionType.closestPair,
    QuestionType.scientistTheory,
    QuestionType.longestLife,
    QuestionType.birthplaceMap,
    QuestionType.artistWork,
    QuestionType.northernmostBirthplace,
    QuestionType.athleteAchievement,
    QuestionType.politicianRole,
    QuestionType.southernmostBirthplace,
    QuestionType.scientistFormula,
    QuestionType.artistQuote,
    QuestionType.sportStatline,
    QuestionType.politicianEventMatch,
    QuestionType.scientistDiscovery,
    QuestionType.workDescription,
    QuestionType.mapEventLocation,
    QuestionType.era,
    QuestionType.twoCluesOnePerson,
    QuestionType.multiClueExpert,
  ];

  static Set<String> get allProductIds => <String>{
    noAdsProductId,
    earlyBattleAccessProductId,
    nextQuestionUnlockProductId,
    politicsCapsuleProductId,
    scienceCapsuleProductId,
    artCapsuleProductId,
    sportsCapsuleProductId,
    chronicleCapsuleProductId,
  };

  static QuestionType? previousPremiumQuestionType(QuestionType type) {
    final ordered = premiumQuestionUnlockOrder;
    final index = ordered.indexOf(type);
    if (index <= 0) return null;
    return ordered[index - 1];
  }

  static int questionStepNumber(QuestionType type) {
    final ordered = premiumQuestionUnlockOrder;
    final index = ordered.indexOf(type);
    return index < 0 ? 0 : index + 1;
  }
}
