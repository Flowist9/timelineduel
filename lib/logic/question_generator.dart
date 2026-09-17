import 'dart:math';

import '../models/person.dart';
import '../models/question.dart';

final Random _random = Random();

bool livedAtSameTime(Person a, Person b, {int currentYear = 2026}) {
  final int aEnd = a.deathYear ?? currentYear;
  final int bEnd = b.deathYear ?? currentYear;
  return a.birthYear <= bEnd && b.birthYear <= aEnd;
}

Question generateOverlapQuestionFromPool(List<Person> pool) {
  if (pool.length < 2) {
    throw StateError('Pool needs at least 2 people.');
  }

  final int i = _random.nextInt(pool.length);
  int j;
  do {
    j = _random.nextInt(pool.length);
  } while (j == i);

  final Person a = pool[i];
  final Person b = pool[j];

  return Question(
    type: QuestionType.overlap,
    prompt: 'Did these two people live at the same time?',
    options: const ['Yes', 'No'],
    correctOption: livedAtSameTime(a, b) ? 'Yes' : 'No',
    a: a,
    b: b,
  );
}
