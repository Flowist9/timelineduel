import 'dart:math';

import 'progression_catalog.dart';
import '../models/question.dart';

class GameProgression {
  static const int baseXpRequirement = 25;
  static const int xpLinearIncreasePerLevel = 4;
  static const int xpCurveDivisor = 90;
  static const int xpRequirementMultiplier = 2;
  static const int maxBirthYearChoice = 2026;

  static int xpRequirementForLevel(int targetLevel) {
    if (targetLevel <= 1) {
      return baseXpRequirement;
    }

    final levelIndex = targetLevel - 1;
    final rawRequirement =
        baseXpRequirement +
        (levelIndex * xpLinearIncreasePerLevel) +
        ((levelIndex * (levelIndex - 1)) ~/ xpCurveDivisor);

    return max(baseXpRequirement, rawRequirement * xpRequirementMultiplier);
  }

  static List<QuestionType> newlyUnlockedTypes({
    required int previousLevel,
    required int currentLevel,
  }) {
    return ProgressionCatalog.implementedQuestionTypesUnlockedBetween(
      previousLevel,
      currentLevel,
    );
  }

  static int? questionUnlockLevel(QuestionType type) {
    return ProgressionCatalog.questionUnlockLevel(type);
  }

  static bool isQuestionTypeUnlocked({
    required QuestionType type,
    required int level,
    required int unlockedPeople,
  }) {
    return ProgressionCatalog.isQuestionUnlocked(type, level) &&
        type.hasEnoughUnlockedPeople(unlockedPeople);
  }

  static List<int> generateBirthYearChoices(
    int correctYear,
    Random random, {
    int maxYear = maxBirthYearChoice,
    int optionCount = 4,
  }) {
    final values = <int>{correctYear};

    final candidateOffsets = <int>[-5, -4, -3, -2, -1, 1, 2, 3, 4, 5]
      ..shuffle(random);

    for (final offset in candidateOffsets) {
      if (values.length >= optionCount) break;

      final candidate = correctYear + offset;
      if (candidate == 0 || candidate > maxYear) continue;
      values.add(candidate);
    }

    var fallbackOffset = 6;
    while (values.length < optionCount) {
      for (final sign in [-1, 1]) {
        if (values.length >= optionCount) break;
        final candidate = correctYear + (fallbackOffset * sign);
        if (candidate == 0 || candidate > maxYear) continue;
        values.add(candidate);
      }
      fallbackOffset += 1;
    }

    return values.toList()..shuffle(random);
  }
}
