import 'package:flutter_test/flutter_test.dart';
import 'package:untitled4/logic/game_progression.dart';
import 'package:untitled4/models/question.dart';

void main() {
  test('question type metadata stays centralized and consistent', () {
    expect(QuestionType.birthYear.title, 'Birth year');
    expect(GameProgression.questionUnlockLevel(QuestionType.birthYear), 15);
    expect(GameProgression.questionUnlockLevel(QuestionType.overlap), isNull);
    expect(QuestionType.longestLife.minUnlockedPeople, 3);
  });

  test('question types are only available when requirements are met', () {
    expect(
      GameProgression.isQuestionTypeUnlocked(
        type: QuestionType.overlap,
        level: 1,
        unlockedPeople: 2,
      ),
      isTrue,
    );
    expect(
      GameProgression.isQuestionTypeUnlocked(
        type: QuestionType.meetingCandidate,
        level: 44,
        unlockedPeople: 3,
      ),
      isFalse,
    );
    expect(
      GameProgression.isQuestionTypeUnlocked(
        type: QuestionType.meetingCandidate,
        level: 45,
        unlockedPeople: 2,
      ),
      isFalse,
    );
    expect(
      GameProgression.isQuestionTypeUnlocked(
        type: QuestionType.meetingCandidate,
        level: 45,
        unlockedPeople: 3,
      ),
      isTrue,
    );
  });
}
