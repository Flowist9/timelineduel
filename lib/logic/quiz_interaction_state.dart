import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../models/person.dart';
import '../models/question.dart';

class QuizInteractionState {
  String? _preparedKey;
  List<Person> _orderSequence = <Person>[];
  List<Person> _closestPairSelection = <Person>[];
  LatLng? _mapGuess;

  List<Person> get orderSequence => List.unmodifiable(_orderSequence);
  List<Person> get closestPairSelection =>
      List.unmodifiable(_closestPairSelection);
  LatLng? get mapGuess => _mapGuess;

  void prepareForQuestion(Question? question, Random random) {
    if (question == null) {
      reset();
      return;
    }

    if (question.type == QuestionType.orderSequence) {
      final key = 'order|${question.figures.map((p) => p.id).join('|')}';
      if (_preparedKey == key && _orderSequence.isNotEmpty) {
        return;
      }

      _preparedKey = key;
      _orderSequence = [...question.figures]..shuffle(random);
      _closestPairSelection = <Person>[];

      final sameOrder =
          _orderSequence.length == question.figures.length &&
          _orderSequence.asMap().entries.every(
            (entry) => entry.value.id == question.figures[entry.key].id,
          );

      if (sameOrder && _orderSequence.length > 1) {
        final first = _orderSequence.removeAt(0);
        _orderSequence.insert(1, first);
      }
      return;
    }

    if (question.type == QuestionType.closestPair) {
      final key = 'closest|${question.figures.map((p) => p.id).join('|')}';
      if (_preparedKey == key) {
        return;
      }

      _preparedKey = key;
      _orderSequence = <Person>[];
      _closestPairSelection = <Person>[];
      _mapGuess = null;
      return;
    }

    if (question.type == QuestionType.birthplaceMap) {
      final key =
          'map|${question.subject?.id ?? ''}|${question.correctOption}|${question.supportingLabel ?? ''}';
      if (_preparedKey == key) {
        return;
      }

      _preparedKey = key;
      _orderSequence = <Person>[];
      _closestPairSelection = <Person>[];
      _mapGuess = null;
      return;
    }

    reset();
  }

  void reset() {
    _preparedKey = null;
    _orderSequence = <Person>[];
    _closestPairSelection = <Person>[];
    _mapGuess = null;
  }

  void setOrderSequence(List<Person> nextSequence) {
    _orderSequence = List<Person>.from(nextSequence);
  }

  bool toggleClosestPair(Person person) {
    final alreadySelected = _closestPairSelection.any((p) => p.id == person.id);
    if (alreadySelected) {
      _closestPairSelection = _closestPairSelection
          .where((p) => p.id != person.id)
          .toList();
      return false;
    }

    if (_closestPairSelection.length == 2) {
      _closestPairSelection = <Person>[person];
      return false;
    }

    _closestPairSelection = [..._closestPairSelection, person];
    return _closestPairSelection.length == 2;
  }

  void setMapGuess(LatLng? point) {
    _mapGuess = point;
  }
}
