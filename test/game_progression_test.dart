import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:untitled4/logic/game_progression.dart';
import 'package:untitled4/models/question.dart';

void main() {
  test('xp requirements grow predictably by level', () {
    expect(GameProgression.xpRequirementForLevel(1), 25);
    expect(GameProgression.xpRequirementForLevel(2), 58);
    expect(GameProgression.xpRequirementForLevel(3), 66);
  });

  test('newly unlocked question types are derived from level boundaries', () {
    final unlocked = GameProgression.newlyUnlockedTypes(
      previousLevel: 9,
      currentLevel: 16,
    );

    expect(unlocked, contains(QuestionType.birthYear));
    expect(unlocked, isNot(contains(QuestionType.earlierPerson)));
    expect(unlocked, isNot(contains(QuestionType.birthCountry)));
  });

  test('birth year choices contain the correct year and four options', () {
    final options = GameProgression.generateBirthYearChoices(1769, Random(1));

    expect(options, hasLength(4));
    expect(options, contains(1769));
    expect(options.toSet(), hasLength(4));
  });
}
