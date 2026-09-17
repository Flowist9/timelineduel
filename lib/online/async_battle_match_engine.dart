import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../battle/battle_models.dart';
import '../battle/legendary_abilities.dart';
import 'online_models.dart';

class AsyncBattleResolution {
  final double hostMetric;
  final double guestMetric;
  final bool hostWon;
  final bool isDraw;
  final String explanation;
  final int hostScoreDelta;
  final int guestScoreDelta;
  final List<String> abilityNotes;

  const AsyncBattleResolution({
    required this.hostMetric,
    required this.guestMetric,
    required this.hostWon,
    required this.isDraw,
    required this.explanation,
    this.hostScoreDelta = 0,
    this.guestScoreDelta = 0,
    this.abilityNotes = const [],
  });
}

class AsyncBattleMatchEngine {
  static final Distance _distance = const Distance();

  static AsyncBattleResolution resolve({
    required AsyncBattleRoundSeed round,
    required int roundIndex,
    required List<AsyncBattleRoundSeed> rounds,
    AsyncBattleDeckCard? hostCard,
    AsyncBattleDeckCard? guestCard,
    AsyncBattleGuessSubmission? hostGuess,
    AsyncBattleGuessSubmission? guestGuess,
  }) {
    if (round.inputMode == BattleRoundInputMode.yearLockGuess) {
      return _resolveYearGuess(round, hostGuess, guestGuess);
    }
    if (round.inputMode == BattleRoundInputMode.mapGuess) {
      return _resolveLocationGuess(round, hostGuess, guestGuess);
    }
    switch (round.type) {
      case BattleRoundType.bornEarlier:
        return _resolveBornEarlier(
          round: round,
          roundIndex: roundIndex,
          rounds: rounds,
          hostCard: hostCard!,
          guestCard: guestCard!,
        );
      case BattleRoundType.longerLife:
        return _resolveLongerLife(
          round: round,
          roundIndex: roundIndex,
          rounds: rounds,
          hostCard: hostCard!,
          guestCard: guestCard!,
        );
      case BattleRoundType.closerToYear:
        return _resolveCloserToYear(
          round: round,
          roundIndex: roundIndex,
          rounds: rounds,
          hostCard: hostCard!,
          guestCard: guestCard!,
        );
      case BattleRoundType.closerToLocation:
        return _resolveCloserToLocation(
          round: round,
          roundIndex: roundIndex,
          rounds: rounds,
          hostCard: hostCard!,
          guestCard: guestCard!,
        );
    }
  }

  static AsyncBattleResolution _resolveYearGuess(
    AsyncBattleRoundSeed round,
    AsyncBattleGuessSubmission? hostGuess,
    AsyncBattleGuessSubmission? guestGuess,
  ) {
    final targetDate = round.historicalEventDateIso != null
        ? DateTime.parse(round.historicalEventDateIso!).toUtc()
        : DateTime.utc(round.yearTarget ?? 1900, 1, 1);
    final hostDate = _parseGuessDate(hostGuess) ?? targetDate;
    final guestDate = _parseGuessDate(guestGuess) ?? targetDate;
    final hostMetric = hostDate.difference(targetDate).inDays.abs().toDouble();
    final guestMetric = guestDate
        .difference(targetDate)
        .inDays
        .abs()
        .toDouble();
    final isDraw = hostMetric == guestMetric;
    final hostWon = !isDraw && hostMetric < guestMetric;
    return AsyncBattleResolution(
      hostMetric: hostMetric,
      guestMetric: guestMetric,
      hostWon: hostWon,
      isDraw: isDraw,
      explanation: isDraw
          ? 'Both date guesses are equally close to the target.'
          : hostWon
          ? 'The host guess is closer to the event.'
          : 'The opponent guess is closer to the event.',
      hostScoreDelta: hostWon ? 1 : 0,
      guestScoreDelta: !hostWon && !isDraw ? 1 : 0,
    );
  }

  static AsyncBattleResolution _resolveLocationGuess(
    AsyncBattleRoundSeed round,
    AsyncBattleGuessSubmission? hostGuess,
    AsyncBattleGuessSubmission? guestGuess,
  ) {
    final targetLat = round.historicalEventLat ?? round.locationLat;
    final targetLng = round.historicalEventLng ?? round.locationLng;
    final hostMetric = _guessDistanceKm(
      hostGuess?.guessedLat,
      hostGuess?.guessedLng,
      targetLat,
      targetLng,
    );
    final guestMetric = _guessDistanceKm(
      guestGuess?.guessedLat,
      guestGuess?.guessedLng,
      targetLat,
      targetLng,
    );
    final isDraw = hostMetric == guestMetric;
    final hostWon = !isDraw && hostMetric < guestMetric;
    return AsyncBattleResolution(
      hostMetric: hostMetric,
      guestMetric: guestMetric,
      hostWon: hostWon,
      isDraw: isDraw,
      explanation: isDraw
          ? 'Both map guesses are equally close to the target.'
          : hostWon
          ? 'The host guess is closer to the target.'
          : 'The opponent guess is closer to the target.',
      hostScoreDelta: hostWon ? 1 : 0,
      guestScoreDelta: !hostWon && !isDraw ? 1 : 0,
    );
  }

  static AsyncBattleResolution _resolveBornEarlier({
    required AsyncBattleRoundSeed round,
    required int roundIndex,
    required List<AsyncBattleRoundSeed> rounds,
    required AsyncBattleDeckCard hostCard,
    required AsyncBattleDeckCard guestCard,
  }) {
    return _buildCardResolution(
      round: round,
      roundIndex: roundIndex,
      rounds: rounds,
      hostCard: hostCard,
      guestCard: guestCard,
      hostMetric: hostCard.birthYear.toDouble(),
      guestMetric: guestCard.birthYear.toDouble(),
      hostWinsWhen: (left, right) => left < right,
      drawExplanation:
          '${hostCard.name} and ${guestCard.name} were born in the same year.',
      hostWinExplanation:
          '${hostCard.name} was born earlier than ${guestCard.name}.',
      guestWinExplanation:
          '${guestCard.name} was born earlier than ${hostCard.name}.',
    );
  }

  static AsyncBattleResolution _resolveLongerLife({
    required AsyncBattleRoundSeed round,
    required int roundIndex,
    required List<AsyncBattleRoundSeed> rounds,
    required AsyncBattleDeckCard hostCard,
    required AsyncBattleDeckCard guestCard,
  }) {
    return _buildCardResolution(
      round: round,
      roundIndex: roundIndex,
      rounds: rounds,
      hostCard: hostCard,
      guestCard: guestCard,
      hostMetric: _lifespan(hostCard).toDouble(),
      guestMetric: _lifespan(guestCard).toDouble(),
      hostWinsWhen: (left, right) => left > right,
      drawExplanation:
          '${hostCard.name} and ${guestCard.name} have the same lifespan.',
      hostWinExplanation:
          '${hostCard.name} lived longer than ${guestCard.name}.',
      guestWinExplanation:
          '${guestCard.name} lived longer than ${hostCard.name}.',
    );
  }

  static AsyncBattleResolution _resolveCloserToYear({
    required AsyncBattleRoundSeed round,
    required int roundIndex,
    required List<AsyncBattleRoundSeed> rounds,
    required AsyncBattleDeckCard hostCard,
    required AsyncBattleDeckCard guestCard,
  }) {
    final targetYear = round.yearTarget ?? hostCard.birthYear;
    final hostMetric = (hostCard.birthYear - targetYear).abs().toDouble();
    final guestMetric = (guestCard.birthYear - targetYear).abs().toDouble();
    return _buildCardResolution(
      round: round,
      roundIndex: roundIndex,
      rounds: rounds,
      hostCard: hostCard,
      guestCard: guestCard,
      hostMetric: hostMetric,
      guestMetric: guestMetric,
      hostWinsWhen: (left, right) => left < right,
      drawExplanation:
          '${hostCard.name} and ${guestCard.name} are equally close to ${round.yearLabel ?? targetYear}.',
      hostWinExplanation:
          '${hostCard.name} is closer to ${round.yearLabel ?? targetYear}.',
      guestWinExplanation:
          '${guestCard.name} is closer to ${round.yearLabel ?? targetYear}.',
    );
  }

  static AsyncBattleResolution _resolveCloserToLocation({
    required AsyncBattleRoundSeed round,
    required int roundIndex,
    required List<AsyncBattleRoundSeed> rounds,
    required AsyncBattleDeckCard hostCard,
    required AsyncBattleDeckCard guestCard,
  }) {
    final label = round.locationLabel ?? 'the target place';
    final hostMetric = _distanceKm(
      hostCard,
      round.locationLat,
      round.locationLng,
    );
    final guestMetric = _distanceKm(
      guestCard,
      round.locationLat,
      round.locationLng,
    );
    return _buildCardResolution(
      round: round,
      roundIndex: roundIndex,
      rounds: rounds,
      hostCard: hostCard,
      guestCard: guestCard,
      hostMetric: hostMetric,
      guestMetric: guestMetric,
      hostWinsWhen: (left, right) => left < right,
      drawExplanation:
          '${hostCard.name} and ${guestCard.name} are equally close to $label.',
      hostWinExplanation: '${hostCard.name} was born closer to $label.',
      guestWinExplanation: '${guestCard.name} was born closer to $label.',
    );
  }

  static AsyncBattleResolution _buildCardResolution({
    required AsyncBattleRoundSeed round,
    required int roundIndex,
    required List<AsyncBattleRoundSeed> rounds,
    required AsyncBattleDeckCard hostCard,
    required AsyncBattleDeckCard guestCard,
    required double hostMetric,
    required double guestMetric,
    required bool Function(double left, double right) hostWinsWhen,
    required String drawExplanation,
    required String hostWinExplanation,
    required String guestWinExplanation,
  }) {
    final hostSuppressed = _isSuppressed(actor: hostCard, opponent: guestCard);
    final guestSuppressed = _isSuppressed(actor: guestCard, opponent: hostCard);
    final abilityNotes = <String>[];

    final adjustedHostMetric = _applyMetricAbility(
      round: round,
      actor: hostCard,
      metric: hostMetric,
      suppressed: hostSuppressed,
      abilityNotes: abilityNotes,
    );
    final adjustedGuestMetric = _applyMetricAbility(
      round: round,
      actor: guestCard,
      metric: guestMetric,
      suppressed: guestSuppressed,
      abilityNotes: abilityNotes,
    );

    bool isDraw = adjustedHostMetric == adjustedGuestMetric;
    bool hostWon =
        !isDraw && hostWinsWhen(adjustedHostMetric, adjustedGuestMetric);

    final hostCaesar =
        !hostSuppressed && hostCard.personId == 'caesar' && round.isTiebreaker;
    final guestCaesar =
        !guestSuppressed &&
        guestCard.personId == 'caesar' &&
        round.isTiebreaker;
    if (hostCaesar || guestCaesar) {
      if (hostCaesar && guestCaesar) {
        isDraw = true;
        hostWon = false;
      } else if (hostCaesar) {
        isDraw = false;
        hostWon = true;
        abilityNotes.add('Imperium: Caesar takes the tiebreak automatically.');
      } else {
        isDraw = false;
        hostWon = false;
      }
    }

    final hostNapoleon =
        !hostSuppressed &&
        hostCard.personId == 'napoleon' &&
        !hostWon &&
        !isDraw;
    final guestNapoleon =
        !guestSuppressed &&
        guestCard.personId == 'napoleon' &&
        hostWon &&
        !isDraw;
    if (hostNapoleon || guestNapoleon) {
      isDraw = true;
      hostWon = false;
      abilityNotes.add('Last Stand: Napoleon turns the loss into a draw.');
    }

    final baseExplanation = isDraw
        ? drawExplanation
        : hostWon
        ? hostWinExplanation
        : guestWinExplanation;

    var hostScoreDelta = hostWon ? 1 : 0;
    var guestScoreDelta = !hostWon && !isDraw ? 1 : 0;

    if (hostWon && !hostSuppressed) {
      if (hostCard.personId == 'alexander_great' && roundIndex == 0) {
        hostScoreDelta += 1;
        abilityNotes.add(
          'Blitz Campaign: Alexander adds +1 bonus point in round 1.',
        );
      }
      if (hostCard.personId == 'mandela' &&
          _isFourthRegularRound(rounds, roundIndex)) {
        hostScoreDelta += 1;
        abilityNotes.add(
          'Comeback Spirit: Mandela adds +1 extra point in round 4.',
        );
      }
      if (hostCard.personId == 'jordan' &&
          _isLastRegularRound(rounds, roundIndex)) {
        hostScoreDelta += 1;
        abilityNotes.add(
          'Clutch Performer: Jordan adds +1 bonus point in the last regular round.',
        );
      }
      if (hostCard.personId == 'mozart' &&
          _triggersMozartBonus(
            round,
            adjustedHostMetric,
            adjustedGuestMetric,
          )) {
        hostScoreDelta += 1;
        abilityNotes.add(
          'Perfect Harmony: Mozart earns +1 bonus point for a near-perfect result.',
        );
      }
    }
    if (guestScoreDelta > 0 && !guestSuppressed) {
      if (guestCard.personId == 'alexander_great' && roundIndex == 0) {
        guestScoreDelta += 1;
      }
      if (guestCard.personId == 'mandela' &&
          _isFourthRegularRound(rounds, roundIndex)) {
        guestScoreDelta += 1;
      }
      if (guestCard.personId == 'jordan' &&
          _isLastRegularRound(rounds, roundIndex)) {
        guestScoreDelta += 1;
      }
      if (guestCard.personId == 'mozart' &&
          _triggersMozartBonus(
            round,
            adjustedGuestMetric,
            adjustedHostMetric,
          )) {
        guestScoreDelta += 1;
      }
    }

    if (!hostSuppressed && hostCard.personId == 'einstein') {
      final previews = rounds
          .skip(roundIndex + 1)
          .take(2)
          .map((entry) => entry.title)
          .toList();
      if (previews.isNotEmpty) {
        abilityNotes.add(
          'Thought Experiment: Next questions -> ${previews.join(' | ')}',
        );
      }
    }

    if (!hostSuppressed &&
        hostCard.personId == 'genghis_khan' &&
        battleLegendaryAbilityForPersonId(guestCard.personId) != null) {
      abilityNotes.add(
        'Suppression: ${guestCard.name} cannot use their effect this round.',
      );
    }
    if (!guestSuppressed &&
        guestCard.personId == 'genghis_khan' &&
        battleLegendaryAbilityForPersonId(hostCard.personId) != null) {
      abilityNotes.add(
        'Suppression: ${hostCard.name} cannot use their effect this round.',
      );
    }

    return AsyncBattleResolution(
      hostMetric: adjustedHostMetric,
      guestMetric: adjustedGuestMetric,
      hostWon: hostWon,
      isDraw: isDraw,
      explanation: _composeExplanation(baseExplanation, abilityNotes),
      hostScoreDelta: hostScoreDelta,
      guestScoreDelta: guestScoreDelta,
      abilityNotes: abilityNotes,
    );
  }

  static double _applyMetricAbility({
    required AsyncBattleRoundSeed round,
    required AsyncBattleDeckCard actor,
    required double metric,
    required bool suppressed,
    required List<String> abilityNotes,
  }) {
    if (suppressed) return metric;

    switch (actor.personId) {
      case 'newton':
        if (round.type == BattleRoundType.closerToYear) {
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
        if (round.type == BattleRoundType.closerToLocation) {
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

  static bool _triggersMozartBonus(
    AsyncBattleRoundSeed round,
    double winningMetric,
    double losingMetric,
  ) {
    switch (round.type) {
      case BattleRoundType.closerToYear:
      case BattleRoundType.closerToLocation:
        final threshold = max(1.0, losingMetric * 0.10);
        return winningMetric <= threshold;
      case BattleRoundType.bornEarlier:
      case BattleRoundType.longerLife:
        return false;
    }
  }

  static bool _isSuppressed({
    required AsyncBattleDeckCard actor,
    required AsyncBattleDeckCard opponent,
  }) {
    return opponent.personId == 'genghis_khan' &&
        battleLegendaryAbilityForPersonId(actor.personId) != null;
  }

  static bool _isFourthRegularRound(
    List<AsyncBattleRoundSeed> rounds,
    int roundIndex,
  ) {
    if (rounds[roundIndex].isTiebreaker) return false;
    final regularIndex = rounds
        .take(roundIndex + 1)
        .where((round) => !round.isTiebreaker)
        .length;
    return regularIndex == 4;
  }

  static bool _isLastRegularRound(
    List<AsyncBattleRoundSeed> rounds,
    int roundIndex,
  ) {
    if (rounds[roundIndex].isTiebreaker) return false;
    final totalRegularRounds = rounds
        .where((round) => !round.isTiebreaker)
        .length;
    final regularIndex = rounds
        .take(roundIndex + 1)
        .where((round) => !round.isTiebreaker)
        .length;
    return regularIndex == totalRegularRounds;
  }

  static String _composeExplanation(String base, List<String> abilityNotes) {
    if (abilityNotes.isEmpty) return base;
    return '$base\n\n${abilityNotes.join('\n')}';
  }

  static int _lifespan(AsyncBattleDeckCard card) {
    final endYear = card.deathYear ?? DateTime.now().year;
    return max(0, endYear - card.birthYear);
  }

  static double _distanceKm(
    AsyncBattleDeckCard card,
    double? targetLat,
    double? targetLng,
  ) {
    if (card.birthLat == null ||
        card.birthLng == null ||
        targetLat == null ||
        targetLng == null) {
      return 20000;
    }
    final meters = _distance.as(
      LengthUnit.Meter,
      LatLng(card.birthLat!, card.birthLng!),
      LatLng(targetLat, targetLng),
    );
    return meters / 1000;
  }

  static DateTime? _parseGuessDate(AsyncBattleGuessSubmission? guess) {
    if (guess?.guessedDateIso != null) {
      return DateTime.tryParse(guess!.guessedDateIso!)?.toUtc();
    }
    if (guess?.guessedYear != null) {
      return DateTime.utc(guess!.guessedYear!, 1, 1);
    }
    return null;
  }

  static double _guessDistanceKm(
    double? guessLat,
    double? guessLng,
    double? targetLat,
    double? targetLng,
  ) {
    if (guessLat == null ||
        guessLng == null ||
        targetLat == null ||
        targetLng == null) {
      return 20000;
    }
    final meters = _distance.as(
      LengthUnit.Meter,
      LatLng(guessLat, guessLng),
      LatLng(targetLat, targetLng),
    );
    return meters / 1000;
  }
}
