import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../ads/ads_service.dart';
import '../localization/app_language.dart';
import '../data/achievement_facts.dart';
import '../data/persons.dart';
import '../data/role_facts.dart';
import '../data/theory_facts.dart';
import '../data/work_facts.dart';
import '../data/quiz_facts.dart';
import '../logic/game_progression.dart';
import '../logic/game_session.dart';
import '../logic/progression_catalog.dart';
import '../logic/question_generator.dart';
import '../logic/quiz_interaction_state.dart';
import '../models/category.dart';
import '../models/game_badge.dart';
import '../models/person.dart';
import '../models/late_game_fact.dart';
import '../models/person_status.dart';
import '../models/question.dart';
import '../widgets/person_map_marker.dart';
import '../widgets/person_portrait.dart';
import '../widgets/reward_card_reveal_dialog.dart';
import 'game/widgets/unlock_birth_year_step.dart';
import 'game/widgets/quiz_panel.dart';
import 'game/widgets/unlock_famous_for_step.dart';
import 'game/widgets/unlock_map_step.dart';
import '../maps/map_tile_config.dart';

enum _EraMode { cross, modern, ancient }

enum _GameMode { normalQuiz, unlockBirthYear, unlockMap, unlockSort }

class GameScreen extends StatefulWidget {
  final GameSession session;
  final AdsService? adsService;
  final bool showIntroTutorialOnStart;

  const GameScreen({
    super.key,
    required this.session,
    this.adsService,
    this.showIntroTutorialOnStart = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // --------------------
  // Normal quiz state
  // --------------------
  Question? _question;
  String? _feedbackText;
  bool? _wasCorrect;
  bool _buttonsLocked = false;
  LatLng? _quizMapGuess;
  double? _quizMapKm;
  final QuizInteractionState _quizInteraction = QuizInteractionState();

  // --------------------
  // General helpers
  // --------------------
  final Random _rand = Random();

  // --------------------
  // Wheel
  // --------------------
  late final StreamController<int> _wheelSelected =
      StreamController<int>.broadcast();

  final List<Category> _wheelCategories = const [
    Category.politician,
    Category.scientist,
    Category.artist,
    Category.athlete,
  ];

  // --------------------
  // Unlock flow state
  // --------------------
  List<int> _birthYearChoices = [];

  // map step
  LatLng? _mapGuess;
  double? _mapKm;
  bool _mapDone = false;
  bool _mapWasCorrect = false;
  int _mapAttempts = 0;
  bool _mapRevealTarget = false;

  final Distance _distance = const Distance();

  // famous-for step
  List<String> _famousForOptions = [];
  bool _famousForAnswered = false;
  bool _famousForWasCorrect = false;
  String? _famousForCorrectAnswer;

  // tracks which person's unlock UI is currently prepared
  String? _preparedUnlockPersonId;
  bool _tutorialShown = false;

  @override
  void initState() {
    super.initState();
    _tryGenerateQuestion();
    _prepareUnlockUiIfNeeded();
    if (widget.showIntroTutorialOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntroTutorialIfNeeded();
      });
    }
  }

  @override
  void dispose() {
    _wheelSelected.close();
    super.dispose();
  }

  // ============================================================
  // Helpers
  // ============================================================

  Person? get _activeUnlockPerson => widget.session.activeUnlockPerson;

  _GameMode _currentMode() {
    final person = _activeUnlockPerson;
    if (person == null) return _GameMode.normalQuiz;

    if (!widget.session.isStepDone(person.id, UnlockStep.birthYear)) {
      return _GameMode.unlockBirthYear;
    }
    if (!widget.session.isStepDone(person.id, UnlockStep.map)) {
      return _GameMode.unlockMap;
    }
    if (!widget.session.isStepDone(person.id, UnlockStep.famousFor)) {
      return _GameMode.unlockSort;
    }

    return _GameMode.normalQuiz;
  }

  bool _isModern(Person p) => p.birthYear >= 1400;

  int _birthDist(Person a, Person b) => (a.birthYear - b.birthYear).abs();

  double _birthLocationDistanceKm(Person a, Person b) {
    final aLat = a.birthLat;
    final aLng = a.birthLng;
    final bLat = b.birthLat;
    final bLng = b.birthLng;
    if (aLat == null || aLng == null || bLat == null || bLng == null) {
      return double.infinity;
    }
    return _distance.as(
      LengthUnit.Kilometer,
      LatLng(aLat, aLng),
      LatLng(bLat, bLng),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showIntroTutorialIfNeeded() async {
    if (_tutorialShown || !mounted) return;
    if (widget.session.level != 1 || widget.session.xp != 0) return;

    _tutorialShown = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF4C3929), Color(0xFF2A1B12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFF1E2CB).withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB78A52).withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Timeline Duel',
                    style: TextStyle(
                      color: Color(0xFFF8F0E3),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You start with one unlocked person per category. You discover new figures through level-ups and the wheel.',
                    style: TextStyle(color: Color(0xFFE6D6BF), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How the opening works:',
                    style: TextStyle(
                      color: Color(0xFFD4B06A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '1. Start with the core question: did two people live at the same time?',
                    style: TextStyle(color: Color(0xFFF8F0E3), height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2. Earn XP and spin the wheel on level-up to discover new people.',
                    style: TextStyle(color: Color(0xFFF8F0E3), height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '3. Every 5 levels you unlock a new question type, along with a short explanation.',
                    style: TextStyle(color: Color(0xFFF8F0E3), height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD4B06A),
                        foregroundColor: const Color(0xFF2D2012),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Los gehts',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showQuestionTypeUnlockDialog(QuestionType type) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF4C3929), Color(0xFF2A1B12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFF1E2CB).withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB78A52).withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD4B06A),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF2D2012),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'New question type unlocked',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD4B06A),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    type.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF8F0E3),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    type.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE6D6BF),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD4B06A),
                        foregroundColor: const Color(0xFF2D2012),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMilestoneDialog(
    ProgressionMilestone milestone, {
    List<Person> rewardedPeople = const [],
  }) async {
    final icon = switch (milestone.kind) {
      ProgressionMilestoneKind.feature => Icons.lock_open_rounded,
      ProgressionMilestoneKind.capsule => Icons.redeem_rounded,
      ProgressionMilestoneKind.question => Icons.auto_awesome_rounded,
    };
    final accent = switch (milestone.kind) {
      ProgressionMilestoneKind.feature => const Color(0xFF8DC8FF),
      ProgressionMilestoneKind.capsule => const Color(0xFFD4B06A),
      ProgressionMilestoneKind.question => const Color(0xFFD4B06A),
    };

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF4C3929), Color(0xFF2A1B12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFF1E2CB).withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                    child: Icon(icon, color: const Color(0xFF2D2012), size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    switch (milestone.kind) {
                      ProgressionMilestoneKind.feature => 'Feature unlocked',
                      ProgressionMilestoneKind.capsule => 'Capsule opened',
                      ProgressionMilestoneKind.question =>
                        'New milestone reached',
                    },
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFD4B06A),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    milestone.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF8F0E3),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    milestone.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE6D6BF),
                      height: 1.45,
                    ),
                  ),
                  if (rewardedPeople.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'New drops',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: rewardedPeople
                          .map(
                            (person) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              child: Text(
                                person.name,
                                style: const TextStyle(
                                  color: Color(0xFFF8F0E3),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: const Color(0xFF2D2012),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _resetQuizMapState() {
    _quizMapGuess = null;
    _quizMapKm = null;
  }

  void _tryGenerateQuestion() {
    final unlocked = widget.session.unlockedPersons;
    _resetQuizMapState();
    if (unlocked.length < 2) {
      _question = null;
      _quizInteraction.reset();
      return;
    }
    _question = _generateNextQuestion();
    _quizInteraction.prepareForQuestion(_question, _rand);
  }

  Future<void> _submitBirthMapGuess(LatLng latLng) async {
    final question = _question;
    if (_buttonsLocked ||
        question == null ||
        (question.type != QuestionType.birthplaceMap &&
            question.type != QuestionType.mapEventLocation)) {
      return;
    }

    final targetLat = question.type == QuestionType.mapEventLocation
        ? question.supportingLat
        : question.subject?.birthLat;
    final targetLng = question.type == QuestionType.mapEventLocation
        ? question.supportingLng
        : question.subject?.birthLng;
    if (targetLat == null || targetLng == null) {
      return;
    }

    final target = LatLng(targetLat, targetLng);
    final km = _distance.as(LengthUnit.Kilometer, latLng, target);
    final radiusKm = widget.session.activeMapRadiusKm;
    final isCorrect = km <= radiusKm;
    widget.session.consumeBoostForMapAttempt();

    setState(() {
      _quizMapGuess = latLng;
      _quizMapKm = km;
    });

    await _submitAnswer(isCorrect ? question.correctOption : '__map_guess__');
  }

  void _submitOrderSequenceAnswer() {
    final question = _question;
    if (_buttonsLocked ||
        question == null ||
        question.type != QuestionType.orderSequence) {
      return;
    }

    final selectedOrder = _quizInteraction.orderSequence
        .map((p) => p.name)
        .join(' -> ');
    _submitAnswer(selectedOrder);
  }

  Future<void> _toggleClosestPairSelection(Person person) async {
    final question = _question;
    if (_buttonsLocked ||
        question == null ||
        question.type != QuestionType.closestPair) {
      return;
    }

    late final bool shouldSubmit;
    setState(() {
      shouldSubmit = _quizInteraction.toggleClosestPair(person);
    });

    if (!shouldSubmit) {
      return;
    }

    final chosenLabel = _quizInteraction.closestPairSelection
        .map((p) => p.name)
        .join(' und ');
    final correctNames = question.correctOption
        .split(' und ')
        .map((name) => name.trim())
        .toSet();
    final chosenNames = _quizInteraction.closestPairSelection
        .map((p) => p.name)
        .toSet();
    final submittedOption =
        chosenNames.length == 2 &&
            chosenNames.containsAll(correctNames) &&
            correctNames.containsAll(chosenNames)
        ? question.correctOption
        : chosenLabel;

    await _submitAnswer(submittedOption);
  }

  void _prepareUnlockUiIfNeeded() {
    final person = _activeUnlockPerson;

    if (person == null) {
      _preparedUnlockPersonId = null;
      return;
    }

    if (_preparedUnlockPersonId == person.id) return;

    _preparedUnlockPersonId = person.id;

    _birthYearChoices = GameProgression.generateBirthYearChoices(
      person.birthYear,
      _rand,
    );
    _resetMapStep();
    _prepareFamousForStep(person);
  }

  void _resetMapStep() {
    _mapGuess = null;
    _mapKm = null;
    _mapDone = false;
    _mapWasCorrect = false;
    _mapAttempts = 0;
    _mapRevealTarget = false;
  }

  void _prepareFamousForStep(Person person) {
    final quiz = famousForQuiz[person.id];
    if (quiz == null) {
      _famousForOptions = const [];
      _famousForAnswered = false;
      _famousForWasCorrect = false;
      _famousForCorrectAnswer = null;
      return;
    }

    _famousForOptions = [quiz.correct, ...quiz.wrong.take(3)]..shuffle(_rand);
    _famousForAnswered = false;
    _famousForWasCorrect = false;
    _famousForCorrectAnswer = quiz.correct;
  }

  String _categoryLabel(Category c) {
    switch (c) {
      case Category.politician:
        return 'Politics';
      case Category.scientist:
        return 'Science';
      case Category.artist:
        return 'Art';
      case Category.athlete:
        return 'Sport';
    }
  }

  // ============================================================
  // Question generation
  // ============================================================

  Question _generateNextQuestion() {
    final unlocked = widget.session.unlockedPersons;
    final availableTypes = _availableQuestionTypes(unlocked);
    final questionType = availableTypes[_rand.nextInt(availableTypes.length)];

    switch (questionType) {
      case QuestionType.birthCentury:
        return _generateBirthCenturyQuestion(unlocked);
      case QuestionType.birthYear:
        return _generateBirthYearQuizQuestion(unlocked);
      case QuestionType.earlierPerson:
        return _generateEarlierQuizQuestion(unlocked);
      case QuestionType.era:
        return _generateEraQuizQuestion(unlocked);
      case QuestionType.meetingCandidate:
        return _generateMeetingCandidateQuestion(unlocked);
      case QuestionType.orderSequence:
        return _generateOrderSequenceQuestion(unlocked);
      case QuestionType.beforeAfterEvent:
        return _generateBeforeAfterEventQuestion(unlocked);
      case QuestionType.closestPair:
        return _generateClosestPairQuestion(unlocked);
      case QuestionType.longestLife:
        return _generateLongestLifeQuestion(unlocked);
      case QuestionType.birthCountry:
        return _generateBirthCountryQuestion(unlocked);
      case QuestionType.birthPlace:
        return _generateBirthPlaceQuestion(unlocked);
      case QuestionType.birthplaceMap:
        return _generateBirthplaceMapQuestion(unlocked);
      case QuestionType.mapEventLocation:
        return _generateMapEventLocationQuestion(unlocked);
      case QuestionType.northernmostBirthplace:
        return _generateLatitudeExtremesQuestion(
          unlocked,
          type: QuestionType.northernmostBirthplace,
          north: true,
        );
      case QuestionType.southernmostBirthplace:
        return _generateLatitudeExtremesQuestion(
          unlocked,
          type: QuestionType.southernmostBirthplace,
          north: false,
        );
      case QuestionType.scientistTheory:
        return _generateScientistTheoryQuestion(unlocked);
      case QuestionType.scientistFormula:
        return _generateScientistFormulaQuestion(unlocked);
      case QuestionType.scientistDiscovery:
        return _generateScientistDiscoveryQuestion(unlocked);
      case QuestionType.artistWork:
        return _generateArtistWorkQuestion(unlocked);
      case QuestionType.artistQuote:
        return _generateArtistQuoteQuestion(unlocked);
      case QuestionType.workDescription:
        return _generateWorkDescriptionQuestion(unlocked);
      case QuestionType.athleteAchievement:
        return _generateAthleteAchievementQuestion(unlocked);
      case QuestionType.sportStatline:
        return _generateSportStatlineQuestion(unlocked);
      case QuestionType.politicianRole:
        return _generatePoliticianRoleQuestion(unlocked);
      case QuestionType.politicianEventMatch:
        return _generatePoliticianEventMatchQuestion(unlocked);
      case QuestionType.twoCluesOnePerson:
        return _generateTwoCluesOnePersonQuestion(unlocked);
      case QuestionType.multiClueExpert:
        return _generateMultiClueExpertQuestion(unlocked);
      case QuestionType.overlap:
        return _generateOverlapQuizQuestion(unlocked);
    }
  }

  List<QuestionType> _availableQuestionTypes(List<Person> unlocked) {
    final level = widget.session.level;
    const supportedTypes = <QuestionType>{
      QuestionType.overlap,
      QuestionType.birthYear,
      QuestionType.birthCentury,
      QuestionType.earlierPerson,
      QuestionType.era,
      QuestionType.meetingCandidate,
      QuestionType.orderSequence,
      QuestionType.beforeAfterEvent,
      QuestionType.closestPair,
      QuestionType.longestLife,
      QuestionType.birthCountry,
      QuestionType.birthPlace,
      QuestionType.birthplaceMap,
      QuestionType.mapEventLocation,
      QuestionType.northernmostBirthplace,
      QuestionType.southernmostBirthplace,
      QuestionType.scientistTheory,
      QuestionType.scientistFormula,
      QuestionType.scientistDiscovery,
      QuestionType.artistWork,
      QuestionType.artistQuote,
      QuestionType.workDescription,
      QuestionType.athleteAchievement,
      QuestionType.sportStatline,
      QuestionType.politicianRole,
      QuestionType.politicianEventMatch,
      QuestionType.twoCluesOnePerson,
      QuestionType.multiClueExpert,
    };
    final unlockedByLevel = QuestionType.values.where((type) {
      return supportedTypes.contains(type) &&
          GameProgression.isQuestionTypeUnlocked(
            type: type,
            level: level,
            unlockedPeople: unlocked.length,
          ) &&
          _questionTypePoolReady(type, unlocked);
    }).toList();

    if (unlockedByLevel.length == 1) {
      return const [
        QuestionType.overlap,
        QuestionType.overlap,
        QuestionType.overlap,
      ];
    }

    return unlockedByLevel;
  }

  bool _isCategorySpecificQuestionType(QuestionType type) {
    return switch (type) {
      QuestionType.scientistTheory ||
      QuestionType.scientistFormula ||
      QuestionType.scientistDiscovery ||
      QuestionType.artistWork ||
      QuestionType.artistQuote ||
      QuestionType.workDescription ||
      QuestionType.athleteAchievement ||
      QuestionType.sportStatline ||
      QuestionType.politicianRole ||
      QuestionType.politicianEventMatch ||
      QuestionType.twoCluesOnePerson ||
      QuestionType.multiClueExpert => true,
      _ => false,
    };
  }

  bool _questionTypePoolReady(QuestionType type, List<Person> unlocked) {
    int countFor(Category category, Map<String, LateGameChoiceFact> factMap) {
      return unlocked
          .where(
            (person) =>
                person.category == category && factMap.containsKey(person.id),
          )
          .length;
    }

    final geoCount = unlocked
        .where((person) => person.birthLat != null && person.birthLng != null)
        .length;

    return switch (type) {
      QuestionType.scientistTheory ||
      QuestionType.scientistFormula ||
      QuestionType.scientistDiscovery =>
        countFor(Category.scientist, theoryFacts) >= 4,
      QuestionType.birthCentury => geoCount >= 4,
      QuestionType.artistWork ||
      QuestionType.artistQuote ||
      QuestionType.workDescription => countFor(Category.artist, workFacts) >= 4,
      QuestionType.athleteAchievement || QuestionType.sportStatline =>
        countFor(Category.athlete, achievementFacts) >= 4,
      QuestionType.politicianRole || QuestionType.politicianEventMatch =>
        countFor(Category.politician, roleFacts) >= 4,
      QuestionType.northernmostBirthplace ||
      QuestionType.southernmostBirthplace ||
      QuestionType.birthplaceMap => geoCount >= 3,
      QuestionType.mapEventLocation => _historicEvents.isNotEmpty,
      QuestionType.twoCluesOnePerson ||
      QuestionType.multiClueExpert => unlocked.length >= 4,
      _ => true,
    };
  }

  Question _generateCategoryFactQuestion(
    List<Person> unlocked, {
    required Category category,
    required Map<String, LateGameChoiceFact> factMap,
    required QuestionType type,
    required String prompt,
  }) {
    final eligible = unlocked
        .where(
          (person) =>
              person.category == category && factMap.containsKey(person.id),
        )
        .toList();
    if (eligible.length < 4) {
      return _generateOverlapQuizQuestion(unlocked);
    }

    final subject = eligible[_rand.nextInt(eligible.length)];
    final fact = factMap[subject.id]!;
    final clue = fact.correct[_rand.nextInt(fact.correct.length)];
    final distractors = [...eligible]
      ..removeWhere((person) => person.id == subject.id);
    distractors.shuffle(_rand);
    final figures = <Person>[subject, ...distractors.take(3)]..shuffle(_rand);

    return Question(
      type: type,
      prompt: prompt,
      options: figures.map((person) => person.name).toList(),
      correctOption: subject.name,
      subject: subject,
      figures: figures,
      supportingLabel: clue,
    );
  }

  Question _generateScientistTheoryQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.scientist,
      factMap: theoryFacts,
      type: QuestionType.scientistTheory,
      prompt: 'Whose formula, law, or theory is this?',
    );
  }

  Question _generateScientistFormulaQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.scientist,
      factMap: theoryFacts,
      type: QuestionType.scientistFormula,
      prompt: 'Which scientist matches this formula-style clue?',
    );
  }

  Question _generateScientistDiscoveryQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.scientist,
      factMap: theoryFacts,
      type: QuestionType.scientistDiscovery,
      prompt: 'Who is associated with this discovery or breakthrough clue?',
    );
  }

  Question _generateArtistWorkQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.artist,
      factMap: workFacts,
      type: QuestionType.artistWork,
      prompt: 'Who is associated with this work?',
    );
  }

  Question _generateArtistQuoteQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.artist,
      factMap: workFacts,
      type: QuestionType.artistQuote,
      prompt: 'Which artist or author fits this text clue best?',
    );
  }

  Question _generateWorkDescriptionQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.artist,
      factMap: workFacts,
      type: QuestionType.workDescription,
      prompt: 'Which creator is tied to this stronger work description?',
    );
  }

  Question _generateAthleteAchievementQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.athlete,
      factMap: achievementFacts,
      type: QuestionType.athleteAchievement,
      prompt: 'Whose career achievement is this?',
    );
  }

  Question _generateSportStatlineQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.athlete,
      factMap: achievementFacts,
      type: QuestionType.sportStatline,
      prompt: 'Which athlete fits this statline or record clue?',
    );
  }

  Question _generatePoliticianRoleQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.politician,
      factMap: roleFacts,
      type: QuestionType.politicianRole,
      prompt: 'Which leader fits this role clue?',
    );
  }

  Question _generatePoliticianEventMatchQuestion(List<Person> unlocked) {
    return _generateCategoryFactQuestion(
      unlocked,
      category: Category.politician,
      factMap: roleFacts,
      type: QuestionType.politicianEventMatch,
      prompt: 'Which leader best matches this event or turning-point clue?',
    );
  }

  List<Person> _geoEligiblePersons(List<Person> unlocked) {
    return unlocked
        .where((person) => person.birthLat != null && person.birthLng != null)
        .toList();
  }

  Question _generateBirthCountryQuestion(List<Person> unlocked) {
    final available = unlocked.where((p) => p.birthCountry.isNotEmpty).toList();
    if (available.length < 4) {
      return _generateBirthYearQuizQuestion(unlocked);
    }

    final person = available[_rand.nextInt(available.length)];
    final distractorCountries =
        available
            .where((candidate) => candidate.id != person.id)
            .map((candidate) => candidate.birthCountry)
            .where((country) => country != person.birthCountry)
            .toSet()
            .toList()
          ..shuffle(_rand);
    if (distractorCountries.length < 3) {
      return _generateBirthYearQuizQuestion(unlocked);
    }

    final options = <String>[
      person.birthCountry,
      ...distractorCountries.take(3),
    ]..shuffle(_rand);

    return Question(
      type: QuestionType.birthCountry,
      prompt: 'In which country was ${person.name} born?',
      options: options,
      correctOption: person.birthCountry,
      subject: person,
      figures: [person],
    );
  }

  Question _generateBirthPlaceQuestion(List<Person> unlocked) {
    final available = unlocked.where((p) => p.birthPlaceLabel != null).toList();
    if (available.length < 4) {
      return _generateBirthCountryQuestion(unlocked);
    }

    final person = available[_rand.nextInt(available.length)];
    final distractorPlaces =
        available
            .where(
              (candidate) =>
                  candidate.id != person.id &&
                  candidate.birthPlaceLabel != null,
            )
            .map((candidate) => candidate.birthPlaceLabel!)
            .where((place) => place != person.birthPlaceLabel)
            .toSet()
            .toList()
          ..shuffle(_rand);
    if (distractorPlaces.length < 3) {
      return _generateBirthCountryQuestion(unlocked);
    }

    final correctPlace = person.birthPlaceLabel!;
    final options = <String>[correctPlace, ...distractorPlaces.take(3)]
      ..shuffle(_rand);

    return Question(
      type: QuestionType.birthPlace,
      prompt: 'Which city or birthplace label belongs to ${person.name}?',
      options: options,
      correctOption: correctPlace,
      subject: person,
      figures: [person],
    );
  }

  Question _generateBirthplaceMapQuestion(List<Person> unlocked) {
    final available = _geoEligiblePersons(unlocked);
    if (available.isEmpty) {
      return _generateBirthCountryQuestion(unlocked);
    }

    final person = available[_rand.nextInt(available.length)];
    return Question(
      type: QuestionType.birthplaceMap,
      prompt: 'Tap the approximate birthplace of ${person.name}.',
      options: const [],
      correctOption: person.birthCountry,
      subject: person,
      figures: [person],
      supportingLabel: person.birthPlaceLabel,
      supportingLat: person.birthLat,
      supportingLng: person.birthLng,
    );
  }

  Question _generateMapEventLocationQuestion(List<Person> unlocked) {
    final event = _historicEvents[_rand.nextInt(_historicEvents.length)];
    return Question(
      type: QuestionType.mapEventLocation,
      prompt: 'Tap the approximate location of ${event.label}.',
      options: const [],
      correctOption: event.label,
      supportingLabel: event.label,
      supportingYear: event.year,
      supportingLat: event.lat,
      supportingLng: event.lng,
    );
  }

  Question _generateLatitudeExtremesQuestion(
    List<Person> unlocked, {
    required QuestionType type,
    required bool north,
  }) {
    final available = _geoEligiblePersons(unlocked);
    if (available.length < 3) {
      return _generateBirthCountryQuestion(unlocked);
    }

    final figures = [...available]..shuffle(_rand);
    final optionsPeople = figures.take(3).toList();
    optionsPeople.sort((a, b) {
      final aLat = a.birthLat ?? 0;
      final bLat = b.birthLat ?? 0;
      return north ? bLat.compareTo(aLat) : aLat.compareTo(bLat);
    });
    final correct = optionsPeople.first;
    final answers = optionsPeople.map((person) => person.name).toList()
      ..shuffle(_rand);

    return Question(
      type: type,
      prompt: north
          ? 'Who was born farthest north?'
          : 'Who was born farthest south?',
      options: answers,
      correctOption: correct.name,
      figures: optionsPeople,
      subject: correct,
      supportingLabel: north
          ? 'Compare the birthplaces from north to south.'
          : 'Compare the birthplaces from south to north.',
    );
  }

  List<String> _cluePoolForPerson(Person person) {
    final clues = <String>[
      'Category: ${_categoryLabel(person.category)}',
      'Era: ${_eraLabelForYear(person.birthYear)}',
      'Birth country: ${person.birthCountry}',
      'Born in the ${((person.birthYear - 1) ~/ 100) + 1}th century',
      if (person.birthPlaceLabel != null)
        'Birthplace: ${person.birthPlaceLabel}',
      'Known for: ${person.hint}',
    ];
    return clues.toSet().toList();
  }

  Question _generatePersonClueQuestion(
    List<Person> unlocked, {
    required QuestionType type,
    required int clueCount,
    required String prompt,
  }) {
    if (unlocked.length < 4) {
      return _generateOverlapQuizQuestion(unlocked);
    }

    final pool = [...unlocked]..shuffle(_rand);
    final figures = pool.take(4).toList();
    final subject = figures[_rand.nextInt(figures.length)];
    final clues = _cluePoolForPerson(subject)..shuffle(_rand);
    final selectedClues = clues.take(clueCount).toList();
    final clueBlock = List.generate(
      selectedClues.length,
      (index) => '${index + 1}. ${selectedClues[index]}',
    ).join('\n');

    return Question(
      type: type,
      prompt: prompt,
      options: figures.map((person) => person.name).toList(),
      correctOption: subject.name,
      subject: subject,
      figures: figures,
      supportingLabel: clueBlock,
    );
  }

  Question _generateTwoCluesOnePersonQuestion(List<Person> unlocked) {
    return _generatePersonClueQuestion(
      unlocked,
      type: QuestionType.twoCluesOnePerson,
      clueCount: 2,
      prompt: 'Who matches these two clues?',
    );
  }

  Question _generateMultiClueExpertQuestion(List<Person> unlocked) {
    return _generatePersonClueQuestion(
      unlocked,
      type: QuestionType.multiClueExpert,
      clueCount: 3,
      prompt: 'Who matches this expert bundle of clues?',
    );
  }

  Question _generateOverlapQuizQuestion(List<Person> unlocked) {
    Person pickFrom(List<Person> list) => list[_rand.nextInt(list.length)];

    final unlockedModern = unlocked.where(_isModern).toList();
    final unlockedAncient = unlocked.where((p) => !_isModern(p)).toList();
    final eraMode = _chooseEraModeByLevel(widget.session.level);

    Person a;
    Person b;

    if (eraMode == _EraMode.cross &&
        unlockedModern.isNotEmpty &&
        unlockedAncient.isNotEmpty) {
      a = pickFrom(unlockedAncient);
      b = pickFrom(unlockedModern);
    } else if (eraMode == _EraMode.modern && unlockedModern.length >= 2) {
      a = pickFrom(unlockedModern);
      do {
        b = pickFrom(unlockedModern);
      } while (b.id == a.id);
    } else if (eraMode == _EraMode.ancient && unlockedAncient.length >= 2) {
      a = pickFrom(unlockedAncient);
      do {
        b = pickFrom(unlockedAncient);
      } while (b.id == a.id);
    } else {
      return generateOverlapQuestionFromPool(unlocked);
    }

    final pair = _enforceDistanceDifficulty(a, b, unlocked);
    return Question(
      type: QuestionType.overlap,
      prompt: 'Did these two people live at the same time?',
      options: const ['Yes', 'No'],
      correctOption: livedAtSameTime(pair.$1, pair.$2) ? 'Yes' : 'No',
      a: pair.$1,
      b: pair.$2,
      figures: [pair.$1, pair.$2],
    );
  }

  Question _generateBirthYearQuizQuestion(List<Person> unlocked) {
    final person = unlocked[_rand.nextInt(unlocked.length)];
    final options = GameProgression.generateBirthYearChoices(
      person.birthYear,
      _rand,
    ).map((year) => '$year').toList();

    return Question(
      type: QuestionType.birthYear,
      prompt: 'In which year was ${person.name} born?',
      options: options,
      correctOption: '${person.birthYear}',
      subject: person,
      figures: [person],
    );
  }

  Question _generateBirthCenturyQuestion(List<Person> unlocked) {
    final available = _geoEligiblePersons(unlocked);
    if (available.length < 4) {
      return _generateBirthYearQuizQuestion(unlocked);
    }

    final subject = available[_rand.nextInt(available.length)];
    final candidates = [...available]
      ..removeWhere((person) => person.id == subject.id)
      ..shuffle(_rand);

    final optionsPeople = candidates.take(3).toList();
    if (optionsPeople.length < 3) {
      return _generateBirthYearQuizQuestion(unlocked);
    }

    optionsPeople.sort(
      (a, b) => _birthLocationDistanceKm(
        subject,
        a,
      ).compareTo(_birthLocationDistanceKm(subject, b)),
    );
    final correct = optionsPeople.first;
    final shuffledOptions = [...optionsPeople]..shuffle(_rand);

    return Question(
      type: QuestionType.birthCentury,
      prompt: 'Who was born closest to ${subject.name}?',
      options: shuffledOptions.map((person) => person.name).toList(),
      correctOption: correct.name,
      subject: subject,
      figures: [subject, ...shuffledOptions],
    );
  }

  Question _generateEarlierQuizQuestion(List<Person> unlocked) {
    final first = unlocked[_rand.nextInt(unlocked.length)];
    late Person second;
    do {
      second = unlocked[_rand.nextInt(unlocked.length)];
    } while (second.id == first.id || second.birthYear == first.birthYear);

    final earlier = first.birthYear <= second.birthYear ? first : second;
    final options = [first.name, second.name]..shuffle(_rand);

    return Question(
      type: QuestionType.earlierPerson,
      prompt: 'Who was born earlier?',
      options: options,
      correctOption: earlier.name,
      a: first,
      b: second,
      figures: [first, second],
    );
  }

  Question _generateEraQuizQuestion(List<Person> unlocked) {
    final person = unlocked[_rand.nextInt(unlocked.length)];
    const options = ['Ancient', 'Medieval', 'Early Modern', 'Modern'];

    return Question(
      type: QuestionType.era,
      prompt: 'Which era fits ${person.name} best?',
      options: options,
      correctOption: _eraLabelForYear(person.birthYear),
      subject: person,
      figures: [person],
    );
  }

  Question _generateMeetingCandidateQuestion(List<Person> unlocked) {
    final subject = unlocked[_rand.nextInt(unlocked.length)];
    final overlaps = unlocked
        .where((p) => p.id != subject.id && livedAtSameTime(subject, p))
        .toList();
    final nonOverlaps = unlocked
        .where((p) => p.id != subject.id && !livedAtSameTime(subject, p))
        .toList();

    if (overlaps.isEmpty || nonOverlaps.length < 2) {
      return _generateOverlapQuizQuestion(unlocked);
    }

    final correct = overlaps[_rand.nextInt(overlaps.length)];
    final wrongs = <Person>[];
    final shuffledWrong = [...nonOverlaps]..shuffle(_rand);
    wrongs.addAll(shuffledWrong.take(2));

    final options = [correct.name, ...wrongs.map((p) => p.name)]
      ..shuffle(_rand);

    return Question(
      type: QuestionType.meetingCandidate,
      prompt: 'Which of these people could ${subject.name} have met?',
      options: options,
      correctOption: correct.name,
      subject: subject,
      figures: [subject, correct, ...wrongs],
    );
  }

  Question _generateOrderSequenceQuestion(List<Person> unlocked) {
    final picked = [...unlocked]..shuffle(_rand);
    final trio = picked.take(3).toList()
      ..sort((a, b) => a.birthYear.compareTo(b.birthYear));
    final wrongOne = [trio[1], trio[0], trio[2]];
    final wrongTwo = [trio[2], trio[0], trio[1]];

    String labelFor(List<Person> persons) =>
        persons.map((p) => p.name).join(' -> ');

    final options = [labelFor(trio), labelFor(wrongOne), labelFor(wrongTwo)]
      ..shuffle(_rand);

    return Question(
      type: QuestionType.orderSequence,
      prompt: 'Which order is correct from earliest to latest?',
      options: options,
      correctOption: labelFor(trio),
      figures: trio,
    );
  }

  Question _generateBeforeAfterEventQuestion(List<Person> unlocked) {
    final events = _historicEvents;
    final event = events[_rand.nextInt(events.length)];
    final person = unlocked[_rand.nextInt(unlocked.length)];
    final options = const ['Before', 'After'];

    return Question(
      type: QuestionType.beforeAfterEvent,
      prompt: 'Was ${person.name} born before or after ${event.label}?',
      options: options,
      correctOption: person.birthYear < event.year ? 'Before' : 'After',
      subject: person,
      figures: [person],
      supportingLabel: event.label,
      supportingYear: event.year,
    );
  }

  Question _generateClosestPairQuestion(List<Person> unlocked) {
    final picked = [...unlocked]..shuffle(_rand);
    final candidates = picked.take(4).toList();

    List<Person> bestPair = [candidates[0], candidates[1]];
    var bestDistance = _birthDist(candidates[0], candidates[1]);

    for (int i = 0; i < candidates.length; i++) {
      for (int j = i + 1; j < candidates.length; j++) {
        final distance = _birthDist(candidates[i], candidates[j]);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestPair = [candidates[i], candidates[j]];
        }
      }
    }

    String pairLabel(Person a, Person b) => '${a.name} und ${b.name}';
    final options = <String>{pairLabel(bestPair[0], bestPair[1])};

    while (options.length < 3) {
      final first = candidates[_rand.nextInt(candidates.length)];
      final second = candidates[_rand.nextInt(candidates.length)];
      if (first.id == second.id) continue;
      options.add(pairLabel(first, second));
    }

    final shuffled = options.toList()..shuffle(_rand);

    return Question(
      type: QuestionType.closestPair,
      prompt: 'Which of these were born closest to each other? ',
      options: shuffled,
      correctOption: pairLabel(bestPair[0], bestPair[1]),
      figures: candidates,
    );
  }

  Question _generateLongestLifeQuestion(List<Person> unlocked) {
    final picked = [...unlocked]..shuffle(_rand);
    final trio = picked.take(3).toList();
    int lifeLength(Person p) =>
        (p.deathYear ?? DateTime.now().year) - p.birthYear;
    trio.sort((a, b) => lifeLength(b).compareTo(lifeLength(a)));
    final options = trio.map((p) => p.name).toList()..shuffle(_rand);

    return Question(
      type: QuestionType.longestLife,
      prompt: 'Who lived/lives the longest?',
      options: options,
      correctOption: trio.first.name,
      figures: trio,
    );
  }

  String _eraLabelForYear(int year) {
    if (year < 500) return 'Ancient';
    if (year < 1450) return 'Medieval';
    if (year < 1800) return 'Early Modern';
    return 'Modern';
  }

  List<_HistoricEvent> get _historicEvents => const [
    _HistoricEvent('the French Revolution', 1789, 48.8566, 2.3522),
    _HistoricEvent('the Fall of Constantinople', 1453, 41.0082, 28.9784),
    _HistoricEvent('Columbus reaching the Bahamas', 1492, 24.06, -74.48),
    _HistoricEvent(
      'the start of World War I in Sarajevo',
      1914,
      43.8563,
      18.4131,
    ),
  ];
  double _difficultyScore() {
    return widget.session.level + widget.session.unlockedPersons.length * 0.15;
  }

  double _targetDistanceForDifficulty(double difficulty) {
    return max(35.0, 500 * pow(0.88, difficulty - 1).toDouble());
  }

  (int, int) _distanceBandByLevel(int level) {
    final difficulty = _difficultyScore();
    final target = _targetDistanceForDifficulty(difficulty);
    final tolerance = max(25.0, target * 0.55);

    final minD = max(0.0, target - tolerance).round();
    final maxD = (target + tolerance).round();

    return (minD, maxD);
  }

  _EraMode _chooseEraModeByLevel(int level) {
    final r = _rand.nextDouble();
    final difficulty = _difficultyScore();

    final crossChance = max(0.12, 0.72 * pow(0.9, difficulty - 1).toDouble());
    final modernChance = min(0.70, 0.18 + difficulty * 0.035);

    if (r < crossChance) return _EraMode.cross;
    if (r < crossChance + modernChance) return _EraMode.modern;
    return _EraMode.ancient;
  }

  (Person, Person) _enforceDistanceDifficulty(
    Person a,
    Person b,
    List<Person> unlockedPool,
  ) {
    final (minD, maxD) = _distanceBandByLevel(widget.session.level);
    final target = _targetDistanceForDifficulty(_difficultyScore());

    if (_isModern(a) != _isModern(b)) return (a, b);

    final sameEra = unlockedPool
        .where((p) => _isModern(p) == _isModern(a) && p.id != a.id)
        .toList();

    if (sameEra.isEmpty) return (a, b);

    Person best = b;
    double bestScore = double.infinity;

    for (int tries = 0; tries < 40; tries++) {
      final candidate = sameEra[_rand.nextInt(sameEra.length)];
      final dist = _birthDist(a, candidate).toDouble();

      double score;
      if (dist >= minD && dist <= maxD) {
        score = (dist - target).abs();
      } else {
        score = (dist - target).abs() + 1000;
      }

      if (score < bestScore && candidate.id != a.id) {
        best = candidate;
        bestScore = score;
      }
    }

    return (a, best);
  }

  String _yearLabel(int year) {
    if (year < 0) return '${-year} v. Chr.';
    return '$year';
  }

  String _birthYearFeedback(Question question) {
    final figures = question.figures.isNotEmpty
        ? question.figures
        : [
            if (question.subject != null) question.subject!,
            if (question.a != null) question.a!,
            if (question.b != null) question.b!,
          ];

    final seen = <String>{};
    final labels = <String>[];
    for (final person in figures) {
      if (seen.add(person.id)) {
        final deathLabel = person.deathYear == null
            ? 'Today'
            : _yearLabel(person.deathYear!);
        labels.add(
          '${person.name}: ${_yearLabel(person.birthYear)} - $deathLabel',
        );
      }
    }

    return labels.join(' | ');
  }

  String _feedbackTextForQuestion(
    Question question, {
    required bool isCorrect,
    bool shielded = false,
  }) {
    final lines = <String>[
      if (shielded)
        'Mistake, but your boost protected the streak.'
      else
        (isCorrect ? 'Correct!' : 'Wrong!'),
    ];

    if (_isCategorySpecificQuestionType(question.type)) {
      if (question.supportingLabel != null) {
        lines.add('Clue: ${question.supportingLabel}');
      }
      final answerPerson = question.subject;
      if (answerPerson != null) {
        lines.add('Correct answer: ${answerPerson.name}');
        lines.add('Why it fits: ${answerPerson.hint}');
      }
    }

    if ((question.type == QuestionType.birthplaceMap ||
            question.type == QuestionType.mapEventLocation) &&
        _quizMapKm != null) {
      final radiusKm = widget.session.activeMapRadiusKm;
      lines.add('${_quizMapKm!.round()} km away. Target radius: $radiusKm km.');
      if (question.type == QuestionType.mapEventLocation) {
        final eventLabel = question.supportingLabel ?? 'Historic event';
        final yearSuffix = question.supportingYear == null
            ? ''
            : ' (${question.supportingYear})';
        lines.add('Event location: $eventLabel$yearSuffix');
      } else {
        final person = question.subject;
        if (person != null) {
          final placeLabel = person.birthPlaceLabel ?? person.birthCountry;
          lines.add('Birthplace: $placeLabel, ${person.birthCountry}');
        }
      }
    }

    if (question.type == QuestionType.birthCentury) {
      final subject = question.subject;
      final candidates =
          question.figures
              .where((person) => subject == null || person.id != subject.id)
              .where(
                (person) => person.birthLat != null && person.birthLng != null,
              )
              .toList()
            ..sort(
              (a, b) => _birthLocationDistanceKm(
                subject!,
                a,
              ).compareTo(_birthLocationDistanceKm(subject, b)),
            );
      if (subject != null && candidates.isNotEmpty) {
        final winner = candidates.first;
        final km = _birthLocationDistanceKm(subject, winner).round();
        lines.add(
          '${winner.name} was the closest birthplace to ${subject.name} ($km km).',
        );
        return lines.join('\n');
      }
    }

    lines.add(_birthYearFeedback(question));
    return lines.join('\n');
  }

  Widget? _buildQuizFeedbackSupplement(Question question) {
    if (_isTimelineFeedbackQuestion(question)) {
      return _buildTimeQuestionFeedbackSupplement(question);
    }

    if (question.type == QuestionType.longestLife) {
      return _buildLongestLifeFeedbackSupplement(question);
    }

    if (question.type == QuestionType.birthCentury) {
      return _buildClosestBirthplaceFeedbackSupplement(question);
    }

    if (question.type == QuestionType.northernmostBirthplace ||
        question.type == QuestionType.southernmostBirthplace) {
      return _buildGeoExtremesMapFeedbackSupplement(question);
    }

    if (_isCategorySpecificQuestionType(question.type)) {
      return _buildCategoryFactFeedbackSupplement(question);
    }

    if (question.type != QuestionType.birthplaceMap &&
        question.type != QuestionType.mapEventLocation) {
      return null;
    }

    final isEventMap = question.type == QuestionType.mapEventLocation;
    final person = question.subject;
    final targetLat = isEventMap ? question.supportingLat : person?.birthLat;
    final targetLng = isEventMap ? question.supportingLng : person?.birthLng;
    final placeLabel = isEventMap
        ? (question.supportingLabel ?? 'Historic event')
        : ((person?.birthPlaceLabel ?? person?.birthCountry) ??
              'Unknown location');
    final secondaryLabel = isEventMap
        ? (question.supportingYear == null
              ? null
              : 'Year ${question.supportingYear}')
        : person?.birthCountry;
    if (targetLat == null || targetLng == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFF1E2CB).withValues(alpha: 0.08),
          border: Border.all(
            color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          isEventMap
              ? (secondaryLabel == null
                    ? 'Event: $placeLabel'
                    : 'Event: $placeLabel, $secondaryLabel')
              : 'Birthplace: $placeLabel, ${person!.birthCountry}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF8F0E3),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final target = LatLng(targetLat, targetLng);
    final points = <LatLng>[target];
    if (_quizMapGuess != null) {
      points.add(_quizMapGuess!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Location label
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFF1E2CB).withValues(alpha: 0.08),
            border: Border.all(
              color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isEventMap ? Icons.flag_rounded : Icons.public_rounded,
                color: const Color(0xFFD4B06A),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEventMap
                      ? (secondaryLabel == null
                            ? placeLabel
                            : '$placeLabel, $secondaryLabel')
                      : '$placeLabel, ${person!.birthCountry}',
                  style: const TextStyle(
                    color: Color(0xFFF8F0E3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildFeedbackPill(
                _quizMapKm == null
                    ? 'Radius ${widget.session.activeMapRadiusKm} km'
                    : '${_quizMapKm!.round()} km',
                icon: _quizMapKm == null
                    ? Icons.track_changes_rounded
                    : Icons.route_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Map fills remaining space
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
                ),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _quizMapGuess ?? target,
                  initialZoom: _quizMapGuess == null ? 4.6 : 3.1,
                  initialCameraFit: points.length > 1
                      ? CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(points),
                          padding: const EdgeInsets.all(32),
                        )
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapTileConfig.standardRasterUrlTemplate,
                    userAgentPackageName: MapTileConfig.userAgentPackageName,
                  ),
                  if (_quizMapGuess != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [_quizMapGuess!, target],
                          strokeWidth: 4.5,
                          color: const Color(0xFFD4B06A),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (_quizMapGuess != null)
                        Marker(
                          point: _quizMapGuess!,
                          width: 118,
                          height: 92,
                          child: const _RevealGuessMapMarker(),
                        ),
                      Marker(
                        point: target,
                        width: 118,
                        height: 102,
                        child: isEventMap
                            ? _HistoricEventMapMarker(
                                label: question.supportingLabel ?? 'Event',
                              )
                            : PersonMapMarker(person: person!, unlocked: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFactFeedbackSupplement(Question question) {
    final subject = question.subject;
    if (subject == null) return const SizedBox.shrink();

    final label = switch (question.type) {
      QuestionType.scientistTheory => 'Theory or formula',
      QuestionType.scientistFormula => 'Formula clue',
      QuestionType.scientistDiscovery => 'Discovery clue',
      QuestionType.artistWork => 'Work clue',
      QuestionType.artistQuote => 'Text clue',
      QuestionType.workDescription => 'Work description',
      QuestionType.athleteAchievement => 'Achievement clue',
      QuestionType.sportStatline => 'Statline clue',
      QuestionType.politicianRole => 'Role clue',
      QuestionType.politicianEventMatch => 'Event clue',
      QuestionType.twoCluesOnePerson => 'Two-clue bundle',
      QuestionType.multiClueExpert => 'Expert clue bundle',
      _ => 'Clue',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Portrait card — fills available space
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PersonPortrait(
                  person: subject,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 20,
                  variant: PersonImageVariant.vs,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1F1611).withValues(alpha: 0.97),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Text(
                      subject.name,
                      style: const TextStyle(
                        color: Color(0xFFF8F0E3),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Clue info box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFF1E2CB).withValues(alpha: 0.06),
            border: Border.all(
              color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD4B06A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                question.supportingLabel ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF8F0E3),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subject.hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE6D6BF),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeoExtremesMapFeedbackSupplement(Question question) {
    final figures = question.figures
        .where((p) => p.birthLat != null && p.birthLng != null)
        .toList();
    if (figures.isEmpty) return const SizedBox.shrink();
    final subject = question.subject;
    final isNorth = question.type == QuestionType.northernmostBirthplace;

    final points = figures
        .map((p) => LatLng(p.birthLat!, p.birthLng!))
        .toList();

    final markers = <Marker>[
      for (final person in figures)
        Marker(
          point: LatLng(person.birthLat!, person.birthLng!),
          width: person.id == subject?.id ? 130 : 110,
          height: person.id == subject?.id ? 80 : 68,
          child: _GeoMarkerPin(
            person: person,
            isWinner: person.id == subject?.id,
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
                ),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(56),
                  ),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapTileConfig.standardRasterUrlTemplate,
                    userAgentPackageName: MapTileConfig.userAgentPackageName,
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildFeedbackPillWrap([
          for (final person in figures)
            _buildFeedbackPill(
              '${person.name}: ${person.birthPlaceLabel ?? person.birthCountry}',
              icon: person.id == subject?.id
                  ? (isNorth
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                  : Icons.place_rounded,
            ),
        ]),
      ],
    );
  }

  Widget _buildClosestBirthplaceFeedbackSupplement(Question question) {
    final subject = question.subject;
    if (subject == null ||
        subject.birthLat == null ||
        subject.birthLng == null) {
      return const SizedBox.shrink();
    }

    final candidates = question.figures
        .where((person) => person.id != subject.id)
        .where((person) => person.birthLat != null && person.birthLng != null)
        .toList();
    if (candidates.isEmpty) return const SizedBox.shrink();

    candidates.sort(
      (a, b) => _birthLocationDistanceKm(
        subject,
        a,
      ).compareTo(_birthLocationDistanceKm(subject, b)),
    );
    final winnerId = question.correctOption;
    final points = <LatLng>[
      LatLng(subject.birthLat!, subject.birthLng!),
      for (final person in candidates)
        LatLng(person.birthLat!, person.birthLng!),
    ];

    final markers = <Marker>[
      Marker(
        point: LatLng(subject.birthLat!, subject.birthLng!),
        width: 136,
        height: 84,
        child: _GeoMarkerPin(
          person: subject,
          isWinner: false,
          labelOverride: 'Target',
        ),
      ),
      for (final person in candidates)
        Marker(
          point: LatLng(person.birthLat!, person.birthLng!),
          width: person.name == winnerId ? 130 : 112,
          height: person.name == winnerId ? 80 : 68,
          child: _GeoMarkerPin(
            person: person,
            isWinner: person.name == winnerId,
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
                ),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(56),
                  ),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapTileConfig.standardRasterUrlTemplate,
                    userAgentPackageName: MapTileConfig.userAgentPackageName,
                  ),
                  PolylineLayer(
                    polylines: [
                      for (final person in candidates)
                        Polyline(
                          points: [
                            LatLng(subject.birthLat!, subject.birthLng!),
                            LatLng(person.birthLat!, person.birthLng!),
                          ],
                          strokeWidth: person.name == winnerId ? 4.2 : 2.6,
                          color: person.name == winnerId
                              ? const Color(0xFFD4B06A)
                              : const Color(0xFFE6D6BF).withValues(alpha: 0.45),
                        ),
                    ],
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildFeedbackPillWrap([
          _buildFeedbackPill(
            'Target: ${subject.name}',
            icon: Icons.adjust_rounded,
          ),
          for (final person in candidates)
            _buildFeedbackPill(
              '${person.name}: ${_birthLocationDistanceKm(subject, person).round()} km',
              icon: person.name == winnerId
                  ? Icons.emoji_events_rounded
                  : Icons.route_rounded,
            ),
        ]),
      ],
    );
  }

  Widget _buildLongestLifeFeedbackSupplement(Question question) {
    final figures = question.figures;
    if (figures.isEmpty) return const SizedBox.shrink();
    final currentYear = DateTime.now().year;
    final lifespans = [
      for (final p in figures) (p.deathYear ?? currentYear) - p.birthYear,
    ];
    final maxLifespan = lifespans.reduce((a, b) => a > b ? a : b).toDouble();
    return _QuizLifespanBars(
      figures: figures,
      lifespans: lifespans,
      maxLifespan: maxLifespan,
    );
  }

  bool _isTimelineFeedbackQuestion(Question question) {
    return question.type == QuestionType.birthYear ||
        question.type == QuestionType.earlierPerson ||
        question.type == QuestionType.beforeAfterEvent ||
        question.type == QuestionType.overlap;
  }

  Widget _buildTimeQuestionFeedbackSupplement(Question question) {
    final entries = _timeFeedbackEntries(question);
    if (entries.isEmpty) return const SizedBox.shrink();

    final allYears = [
      for (final e in entries) ...[e.year, if (e.endYear != null) e.endYear!],
    ]..sort();
    final minYear = allYears.first;
    final maxYear = allYears.last;
    final span = max(24, maxYear - minYear);
    final paddedMin = minYear - max(8, span ~/ 8);
    final paddedMax = maxYear + max(8, span ~/ 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4A25), Color(0xFF3A2718)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFD4B06A).withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4B06A).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final lineX = constraints.maxWidth / 2;
                const topPadding = 36.0;
                const bottomPadding = 36.0;
                final bubbleWidth = min(148.0, (constraints.maxWidth - 80) / 2);
                final usableHeight =
                    constraints.maxHeight - topPadding - bottomPadding;

                double yFor(int year) {
                  final t = ((year - paddedMin) / (paddedMax - paddedMin))
                      .clamp(0.0, 1.0);
                  return topPadding + usableHeight * t;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Earlier tag
                    Positioned(
                      left: lineX - 38,
                      top: 0,
                      child: const _TimeAxisTag(
                        label: 'Earlier',
                        icon: Icons.north_rounded,
                      ),
                    ),
                    // Later tag
                    Positioned(
                      left: lineX - 34,
                      bottom: 0,
                      child: const _TimeAxisTag(
                        label: 'Later',
                        icon: Icons.south_rounded,
                      ),
                    ),
                    // Glow track
                    Positioned(
                      left: lineX - 14,
                      top: 28,
                      bottom: 28,
                      child: Container(
                        width: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0x10FFF4D6),
                        ),
                      ),
                    ),
                    // Main gradient line
                    Positioned(
                      left: lineX - 2,
                      top: 28,
                      bottom: 28,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFE1A6),
                              Color(0xFFD4B06A),
                              Color(0xFF8C5A43),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD4B06A,
                              ).withValues(alpha: 0.30),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Entries
                    for (int i = 0; i < entries.length; i++) ...[
                      // Lifespan bar (when endYear set)
                      if (entries[i].endYear != null) ...[
                        Positioned(
                          left: entries[i].alignLeft ? lineX - 9 : lineX + 5,
                          top: yFor(entries[i].year),
                          height:
                              yFor(entries[i].endYear!) - yFor(entries[i].year),
                          child: Container(
                            width: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: entries[i].color.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        // End-year dot
                        Positioned(
                          left: lineX - 1,
                          top: yFor(entries[i].endYear!),
                          child: _TimeAxisMarker(
                            entry: entries[i],
                            small: true,
                          ),
                        ),
                      ],
                      // Birth dot on line
                      Positioned(
                        left: lineX - 1,
                        top: yFor(entries[i].year),
                        child: _TimeAxisMarker(entry: entries[i]),
                      ),
                      // Connector to bubble (from midpoint when lifespan)
                      Positioned(
                        left: entries[i].alignLeft ? lineX - 20 : lineX + 6,
                        top: entries[i].endYear != null
                            ? (yFor(entries[i].year) +
                                      yFor(entries[i].endYear!)) /
                                  2
                            : yFor(entries[i].year),
                        child: Container(
                          width: 14,
                          height: 2,
                          color: entries[i].color.withValues(alpha: 0.80),
                        ),
                      ),
                      // Bubble card (centered on lifespan midpoint)
                      Positioned(
                        left: entries[i].alignLeft
                            ? lineX - bubbleWidth - 20
                            : lineX + 20,
                        top:
                            (entries[i].endYear != null
                                ? (yFor(entries[i].year) +
                                          yFor(entries[i].endYear!)) /
                                      2
                                : yFor(entries[i].year)) -
                            60,
                        width: bubbleWidth,
                        child: _TimeAxisBubble(entry: entries[i]),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        if (question.type != QuestionType.overlap) ...[
          const SizedBox(height: 10),
          _buildFeedbackPillWrap([
            for (final detail in _timeFeedbackDetails(question))
              _buildFeedbackPill(detail.label, icon: detail.icon),
          ]),
        ],
      ],
    );
  }

  List<_TimeFeedbackEntry> _timeFeedbackEntries(Question question) {
    switch (question.type) {
      case QuestionType.birthYear:
        final person = question.subject;
        if (person == null) return const [];
        return [
          _TimeFeedbackEntry(
            label: person.name,
            caption: 'Birth',
            year: person.birthYear,
            color: const Color(0xFFD4B06A),
            icon: Icons.cake_rounded,
            alignLeft: true,
            person: person,
          ),
        ];
      case QuestionType.earlierPerson:
      case QuestionType.overlap:
        final figures = [
          if (question.a != null) question.a!,
          if (question.b != null) question.b!,
        ];
        return [
          for (int i = 0; i < figures.length; i++)
            _TimeFeedbackEntry(
              label: figures[i].name,
              caption: question.type == QuestionType.overlap
                  ? 'Lifespan'
                  : null,
              year: figures[i].birthYear,
              endYear: question.type == QuestionType.overlap
                  ? figures[i].deathYear
                  : null,
              color: i == 0 ? const Color(0xFF4FD198) : const Color(0xFF5DA2FF),
              icon: i == 0 ? Icons.person_rounded : Icons.smart_toy_rounded,
              alignLeft: i.isEven,
              person: figures[i],
            ),
        ];
      case QuestionType.beforeAfterEvent:
        final person = question.subject;
        if (person == null || question.supportingYear == null) return const [];
        return [
          _TimeFeedbackEntry(
            label: person.name,
            caption: 'Birth',
            year: person.birthYear,
            color: const Color(0xFF4FD198),
            icon: Icons.person_rounded,
            alignLeft: true,
            person: person,
          ),
          _TimeFeedbackEntry(
            label: question.supportingLabel ?? 'Event',
            caption: 'Event',
            year: question.supportingYear!,
            color: const Color(0xFFD4B06A),
            icon: Icons.flag_rounded,
            alignLeft: false,
          ),
        ];
      default:
        return const [];
    }
  }

  List<({String label, IconData icon})> _timeFeedbackDetails(
    Question question,
  ) {
    switch (question.type) {
      case QuestionType.birthYear:
        final person = question.subject;
        if (person == null) return const [];
        final deathLabel = person.deathYear == null
            ? 'Today'
            : _yearLabel(person.deathYear!);
        return [
          (
            label: 'Born ${_yearLabel(person.birthYear)}',
            icon: Icons.cake_rounded,
          ),
          (label: 'Died $deathLabel', icon: Icons.hourglass_bottom_rounded),
        ];
      case QuestionType.earlierPerson:
        final figuresE = [
          if (question.a != null) question.a!,
          if (question.b != null) question.b!,
        ];
        return [
          for (final person in figuresE)
            (
              label: '${person.name}: ${_yearLabel(person.birthYear)}',
              icon: Icons.schedule_rounded,
            ),
        ];
      case QuestionType.overlap:
        final figuresO = [
          if (question.a != null) question.a!,
          if (question.b != null) question.b!,
        ];
        return [
          for (final person in figuresO)
            (
              label:
                  '${person.name}: ${_yearLabel(person.birthYear)} – '
                  '${person.deathYear == null ? 'Today' : _yearLabel(person.deathYear!)}',
              icon: Icons.timeline_rounded,
            ),
        ];
      case QuestionType.beforeAfterEvent:
        final person = question.subject;
        if (person == null || question.supportingYear == null) return const [];
        return [
          (
            label: '${person.name}: ${_yearLabel(person.birthYear)}',
            icon: Icons.person_rounded,
          ),
          (
            label:
                '${question.supportingLabel ?? 'Ereignis'}: ${_yearLabel(question.supportingYear!)}',
            icon: Icons.flag_rounded,
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _buildFeedbackPillWrap(List<Widget> children) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: children
          .map(
            (child) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
              child: child,
            ),
          )
          .toList(),
    );
  }

  Widget _buildFeedbackPill(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF1E2CB).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFFD4B06A)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
  // Wheel / XP
  // ============================================================

  Future<Category?> _showWheelDialog() async {
    return showDialog<Category>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool spinning = false;

        List<Color> wheelColors(Category category) {
          final base = _categoryColor(category);
          return [
            Color.lerp(base, Colors.white, 0.16)!,
            Color.lerp(base, Colors.black, 0.12)!,
          ];
        }

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF12274A), Color(0xFF09162D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB78A52).withValues(alpha: 0.20),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Level geschafft',
                        style: TextStyle(
                          color: Color(0xFFD4B06A),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bonus Wheel',
                        style: TextStyle(
                          color: Color(0xFFF8F0E3),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        spinning
                            ? 'The wheel is spinning...'
                            : 'Spin the wheel and reveal your reward afterward.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFE0CFB5),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 300,
                        width: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFF17386D), Color(0xFF09162D)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD4B06A,
                              ).withValues(alpha: 0.12),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: FortuneWheel(
                          selected: _wheelSelected.stream,
                          animateFirst: false,
                          indicators: const [
                            FortuneIndicator(
                              alignment: Alignment.topCenter,
                              child: TriangleIndicator(
                                color: Color(0xFFD4B06A),
                              ),
                            ),
                          ],
                          items: [
                            for (final c in _wheelCategories)
                              FortuneItem(
                                style: FortuneItemStyle(
                                  color: wheelColors(c).first,
                                  borderColor: Colors.white,
                                  borderWidth: 1,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _categoryIcon(c),
                                      color: const Color(0xFFF8F0E3),
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        _categoryLabel(c),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFFF8F0E3),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: spinning
                              ? null
                              : () {
                                  final index = _rand.nextInt(
                                    _wheelCategories.length,
                                  );
                                  _wheelSelected.add(index);
                                  setLocalState(() {
                                    spinning = true;
                                  });

                                  Future.delayed(
                                    const Duration(milliseconds: 3800),
                                    () {
                                      if (!mounted) return;
                                      Navigator.of(
                                        context,
                                      ).pop(_wheelCategories[index]);
                                    },
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F8CFF),
                            foregroundColor: const Color(0xFFF8F0E3),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            spinning ? 'Dreht...' : 'Rad drehen',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showWheelRewardDialog({
    required Category category,
    Person? discovered,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final categoryColor = _categoryColor(category);
        return RewardCardRevealDialog(
          eyebrow: 'Reward!',
          title: 'You won ${_categoryLabel(category)}',
          subtitle: discovered == null
              ? 'No new person was available in this category right now.'
              : '${discovered.name} joins your collection.',
          confirmLabel: 'Continue',
          accentIcon: _categoryIcon(category),
          accentColor: categoryColor,
          accentLabel: _categoryLabel(category),
          person: discovered,
        );
      },
    );
  }

  Future<void> _showBadgeUnlockDialog(List<GameBadge> badges) async {
    for (final badge in badges) {
      final boost = badge.rewardBoost;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C3929), Color(0xFF2A1B12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFF1E2CB).withValues(alpha: 0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: badge.color.withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: badge.color,
                      ),
                      child: Icon(
                        badge.icon,
                        color: const Color(0xFFF8F0E3),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Neuer Badge',
                      style: TextStyle(
                        color: Color(0xFFD4B06A),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF8F0E3),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      badge.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE6D6BF),
                        height: 1.4,
                      ),
                    ),
                    if (boost != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: const Color(
                            0xFFF1E2CB,
                          ).withValues(alpha: 0.08),
                          border: Border.all(
                            color: badge.color.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Temporärer Boost aktiviert: ${boost.name}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: badge.color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              boost.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFE6D6BF)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: badge.color,
                          foregroundColor: const Color(0xFF2D2012),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  List<GameBadge> _mergeBadgeLists(Iterable<List<GameBadge>> badgeLists) {
    final merged = <GameBadge>[];
    final seen = <String>{};

    for (final list in badgeLists) {
      for (final badge in list) {
        if (seen.add(badge.id)) {
          merged.add(badge);
        }
      }
    }

    return merged;
  }

  int _nextXpRequirementForLevel(int level) {
    return GameProgression.xpRequirementForLevel(level);
  }

  int _xpRequirementForCurrentLevel(int targetLevel) {
    return GameProgression.xpRequirementForLevel(targetLevel);
  }

  int _xpRewardForQuestion(Question question) {
    final unlockLevel =
        ProgressionCatalog.questionUnlockLevel(question.type) ?? 1;
    final streakBonus = switch (widget.session.streak) {
      >= 10 => 3,
      >= 6 => 2,
      >= 3 => 1,
      _ => 0,
    };
    final difficultyBonus = switch (unlockLevel) {
      >= 175 => 6,
      >= 120 => 5,
      >= 70 => 3,
      >= 35 => 1,
      _ => 0,
    };

    return 10 +
        streakBonus +
        difficultyBonus +
        widget.session.xpBonusForCorrectAnswer();
  }

  int _coinRewardForQuestion(Question question) {
    final unlockLevel =
        ProgressionCatalog.questionUnlockLevel(question.type) ?? 1;
    final baseReward = unlockLevel >= 85 ? 2 : 1;
    final streakBonus = widget.session.streak >= 8 ? 1 : 0;
    return baseReward + streakBonus;
  }

  int _coinsRewardForLevelUp(int level) {
    if (level >= 150) return 12;
    if (level >= 100) return 10;
    if (level >= 50) return 7;
    return 5;
  }

  void _setDevLevel(int targetLevel) {
    widget.session.level = targetLevel;
    widget.session.xp = 0;
    widget.session.xpToNext = _xpRequirementForCurrentLevel(targetLevel);
    widget.session.save();

    setState(() {
      _tryGenerateQuestion();
      _prepareUnlockUiIfNeeded();
      _feedbackText = null;
      _wasCorrect = null;
      _buttonsLocked = false;
    });

    _showSnackBar('Dev: Level auf $targetLevel gesetzt.');
  }

  void _unlockAllPersonsForDev() {
    for (final person in allPersons) {
      widget.session.statusById[person.id] = PersonStatus.unlocked;
    }
    widget.session.save();

    setState(() {
      _tryGenerateQuestion();
      _prepareUnlockUiIfNeeded();
    });

    _showSnackBar('Dev: All people unlocked.');
  }

  Future<void> _showDevTools() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2A1B12),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        Widget levelButton(int level) {
          return FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _setDevLevel(level);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4B06A),
              foregroundColor: const Color(0xFF2D2012),
            ),
            child: Text('Level $level'),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dev Tools',
                    style: TextStyle(
                      color: Color(0xFFF8F0E3),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Zum schnellen Testen von Mid- und Lategame-Inhalten.',
                    style: TextStyle(color: Color(0xFFE6D6BF), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      levelButton(5),
                      levelButton(10),
                      levelButton(15),
                      levelButton(20),
                      levelButton(25),
                      levelButton(30),
                      levelButton(35),
                      levelButton(40),
                      levelButton(45),
                      levelButton(50),
                      levelButton(55),
                      levelButton(60),
                      levelButton(65),
                      levelButton(70),
                      levelButton(75),
                      levelButton(80),
                      levelButton(85),
                      levelButton(90),
                      levelButton(95),
                      levelButton(100),
                      levelButton(105),
                      levelButton(110),
                      levelButton(115),
                      levelButton(120),
                      levelButton(125),
                      levelButton(130),
                      levelButton(135),
                      levelButton(140),
                      levelButton(145),
                      levelButton(150),
                      levelButton(155),
                      levelButton(160),
                      levelButton(165),
                      levelButton(170),
                      levelButton(175),
                      levelButton(180),
                      levelButton(185),
                      levelButton(190),
                      levelButton(195),
                      levelButton(200),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _unlockAllPersonsForDev();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF8F0E3),
                        side: BorderSide(
                          color: const Color(
                            0xFFD4B06A,
                          ).withValues(alpha: 0.45),
                        ),
                      ),
                      icon: const Icon(Icons.groups_rounded),
                      label: const Text('Alle Personen freischalten'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _gainXp(int amount) async {
    widget.session.xp += amount;

    while (widget.session.xp >= widget.session.xpToNext) {
      final previousLevel = widget.session.level;
      widget.session.xp -= widget.session.xpToNext;
      widget.session.level += 1;
      widget.session.addCoins(_coinsRewardForLevelUp(widget.session.level));
      widget.session.xpToNext = _nextXpRequirementForLevel(
        widget.session.level,
      );

      final newlyUnlockedTypes = GameProgression.newlyUnlockedTypes(
        previousLevel: previousLevel,
        currentLevel: widget.session.level,
      );

      final selectedCategory = await _showWheelDialog();
      if (!mounted) return;

      if (selectedCategory != null) {
        final instantUnlock = widget.session.unlockedPersons.length < 3;
        final discovered = widget.session.discoverFromCategory(
          selectedCategory,
          instantUnlock: instantUnlock,
        );

        if (discovered != null) {
          _preparedUnlockPersonId = null;
          _prepareUnlockUiIfNeeded();
          _tryGenerateQuestion();
        }

        if (!mounted) return;
        await _showWheelRewardDialog(
          category: selectedCategory,
          discovered: discovered,
        );
      }

      for (final type in newlyUnlockedTypes) {
        if (!mounted) return;
        await _showQuestionTypeUnlockDialog(type);
      }
    }
    widget.session.save();
  }
  // ============================================================
  // Normal quiz submit
  // ============================================================

  Future<void> _submitAnswer(String selectedOption) async {
    if (_buttonsLocked || _question == null) return;

    final currentQuestion = _question!;
    final isCorrect = currentQuestion.isCorrect(selectedOption);

    setState(() {
      _buttonsLocked = true;
      _wasCorrect = isCorrect;
      _feedbackText = _feedbackTextForQuestion(
        currentQuestion,
        isCorrect: isCorrect,
      );
    });

    await _showQuizFeedbackDialog();
    if (!mounted) return;

    List<GameBadge> earnedBadges = const [];

    if (isCorrect) {
      widget.session.streak += 1;
      earnedBadges = widget.session.recordQuizAnswer(correct: true);
      final gainedXp = _xpRewardForQuestion(currentQuestion);
      final gainedCoins = _coinRewardForQuestion(currentQuestion);

      widget.session.consumeBoostForCorrectAnswer();
      widget.session.addCoins(gainedCoins);

      await _gainXp(gainedXp);
      if (!mounted) return;
    } else {
      final shielded = widget.session.consumeWrongAnswerShield();
      earnedBadges = widget.session.recordQuizAnswer(correct: false);

      if (shielded) {
        _feedbackText = _feedbackTextForQuestion(
          currentQuestion,
          isCorrect: false,
          shielded: true,
        );
      } else {
        widget.session.streak = 0;
        widget.session.xp = max(0, widget.session.xp - 2);
      }
    }

    if (mounted) {
      setState(() {});
    }
    widget.session.save();

    if (earnedBadges.isNotEmpty && mounted) {
      await _showBadgeUnlockDialog(earnedBadges);
      if (!mounted) return;
    }

    if (widget.adsService != null) {
      await widget.adsService!.registerQuizAnswerAndMaybeShowInterstitial();
      if (!mounted) return;
    }

    if (!mounted) return;
    _advanceQuizAfterFeedback();
  }

  Future<void> _showQuizFeedbackDialog() async {
    if (!mounted || _feedbackText == null || _wasCorrect == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isCorrect = _wasCorrect == true;
        final accent = isCorrect
            ? const Color(0xFFB7A16A)
            : const Color(0xFF8C5A43);
        final supplement = _question == null
            ? null
            : _buildQuizFeedbackSupplement(_question!);

        // Content for the Expanded area
        Widget expandedContent;
        if (supplement != null) {
          expandedContent = supplement;
        } else if (_question?.subject != null) {
          // Show person portrait card filling available space
          final person = _question!.subject!;
          final color = _categoryColor(person.category);
          expandedContent = ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PersonPortrait(
                  person: person,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 20,
                  variant: PersonImageVariant.vs,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1F1611).withValues(alpha: 0.96),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            color: Color(0xFFF8F0E3),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _birthYearFeedback(_question!),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Fallback: styled text block
          final bodyLines = _feedbackText!
              .split('\n')
              .skip(1)
              .join('\n')
              .trim();
          expandedContent = Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFF1E2CB).withValues(alpha: 0.07),
                border: Border.all(
                  color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                bodyLines.isEmpty
                    ? (isCorrect ? 'Great job!' : 'Better luck next time.')
                    : bodyLines,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF8F0E3),
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 36,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: constraints.maxHeight,
                ),
                child: Container(
                  height: constraints.maxHeight,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A3B22), Color(0xFF3B2619)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFFF1E2CB).withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.20),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.18),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isCorrect
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              color: accent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCorrect ? 'Correct!' : 'Wrong!',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                if (_question != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _birthYearFeedback(_question!),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFE6D6BF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Main content — fills remaining space
                      Flexible(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF201713),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE6B968),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    'Richtige Antwort',
                                    'Correct answer',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFFE6B968),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _question!.correctAnswerLabel,
                                  style: const TextStyle(
                                    color: Color(0xFFFFF6E7),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(flex: 3, child: expandedContent),
                      const SizedBox(height: 14),
                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: isCorrect
                                ? const Color(0xFF2D2012)
                                : const Color(0xFFF8EFE1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _advanceQuizAfterFeedback() {
    if (!mounted) return;

    setState(() {
      _tryGenerateQuestion();
      _prepareUnlockUiIfNeeded();
      _feedbackText = null;
      _wasCorrect = null;
      _buttonsLocked = false;
    });
  }
  // ============================================================
  // Unlock flow submit
  // ============================================================

  void _submitBirthYear(Person person, int selectedYear) {
    final correct = selectedYear == person.birthYear;

    if (!correct) {
      _showSnackBar(
        context.tr(
          'Richtige Antwort: ${_yearLabel(person.birthYear)}. Versuche es noch einmal.',
          'Correct answer: ${_yearLabel(person.birthYear)}. Try again.',
        ),
      );

      setState(() {
        _birthYearChoices = GameProgression.generateBirthYearChoices(
          person.birthYear,
          _rand,
        );
      });
      return;
    }

    widget.session.markStepDone(person, UnlockStep.birthYear);
    _showSnackBar(
      context.tr(
        'Richtig: ${_yearLabel(person.birthYear)}.',
        'Correct: ${_yearLabel(person.birthYear)}.',
      ),
    );

    setState(() {
      _resetMapStep();
    });
  }

  void _handleMapTap(Person person, LatLng latLng) {
    if (person.birthLat == null || person.birthLng == null || _mapDone) return;

    final target = LatLng(person.birthLat!, person.birthLng!);
    final km = _distance.as(LengthUnit.Kilometer, latLng, target);

    final radiusKm = widget.session.activeMapRadiusKm;
    final correct = km <= radiusKm;
    widget.session.consumeBoostForMapAttempt();
    final nextAttempts = _mapAttempts + 1;
    final outOfAttempts = !correct && nextAttempts >= 3;

    setState(() {
      _mapGuess = latLng;
      _mapKm = km;
      _mapAttempts = nextAttempts;
      _mapWasCorrect = correct;
      _mapDone = correct || outOfAttempts;
      _mapRevealTarget = _mapDone;
    });

    final answer = Question(
      type: QuestionType.birthplaceMap,
      prompt: '',
      options: const [],
      correctOption: person.birthCountry,
      subject: person,
    ).correctAnswerLabel;
    _showSnackBar(
      context.tr(
        'Richtiger Ort: $answer · ${km.round()} km entfernt · Versuch $nextAttempts/3',
        'Correct location: $answer · ${km.round()} km away · Attempt $nextAttempts/3',
      ),
    );
  }

  Future<void> _confirmMapStep(Person person) async {
    if (!_mapDone) return;

    final badgeProgress = <List<GameBadge>>[
      widget.session.markStepDone(person, UnlockStep.map),
    ];
    if (_mapWasCorrect) {
      badgeProgress.add(widget.session.recordMapSuccess());
    }

    _showSnackBar(
      _mapWasCorrect
          ? 'Map step completed.'
          : 'Location revealed. Map step completed.',
    );

    setState(() {
      _prepareFamousForStep(person);
    });

    final earnedBadges = _mergeBadgeLists(badgeProgress);
    if (earnedBadges.isNotEmpty && mounted) {
      await _showBadgeUnlockDialog(earnedBadges);
    }
  }

  Future<void> _submitFamousForStep(
    Person person,
    String selectedAnswer,
  ) async {
    if (_famousForAnswered) return;

    final quiz = famousForQuiz[person.id];
    if (quiz == null) {
      final earnedBadges = widget.session.markStepDone(
        person,
        UnlockStep.famousFor,
      );
      _preparedUnlockPersonId = null;
      _tryGenerateQuestion();
      setState(() {});
      if (earnedBadges.isNotEmpty && mounted) {
        await _showBadgeUnlockDialog(earnedBadges);
      }
      return;
    }

    final isCorrect = selectedAnswer == quiz.correct;

    setState(() {
      _famousForAnswered = true;
      _famousForWasCorrect = isCorrect;
      _famousForCorrectAnswer = quiz.correct;
    });

    if (isCorrect) {
      final earnedBadges = widget.session.markStepDone(
        person,
        UnlockStep.famousFor,
      );

      _showSnackBar(
        context.tr(
          'Richtige Antwort: ${quiz.correct}. ${person.name} freigeschaltet.',
          'Correct answer: ${quiz.correct}. ${person.name} unlocked.',
        ),
      );

      _preparedUnlockPersonId = null;
      _tryGenerateQuestion();

      setState(() {});

      if (earnedBadges.isNotEmpty && mounted) {
        await _showBadgeUnlockDialog(earnedBadges);
      }
    } else {
      _showSnackBar(
        context.tr(
          'Richtige Antwort: ${quiz.correct}',
          'Correct answer: ${quiz.correct}',
        ),
      );
    }
  }

  void _retryFamousForStep(Person person) {
    setState(() {
      _prepareFamousForStep(person);
    });
  }

  Color _categoryColor(Category category) {
    switch (category) {
      case Category.politician:
        return const Color(0xFF9B6A43);
      case Category.scientist:
        return const Color(0xFF8D7858);
      case Category.artist:
        return const Color(0xFFB07A54);
      case Category.athlete:
        return const Color(0xFF6F6A45);
    }
  }

  IconData _categoryIcon(Category category) {
    switch (category) {
      case Category.politician:
        return Icons.account_balance_rounded;
      case Category.scientist:
        return Icons.biotech_rounded;
      case Category.artist:
        return Icons.palette_rounded;
      case Category.athlete:
        return Icons.emoji_events_rounded;
    }
  }

  Widget _buildPanel(Widget child, {EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF291E19), Color(0xFF1C1512)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFF1E2CB).withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildCompactTopChip({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF1E2CB).withValues(alpha: 0.10),
        border: Border.all(
          color: const Color(0xFFF1E2CB).withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF8F0E3),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTag(String label, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: done
            ? const Color(0xFFD1B17A).withValues(alpha: 0.95)
            : const Color(0xFFF1E2CB).withValues(alpha: 0.10),
      ),
      child: Text(
        done ? '$label OK' : label,
        style: TextStyle(
          color: done ? const Color(0xFF3D2A18) : const Color(0xFFF8F0E3),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTimelineDraggableCard(
    Person person,
    int? slotNumber, {
    bool showLabel = true,
  }) {
    final color = _categoryColor(person.category);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (slotNumber != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$slotNumber',
              style: const TextStyle(
                color: Color(0xFFD4B06A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.75), width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: PersonPortrait(
              person: person,
              width: 84,
              height: 84,
              borderRadius: 42,
              variant: PersonImageVariant.portrait,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 104,
            child: Text(
              person.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // UI builders
  // ============================================================

  Widget _buildMainQuiz({bool fitViewport = false}) {
    return QuizPanel(
      unlockedCount: widget.session.unlockedPersons.length,
      question: _question,
      fitViewport: fitViewport,
      buttonsLocked: _buttonsLocked,
      quizOrderSequence: _quizInteraction.orderSequence,
      quizClosestPairSelection: _quizInteraction.closestPairSelection,
      birthMapGuess: _quizMapGuess,
      birthMapDistanceKm: _quizMapKm,
      birthMapRadiusKm: widget.session.activeMapRadiusKm,
      onSubmitAnswer: _submitAnswer,
      onTapBirthMap: _submitBirthMapGuess,
      onToggleClosestPairSelection: _toggleClosestPairSelection,
      onSubmitOrderSequenceAnswer: _submitOrderSequenceAnswer,
      onOrderSequenceChanged: (nextSequence) {
        setState(() {
          _quizInteraction.setOrderSequence(nextSequence);
        });
      },
      categoryLabel: _categoryLabel,
      categoryColor: _categoryColor,
      timelineCardBuilder: _buildTimelineDraggableCard,
      panelBuilder: _buildPanel,
    );
  }

  Widget _buildUnlockHeader(Person person, String title, String subtitle) {
    final progress = widget.session.progressFor(person.id);
    final color = _categoryColor(person.category);

    return _buildPanel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: color,
                ),
                child: Icon(
                  _categoryIcon(person.category),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        color: Color(0xFFF8F0E3),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _categoryLabel(person.category),
                      style: const TextStyle(
                        color: Color(0xFFE6D6BF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Freischaltung aktiv',
            style: TextStyle(
              color: Color(0xFFD4B06A),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF8F0E3),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFE6D6BF), height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStepTag(
                'Birth year',
                progress.contains(UnlockStep.birthYear),
              ),
              _buildStepTag('Map', progress.contains(UnlockStep.map)),
              _buildStepTag(
                'Known for',
                progress.contains(UnlockStep.famousFor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBirthYearStep(Person person) {
    return UnlockBirthYearStep(
      person: person,
      color: _categoryColor(person.category),
      birthYearChoices: _birthYearChoices,
      onSubmitYear: (year) => _submitBirthYear(person, year),
      headerBuilder: _buildUnlockHeader,
      panelBuilder: _buildPanel,
    );
  }

  Widget _buildMapStep(Person person) {
    return UnlockMapStep(
      person: person,
      color: _categoryColor(person.category),
      mapGuess: _mapGuess,
      mapKm: _mapKm,
      mapDone: _mapDone,
      mapWasCorrect: _mapWasCorrect,
      mapRevealTarget: _mapRevealTarget,
      mapAttempts: _mapAttempts,
      onSkip: () {
        widget.session.markStepDone(person, UnlockStep.map);
        setState(() {
          _prepareFamousForStep(person);
        });
      },
      onConfirm: () => _confirmMapStep(person),
      onTapMap: (latLng) => _handleMapTap(person, latLng),
      headerBuilder: _buildUnlockHeader,
      panelBuilder: _buildPanel,
    );
  }

  Widget _buildSortStep(Person person) {
    return UnlockFamousForStep(
      person: person,
      color: _categoryColor(person.category),
      quiz: famousForQuiz[person.id],
      options: _famousForOptions,
      isAnswered: _famousForAnswered,
      wasCorrect: _famousForWasCorrect,
      correctAnswer: _famousForCorrectAnswer,
      onSkip: () {
        widget.session.markStepDone(person, UnlockStep.famousFor);
        _preparedUnlockPersonId = null;
        _tryGenerateQuestion();
        setState(() {});
      },
      onRetry: () => _retryFamousForStep(person),
      onSubmitAnswer: (answer) => _submitFamousForStep(person, answer),
      headerBuilder: _buildUnlockHeader,
      panelBuilder: _buildPanel,
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final xp = widget.session.xp;
    final xpToNext = widget.session.xpToNext;
    final level = widget.session.level;
    final progress = xpToNext == 0 ? 0.0 : xp / xpToNext;

    final mode = _currentMode();
    final unlockPerson = _activeUnlockPerson;
    final heroColor = unlockPerson == null
        ? const Color(0xFF9E7A4B)
        : _categoryColor(unlockPerson.category);

    Widget content;
    switch (mode) {
      case _GameMode.unlockBirthYear:
        content = _buildBirthYearStep(unlockPerson!);
        break;
      case _GameMode.unlockMap:
        content = _buildMapStep(unlockPerson!);
        break;
      case _GameMode.unlockSort:
        content = _buildSortStep(unlockPerson!);
        break;
      case _GameMode.normalQuiz:
        content = _buildMainQuiz();
        break;
    }

    final activeBoostBadge = widget.session.activeBoostBadge;
    final activeBoost = widget.session.activeBoost;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final activeBoostPanel = activeBoostBadge != null && activeBoost != null
        ? Tooltip(
            message:
                '${activeBoostBadge.title}\n${activeBoostBadge.rewardBoost?.description ?? activeBoostBadge.description}',
            triggerMode: TooltipTriggerMode.tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    activeBoostBadge.icon,
                    color: activeBoostBadge.color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Bonus aktiv · ${activeBoost.chargesLeft} Anwendungen',
                        'Bonus active · ${activeBoost.chargesLeft} charges',
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.info_outline_rounded, size: 16),
                ],
              ),
            ),
          )
        : null;
    final useFixedQuizViewport =
        mode == _GameMode.normalQuiz &&
        unlockPerson == null &&
        MediaQuery.textScalerOf(context).scale(16) <= 20 &&
        viewportHeight >= 640;
    if (useFixedQuizViewport) {
      content = _buildMainQuiz(fitViewport: true);
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 12,
        toolbarHeight: 74,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Text(
                    'Timeline Quiz',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
                  ),
                ),
                const SizedBox(width: 8),
                _buildCompactTopChip(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFFD4B06A),
                  label: 'Lv $level',
                ),
                const SizedBox(width: 6),
                _buildCompactTopChip(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFB7794E),
                  label: '${widget.session.streak}',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0).toDouble(),
                      minHeight: 6,
                      backgroundColor: const Color(
                        0xFFF1E2CB,
                      ).withValues(alpha: 0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFD4B06A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$xp / $xpToNext',
                  style: const TextStyle(
                    color: Color(0xFFE8DCCB),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF8F0E3),
        elevation: 0,
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              onPressed: _showDevTools,
              backgroundColor: const Color(0xFFD4B06A),
              foregroundColor: const Color(0xFF2D2012),
              child: const Icon(Icons.tune_rounded),
            )
          : null,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C2017), Color(0xFF140E0A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: heroColor.withValues(alpha: 0.26),
                    blurRadius: 90,
                    spreadRadius: 18,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4B06A).withValues(alpha: 0.16),
                    blurRadius: 90,
                    spreadRadius: 18,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: useFixedQuizViewport
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (activeBoostPanel != null) ...[
                          activeBoostPanel,
                          const SizedBox(height: 8),
                        ],
                        Expanded(child: content),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (activeBoostPanel != null) ...[
                          activeBoostPanel,
                          const SizedBox(height: 10),
                        ],
                        content,
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoricEventMapMarker extends StatelessWidget {
  final String label;

  const _HistoricEventMapMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD4B06A),
            border: Border.all(color: const Color(0xFFF8F0E3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.flag_rounded,
            color: Color(0xFF2D2012),
            size: 26,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 132),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xCC4C3929),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF1E2CB).withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF8F0E3),
              fontWeight: FontWeight.w700,
              height: 1.1,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _RevealGuessMapMarker extends StatelessWidget {
  const _RevealGuessMapMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF8C5A43),
            border: Border.all(color: const Color(0xFFF8F0E3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.place_rounded,
            color: Color(0xFFF8F0E3),
            size: 28,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 118),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xCC4C3929),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF1E2CB).withValues(alpha: 0.18),
            ),
          ),
          child: const Text(
            'Your Guess',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF8F0E3),
              fontWeight: FontWeight.w700,
              height: 1.1,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeFeedbackEntry {
  final String label;
  final String? caption;
  final int year;
  final int? endYear; // death year for lifespan display
  final Color color;
  final IconData icon;
  final bool alignLeft;
  final Person? person;

  const _TimeFeedbackEntry({
    required this.label,
    required this.year,
    required this.color,
    required this.icon,
    required this.alignLeft,
    this.caption,
    this.endYear,
    this.person,
  });
}

class _TimeAxisTag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _TimeAxisTag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0x3323150E),
        border: Border.all(color: const Color(0x44FFF1C7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD4B06A)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF1E2CB),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeAxisMarker extends StatelessWidget {
  final _TimeFeedbackEntry entry;
  final bool small;

  const _TimeAxisMarker({required this.entry, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 10.0 : 16.0;
    final half = size / 2;
    return Transform.translate(
      offset: Offset(-half, -half),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: small ? entry.color.withValues(alpha: 0.70) : entry.color,
          border: Border.all(
            color: const Color(0xFFF8F0E3),
            width: small ? 1.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: entry.color.withValues(alpha: 0.30),
              blurRadius: small ? 6 : 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: small
            ? null
            : Icon(entry.icon, size: 8, color: const Color(0xFF2D2012)),
      ),
    );
  }
}

class _TimeAxisBubble extends StatelessWidget {
  final _TimeFeedbackEntry entry;

  const _TimeAxisBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1F1611).withValues(alpha: 0.95),
        border: Border.all(
          color: entry.color.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: entry.color.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: entry.alignLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.person != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PersonPortrait(
                person: entry.person!,
                width: double.infinity,
                height: 68,
                borderRadius: 10,
                variant: PersonImageVariant.portrait,
              ),
            ),
            const SizedBox(height: 6),
          ],
          // Year / lifespan range prominently
          Text(
            entry.endYear != null
                ? '${_yearLabelStatic(entry.year)} – ${_yearLabelStatic(entry.endYear!)}'
                : _yearLabelStatic(entry.year),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: entry.alignLeft ? TextAlign.left : TextAlign.right,
            style: TextStyle(
              color: entry.color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            entry.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: entry.alignLeft ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              color: Color(0xFFF8F0E3),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

String _yearLabelStatic(int year) {
  if (year < 0) return '${-year} BC';
  return '$year';
}

class _GeoMarkerPin extends StatelessWidget {
  final Person person;
  final bool isWinner;
  final String? labelOverride;

  const _GeoMarkerPin({
    required this.person,
    required this.isWinner,
    this.labelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWinner ? const Color(0xFF5CCB8A) : const Color(0xFFD4B06A);
    final size = isWinner ? 52.0 : 44.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
            border: Border.all(color: color, width: isWinner ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: PersonPortrait(
              person: person,
              width: size,
              height: size,
              borderRadius: size / 2,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 110),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.85),
          ),
          child: Text(
            labelOverride ?? person.birthPlaceLabel ?? person.birthCountry,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWinner
                  ? const Color(0xFF1B2E20)
                  : const Color(0xFF2D1E0A),
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizLifespanBars extends StatefulWidget {
  final List<Person> figures;
  final List<int> lifespans;
  final double maxLifespan;

  const _QuizLifespanBars({
    required this.figures,
    required this.lifespans,
    required this.maxLifespan,
  });

  @override
  State<_QuizLifespanBars> createState() => _QuizLifespanBarsState();
}

class _QuizLifespanBarsState extends State<_QuizLifespanBars> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) setState(() => _animate = true);
    });
  }

  static const List<Color> _barColors = [
    Color(0xFF4FD198),
    Color(0xFF5DA2FF),
    Color(0xFFE8A86A),
  ];

  @override
  Widget build(BuildContext context) {
    final winnerIdx = widget.lifespans.indexOf(
      widget.lifespans.reduce((a, b) => a > b ? a : b),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < widget.figures.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _buildBar(i, winnerIdx)),
          ],
        ],
      ),
    );
  }

  Widget _buildBar(int i, int winnerIdx) {
    final person = widget.figures[i];
    final years = widget.lifespans[i];
    final ratio = widget.maxLifespan <= 0
        ? 0.0
        : (years / widget.maxLifespan).clamp(0.0, 1.0);
    final isWinner = i == winnerIdx;
    final color = _barColors[i % _barColors.length];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _animate ? years.toDouble() : 0),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => Text(
            '${animated.toStringAsFixed(0)} yrs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isWinner
                  ? const Color(0xFF5CCB8A)
                  : const Color(0xFFF7ECDD).withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _animate ? ratio : 0),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) {
            return Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: animated,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.65),
                          color,
                          Color.lerp(color, Colors.white, 0.25)!,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PersonPortrait(person: person, width: 48, height: 48),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          person.name.split(' ').last,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isWinner ? const Color(0xFF5CCB8A) : color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _HistoricEvent {
  final String label;
  final int year;
  final double lat;
  final double lng;

  const _HistoricEvent(this.label, this.year, this.lat, this.lng);
}
