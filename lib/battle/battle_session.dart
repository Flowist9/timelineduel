import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../logic/game_session.dart';
import '../models/person.dart';
import 'legendary_abilities.dart';
import 'battle_models.dart';
import 'battle_targets.dart';

class BattleRoundDefinition {
  final BattleRoundType type;
  final String title;
  final String prompt;
  final bool isTiebreaker;
  final BattleRoundInputMode inputMode;
  final BattleYearTarget? yearTarget;
  final BattleLocationTarget? locationTarget;
  final BattleHistoricalEventTarget? historicalEventTarget;

  const BattleRoundDefinition({
    required this.type,
    required this.title,
    required this.prompt,
    this.isTiebreaker = false,
    this.inputMode = BattleRoundInputMode.cardSelection,
    this.yearTarget,
    this.locationTarget,
    this.historicalEventTarget,
  });

  bool get usesDirectGuess => inputMode != BattleRoundInputMode.cardSelection;
}

class BattleRoundResult {
  final int roundNumber;
  final BattleRoundDefinition definition;
  final Person? playerCard;
  final Person? botCard;
  final double playerMetric;
  final double botMetric;
  final bool playerWon;
  final bool isDraw;
  final String explanation;
  final int? playerGuessedYear;
  final int? botGuessedYear;
  final DateTime? playerGuessedDate;
  final DateTime? botGuessedDate;
  final double? playerGuessLat;
  final double? playerGuessLng;
  final double? botGuessLat;
  final double? botGuessLng;
  final int playerScoreDelta;
  final int botScoreDelta;
  final List<String> abilityNotes;

  const BattleRoundResult({
    required this.roundNumber,
    required this.definition,
    required this.playerCard,
    required this.botCard,
    required this.playerMetric,
    required this.botMetric,
    required this.playerWon,
    required this.isDraw,
    required this.explanation,
    this.playerGuessedYear,
    this.botGuessedYear,
    this.playerGuessedDate,
    this.botGuessedDate,
    this.playerGuessLat,
    this.playerGuessLng,
    this.botGuessLat,
    this.botGuessLng,
    this.playerScoreDelta = 0,
    this.botScoreDelta = 0,
    this.abilityNotes = const [],
  });

  bool get isDirectGuessRound => definition.usesDirectGuess;
}

class BattleSession {
  final Random _random;
  final Distance _distance = const Distance();

  final List<Person> playerDeck;
  final List<Person> botDeck;
  final List<BattleRoundDefinition> rounds;

  int currentRoundIndex;
  int playerScore;
  int botScore;
  List<Person> remainingPlayerCards;
  List<Person> remainingBotCards;
  List<BattleRoundResult> history;
  BattleRoundResult? lastResult;

  BattleSession({
    required this.playerDeck,
    required this.botDeck,
    required this.rounds,
    Random? random,
    this.currentRoundIndex = 0,
    this.playerScore = 0,
    this.botScore = 0,
    List<Person>? remainingPlayerCards,
    List<Person>? remainingBotCards,
    List<BattleRoundResult>? history,
    this.lastResult,
  }) : _random = random ?? Random(),
       remainingPlayerCards =
           remainingPlayerCards ?? List<Person>.from(playerDeck),
       remainingBotCards = remainingBotCards ?? List<Person>.from(botDeck),
       history = history ?? <BattleRoundResult>[];

  bool get isFinished => currentRoundIndex >= rounds.length;

  bool get isShowingResult => lastResult != null;

  bool get pendingTiebreakAfterResult =>
      lastResult != null &&
      currentRoundIndex + 1 >= rounds.length &&
      playerScore == botScore;

  BattleRoundDefinition get currentRound => rounds[currentRoundIndex];

  List<Person> get availablePlayerCards => currentRound.usesDirectGuess
      ? const []
      : _cardsForRound(
          currentRound,
          currentRound.isTiebreaker ? playerDeck : remainingPlayerCards,
        );

  List<Person> get availableBotCards => currentRound.usesDirectGuess
      ? const []
      : _cardsForRound(
          currentRound,
          currentRound.isTiebreaker ? botDeck : remainingBotCards,
        );

  BattleRoundResult playRound(Person playerCard) {
    if (currentRound.usesDirectGuess) {
      throw StateError('This round expects a direct guess.');
    }
    if (!availablePlayerCards.any((card) => card.id == playerCard.id)) {
      throw StateError('This card cannot be played in the current round.');
    }

    final botCard = _chooseBotCard();
    final result = _resolveRound(
      definition: currentRound,
      playerCard: playerCard,
      botCard: botCard,
    );

    if (!currentRound.isTiebreaker) {
      remainingPlayerCards.removeWhere((card) => card.id == playerCard.id);
      remainingBotCards.removeWhere((card) => card.id == botCard.id);
    }
    history = [...history, result];
    lastResult = result;
    _applyScore(result);

    return result;
  }

  BattleRoundResult playDateTiebreakGuess(DateTime guessedDate) {
    final target = currentRound.historicalEventTarget;
    if (currentRound.inputMode != BattleRoundInputMode.yearLockGuess ||
        target == null) {
      throw StateError('This round does not expect a date guess.');
    }
    final normalizedGuess = _normalizeDate(guessedDate);
    final targetDate = _normalizeDate(target.date);
    final botGuess = _buildBotDateGuess(targetDate);
    final playerMetric = normalizedGuess
        .difference(targetDate)
        .inDays
        .abs()
        .toDouble();
    final botMetric = botGuess.difference(targetDate).inDays.abs().toDouble();
    final isDraw = playerMetric == botMetric;
    final playerWon = !isDraw && playerMetric < botMetric;
    final result = BattleRoundResult(
      roundNumber: currentRoundIndex + 1,
      definition: currentRound,
      playerCard: null,
      botCard: null,
      playerMetric: playerMetric,
      botMetric: botMetric,
      playerWon: playerWon,
      isDraw: isDraw,
      explanation: isDraw
          ? 'Both date guesses are equally close to the event.'
          : playerWon
          ? 'Your date guess is closer to the event.'
          : 'The bot guess is closer to the event.',
      playerGuessedYear: normalizedGuess.year,
      botGuessedYear: botGuess.year,
      playerGuessedDate: normalizedGuess,
      botGuessedDate: botGuess,
      playerScoreDelta: playerWon ? 1 : 0,
      botScoreDelta: !playerWon && !isDraw ? 1 : 0,
    );
    history = [...history, result];
    lastResult = result;
    _applyScore(result);
    return result;
  }

  BattleRoundResult playLocationTiebreakGuess({
    required double guessedLat,
    required double guessedLng,
  }) {
    final eventTarget = currentRound.historicalEventTarget;
    final fallbackTarget = currentRound.locationTarget;
    if (currentRound.inputMode != BattleRoundInputMode.mapGuess ||
        (eventTarget == null && fallbackTarget == null)) {
      throw StateError('This round does not expect a map guess.');
    }
    final targetLat = eventTarget?.lat ?? fallbackTarget!.lat;
    final targetLng = eventTarget?.lng ?? fallbackTarget!.lng;
    final botGuess = _buildBotLocationGuess(eventTarget, fallbackTarget);
    final playerMetric =
        _distance.as(
          LengthUnit.Meter,
          LatLng(guessedLat, guessedLng),
          LatLng(targetLat, targetLng),
        ) /
        1000;
    final botMetric =
        _distance.as(
          LengthUnit.Meter,
          LatLng(botGuess[0], botGuess[1]),
          LatLng(targetLat, targetLng),
        ) /
        1000;
    final isDraw = playerMetric == botMetric;
    final playerWon = !isDraw && playerMetric < botMetric;
    final result = BattleRoundResult(
      roundNumber: currentRoundIndex + 1,
      definition: currentRound,
      playerCard: null,
      botCard: null,
      playerMetric: playerMetric,
      botMetric: botMetric,
      playerWon: playerWon,
      isDraw: isDraw,
      explanation: isDraw
          ? 'Both location guesses are equally close to the target.'
          : playerWon
          ? 'Your map guess is closer to the target.'
          : 'The bot map guess is closer to the target.',
      playerGuessLat: guessedLat,
      playerGuessLng: guessedLng,
      botGuessLat: botGuess[0],
      botGuessLng: botGuess[1],
      playerScoreDelta: playerWon ? 1 : 0,
      botScoreDelta: !playerWon && !isDraw ? 1 : 0,
    );
    history = [...history, result];
    lastResult = result;
    _applyScore(result);
    return result;
  }

  void advanceAfterResult() {
    if (lastResult == null) return;
    final shouldAppendTiebreak =
        currentRoundIndex + 1 >= rounds.length && playerScore == botScore;
    if (shouldAppendTiebreak) {
      rounds.add(_buildTiebreakerRound());
    }
    currentRoundIndex += 1;
    lastResult = null;
  }

  Person _chooseBotCard() {
    if (availableBotCards.isEmpty) {
      throw StateError('The bot has no playable cards left.');
    }

    final round = currentRound;
    final sorted = [...availableBotCards]
      ..sort((a, b) => _roundScore(round, a).compareTo(_roundScore(round, b)));

    final topCount = min(2, sorted.length);
    return sorted[_random.nextInt(topCount)];
  }

  List<Person> _cardsForRound(
    BattleRoundDefinition definition,
    List<Person> cards,
  ) {
    if (definition.type != BattleRoundType.closerToLocation) {
      return cards;
    }

    final geoCards = cards
        .where((person) => person.birthLat != null && person.birthLng != null)
        .toList();
    return geoCards.isNotEmpty ? geoCards : cards;
  }

  double _roundScore(BattleRoundDefinition definition, Person person) {
    switch (definition.type) {
      case BattleRoundType.bornEarlier:
        return person.birthYear.toDouble();
      case BattleRoundType.longerLife:
        return -_lifespan(person).toDouble();
      case BattleRoundType.closerToYear:
        final target = definition.yearTarget!;
        return (person.birthYear - target.year).abs().toDouble();
      case BattleRoundType.closerToLocation:
        final target = definition.locationTarget!;
        return _birthDistanceKm(person, target);
    }
  }

  BattleRoundResult _resolveRound({
    required BattleRoundDefinition definition,
    required Person playerCard,
    required Person botCard,
  }) {
    switch (definition.type) {
      case BattleRoundType.bornEarlier:
        return _resolveBornEarlier(definition, playerCard, botCard);
      case BattleRoundType.longerLife:
        return _resolveLongerLife(definition, playerCard, botCard);
      case BattleRoundType.closerToYear:
        return _resolveCloserToYear(definition, playerCard, botCard);
      case BattleRoundType.closerToLocation:
        return _resolveCloserToLocation(definition, playerCard, botCard);
    }
  }

  BattleRoundResult _resolveBornEarlier(
    BattleRoundDefinition definition,
    Person playerCard,
    Person botCard,
  ) {
    final playerMetric = playerCard.birthYear.toDouble();
    final botMetric = botCard.birthYear.toDouble();
    return _buildCardRoundResult(
      definition: definition,
      playerCard: playerCard,
      botCard: botCard,
      playerMetric: playerMetric,
      botMetric: botMetric,
      playerWinsWhen: (left, right) => left < right,
      drawExplanation:
          '${playerCard.name} and ${botCard.name} were born in the same year.',
      playerWinExplanation:
          '${playerCard.name} was born earlier than ${botCard.name}.',
      botWinExplanation:
          '${botCard.name} was born earlier than ${playerCard.name}.',
    );
  }

  BattleRoundResult _resolveLongerLife(
    BattleRoundDefinition definition,
    Person playerCard,
    Person botCard,
  ) {
    final playerMetric = _lifespan(playerCard).toDouble();
    final botMetric = _lifespan(botCard).toDouble();
    return _buildCardRoundResult(
      definition: definition,
      playerCard: playerCard,
      botCard: botCard,
      playerMetric: playerMetric,
      botMetric: botMetric,
      playerWinsWhen: (left, right) => left > right,
      drawExplanation:
          '${playerCard.name} and ${botCard.name} have the same lifespan.',
      playerWinExplanation:
          '${playerCard.name} lived longer than ${botCard.name}.',
      botWinExplanation:
          '${botCard.name} lived longer than ${playerCard.name}.',
    );
  }

  BattleRoundResult _resolveCloserToYear(
    BattleRoundDefinition definition,
    Person playerCard,
    Person botCard,
  ) {
    final target = definition.yearTarget!;
    final playerMetric = (playerCard.birthYear - target.year).abs().toDouble();
    final botMetric = (botCard.birthYear - target.year).abs().toDouble();
    return _buildCardRoundResult(
      definition: definition,
      playerCard: playerCard,
      botCard: botCard,
      playerMetric: playerMetric,
      botMetric: botMetric,
      playerWinsWhen: (left, right) => left < right,
      drawExplanation:
          '${playerCard.name} and ${botCard.name} are equally close to ${target.year}.',
      playerWinExplanation:
          '${playerCard.name} is closer to ${target.label} with a gap of ${playerMetric.toStringAsFixed(0)} years.',
      botWinExplanation:
          '${botCard.name} is closer to ${target.label} with a gap of ${botMetric.toStringAsFixed(0)} years.',
    );
  }

  BattleRoundResult _resolveCloserToLocation(
    BattleRoundDefinition definition,
    Person playerCard,
    Person botCard,
  ) {
    final target = definition.locationTarget!;
    final playerMetric = _birthDistanceKm(playerCard, target);
    final botMetric = _birthDistanceKm(botCard, target);
    return _buildCardRoundResult(
      definition: definition,
      playerCard: playerCard,
      botCard: botCard,
      playerMetric: playerMetric,
      botMetric: botMetric,
      playerWinsWhen: (left, right) => left < right,
      drawExplanation:
          '${playerCard.name} and ${botCard.name} are equally close to ${target.label}.',
      playerWinExplanation:
          '${playerCard.name} was born closer to ${target.label}.',
      botWinExplanation: '${botCard.name} was born closer to ${target.label}.',
    );
  }

  BattleRoundResult _buildCardRoundResult({
    required BattleRoundDefinition definition,
    required Person playerCard,
    required Person botCard,
    required double playerMetric,
    required double botMetric,
    required bool Function(double left, double right) playerWinsWhen,
    required String drawExplanation,
    required String playerWinExplanation,
    required String botWinExplanation,
  }) {
    final playerSuppressed = _isSuppressed(
      actor: playerCard,
      opponent: botCard,
    );
    final botSuppressed = _isSuppressed(actor: botCard, opponent: playerCard);
    final abilityNotes = <String>[];

    final adjustedPlayerMetric = _applyMetricAbility(
      definition: definition,
      actor: playerCard,
      opponent: botCard,
      metric: playerMetric,
      suppressed: playerSuppressed,
      abilityNotes: abilityNotes,
    );
    final adjustedBotMetric = _applyMetricAbility(
      definition: definition,
      actor: botCard,
      opponent: playerCard,
      metric: botMetric,
      suppressed: botSuppressed,
      abilityNotes: abilityNotes,
    );

    bool isDraw = adjustedPlayerMetric == adjustedBotMetric;
    bool playerWon =
        !isDraw && playerWinsWhen(adjustedPlayerMetric, adjustedBotMetric);

    final playerCaesar =
        !playerSuppressed &&
        playerCard.id == 'caesar' &&
        definition.isTiebreaker;
    final botCaesar =
        !botSuppressed && botCard.id == 'caesar' && definition.isTiebreaker;
    if (playerCaesar || botCaesar) {
      if (playerCaesar && botCaesar) {
        isDraw = true;
        playerWon = false;
      } else if (playerCaesar) {
        isDraw = false;
        playerWon = true;
        abilityNotes.add('Imperium: Caesar takes the tiebreak automatically.');
      } else {
        isDraw = false;
        playerWon = false;
      }
    }

    final playerNapoleon =
        !playerSuppressed &&
        playerCard.id == 'napoleon' &&
        !playerWon &&
        !isDraw;
    final botNapoleon =
        !botSuppressed && botCard.id == 'napoleon' && playerWon && !isDraw;
    if (playerNapoleon || botNapoleon) {
      isDraw = true;
      playerWon = false;
      abilityNotes.add('Last Stand: Napoleon turns the loss into a draw.');
    }

    final baseExplanation = isDraw
        ? drawExplanation
        : playerWon
        ? playerWinExplanation
        : botWinExplanation;

    var playerScoreDelta = playerWon ? 1 : 0;
    var botScoreDelta = !playerWon && !isDraw ? 1 : 0;

    if (playerWon && !playerSuppressed) {
      if (playerCard.id == 'alexander_great' && currentRoundIndex == 0) {
        playerScoreDelta += 1;
        abilityNotes.add(
          'Blitz Campaign: Alexander adds +1 bonus point in round 1.',
        );
      }
      if (playerCard.id == 'mandela' && _isFourthRegularRound()) {
        playerScoreDelta += 1;
        abilityNotes.add(
          'Comeback Spirit: Mandela adds +1 extra point in round 4.',
        );
      }
      if (playerCard.id == 'jordan' && _isLastRegularRound()) {
        playerScoreDelta += 1;
        abilityNotes.add(
          'Clutch Performer: Jordan adds +1 bonus point in the last regular round.',
        );
      }
      if (playerCard.id == 'mozart' &&
          _triggersMozartBonus(
            definition,
            adjustedPlayerMetric,
            adjustedBotMetric,
          )) {
        playerScoreDelta += 1;
        abilityNotes.add(
          'Perfect Harmony: Mozart earns +1 bonus point for a near-perfect result.',
        );
      }
    }
    if (botScoreDelta > 0 && !botSuppressed) {
      if (botCard.id == 'alexander_great' && currentRoundIndex == 0) {
        botScoreDelta += 1;
      }
      if (botCard.id == 'mandela' && _isFourthRegularRound()) {
        botScoreDelta += 1;
      }
      if (botCard.id == 'jordan' && _isLastRegularRound()) {
        botScoreDelta += 1;
      }
      if (botCard.id == 'mozart' &&
          _triggersMozartBonus(
            definition,
            adjustedBotMetric,
            adjustedPlayerMetric,
          )) {
        botScoreDelta += 1;
      }
    }

    if (!playerSuppressed && playerCard.id == 'einstein') {
      final previews = rounds
          .skip(currentRoundIndex + 1)
          .take(2)
          .map((round) => round.title)
          .toList();
      if (previews.isNotEmpty) {
        abilityNotes.add(
          'Thought Experiment: Next questions -> ${previews.join(' | ')}',
        );
      }
    }

    if (!playerSuppressed &&
        playerCard.id == 'genghis_khan' &&
        _opponentHasAnyLegendaryEffect(botCard)) {
      abilityNotes.add(
        'Suppression: ${botCard.name} cannot use their effect this round.',
      );
    }
    if (!botSuppressed &&
        botCard.id == 'genghis_khan' &&
        _opponentHasAnyLegendaryEffect(playerCard)) {
      abilityNotes.add(
        'Suppression: ${playerCard.name} cannot use their effect this round.',
      );
    }

    return BattleRoundResult(
      roundNumber: currentRoundIndex + 1,
      definition: definition,
      playerCard: playerCard,
      botCard: botCard,
      playerMetric: adjustedPlayerMetric,
      botMetric: adjustedBotMetric,
      playerWon: playerWon,
      isDraw: isDraw,
      explanation: _composeExplanation(baseExplanation, abilityNotes),
      playerScoreDelta: playerScoreDelta,
      botScoreDelta: botScoreDelta,
      abilityNotes: abilityNotes,
    );
  }

  double _applyMetricAbility({
    required BattleRoundDefinition definition,
    required Person actor,
    required Person opponent,
    required double metric,
    required bool suppressed,
    required List<String> abilityNotes,
  }) {
    if (suppressed) return metric;

    switch (actor.id) {
      case 'newton':
        if (definition.type == BattleRoundType.closerToYear) {
          final adjusted = max(0.0, metric - 20);
          if (adjusted != metric) {
            abilityNotes.add(
              'Law of Time: ${actor.name} receives a +/-20 year tolerance.',
            );
          }
          return adjusted;
        }
        return metric;
      case 'leonardo':
        if (definition.type == BattleRoundType.closerToLocation) {
          final adjusted = max(0.0, metric - 100);
          if (adjusted != metric) {
            abilityNotes.add(
              'Master of Many Fields: ${actor.name} receives a 100 km map bonus.',
            );
          }
          return adjusted;
        }
        return metric;
      default:
        return metric;
    }
  }

  bool _isSuppressed({required Person actor, required Person opponent}) {
    return opponent.id == 'genghis_khan' &&
        battleLegendaryAbilityForPersonId(actor.id) != null;
  }

  bool _triggersMozartBonus(
    BattleRoundDefinition definition,
    double winningMetric,
    double losingMetric,
  ) {
    switch (definition.type) {
      case BattleRoundType.closerToYear:
      case BattleRoundType.closerToLocation:
        final threshold = max(1.0, losingMetric * 0.10);
        return winningMetric <= threshold;
      case BattleRoundType.bornEarlier:
      case BattleRoundType.longerLife:
        return false;
    }
  }

  bool _opponentHasAnyLegendaryEffect(Person person) {
    return battleLegendaryAbilityForPersonId(person.id) != null;
  }

  bool _isFourthRegularRound() {
    if (currentRound.isTiebreaker) return false;
    final regularIndex = rounds
        .take(currentRoundIndex + 1)
        .where((round) => !round.isTiebreaker)
        .length;
    return regularIndex == 4;
  }

  bool _isLastRegularRound() {
    if (currentRound.isTiebreaker) return false;
    final totalRegularRounds = rounds
        .where((round) => !round.isTiebreaker)
        .length;
    final regularIndex = rounds
        .take(currentRoundIndex + 1)
        .where((round) => !round.isTiebreaker)
        .length;
    return regularIndex == totalRegularRounds;
  }

  String _composeExplanation(String base, List<String> abilityNotes) {
    if (abilityNotes.isEmpty) return base;
    return '$base\n\n${abilityNotes.join('\n')}';
  }

  void _applyScore(BattleRoundResult result) {
    playerScore += result.playerScoreDelta;
    botScore += result.botScoreDelta;
  }

  double _birthDistanceKm(Person person, BattleLocationTarget target) {
    if (person.birthLat == null || person.birthLng == null) {
      return 20000;
    }

    final meters = _distance.as(
      LengthUnit.Meter,
      LatLng(person.birthLat!, person.birthLng!),
      LatLng(target.lat, target.lng),
    );
    return meters / 1000;
  }

  int _lifespan(Person person) {
    final endYear = person.deathYear ?? DateTime.now().year;
    return max(0, endYear - person.birthYear);
  }

  BattleRoundDefinition _buildTiebreakerRound() {
    final event = randomBattleHistoricalEventTarget(_random);
    if (_random.nextBool()) {
      return BattleRoundDefinition(
        type: BattleRoundType.closerToLocation,
        title: 'Tiebreak: Where was it?',
        prompt: 'Tiebreak for the win. ${event.locationPrompt}',
        isTiebreaker: true,
        inputMode: BattleRoundInputMode.mapGuess,
        historicalEventTarget: event,
      );
    }

    return BattleRoundDefinition(
      type: BattleRoundType.closerToYear,
      title: 'Tiebreak: When was it?',
      prompt: 'Tiebreak for the win. ${event.datePrompt}',
      isTiebreaker: true,
      inputMode: BattleRoundInputMode.yearLockGuess,
      historicalEventTarget: event,
    );
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  DateTime _buildBotDateGuess(DateTime targetDate) {
    final offsetDays = 25 + _random.nextInt(2200);
    final direction = _random.nextBool() ? -1 : 1;
    return _normalizeDate(
      targetDate.add(Duration(days: offsetDays * direction)),
    );
  }

  List<double> _buildBotLocationGuess(
    BattleHistoricalEventTarget? eventTarget,
    BattleLocationTarget? fallbackTarget,
  ) {
    final baseLat = eventTarget?.lat ?? fallbackTarget!.lat;
    final baseLng = eventTarget?.lng ?? fallbackTarget!.lng;
    final latOffset = (_random.nextDouble() * 22) - 11;
    final lngOffset = (_random.nextDouble() * 28) - 14;
    final lat = (baseLat + latOffset).clamp(-75.0, 75.0);
    final lng = baseLng + lngOffset;
    final normalizedLng = lng > 180
        ? lng - 360
        : (lng < -180 ? lng + 360 : lng);
    return [lat, normalizedLng];
  }
}

class BattleSessionFactory {
  final Random _random;

  BattleSessionFactory({Random? random}) : _random = random ?? Random();

  BattleSession create({
    required GameSession session,
    required List<Person> playerDeck,
  }) {
    final botDeck = _buildBotDeck(session: session, playerDeck: playerDeck);
    final rounds = _buildRounds(playerDeck: playerDeck, botDeck: botDeck);

    return BattleSession(
      playerDeck: playerDeck,
      botDeck: botDeck,
      rounds: rounds,
      random: _random,
    );
  }

  List<Person> _buildBotDeck({
    required GameSession session,
    required List<Person> playerDeck,
  }) {
    final owned = session.unlockedPersons;
    final selected = <Person>[];
    final usedIds = <String>{};

    for (final slotType in defaultBattleDraftSlots) {
      final playerCard = playerDeck.firstWhere((card) => slotType.allows(card));
      final strictPool = owned
          .where(
            (person) =>
                slotType.allows(person) &&
                person.id != playerCard.id &&
                !usedIds.contains(person.id),
          )
          .toList();
      final relaxedPool = owned
          .where(
            (person) => slotType.allows(person) && !usedIds.contains(person.id),
          )
          .toList();
      final pool = strictPool.isNotEmpty ? strictPool : relaxedPool;
      final choice = pool[_random.nextInt(pool.length)];
      selected.add(choice);
      usedIds.add(choice.id);
    }

    return selected;
  }

  List<BattleRoundDefinition> _buildRounds({
    required List<Person> playerDeck,
    required List<Person> botDeck,
  }) {
    final yearTarget = randomBattleYearTarget(_random);
    final locationTarget = randomBattleLocationTarget(_random);

    final hasGeoBattle =
        playerDeck.any(
          (person) => person.birthLat != null && person.birthLng != null,
        ) &&
        botDeck.any(
          (person) => person.birthLat != null && person.birthLng != null,
        );

    final rounds = <BattleRoundDefinition>[
      const BattleRoundDefinition(
        type: BattleRoundType.bornEarlier,
        title: 'Who was born earlier?',
        prompt: 'Which played figure was born earlier?',
      ),
      const BattleRoundDefinition(
        type: BattleRoundType.longerLife,
        title: 'Who lived longer?',
        prompt: 'Which played figure had the longer lifespan?',
      ),
      BattleRoundDefinition(
        type: BattleRoundType.closerToYear,
        title: 'Who is closer to the event?',
        prompt: yearTarget.context,
        yearTarget: yearTarget,
      ),
      if (hasGeoBattle)
        BattleRoundDefinition(
          type: BattleRoundType.closerToLocation,
          title: 'Who is closer to the place?',
          prompt: locationTarget.context,
          locationTarget: locationTarget,
        )
      else
        const BattleRoundDefinition(
          type: BattleRoundType.bornEarlier,
          title: 'Who was born earlier?',
          prompt: 'Which played figure was born earlier?',
        ),
    ]..shuffle(_random);

    if (hasGeoBattle) {
      final locationIndex = rounds.indexWhere(
        (round) => round.type == BattleRoundType.closerToLocation,
      );
      if (locationIndex > 1) {
        final locationRound = rounds.removeAt(locationIndex);
        rounds.insert(1, locationRound);
      }
    }

    return rounds;
  }
}
