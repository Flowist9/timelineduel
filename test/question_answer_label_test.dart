import 'package:flutter_test/flutter_test.dart';
import 'package:untitled4/models/question.dart';

void main() {
  for (final type in QuestionType.values) {
    test('${type.name} always exposes the supplied solution', () {
      final question = Question(
        type: type,
        prompt: 'Question',
        options: const [],
        correctOption: 'Solution',
      );
      expect(question.correctAnswerLabel, 'Solution');
    });
  }
  test('map feedback includes the location and coordinate directions', () {
    const question = Question(
      type: QuestionType.mapEventLocation,
      prompt: '',
      options: [],
      correctOption: 'Event',
      supportingLabel: 'Target',
      supportingLat: -12.5,
      supportingLng: -45.25,
    );
    expect(question.correctAnswerLabel, 'Target\n12.50° S, 45.25° W');
  });
  test('chronological solutions retain every name in the correct order', () {
    const question = Question(
      type: QuestionType.orderSequence,
      prompt: '',
      options: [],
      correctOption: 'First -> Second -> Third',
    );
    expect(question.correctAnswerLabel, 'First → Second → Third');
  });
}
