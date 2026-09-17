import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../battle/battle_draft_builder.dart';
import '../battle/battle_models.dart';
import '../battle/battle_targets.dart';
import '../logic/game_session.dart';
import '../models/person.dart';
import 'online_battle_repository.dart';
import 'online_identity.dart';
import 'online_models.dart';

class OnlineBattleStats {
  final int rating;
  final int openMatches;
  final int completedMatches;
  final int wins;
  final int losses;
  final int draws;
  final int roundsWon;
  final int roundsLost;

  const OnlineBattleStats({
    required this.rating,
    required this.openMatches,
    required this.completedMatches,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.roundsWon,
    required this.roundsLost,
  });
}

class OnlineFriendStats extends OnlineBattleStats {
  final DateTime? friendsSince;

  const OnlineFriendStats({
    required super.rating,
    required this.friendsSince,
    required super.openMatches,
    required super.completedMatches,
    required super.wins,
    required super.losses,
    required super.draws,
    required super.roundsWon,
    required super.roundsLost,
  });
}

class OnlineBattleController extends ChangeNotifier {
  final OnlineBackendKind backendKind;
  final OnlineIdentityGateway _identityGateway;
  final OnlineBattleRepository _repository;

  StreamSubscription<OnlineBattleProfile?>? _profileSub;
  StreamSubscription<List<OnlineBattleProfile>>? _leaderboardSub;
  StreamSubscription<List<OnlineFriendRequest>>? _friendRequestsSub;
  StreamSubscription<List<OnlineBattleInvite>>? _invitesSub;
  StreamSubscription<List<AsyncBattleMatch>>? _matchesSub;

  bool _isBootstrapping = false;
  bool _isReady = false;
  String? _userId;
  String? _errorMessage;
  OnlineBattleProfile? _profile;
  List<OnlineBattleProfile> _leaderboard = const [];
  List<OnlineFriendRequest> _friendRequests = const [];
  List<OnlineBattleInvite> _invites = const [];
  List<AsyncBattleMatch> _matches = const [];
  final Random _random = Random();

  OnlineBattleController({
    required this.backendKind,
    required OnlineIdentityGateway identityGateway,
    required OnlineBattleRepository repository,
  }) : _identityGateway = identityGateway,
       _repository = repository;

  bool get isBootstrapping => _isBootstrapping;
  bool get isReady => _isReady;
  bool get usesFirebase => backendKind == OnlineBackendKind.firebase;
  bool get isOfflineMode => backendKind == OnlineBackendKind.localFallback;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  OnlineBattleProfile? get profile => _profile;
  List<OnlineBattleProfile> get leaderboard => _leaderboard;
  List<OnlineFriendRequest> get friendRequests => _friendRequests;
  List<OnlineBattleInvite> get invites => _invites;
  List<AsyncBattleMatch> get matches => _matches;
  bool get needsDisplayNameSetup {
    final profile = _profile;
    final uid = _userId;
    if (profile == null || uid == null) return true;
    return profile.displayName.trim() == _defaultDisplayNameFor(uid);
  }

  List<OnlineFriendRequest> get incomingFriendRequests {
    final uid = _userId;
    if (uid == null) return const [];
    return _friendRequests
        .where(
          (request) =>
              request.toUserId == uid &&
              request.status == OnlineFriendRequestStatus.pending,
        )
        .toList();
  }

  List<OnlineBattleProfile> get friends {
    final uid = _userId;
    if (uid == null) return const [];
    return _friendRequests
        .where((request) => request.isAcceptedFor(uid))
        .map(
          (request) => OnlineBattleProfile(
            userId: request.otherUserId(uid),
            displayName: request.otherDisplayName(uid),
            friendCode: request.otherFriendCode(uid),
            rating: 1000,
            createdAt: request.createdAt,
            updatedAt: request.updatedAt,
          ),
        )
        .toList();
  }

  List<OnlineBattleInvite> get incomingBattleInvites {
    final uid = _userId;
    if (uid == null) return const [];
    return _invites
        .where(
          (invite) =>
              invite.targetUserId == uid &&
              invite.status == OnlineBattleInviteStatus.open,
        )
        .toList();
  }

  AsyncBattleMatch? matchById(String matchId) {
    for (final match in _matches) {
      if (match.id == matchId) return match;
    }
    return null;
  }

  List<AsyncBattleDraftSlot> draftSlotsForMatch(AsyncBattleMatch match) {
    final uid = _userId;
    if (uid == null) return const [];
    return match.draftSlotsFor(uid);
  }

  bool isDraftReadyForCurrentUser(AsyncBattleMatch match) {
    final uid = _userId;
    if (uid == null) return false;
    final slots = match.draftSlotsFor(uid);
    return slots.length == battleDeckSize &&
        slots.every((slot) => slot.isComplete);
  }

  Future<void> bootstrap() async {
    if (_isBootstrapping || _isReady) return;
    _isBootstrapping = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = await _identityGateway.signIn();
      _userId = uid;
      _bindStreams(uid);
      final now = DateTime.now();
      final existing = await _repository.fetchProfile(uid);
      if (existing == null) {
        await _repository.saveProfile(
          OnlineBattleProfile(
            userId: uid,
            displayName: _defaultDisplayNameFor(uid),
            friendCode: _buildFriendCode(uid),
            rating: 1000,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else if (existing.friendCode.isEmpty) {
        await _repository.saveProfile(
          existing.copyWith(friendCode: _buildFriendCode(uid), updatedAt: now),
        );
      }
      _isReady = true;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  void _bindStreams(String uid) {
    _profileSub?.cancel();
    _leaderboardSub?.cancel();
    _friendRequestsSub?.cancel();
    _invitesSub?.cancel();
    _matchesSub?.cancel();

    _profileSub = _repository.watchProfile(uid).listen((profile) {
      _profile = profile;
      notifyListeners();
    });
    _leaderboardSub = _repository.watchTopProfiles().listen((profiles) {
      _leaderboard = profiles;
      notifyListeners();
    });
    _friendRequestsSub = _repository.watchFriendRequestsForUser(uid).listen((
      requests,
    ) {
      _friendRequests = requests;
      notifyListeners();
    });
    _invitesSub = _repository.watchInvitesForUser(uid).listen((invites) {
      _invites = invites;
      notifyListeners();
    });
    _matchesSub = _repository.watchMatchesForUser(uid).listen((matches) {
      _matches = matches;
      notifyListeners();
    });
  }

  Future<void> updateDisplayName(String displayName) async {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Online profile is not initialized yet.');
    }
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw StateError('Please enter a name.');
    }
    final now = DateTime.now();
    await _repository.saveProfile(
      OnlineBattleProfile(
        userId: uid,
        displayName: trimmed,
        friendCode: _profile?.friendCode ?? _buildFriendCode(uid),
        rating: _profile?.rating ?? 1000,
        createdAt: _profile?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> sendFriendRequest(String friendCode) async {
    final profile = _profile;
    if (profile == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    await _repository.sendFriendRequest(
      fromProfile: profile,
      targetFriendCode: friendCode.trim().toUpperCase(),
    );
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    await _repository.acceptFriendRequest(requestId: requestId, userId: uid);
  }

  Future<void> removeFriend(String friendUserId) async {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    await _repository.removeFriend(userId: uid, friendUserId: friendUserId);
  }

  int? get leaderboardRank {
    final profile = _profile;
    if (profile == null) return null;
    for (var index = 0; index < _leaderboard.length; index += 1) {
      if (_leaderboard[index].userId == profile.userId) {
        return index + 1;
      }
    }
    return null;
  }

  OnlineBattleStats get overallStats {
    final uid = _userId;
    if (uid == null) {
      return const OnlineBattleStats(
        rating: 1000,
        openMatches: 0,
        completedMatches: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        roundsWon: 0,
        roundsLost: 0,
      );
    }
    return _aggregateStats(
      rating: _profile?.rating ?? 1000,
      matches: _matches.where((match) => match.involvesUser(uid)),
      currentUserId: uid,
    );
  }

  OnlineFriendRequest? friendshipFor(String friendUserId) {
    final uid = _userId;
    if (uid == null) return null;
    for (final request in _friendRequests) {
      if (request.status == OnlineFriendRequestStatus.accepted &&
          request.involves(uid) &&
          request.involves(friendUserId)) {
        return request;
      }
    }
    return null;
  }

  OnlineFriendStats statsForFriend(String friendUserId) {
    final uid = _userId;
    if (uid == null) {
      return const OnlineFriendStats(
        rating: 1000,
        friendsSince: null,
        openMatches: 0,
        completedMatches: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        roundsWon: 0,
        roundsLost: 0,
      );
    }

    OnlineBattleProfile? friend;
    for (final entry in friends) {
      if (entry.userId == friendUserId) {
        friend = entry;
        break;
      }
    }
    final friendship = friendshipFor(friendUserId);
    final relevantMatches = _matches.where((match) {
      final opponentId = match.host.userId == uid
          ? match.guest?.userId
          : match.host.userId;
      return opponentId == friendUserId;
    });
    final aggregate = _aggregateStats(
      rating: friend?.rating ?? 1000,
      matches: relevantMatches,
      currentUserId: uid,
    );
    return OnlineFriendStats(
      rating: aggregate.rating,
      friendsSince: friendship?.updatedAt,
      openMatches: aggregate.openMatches,
      completedMatches: aggregate.completedMatches,
      wins: aggregate.wins,
      losses: aggregate.losses,
      draws: aggregate.draws,
      roundsWon: aggregate.roundsWon,
      roundsLost: aggregate.roundsLost,
    );
  }

  OnlineBattleStats _aggregateStats({
    required int rating,
    required Iterable<AsyncBattleMatch> matches,
    required String currentUserId,
  }) {
    var openMatches = 0;
    var completedMatches = 0;
    var wins = 0;
    var losses = 0;
    var draws = 0;
    var roundsWon = 0;
    var roundsLost = 0;

    for (final match in matches) {
      final myScore = match.host.userId == currentUserId
          ? match.hostScore
          : match.guestScore;
      final otherScore = match.host.userId == currentUserId
          ? match.guestScore
          : match.hostScore;
      roundsWon += myScore;
      roundsLost += otherScore;
      if (match.isCompleted) {
        completedMatches += 1;
        if (myScore > otherScore) {
          wins += 1;
        } else if (myScore < otherScore) {
          losses += 1;
        } else {
          draws += 1;
        }
      } else {
        openMatches += 1;
      }
    }

    return OnlineBattleStats(
      rating: rating,
      openMatches: openMatches,
      completedMatches: completedMatches,
      wins: wins,
      losses: losses,
      draws: draws,
      roundsWon: roundsWon,
      roundsLost: roundsLost,
    );
  }

  Future<OnlineBattleInvite> createInvite({
    required GameSession session,
    required OnlineBattleProfile friend,
  }) async {
    final profile = _profile;
    if (profile == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    final draftSlots = _buildDraftSlots(session);
    return _repository.createInvite(
      hostProfile: profile,
      targetUserId: friend.userId,
      targetDisplayName: friend.displayName,
      hostDraftSlots: draftSlots,
    );
  }

  Future<AsyncBattleMatch> joinInvite({
    required String inviteId,
    required GameSession session,
  }) async {
    final profile = _profile;
    if (profile == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    final draftSlots = _buildDraftSlots(session);
    final rounds = _buildRoundSeeds(_buildSuggestedDeck(session));
    return _repository.acceptInvite(
      inviteId: inviteId,
      guestProfile: profile,
      guestDraftSlots: draftSlots,
      rounds: rounds,
    );
  }

  Future<AsyncBattleMatch> startRandomMatchmaking({
    required GameSession session,
    int maxOpenSearches = 3,
    int ratingRange = 150,
  }) async {
    final profile = _profile;
    if (profile == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    final draftSlots = _buildDraftSlots(session);
    final rounds = _buildRoundSeeds(_buildSuggestedDeck(session));
    return _repository.createOrJoinRandomMatch(
      playerProfile: profile,
      draftSlots: draftSlots,
      rounds: rounds,
      maxOpenSearches: maxOpenSearches,
      ratingRange: ratingRange,
    );
  }

  Future<void> submitDraft({
    required String matchId,
    required List<String> selectedCardIds,
  }) async {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    await _repository.submitDraft(
      matchId: matchId,
      userId: uid,
      selectedCardIds: selectedCardIds,
    );
  }

  List<AsyncBattleDeckCard> availableCardsForMatch(AsyncBattleMatch match) {
    final uid = _userId;
    if (uid == null) return const [];
    final deck = match.deckFor(uid);
    final round = match.currentRound;
    if ((round?.inputMode ?? BattleRoundInputMode.cardSelection) !=
        BattleRoundInputMode.cardSelection) {
      return const [];
    }
    if (round?.isTiebreaker ?? false) {
      return deck;
    }
    final usedIds = match.usedCardIdsFor(uid).toSet();
    return deck.where((card) => !usedIds.contains(card.personId)).toList();
  }

  bool canSubmitMove(AsyncBattleMatch match) {
    final uid = _userId;
    if (uid == null || match.isCompleted) return false;
    if (!isDraftReadyForCurrentUser(match)) return false;
    return match.usedCardIdsFor(uid).length < match.rounds.length;
  }

  int nextRoundIndexForCurrentUser(AsyncBattleMatch match) {
    final uid = _userId;
    if (uid == null) return 0;
    return match.submittedRoundCountFor(uid);
  }

  Future<void> submitMove({
    required String matchId,
    String? cardId,
    int? guessedYear,
    String? guessedDateIso,
    double? guessedLat,
    double? guessedLng,
  }) async {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    await _repository.submitMove(
      matchId: matchId,
      userId: uid,
      cardId: cardId,
      guessedYear: guessedYear,
      guessedDateIso: guessedDateIso,
      guessedLat: guessedLat,
      guessedLng: guessedLng,
    );
  }

  Future<void> leaveMatch(String matchId) async {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    await _repository.leaveMatchForUser(matchId: matchId, userId: uid);
  }

  Future<void> leaveAllOpenMatches() async {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Online-Profil noch nicht bereit.');
    }
    await _repository.leaveAllOpenMatchesForUser(userId: uid);
  }

  List<Person> _buildSuggestedDeck(GameSession session) {
    final owned = session.unlockedPersons;
    final usedIds = <String>{};
    final deck = <Person>[];

    for (final slot in defaultBattleDraftSlots) {
      Person? card;
      for (final candidate in owned) {
        if (slot.allows(candidate) && !usedIds.contains(candidate.id)) {
          card = candidate;
          break;
        }
      }
      if (card != null) {
        deck.add(card);
        usedIds.add(card.id);
      }
    }

    if (deck.length < battleDeckSize) {
      for (final person in owned) {
        if (usedIds.add(person.id)) {
          deck.add(person);
        }
        if (deck.length == battleDeckSize) break;
      }
    }

    return deck.take(battleDeckSize).toList();
  }

  List<AsyncBattleDraftSlot> _buildDraftSlots(GameSession session) {
    final result = BattleDraftBuilder().buildForSession(session);
    final state = result.state;
    if (state == null || !result.canStartDraft) {
      throw StateError('At least 4 playable cards are required.');
    }
    return state.slots
        .map(
          (slot) => AsyncBattleDraftSlot(
            type: slot.type,
            candidates: slot.candidates
                .map(AsyncBattleDeckCard.fromPerson)
                .toList(),
            selectedCardId: null,
          ),
        )
        .toList();
  }

  List<AsyncBattleRoundSeed> _buildRoundSeeds(List<Person> deck) {
    final yearTarget = randomBattleYearTarget(_random);
    final locationTarget = randomBattleLocationTarget(_random);
    final hasGeoBattle = deck.any(
      (person) => person.birthLat != null && person.birthLng != null,
    );

    final rounds = <AsyncBattleRoundSeed>[
      const AsyncBattleRoundSeed(
        type: BattleRoundType.bornEarlier,
        title: 'Who was born earlier?',
        prompt: 'Which played figure was born earlier?',
      ),
      const AsyncBattleRoundSeed(
        type: BattleRoundType.longerLife,
        title: 'Who lived longer?',
        prompt: 'Which played figure had the longer lifespan?',
      ),
      AsyncBattleRoundSeed(
        type: BattleRoundType.closerToYear,
        title: 'Who is closer to the event?',
        prompt: yearTarget.context,
        inputMode: BattleRoundInputMode.cardSelection,
        yearLabel: yearTarget.label,
        yearTarget: yearTarget.year,
      ),
      hasGeoBattle
          ? AsyncBattleRoundSeed(
              type: BattleRoundType.closerToLocation,
              title: 'Who is closer to the place?',
              prompt: locationTarget.context,
              inputMode: BattleRoundInputMode.cardSelection,
              locationLabel: locationTarget.label,
              locationLat: locationTarget.lat,
              locationLng: locationTarget.lng,
            )
          : const AsyncBattleRoundSeed(
              type: BattleRoundType.bornEarlier,
              title: 'Who was born earlier?',
              prompt: 'Which played figure was born earlier?',
            ),
    ];

    return rounds;
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _leaderboardSub?.cancel();
    _friendRequestsSub?.cancel();
    _invitesSub?.cancel();
    _matchesSub?.cancel();
    super.dispose();
  }

  String _buildFriendCode(String uid) {
    final normalized = uid
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    return normalized.length >= 6
        ? normalized.substring(0, 6)
        : normalized.padRight(6, 'X');
  }

  String _defaultDisplayNameFor(String uid) {
    return 'Player ${uid.substring(0, 4).toUpperCase()}';
  }
}
