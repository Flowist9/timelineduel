import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:untitled4/logic/quiz_interaction_state.dart';
import 'package:untitled4/models/category.dart';
import 'package:untitled4/models/person.dart';
import 'package:untitled4/models/person_rarity.dart';
import 'package:untitled4/models/question.dart';

Person buildPerson(String id, int year) {
  return Person(
    id: id,
    name: id,
    birthYear: year,
    deathYear: year + 50,
    category: Category.politician,
    hint: '',
    birthCountry: 'X',
    rarity: PersonRarity.common,
  );
}

void main() {
  test('order sequence is prepared once per question key', () {
    final state = QuizInteractionState();
    final figures = [
      buildPerson('a', 1900),
      buildPerson('b', 1910),
      buildPerson('c', 1920),
    ];
    final question = Question(
      type: QuestionType.orderSequence,
      prompt: 'Sort',
      options: const [],
      correctOption: 'a -> b -> c',
      figures: figures,
    );

    state.prepareForQuestion(question, Random(1));
    final firstOrder = state.orderSequence.map((p) => p.id).toList();
    state.prepareForQuestion(question, Random(999));

    expect(state.orderSequence.map((p) => p.id).toList(), firstOrder);
  });

  test(
    'closest pair toggling supports deselect and auto reset after two picks',
    () {
      final state = QuizInteractionState();
      final a = buildPerson('a', 1900);
      final b = buildPerson('b', 1910);
      final c = buildPerson('c', 1920);

      expect(state.toggleClosestPair(a), isFalse);
      expect(state.closestPairSelection, [a]);

      expect(state.toggleClosestPair(a), isFalse);
      expect(state.closestPairSelection, isEmpty);

      expect(state.toggleClosestPair(a), isFalse);
      expect(state.toggleClosestPair(b), isTrue);
      expect(state.closestPairSelection, [a, b]);

      expect(state.toggleClosestPair(c), isFalse);
      expect(state.closestPairSelection, [c]);
    },
  );
}
