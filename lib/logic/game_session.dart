import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:shared_preferences/shared_preferences.dart';

import '../battle/battle_models.dart';
import '../battle/battle_session.dart';
import '../data/badges.dart';
import '../data/persons.dart';
import '../models/category.dart';
import '../models/game_badge.dart';
import '../models/person.dart';
import '../models/question.dart';
import '../models/person_status.dart';
import 'progression_catalog.dart';

enum UnlockStep { birthYear, map, famousFor }

enum CardPackOpenStatus { success, insufficientCoins, soldOut }

class PlayerProgressSnapshot {
  final int level;
  final int xp;
  final int xpToNext;
  final int coins;
  final int ownedCards;
  final int discoveredCards;
  final int undiscoveredCards;
  final int earnedBadges;
  final int totalBadges;
  final int totalAnswers;
  final int correctAnswers;
  final int wrongAnswers;
  final int currentStreak;
  final int bestStreak;
  final int mapSuccesses;
  final int perfectSorts;
  final int questionTypesUnlocked;
  final int premiumQuestionUnlocks;
  final int offlineBattlesPlayed;
  final int offlineBattlesWon;
  final int offlineBattlesDrawn;
  final int offlineBattlesLost;

  const PlayerProgressSnapshot({
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.coins,
    required this.ownedCards,
    required this.discoveredCards,
    required this.undiscoveredCards,
    required this.earnedBadges,
    required this.totalBadges,
    required this.totalAnswers,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.currentStreak,
    required this.bestStreak,
    required this.mapSuccesses,
    required this.perfectSorts,
    required this.questionTypesUnlocked,
    required this.premiumQuestionUnlocks,
    required this.offlineBattlesPlayed,
    required this.offlineBattlesWon,
    required this.offlineBattlesDrawn,
    required this.offlineBattlesLost,
  });

  double get accuracy => totalAnswers == 0 ? 0 : correctAnswers / totalAnswers;

  double get levelProgress => xpToNext == 0 ? 0 : xp / xpToNext;

  int get collectionTotal => ownedCards + discoveredCards + undiscoveredCards;
}

class CardPackOpenResult {
  final CardPackOpenStatus status;
  final List<Person> persons;

  const CardPackOpenResult._({required this.status, this.persons = const []});

  const CardPackOpenResult.success(List<Person> persons)
    : this._(status: CardPackOpenStatus.success, persons: persons);

  const CardPackOpenResult.insufficientCoins()
    : this._(status: CardPackOpenStatus.insufficientCoins);

  const CardPackOpenResult.soldOut()
    : this._(status: CardPackOpenStatus.soldOut);

  bool get opened => status == CardPackOpenStatus.success && persons.isNotEmpty;

  Person? get person => persons.isEmpty ? null : persons.first;
}

class GameSession extends ChangeNotifier {
  static const _storageKey = 'game_session_v1';
  final Random _rand = Random();
  Future<void> _pendingWrite = Future<void>.value();

  /// True when a valid saved game was restored for this session.
  bool hasStoredProgress = false;

  static const int maxOpenDiscoveries = 2;

  int xp = 0;
  int level = 1;
  int xpToNext = 25;
  int coins = 0;
  int streak = 0;
  int bestStreak = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  int perfectSorts = 0;
  int mapSuccesses = 0;
  int offlineBattlesPlayed = 0;
  int offlineBattlesWon = 0;
  int offlineBattlesDrawn = 0;
  int offlineBattlesLost = 0;
  int offlineRoundsWon = 0;
  int offlineRoundsDrawn = 0;
  int offlineRoundsLost = 0;
  bool premiumBattleAccess = false;

  final Map<BattleRoundType, int> _offlineRoundWinsByType = {
    for (final type in BattleRoundType.values) type: 0,
  };
  final Map<BattleRoundType, int> _offlineRoundDrawsByType = {
    for (final type in BattleRoundType.values) type: 0,
  };
  final Map<BattleRoundType, int> _offlineRoundLossesByType = {
    for (final type in BattleRoundType.values) type: 0,
  };

  String? lastUnlockedPersonId;

  final Map<String, PersonStatus> statusById = {};
  final Map<String, Set<UnlockStep>> unlockProgressById = {};
  final Set<String> earnedBadgeIds = <String>{};
  final Set<QuestionType> premiumUnlockedQuestionTypes = <QuestionType>{};

  ActiveBadgeBoost? activeBoost;

  GameSession() {
    for (final p in allPersons) {
      statusById[p.id] = PersonStatus.undiscovered;
      unlockProgressById[p.id] = <UnlockStep>{};
    }

    const startUnlockedIds = <String>{};

    for (final id in startUnlockedIds) {
      statusById[id] = PersonStatus.unlocked;
    }

    _evaluateBadges();
  }

  /// Creates a session and restores its locally stored progress, if present.
  static Future<GameSession> load() async {
    final session = GameSession();
    await session._restore();
    return session;
  }

  /// Queues a local save. It is safe to call after direct state changes.
  Future<void> save() {
    // Pure Dart unit tests create sessions without initializing Flutter's
    // platform binding; there is no device storage available in that case.
    if (!_platformStorageAvailable) return Future<void>.value();
    final encoded = jsonEncode(_toJson());
    _pendingWrite = _pendingWrite.catchError((_) {}).then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, encoded);
    });
    return _pendingWrite;
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    unawaited(save());
  }

  Future<void> _restore() async {
    if (!_platformStorageAvailable) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw == null) return;
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return;

      int readInt(String key, int fallback) =>
          data[key] is int ? data[key] as int : fallback;
      bool readBool(String key, bool fallback) =>
          data[key] is bool ? data[key] as bool : fallback;

      xp = readInt('xp', xp);
      level = readInt('level', level);
      xpToNext = readInt('xpToNext', xpToNext);
      coins = readInt('coins', coins);
      streak = readInt('streak', streak);
      bestStreak = readInt('bestStreak', bestStreak);
      correctAnswers = readInt('correctAnswers', correctAnswers);
      wrongAnswers = readInt('wrongAnswers', wrongAnswers);
      perfectSorts = readInt('perfectSorts', perfectSorts);
      mapSuccesses = readInt('mapSuccesses', mapSuccesses);
      offlineBattlesPlayed = readInt(
        'offlineBattlesPlayed',
        offlineBattlesPlayed,
      );
      offlineBattlesWon = readInt('offlineBattlesWon', offlineBattlesWon);
      offlineBattlesDrawn = readInt('offlineBattlesDrawn', offlineBattlesDrawn);
      offlineBattlesLost = readInt('offlineBattlesLost', offlineBattlesLost);
      offlineRoundsWon = readInt('offlineRoundsWon', offlineRoundsWon);
      offlineRoundsDrawn = readInt('offlineRoundsDrawn', offlineRoundsDrawn);
      offlineRoundsLost = readInt('offlineRoundsLost', offlineRoundsLost);
      premiumBattleAccess = readBool(
        'premiumBattleAccess',
        premiumBattleAccess,
      );
      lastUnlockedPersonId = data['lastUnlockedPersonId'] as String?;

      _restoreEnumMap<PersonStatus>(
        data['statusById'],
        PersonStatus.values,
        statusById,
      );
      _restoreUnlockProgress(data['unlockProgressById']);
      _restoreStringSet(data['earnedBadgeIds'], earnedBadgeIds);
      _restoreEnumSet<QuestionType>(
        data['premiumUnlockedQuestionTypes'],
        QuestionType.values,
        premiumUnlockedQuestionTypes,
      );
      _restoreBattleStats(
        data['offlineRoundWinsByType'],
        _offlineRoundWinsByType,
      );
      _restoreBattleStats(
        data['offlineRoundDrawsByType'],
        _offlineRoundDrawsByType,
      );
      _restoreBattleStats(
        data['offlineRoundLossesByType'],
        _offlineRoundLossesByType,
      );

      final boost = data['activeBoost'];
      if (boost is Map<String, dynamic>) {
        final type = BadgeBoostType.values
            .where((value) => value.name == boost['type'])
            .firstOrNull;
        final sourceBadgeId = boost['sourceBadgeId'];
        final chargesLeft = boost['chargesLeft'];
        if (type != null && sourceBadgeId is String && chargesLeft is int) {
          activeBoost = ActiveBadgeBoost(
            type: type,
            sourceBadgeId: sourceBadgeId,
            chargesLeft: chargesLeft,
          );
          _cleanupBoost();
        }
      }
      hasStoredProgress = true;
    } catch (_) {
      // A corrupted or older save must never prevent the game from starting.
    }
  }

  bool get _platformStorageAvailable {
    try {
      WidgetsBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _restoreEnumMap<T extends Enum>(
    Object? raw,
    List<T> values,
    Map<String, T> target,
  ) {
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      final id = entry.key;
      final name = entry.value;
      if (id is! String || name is! String || !target.containsKey(id)) continue;
      final value = values.where((value) => value.name == name).firstOrNull;
      if (value != null) target[id] = value;
    }
  }

  void _restoreUnlockProgress(Object? raw) {
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      if (entry.key is! String ||
          entry.value is! List ||
          !unlockProgressById.containsKey(entry.key)) {
        continue;
      }
      unlockProgressById[entry.key as String] = (entry.value as List)
          .whereType<String>()
          .map(
            (name) => UnlockStep.values
                .where((step) => step.name == name)
                .firstOrNull,
          )
          .whereType<UnlockStep>()
          .toSet();
    }
  }

  void _restoreStringSet(Object? raw, Set<String> target) {
    if (raw is List) target.addAll(raw.whereType<String>());
  }

  void _restoreEnumSet<T extends Enum>(
    Object? raw,
    List<T> values,
    Set<T> target,
  ) {
    if (raw is List) {
      target.addAll(
        raw
            .whereType<String>()
            .map(
              (name) => values.where((value) => value.name == name).firstOrNull,
            )
            .whereType<T>(),
      );
    }
  }

  void _restoreBattleStats(Object? raw, Map<BattleRoundType, int> target) {
    if (raw is! Map) return;
    for (final type in BattleRoundType.values) {
      final value = raw[type.name];
      if (value is int) target[type] = value;
    }
  }

  Map<String, Object?> _toJson() => {
    'xp': xp,
    'level': level,
    'xpToNext': xpToNext,
    'coins': coins,
    'streak': streak,
    'bestStreak': bestStreak,
    'correctAnswers': correctAnswers,
    'wrongAnswers': wrongAnswers,
    'perfectSorts': perfectSorts,
    'mapSuccesses': mapSuccesses,
    'offlineBattlesPlayed': offlineBattlesPlayed,
    'offlineBattlesWon': offlineBattlesWon,
    'offlineBattlesDrawn': offlineBattlesDrawn,
    'offlineBattlesLost': offlineBattlesLost,
    'offlineRoundsWon': offlineRoundsWon,
    'offlineRoundsDrawn': offlineRoundsDrawn,
    'offlineRoundsLost': offlineRoundsLost,
    'premiumBattleAccess': premiumBattleAccess,
    'lastUnlockedPersonId': lastUnlockedPersonId,
    'statusById': statusById.map((id, status) => MapEntry(id, status.name)),
    'unlockProgressById': unlockProgressById.map(
      (id, steps) => MapEntry(id, steps.map((step) => step.name).toList()),
    ),
    'earnedBadgeIds': earnedBadgeIds.toList(),
    'premiumUnlockedQuestionTypes': premiumUnlockedQuestionTypes
        .map((type) => type.name)
        .toList(),
    'offlineRoundWinsByType': _offlineRoundWinsByType.map(
      (type, value) => MapEntry(type.name, value),
    ),
    'offlineRoundDrawsByType': _offlineRoundDrawsByType.map(
      (type, value) => MapEntry(type.name, value),
    ),
    'offlineRoundLossesByType': _offlineRoundLossesByType.map(
      (type, value) => MapEntry(type.name, value),
    ),
    'activeBoost': activeBoost == null
        ? null
        : {
            'type': activeBoost!.type.name,
            'sourceBadgeId': activeBoost!.sourceBadgeId,
            'chargesLeft': activeBoost!.chargesLeft,
          },
  };

  List<Person> get unlockedPersons => allPersons
      .where((p) => statusById[p.id] == PersonStatus.unlocked)
      .toList();

  int get ownedCardCount => unlockedPersons.length;

  bool isFeatureUnlocked(AppFeature feature) {
    return ProgressionCatalog.isFeatureUnlocked(feature, level);
  }

  bool get canAccessBattleMode =>
      premiumBattleAccess || isFeatureUnlocked(AppFeature.battle);

  bool get canAccessCollection => isFeatureUnlocked(AppFeature.collection);

  bool get canAccessMap => isFeatureUnlocked(AppFeature.map);

  int levelsUntilFeature(AppFeature feature) {
    return ProgressionCatalog.levelsUntilFeature(feature, level);
  }

  int get levelsUntilBattleUnlock =>
      premiumBattleAccess ? 0 : levelsUntilFeature(AppFeature.battle);

  int get levelsUntilCollectionUnlock =>
      levelsUntilFeature(AppFeature.collection);

  int get levelsUntilMapUnlock => levelsUntilFeature(AppFeature.map);

  List<Person> get discoveredNotUnlocked => allPersons
      .where((p) => statusById[p.id] == PersonStatus.discovered)
      .toList();

  PlayerProgressSnapshot get progressSnapshot {
    final unlockedQuestionTypes = QuestionType.values
        .where((type) => isQuestionTypeUnlockedForQuiz(type))
        .length;
    return PlayerProgressSnapshot(
      level: level,
      xp: xp,
      xpToNext: xpToNext,
      coins: coins,
      ownedCards: unlockedPersons.length,
      discoveredCards: discoveredNotUnlocked.length,
      undiscoveredCards: undiscoveredCount(),
      earnedBadges: earnedBadgeIds.length,
      totalBadges: allBadges.length,
      totalAnswers: correctAnswers + wrongAnswers,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      currentStreak: streak,
      bestStreak: bestStreak,
      mapSuccesses: mapSuccesses,
      perfectSorts: perfectSorts,
      questionTypesUnlocked: unlockedQuestionTypes,
      premiumQuestionUnlocks: premiumUnlockedQuestionTypes.length,
      offlineBattlesPlayed: offlineBattlesPlayed,
      offlineBattlesWon: offlineBattlesWon,
      offlineBattlesDrawn: offlineBattlesDrawn,
      offlineBattlesLost: offlineBattlesLost,
    );
  }

  int undiscoveredCount({Category? category}) {
    return allPersons.where((p) {
      if (statusById[p.id] != PersonStatus.undiscovered) return false;
      return category == null || p.category == category;
    }).length;
  }

  List<GameBadge> get earnedBadges =>
      allBadges.where((badge) => earnedBadgeIds.contains(badge.id)).toList();

  List<GameBadge> get lockedBadges =>
      allBadges.where((badge) => !earnedBadgeIds.contains(badge.id)).toList();

  bool hasQuestionTypePremiumUnlock(QuestionType type) {
    return premiumUnlockedQuestionTypes.contains(type);
  }

  void applyPremiumQuestionTypeUnlocks(Iterable<QuestionType> types) {
    premiumUnlockedQuestionTypes
      ..clear()
      ..addAll(types);
    notifyListeners();
  }

  void unlockQuestionTypePremium(QuestionType type) {
    if (premiumUnlockedQuestionTypes.add(type)) {
      notifyListeners();
    }
  }

  void applyPremiumBattleAccess(bool enabled) {
    if (premiumBattleAccess == enabled) return;
    premiumBattleAccess = enabled;
    notifyListeners();
  }

  bool isQuestionTypeUnlockedForQuiz(QuestionType type) {
    return (ProgressionCatalog.isQuestionUnlocked(type, level) &&
            type.hasEnoughUnlockedPeople(unlockedPersons.length)) ||
        premiumUnlockedQuestionTypes.contains(type);
  }

  List<Person> grantCapsuleDrops({int count = 3}) {
    final granted = <Person>[];
    for (var i = 0; i < count; i++) {
      final remaining = allPersons
          .where((p) => statusById[p.id] == PersonStatus.undiscovered)
          .toList();
      if (remaining.isEmpty) {
        break;
      }
      final chosen = _drawWeightedCandidate(remaining);
      statusById[chosen.id] = PersonStatus.unlocked;
      unlockProgressById[chosen.id] = <UnlockStep>{};
      lastUnlockedPersonId = chosen.id;
      granted.add(chosen);
    }

    if (granted.isNotEmpty) {
      _evaluateBadges();
      notifyListeners();
    }
    return granted;
  }

  List<Person> unlockPersonsByIds(Iterable<String> personIds) {
    final unlocked = <Person>[];

    for (final id in personIds) {
      Person? person;
      for (final entry in allPersons) {
        if (entry.id == id) {
          person = entry;
          break;
        }
      }
      if (person == null) continue;
      if (statusById[id] == PersonStatus.unlocked) continue;

      statusById[id] = PersonStatus.unlocked;
      unlockProgressById[id] = <UnlockStep>{};
      lastUnlockedPersonId = id;
      unlocked.add(person);
    }

    if (unlocked.isNotEmpty) {
      _evaluateBadges();
      notifyListeners();
    }

    return unlocked;
  }

  GameBadge? badgeById(String badgeId) {
    for (final badge in allBadges) {
      if (badge.id == badgeId) return badge;
    }
    return null;
  }

  Person? discoverFromCategory(
    Category category, {
    bool instantUnlock = false,
  }) {
    if (!instantUnlock && discoveredNotUnlocked.length >= maxOpenDiscoveries) {
      return null;
    }

    final candidates = allPersons
        .where(
          (p) =>
              p.category == category &&
              statusById[p.id] == PersonStatus.undiscovered,
        )
        .toList();

    if (candidates.isEmpty) return null;

    final chosen = _drawWeightedCandidate(candidates);
    statusById[chosen.id] = instantUnlock
        ? PersonStatus.unlocked
        : PersonStatus.discovered;
    unlockProgressById[chosen.id] = <UnlockStep>{};

    if (instantUnlock) {
      lastUnlockedPersonId = chosen.id;
      _evaluateBadges();
    }

    notifyListeners();
    return chosen;
  }

  CardPackOpenResult openCardPack({
    required int cost,
    Category? category,
    int drawCount = 1,
  }) {
    if (coins < cost) {
      return const CardPackOpenResult.insufficientCoins();
    }

    final candidates = allPersons.where((p) {
      if (statusById[p.id] != PersonStatus.undiscovered) return false;
      return category == null || p.category == category;
    }).toList();

    if (candidates.isEmpty) {
      return const CardPackOpenResult.soldOut();
    }

    coins -= cost;
    final granted = <Person>[];
    final remaining = List<Person>.from(candidates);
    for (var i = 0; i < drawCount && remaining.isNotEmpty; i++) {
      final chosen = _drawWeightedCandidate(remaining);
      remaining.removeWhere((person) => person.id == chosen.id);
      statusById[chosen.id] = PersonStatus.unlocked;
      unlockProgressById[chosen.id] = <UnlockStep>{};
      lastUnlockedPersonId = chosen.id;
      granted.add(chosen);
    }

    _evaluateBadges();
    notifyListeners();
    return CardPackOpenResult.success(granted);
  }

  Person _drawWeightedCandidate(List<Person> candidates) {
    final totalWeight = candidates.fold<int>(
      0,
      (sum, person) => sum + person.rarityWeight,
    );
    var roll = _rand.nextInt(totalWeight);
    var chosen = candidates.first;
    for (final candidate in candidates) {
      roll -= candidate.rarityWeight;
      if (roll < 0) {
        chosen = candidate;
        break;
      }
    }
    return chosen;
  }

  Set<UnlockStep> progressFor(String personId) {
    return unlockProgressById.putIfAbsent(personId, () => <UnlockStep>{});
  }

  bool isStepDone(String personId, UnlockStep step) {
    return progressFor(personId).contains(step);
  }

  List<GameBadge> markStepDone(Person person, UnlockStep step) {
    final progress = progressFor(person.id);
    progress.add(step);

    final fullyDone =
        progress.contains(UnlockStep.birthYear) &&
        progress.contains(UnlockStep.map) &&
        progress.contains(UnlockStep.famousFor);

    if (fullyDone) {
      statusById[person.id] = PersonStatus.unlocked;
      lastUnlockedPersonId = person.id;
    }

    final badges = _evaluateBadges();
    notifyListeners();
    return badges;
  }

  bool isFullyUnlocked(String personId) {
    return statusById[personId] == PersonStatus.unlocked;
  }

  Person? get activeUnlockPerson {
    final discovered = discoveredNotUnlocked;
    if (discovered.isEmpty) return null;
    return discovered.first;
  }

  bool get hasActiveBoost => activeBoost?.isActive ?? false;

  GameBadge? get activeBoostBadge =>
      activeBoost == null ? null : badgeById(activeBoost!.sourceBadgeId);

  int get activeMapRadiusKm {
    if (activeBoost?.type == BadgeBoostType.mapGrace && activeBoost!.isActive) {
      return 450;
    }
    return 300;
  }

  int xpBonusForCorrectAnswer() {
    if (activeBoost?.type == BadgeBoostType.xpSurge && activeBoost!.isActive) {
      return 5;
    }
    return 0;
  }

  bool consumeWrongAnswerShield() {
    if (activeBoost?.type == BadgeBoostType.streakShield &&
        activeBoost!.isActive) {
      activeBoost!.chargesLeft -= 1;
      _cleanupBoost();
      notifyListeners();
      return true;
    }
    return false;
  }

  void consumeBoostForCorrectAnswer() {
    if (activeBoost?.type == BadgeBoostType.xpSurge && activeBoost!.isActive) {
      activeBoost!.chargesLeft -= 1;
      _cleanupBoost();
      notifyListeners();
    }
  }

  void consumeBoostForMapAttempt() {
    if (activeBoost?.type == BadgeBoostType.mapGrace && activeBoost!.isActive) {
      activeBoost!.chargesLeft -= 1;
      _cleanupBoost();
      notifyListeners();
    }
  }

  List<GameBadge> recordQuizAnswer({required bool correct}) {
    if (correct) {
      correctAnswers += 1;
      if (streak > bestStreak) {
        bestStreak = streak;
      }
    } else {
      wrongAnswers += 1;
    }

    final badges = _evaluateBadges();
    notifyListeners();
    return badges;
  }

  void addCoins(int amount) {
    if (amount <= 0) return;
    coins += amount;
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (amount <= 0) return true;
    if (coins < amount) return false;
    coins -= amount;
    notifyListeners();
    return true;
  }

  bool purchaseBoost({
    required BadgeBoostType type,
    required int cost,
    required int charges,
  }) {
    if (!spendCoins(cost)) return false;
    activeBoost = ActiveBadgeBoost(
      type: type,
      sourceBadgeId: 'shop',
      chargesLeft: charges,
    );
    notifyListeners();
    return true;
  }

  List<GameBadge> recordMapSuccess() {
    mapSuccesses += 1;
    final badges = _evaluateBadges();
    notifyListeners();
    return badges;
  }

  List<GameBadge> recordPerfectSort() {
    perfectSorts += 1;
    final badges = _evaluateBadges();
    notifyListeners();
    return badges;
  }

  void recordBattleResult({required bool won, required bool draw}) {
    offlineBattlesPlayed += 1;
    if (draw) {
      offlineBattlesDrawn += 1;
    } else if (won) {
      offlineBattlesWon += 1;
    } else {
      offlineBattlesLost += 1;
    }
    notifyListeners();
  }

  void recordOfflineBattleRounds(Iterable<BattleRoundResult> results) {
    var changed = false;
    for (final result in results) {
      changed = true;
      if (result.isDraw) {
        offlineRoundsDrawn += 1;
        _offlineRoundDrawsByType[result.definition.type] =
            (_offlineRoundDrawsByType[result.definition.type] ?? 0) + 1;
      } else if (result.playerWon) {
        offlineRoundsWon += result.playerScoreDelta;
        offlineRoundsLost += result.botScoreDelta;
        _offlineRoundWinsByType[result.definition.type] =
            (_offlineRoundWinsByType[result.definition.type] ?? 0) +
            result.playerScoreDelta;
        if (result.botScoreDelta > 0) {
          _offlineRoundLossesByType[result.definition.type] =
              (_offlineRoundLossesByType[result.definition.type] ?? 0) +
              result.botScoreDelta;
        }
      } else {
        offlineRoundsWon += result.playerScoreDelta;
        offlineRoundsLost += result.botScoreDelta;
        if (result.playerScoreDelta > 0) {
          _offlineRoundWinsByType[result.definition.type] =
              (_offlineRoundWinsByType[result.definition.type] ?? 0) +
              result.playerScoreDelta;
        }
        _offlineRoundLossesByType[result.definition.type] =
            (_offlineRoundLossesByType[result.definition.type] ?? 0) +
            result.botScoreDelta;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  Map<BattleRoundType, int> get offlineRoundWinsByType =>
      Map<BattleRoundType, int>.unmodifiable(_offlineRoundWinsByType);

  Map<BattleRoundType, int> get offlineRoundDrawsByType =>
      Map<BattleRoundType, int>.unmodifiable(_offlineRoundDrawsByType);

  Map<BattleRoundType, int> get offlineRoundLossesByType =>
      Map<BattleRoundType, int>.unmodifiable(_offlineRoundLossesByType);

  double progressForBadge(GameBadge badge) {
    final values = <double>[];

    if (badge.requiredPersonIds.isNotEmpty) {
      final unlocked = badge.requiredPersonIds
          .where((id) => statusById[id] == PersonStatus.unlocked)
          .length;
      values.add(unlocked / badge.requiredPersonIds.length);
    }
    if (badge.requiredStreak != null) {
      values.add((bestStreak / badge.requiredStreak!).clamp(0.0, 1.0));
    }
    if (badge.requiredCorrectAnswers != null) {
      values.add(
        (correctAnswers / badge.requiredCorrectAnswers!).clamp(0.0, 1.0),
      );
    }
    if (badge.requiredPerfectSorts != null) {
      values.add((perfectSorts / badge.requiredPerfectSorts!).clamp(0.0, 1.0));
    }
    if (badge.requiredMapSuccesses != null) {
      values.add((mapSuccesses / badge.requiredMapSuccesses!).clamp(0.0, 1.0));
    }

    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  String progressLabelForBadge(GameBadge badge) {
    if (badge.requiredPersonIds.isNotEmpty) {
      final unlocked = badge.requiredPersonIds
          .where((id) => statusById[id] == PersonStatus.unlocked)
          .length;
      return '$unlocked / ${badge.requiredPersonIds.length} figures';
    }
    if (badge.requiredStreak != null) {
      return '$bestStreak / ${badge.requiredStreak} streak';
    }
    if (badge.requiredCorrectAnswers != null) {
      return '$correctAnswers / ${badge.requiredCorrectAnswers} correct answers';
    }
    if (badge.requiredPerfectSorts != null) {
      return '$perfectSorts / ${badge.requiredPerfectSorts} perfect sorts';
    }
    if (badge.requiredMapSuccesses != null) {
      return '$mapSuccesses / ${badge.requiredMapSuccesses} map hits';
    }
    return 'No progress';
  }

  bool isBadgeEarned(String badgeId) => earnedBadgeIds.contains(badgeId);

  List<GameBadge> _evaluateBadges() {
    final newlyEarned = <GameBadge>[];

    for (final badge in allBadges) {
      if (earnedBadgeIds.contains(badge.id)) continue;
      if (!_meetsBadgeRequirements(badge)) continue;

      earnedBadgeIds.add(badge.id);
      newlyEarned.add(badge);

      if (badge.rewardBoost != null) {
        activeBoost = ActiveBadgeBoost(
          type: badge.rewardBoost!.type,
          sourceBadgeId: badge.id,
          chargesLeft: badge.rewardBoost!.charges,
        );
      }
    }

    return newlyEarned;
  }

  bool _meetsBadgeRequirements(GameBadge badge) {
    if (badge.requiredPersonIds.isNotEmpty) {
      for (final id in badge.requiredPersonIds) {
        if (statusById[id] != PersonStatus.unlocked) return false;
      }
    }
    if (badge.requiredStreak != null && bestStreak < badge.requiredStreak!) {
      return false;
    }
    if (badge.requiredCorrectAnswers != null &&
        correctAnswers < badge.requiredCorrectAnswers!) {
      return false;
    }
    if (badge.requiredPerfectSorts != null &&
        perfectSorts < badge.requiredPerfectSorts!) {
      return false;
    }
    if (badge.requiredMapSuccesses != null &&
        mapSuccesses < badge.requiredMapSuccesses!) {
      return false;
    }
    return true;
  }

  void _cleanupBoost() {
    if (activeBoost != null && !activeBoost!.isActive) {
      activeBoost = null;
    }
  }
}
