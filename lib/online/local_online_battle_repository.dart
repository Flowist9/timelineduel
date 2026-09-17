import 'dart:async';
import 'dart:math';

import '../battle/battle_models.dart';
import '../battle/battle_targets.dart';
import 'async_battle_match_engine.dart';
import 'online_battle_repository.dart';
import 'online_identity.dart';
import 'online_models.dart';

class LocalOnlineIdentityGateway implements OnlineIdentityGateway {
  final String _userId = 'local_${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<String> signIn() async => _userId;
}

class LocalOnlineBattleRepository implements OnlineBattleRepository {
  final Map<String, OnlineBattleProfile> _profilesByUser = {};
  final Map<String, OnlineFriendRequest> _friendRequestsById = {};
  final Map<String, OnlineBattleInvite> _invitesById = {};
  final Map<String, AsyncBattleMatch> _matchesById = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final Random _random = Random();

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  @override
  Future<OnlineBattleProfile?> fetchProfile(String userId) async {
    return _profilesByUser[userId];
  }

  @override
  Stream<OnlineBattleProfile?> watchProfile(String userId) async* {
    yield _profilesByUser[userId];
    yield* _changes.stream.map((_) => _profilesByUser[userId]);
  }

  @override
  Future<void> saveProfile(OnlineBattleProfile profile) async {
    _profilesByUser[profile.userId] = profile;
    _emit();
  }

  @override
  Future<OnlineBattleProfile?> findProfileByFriendCode(
    String friendCode,
  ) async {
    try {
      return _profilesByUser.values.firstWhere(
        (profile) =>
            profile.friendCode.toUpperCase() == friendCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<OnlineBattleProfile>> watchTopProfiles({int limit = 25}) async* {
    List<OnlineBattleProfile> profiles() {
      final values = _profilesByUser.values.toList()
        ..sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          if (byRating != 0) return byRating;
          return a.updatedAt.compareTo(b.updatedAt);
        });
      return values.take(limit).toList();
    }

    yield profiles();
    yield* _changes.stream.map((_) => profiles());
  }

  @override
  Stream<List<OnlineFriendRequest>> watchFriendRequestsForUser(
    String userId,
  ) async* {
    List<OnlineFriendRequest> requests() {
      final values =
          _friendRequestsById.values
              .where((request) => request.involves(userId))
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return values;
    }

    yield requests();
    yield* _changes.stream.map((_) => requests());
  }

  @override
  Future<OnlineFriendRequest> sendFriendRequest({
    required OnlineBattleProfile fromProfile,
    required String targetFriendCode,
  }) async {
    final target = await findProfileByFriendCode(targetFriendCode);
    if (target == null) {
      throw StateError('Friend code not found.');
    }
    if (target.userId == fromProfile.userId) {
      throw StateError('Du kannst dich nicht selbst hinzufuegen.');
    }
    final existing = _friendRequestsById.values.where((request) {
      final direct =
          request.fromUserId == fromProfile.userId &&
          request.toUserId == target.userId;
      final reverse =
          request.fromUserId == target.userId &&
          request.toUserId == fromProfile.userId;
      return direct || reverse;
    });
    if (existing.any(
      (request) => request.status == OnlineFriendRequestStatus.accepted,
    )) {
      throw StateError('Ihr seid bereits befreundet.');
    }
    if (existing.any(
      (request) => request.status == OnlineFriendRequestStatus.pending,
    )) {
      throw StateError('There is already an open friend request.');
    }

    final now = DateTime.now();
    final id = 'friend_${now.microsecondsSinceEpoch}';
    final request = OnlineFriendRequest(
      id: id,
      fromUserId: fromProfile.userId,
      fromDisplayName: fromProfile.displayName,
      fromFriendCode: fromProfile.friendCode,
      toUserId: target.userId,
      toDisplayName: target.displayName,
      toFriendCode: target.friendCode,
      status: OnlineFriendRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    _friendRequestsById[id] = request;
    _emit();
    return request;
  }

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    final request = _friendRequestsById[requestId];
    if (request == null) throw StateError('Request not found.');
    if (request.toUserId != userId) {
      throw StateError('This request does not belong to you.');
    }
    _friendRequestsById[requestId] = OnlineFriendRequest(
      id: request.id,
      fromUserId: request.fromUserId,
      fromDisplayName: request.fromDisplayName,
      fromFriendCode: request.fromFriendCode,
      toUserId: request.toUserId,
      toDisplayName: request.toDisplayName,
      toFriendCode: request.toFriendCode,
      status: OnlineFriendRequestStatus.accepted,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> removeFriend({
    required String userId,
    required String friendUserId,
  }) async {
    final toRemove = _friendRequestsById.entries.firstWhere(
      (entry) =>
          entry.value.status == OnlineFriendRequestStatus.accepted &&
          entry.value.involves(userId) &&
          entry.value.involves(friendUserId),
      orElse: () => throw StateError('Friendship not found.'),
    );
    _friendRequestsById.remove(toRemove.key);
    _emit();
  }

  @override
  Stream<List<OnlineBattleInvite>> watchInvitesForUser(String userId) async* {
    List<OnlineBattleInvite> invites() {
      final values =
          _invitesById.values
              .where(
                (invite) =>
                    invite.hostUserId == userId ||
                    invite.targetUserId == userId,
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return values;
    }

    yield invites();
    yield* _changes.stream.map((_) => invites());
  }

  @override
  Stream<List<AsyncBattleMatch>> watchMatchesForUser(String userId) async* {
    List<AsyncBattleMatch> matches() {
      final values =
          _matchesById.values
              .where(
                (match) =>
                    match.involvesUser(userId) && !match.isHiddenFor(userId),
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return values;
    }

    yield matches();
    yield* _changes.stream.map((_) => matches());
  }

  @override
  Future<OnlineBattleInvite> createInvite({
    required OnlineBattleProfile hostProfile,
    required String targetUserId,
    required String targetDisplayName,
    required List<AsyncBattleDraftSlot> hostDraftSlots,
  }) async {
    final now = DateTime.now();
    final id = 'invite_${now.microsecondsSinceEpoch}';
    final invite = OnlineBattleInvite(
      id: id,
      inviteCode: _inviteCode(),
      hostUserId: hostProfile.userId,
      hostDisplayName: hostProfile.displayName,
      targetUserId: targetUserId,
      targetDisplayName: targetDisplayName,
      status: OnlineBattleInviteStatus.open,
      hostDraftSlots: hostDraftSlots,
      createdAt: now,
      updatedAt: now,
    );
    _invitesById[id] = invite;
    _emit();
    return invite;
  }

  @override
  Future<AsyncBattleMatch> acceptInvite({
    required String inviteId,
    required OnlineBattleProfile guestProfile,
    required List<AsyncBattleDraftSlot> guestDraftSlots,
    required List<AsyncBattleRoundSeed> rounds,
  }) async {
    final invite = _invitesById[inviteId];
    if (invite == null || invite.status != OnlineBattleInviteStatus.open) {
      throw StateError('Battle invite not found.');
    }
    if (invite.targetUserId != guestProfile.userId) {
      throw StateError('This battle invite does not belong to you.');
    }
    final now = DateTime.now();
    final updatedInvite = OnlineBattleInvite(
      id: invite.id,
      inviteCode: invite.inviteCode,
      hostUserId: invite.hostUserId,
      hostDisplayName: invite.hostDisplayName,
      targetUserId: invite.targetUserId,
      targetDisplayName: invite.targetDisplayName,
      status: OnlineBattleInviteStatus.accepted,
      hostDraftSlots: invite.hostDraftSlots,
      createdAt: invite.createdAt,
      updatedAt: now,
    );
    _invitesById[invite.id] = updatedInvite;

    final match = AsyncBattleMatch(
      id: 'match_${now.microsecondsSinceEpoch}',
      inviteCode: invite.inviteCode,
      isRandomMatch: false,
      status: AsyncBattleMatchStatus.ready,
      host: AsyncBattleMatchParticipant(
        userId: invite.hostUserId,
        displayName: invite.hostDisplayName,
        deck: const [],
      ),
      guest: AsyncBattleMatchParticipant(
        userId: guestProfile.userId,
        displayName: guestProfile.displayName,
        deck: const [],
      ),
      hostRating: _profilesByUser[invite.hostUserId]?.rating ?? 1000,
      guestRating: guestProfile.rating,
      hostDraftSlots: invite.hostDraftSlots,
      guestDraftSlots: guestDraftSlots,
      rounds: rounds,
      currentRoundIndex: 0,
      hostScore: 0,
      guestScore: 0,
      hostUsedCardIds: const [],
      guestUsedCardIds: const [],
      hostGuessSubmissions: const [],
      guestGuessSubmissions: const [],
      history: const [],
      createdAt: now,
      updatedAt: now,
    );
    _matchesById[match.id] = match;
    _emit();
    return match;
  }

  @override
  Future<AsyncBattleMatch> createOrJoinRandomMatch({
    required OnlineBattleProfile playerProfile,
    required List<AsyncBattleDraftSlot> draftSlots,
    required List<AsyncBattleRoundSeed> rounds,
    required int maxOpenSearches,
    required int ratingRange,
  }) async {
    final openMatches =
        _matchesById.values
            .where(
              (match) =>
                  match.isRandomMatch &&
                  match.guest == null &&
                  match.host.userId != playerProfile.userId &&
                  (match.hostRating - playerProfile.rating).abs() <=
                      ratingRange,
            )
            .toList()
          ..sort(
            (a, b) => (a.hostRating - playerProfile.rating).abs().compareTo(
              (b.hostRating - playerProfile.rating).abs(),
            ),
          );

    if (openMatches.isNotEmpty) {
      final existing = openMatches.first;
      final joined = AsyncBattleMatch(
        id: existing.id,
        inviteCode: existing.inviteCode,
        isRandomMatch: true,
        status: existing.hostUsedCardIds.isEmpty
            ? AsyncBattleMatchStatus.ready
            : AsyncBattleMatchStatus.inProgress,
        host: existing.host,
        guest: AsyncBattleMatchParticipant(
          userId: playerProfile.userId,
          displayName: playerProfile.displayName,
          deck: const [],
        ),
        hostRating: existing.hostRating,
        guestRating: playerProfile.rating,
        hostDraftSlots: existing.hostDraftSlots,
        guestDraftSlots: draftSlots,
        rounds: existing.rounds,
        currentRoundIndex: existing.currentRoundIndex,
        hostScore: existing.hostScore,
        guestScore: existing.guestScore,
        hostUsedCardIds: existing.hostUsedCardIds,
        guestUsedCardIds: existing.guestUsedCardIds,
        hostGuessSubmissions: existing.hostGuessSubmissions,
        guestGuessSubmissions: existing.guestGuessSubmissions,
        history: existing.history,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
      _matchesById[joined.id] = joined;
      _emit();
      return joined;
    }

    final myOpenCount = _matchesById.values
        .where(
          (match) =>
              match.isRandomMatch &&
              match.host.userId == playerProfile.userId &&
              match.guest == null,
        )
        .length;
    if (myOpenCount >= maxOpenSearches) {
      throw StateError('You already have $maxOpenSearches open random duels.');
    }

    final now = DateTime.now();
    final match = AsyncBattleMatch(
      id: 'match_${now.microsecondsSinceEpoch}',
      inviteCode: _inviteCode(),
      isRandomMatch: true,
      status: AsyncBattleMatchStatus.waitingForOpponent,
      host: AsyncBattleMatchParticipant(
        userId: playerProfile.userId,
        displayName: playerProfile.displayName,
        deck: const [],
      ),
      guest: null,
      hostRating: playerProfile.rating,
      guestRating: null,
      hostDraftSlots: draftSlots,
      guestDraftSlots: const [],
      rounds: rounds,
      currentRoundIndex: 0,
      hostScore: 0,
      guestScore: 0,
      hostUsedCardIds: const [],
      guestUsedCardIds: const [],
      hostGuessSubmissions: const [],
      guestGuessSubmissions: const [],
      history: const [],
      createdAt: now,
      updatedAt: now,
    );
    _matchesById[match.id] = match;
    _emit();
    return match;
  }

  @override
  Future<void> submitDraft({
    required String matchId,
    required String userId,
    required List<String> selectedCardIds,
  }) async {
    final match = _matchesById[matchId];
    if (match == null) throw StateError('Match not found.');
    final updated = _applyDraft(
      match: match,
      userId: userId,
      selectedCardIds: selectedCardIds,
    );
    _matchesById[matchId] = updated;
    _emit();
  }

  AsyncBattleMatch _applyDraft({
    required AsyncBattleMatch match,
    required String userId,
    required List<String> selectedCardIds,
  }) {
    final role = match.roleFor(userId);
    if (role == null) {
      throw StateError('Du bist nicht Teil dieses Matches.');
    }
    if (selectedCardIds.length != battleDeckSize) {
      throw StateError('Please choose 4 cards for the draft.');
    }

    List<AsyncBattleDraftSlot> updateSlots(List<AsyncBattleDraftSlot> slots) {
      final next = <AsyncBattleDraftSlot>[];
      for (var i = 0; i < slots.length; i += 1) {
        final slot = slots[i];
        final selectedId = selectedCardIds[i];
        final exists = slot.candidates.any(
          (card) => card.personId == selectedId,
        );
        if (!exists) {
          throw StateError('Invalid draft selection.');
        }
        next.add(slot.copyWith(selectedCardId: selectedId));
      }
      return next;
    }

    List<AsyncBattleDeckCard> selectedDeck(List<AsyncBattleDraftSlot> slots) {
      return slots
          .map(
            (slot) => slot.candidates.firstWhere(
              (card) => card.personId == slot.selectedCardId,
            ),
          )
          .toList();
    }

    final hostDraftSlots = role == AsyncBattleMatchRole.host
        ? updateSlots(match.hostDraftSlots)
        : match.hostDraftSlots;
    final guestDraftSlots = role == AsyncBattleMatchRole.guest
        ? updateSlots(match.guestDraftSlots)
        : match.guestDraftSlots;
    final host = role == AsyncBattleMatchRole.host
        ? match.host.copyWith(deck: selectedDeck(hostDraftSlots))
        : match.host;
    final guest = role == AsyncBattleMatchRole.guest
        ? match.guest!.copyWith(deck: selectedDeck(guestDraftSlots))
        : match.guest;

    return AsyncBattleMatch(
      id: match.id,
      inviteCode: match.inviteCode,
      isRandomMatch: match.isRandomMatch,
      status: AsyncBattleMatchStatus.ready,
      host: host,
      guest: guest,
      hostRating: match.hostRating,
      guestRating: match.guestRating,
      hostDraftSlots: hostDraftSlots,
      guestDraftSlots: guestDraftSlots,
      rounds: match.rounds,
      currentRoundIndex: match.currentRoundIndex,
      hostScore: match.hostScore,
      guestScore: match.guestScore,
      hostUsedCardIds: match.hostUsedCardIds,
      guestUsedCardIds: match.guestUsedCardIds,
      hostGuessSubmissions: match.hostGuessSubmissions,
      guestGuessSubmissions: match.guestGuessSubmissions,
      history: match.history,
      createdAt: match.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> submitMove({
    required String matchId,
    required String userId,
    String? cardId,
    int? guessedYear,
    String? guessedDateIso,
    double? guessedLat,
    double? guessedLng,
  }) async {
    final match = _matchesById[matchId];
    if (match == null) throw StateError('Match not found.');
    final updated = _applyMove(
      match: match,
      userId: userId,
      cardId: cardId,
      guessedYear: guessedYear,
      guessedDateIso: guessedDateIso,
      guessedLat: guessedLat,
      guessedLng: guessedLng,
    );
    _matchesById[matchId] = updated;
    if (updated.isCompleted) {
      _applyRatingUpdate(updated);
    }
    _emit();
  }

  @override
  Future<void> leaveMatchForUser({
    required String matchId,
    required String userId,
  }) async {
    final match = _matchesById[matchId];
    if (match == null) throw StateError('Match not found.');
    if (!match.involvesUser(userId)) {
      throw StateError('This match does not belong to you.');
    }
    if (match.isHiddenFor(userId)) return;
    _matchesById[matchId] = AsyncBattleMatch(
      id: match.id,
      inviteCode: match.inviteCode,
      isRandomMatch: match.isRandomMatch,
      status: match.status,
      host: match.host,
      guest: match.guest,
      hostRating: match.hostRating,
      guestRating: match.guestRating,
      hostDraftSlots: match.hostDraftSlots,
      guestDraftSlots: match.guestDraftSlots,
      rounds: match.rounds,
      currentRoundIndex: match.currentRoundIndex,
      hostScore: match.hostScore,
      guestScore: match.guestScore,
      hostUsedCardIds: match.hostUsedCardIds,
      guestUsedCardIds: match.guestUsedCardIds,
      hostGuessSubmissions: match.hostGuessSubmissions,
      guestGuessSubmissions: match.guestGuessSubmissions,
      history: match.history,
      hiddenForUserIds: [...match.hiddenForUserIds, userId],
      createdAt: match.createdAt,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> leaveAllOpenMatchesForUser({required String userId}) async {
    for (final entry in _matchesById.entries.toList()) {
      final match = entry.value;
      if (!match.involvesUser(userId) ||
          match.isCompleted ||
          match.isHiddenFor(userId)) {
        continue;
      }
      _matchesById[entry.key] = AsyncBattleMatch(
        id: match.id,
        inviteCode: match.inviteCode,
        isRandomMatch: match.isRandomMatch,
        status: match.status,
        host: match.host,
        guest: match.guest,
        hostRating: match.hostRating,
        guestRating: match.guestRating,
        hostDraftSlots: match.hostDraftSlots,
        guestDraftSlots: match.guestDraftSlots,
        rounds: match.rounds,
        currentRoundIndex: match.currentRoundIndex,
        hostScore: match.hostScore,
        guestScore: match.guestScore,
        hostUsedCardIds: match.hostUsedCardIds,
        guestUsedCardIds: match.guestUsedCardIds,
        hostGuessSubmissions: match.hostGuessSubmissions,
        guestGuessSubmissions: match.guestGuessSubmissions,
        history: match.history,
        hiddenForUserIds: [...match.hiddenForUserIds, userId],
        createdAt: match.createdAt,
        updatedAt: DateTime.now(),
      );
    }
    _emit();
  }

  AsyncBattleMatch _applyMove({
    required AsyncBattleMatch match,
    required String userId,
    String? cardId,
    int? guessedYear,
    String? guessedDateIso,
    double? guessedLat,
    double? guessedLng,
  }) {
    if (match.isCompleted) {
      throw StateError('This match is already completed.');
    }
    final role = match.roleFor(userId);
    if (role == null) {
      throw StateError('Du bist nicht Teil dieses Matches.');
    }
    final currentRound = match.currentRoundIndex < match.rounds.length
        ? match.rounds[match.currentRoundIndex]
        : null;
    if (currentRound == null) {
      throw StateError('Keine aktive Runde gefunden.');
    }

    var hostUsedCardIds = [...match.hostUsedCardIds];
    var guestUsedCardIds = [...match.guestUsedCardIds];
    var hostGuessSubmissions = [...match.hostGuessSubmissions];
    var guestGuessSubmissions = [...match.guestGuessSubmissions];

    if (currentRound.inputMode == BattleRoundInputMode.cardSelection) {
      final deck = match.deckFor(userId);
      final card = deck.cast<AsyncBattleDeckCard?>().firstWhere(
        (entry) => entry?.personId == cardId,
        orElse: () => null,
      );
      if (card == null) {
        throw StateError('This card does not belong to your deck.');
      }
      if (!(currentRound.isTiebreaker) &&
          match.usedCardIdsFor(userId).contains(cardId)) {
        throw StateError('Diese Karte wurde bereits gespielt.');
      }
      if (role == AsyncBattleMatchRole.host) {
        hostUsedCardIds.add(cardId!);
      } else {
        guestUsedCardIds.add(cardId!);
      }
    } else {
      if (match.hasGuessSubmissionFor(userId, match.currentRoundIndex)) {
        throw StateError(
          'Du hast fuer dieses Stechen bereits einen Guess abgegeben.',
        );
      }
      final submission = AsyncBattleGuessSubmission(
        roundIndex: match.currentRoundIndex,
        guessedYear: guessedYear,
        guessedDateIso: guessedDateIso,
        guessedLat: guessedLat,
        guessedLng: guessedLng,
      );
      if (currentRound.inputMode == BattleRoundInputMode.yearLockGuess &&
          guessedDateIso == null &&
          guessedYear == null) {
        throw StateError('Please enter a date.');
      }
      if (currentRound.inputMode == BattleRoundInputMode.mapGuess &&
          (guessedLat == null || guessedLng == null)) {
        throw StateError('Please place a map guess.');
      }
      if (role == AsyncBattleMatchRole.host) {
        hostGuessSubmissions.add(submission);
      } else {
        guestGuessSubmissions.add(submission);
      }
    }

    final now = DateTime.now();
    final history = <AsyncBattleRoundOutcome>[];
    var hostScore = 0;
    var guestScore = 0;
    var hostCardCursor = 0;
    var guestCardCursor = 0;
    var resolvedRounds = 0;
    for (var i = 0; i < match.rounds.length; i += 1) {
      final round = match.rounds[i];
      AsyncBattleResolution resolution;
      String? hostCardId;
      String? guestCardId;
      int? hostGuessedYear;
      int? guestGuessedYear;
      String? hostGuessedDateIso;
      String? guestGuessedDateIso;
      double? hostGuessLatValue;
      double? hostGuessLngValue;
      double? guestGuessLatValue;
      double? guestGuessLngValue;

      if (round.inputMode == BattleRoundInputMode.cardSelection) {
        if (hostCardCursor >= hostUsedCardIds.length ||
            guestCardCursor >= guestUsedCardIds.length) {
          break;
        }
        hostCardId = hostUsedCardIds[hostCardCursor];
        guestCardId = guestUsedCardIds[guestCardCursor];
        final hostCard = match.host.deck.firstWhere(
          (entry) => entry.personId == hostCardId,
        );
        final guestCard = match.guest!.deck.firstWhere(
          (entry) => entry.personId == guestCardId,
        );
        resolution = AsyncBattleMatchEngine.resolve(
          round: round,
          roundIndex: i,
          rounds: match.rounds,
          hostCard: hostCard,
          guestCard: guestCard,
        );
        hostCardCursor += 1;
        guestCardCursor += 1;
      } else {
        final hostGuess = hostGuessSubmissions
            .cast<AsyncBattleGuessSubmission?>()
            .firstWhere((entry) => entry?.roundIndex == i, orElse: () => null);
        final guestGuess = guestGuessSubmissions
            .cast<AsyncBattleGuessSubmission?>()
            .firstWhere((entry) => entry?.roundIndex == i, orElse: () => null);
        if (hostGuess == null || guestGuess == null) {
          break;
        }
        hostGuessedYear = hostGuess.guessedYear;
        guestGuessedYear = guestGuess.guessedYear;
        hostGuessedDateIso = hostGuess.guessedDateIso;
        guestGuessedDateIso = guestGuess.guessedDateIso;
        hostGuessLatValue = hostGuess.guessedLat;
        hostGuessLngValue = hostGuess.guessedLng;
        guestGuessLatValue = guestGuess.guessedLat;
        guestGuessLngValue = guestGuess.guessedLng;
        resolution = AsyncBattleMatchEngine.resolve(
          round: round,
          roundIndex: i,
          rounds: match.rounds,
          hostGuess: hostGuess,
          guestGuess: guestGuess,
        );
      }
      hostScore += resolution.hostScoreDelta;
      guestScore += resolution.guestScoreDelta;
      history.add(
        AsyncBattleRoundOutcome(
          roundIndex: i,
          hostCardId: hostCardId,
          guestCardId: guestCardId,
          hostMetric: resolution.hostMetric,
          guestMetric: resolution.guestMetric,
          hostWon: resolution.hostWon,
          isDraw: resolution.isDraw,
          explanation: resolution.explanation,
          hostGuessedYear: hostGuessedYear,
          guestGuessedYear: guestGuessedYear,
          hostGuessedDateIso: hostGuessedDateIso,
          guestGuessedDateIso: guestGuessedDateIso,
          hostGuessLat: hostGuessLatValue,
          hostGuessLng: hostGuessLngValue,
          guestGuessLat: guestGuessLatValue,
          guestGuessLng: guestGuessLngValue,
        ),
      );
      resolvedRounds += 1;
    }

    final hostFinished =
        hostUsedCardIds.length + hostGuessSubmissions.length >=
        match.rounds.length;
    final guestFinished =
        guestUsedCardIds.length + guestGuessSubmissions.length >=
        match.rounds.length;
    if (hostFinished && guestFinished) {
      if (hostScore == guestScore) {
        return AsyncBattleMatch(
          id: match.id,
          inviteCode: match.inviteCode,
          isRandomMatch: match.isRandomMatch,
          status: AsyncBattleMatchStatus.inProgress,
          host: match.host,
          guest: match.guest,
          hostRating: match.hostRating,
          guestRating: match.guestRating,
          hostDraftSlots: match.hostDraftSlots,
          guestDraftSlots: match.guestDraftSlots,
          rounds: [...match.rounds, _buildTiebreakRound(match)],
          currentRoundIndex: match.rounds.length,
          hostScore: hostScore,
          guestScore: guestScore,
          hostUsedCardIds: hostUsedCardIds,
          guestUsedCardIds: guestUsedCardIds,
          hostGuessSubmissions: hostGuessSubmissions,
          guestGuessSubmissions: guestGuessSubmissions,
          history: history,
          createdAt: match.createdAt,
          updatedAt: now,
        );
      }
      return AsyncBattleMatch(
        id: match.id,
        inviteCode: match.inviteCode,
        isRandomMatch: match.isRandomMatch,
        status: AsyncBattleMatchStatus.completed,
        host: match.host,
        guest: match.guest,
        hostRating: match.hostRating,
        guestRating: match.guestRating,
        hostDraftSlots: match.hostDraftSlots,
        guestDraftSlots: match.guestDraftSlots,
        rounds: match.rounds,
        currentRoundIndex: match.rounds.length,
        hostScore: hostScore,
        guestScore: guestScore,
        hostUsedCardIds: hostUsedCardIds,
        guestUsedCardIds: guestUsedCardIds,
        hostGuessSubmissions: hostGuessSubmissions,
        guestGuessSubmissions: guestGuessSubmissions,
        history: history,
        createdAt: match.createdAt,
        updatedAt: now,
      );
    }

    final updated = AsyncBattleMatch(
      id: match.id,
      inviteCode: match.inviteCode,
      isRandomMatch: match.isRandomMatch,
      status: AsyncBattleMatchStatus.inProgress,
      host: match.host,
      guest: match.guest,
      hostRating: match.hostRating,
      guestRating: match.guestRating,
      hostDraftSlots: match.hostDraftSlots,
      guestDraftSlots: match.guestDraftSlots,
      rounds: match.rounds,
      currentRoundIndex: resolvedRounds,
      hostScore: hostScore,
      guestScore: guestScore,
      hostUsedCardIds: hostUsedCardIds,
      guestUsedCardIds: guestUsedCardIds,
      hostGuessSubmissions: hostGuessSubmissions,
      guestGuessSubmissions: guestGuessSubmissions,
      history: history,
      createdAt: match.createdAt,
      updatedAt: now,
    );
    return updated;
  }

  void _applyRatingUpdate(AsyncBattleMatch match) {
    final guest = match.guest;
    if (guest == null) return;
    final hostProfile = _profilesByUser[match.host.userId];
    final guestProfile = _profilesByUser[guest.userId];
    if (hostProfile == null || guestProfile == null) return;

    final hostRating = match.hostRating;
    final guestRating = match.guestRating ?? guestProfile.rating;
    final hostActual = match.hostScore == match.guestScore
        ? 0.5
        : (match.hostScore > match.guestScore ? 1.0 : 0.0);
    final guestActual = 1.0 - hostActual;
    final hostExpected = 1 / (1 + pow(10, (guestRating - hostRating) / 400));
    final guestExpected = 1 / (1 + pow(10, (hostRating - guestRating) / 400));
    const kFactor = 32;
    final nextHostRating = (hostRating + kFactor * (hostActual - hostExpected))
        .round();
    final nextGuestRating =
        (guestRating + kFactor * (guestActual - guestExpected)).round();

    _profilesByUser[hostProfile.userId] = hostProfile.copyWith(
      rating: nextHostRating,
      updatedAt: DateTime.now(),
    );
    _profilesByUser[guestProfile.userId] = guestProfile.copyWith(
      rating: nextGuestRating,
      updatedAt: DateTime.now(),
    );
  }

  AsyncBattleRoundSeed _buildTiebreakRound(AsyncBattleMatch match) {
    final event = randomBattleHistoricalEventTarget(_random);
    if (_random.nextBool()) {
      return AsyncBattleRoundSeed(
        type: BattleRoundType.closerToLocation,
        title: 'Stechen: Wo war das?',
        prompt: 'Tiebreak for the win. ${event.locationPrompt}',
        isTiebreaker: true,
        inputMode: BattleRoundInputMode.mapGuess,
        historicalEventTitle: event.title,
        historicalEventDateIso: event.date.toIso8601String(),
        historicalEventLocationLabel: event.locationLabel,
        historicalEventRegionLabel: event.regionLabel,
        historicalEventLat: event.lat,
        historicalEventLng: event.lng,
      );
    }

    return AsyncBattleRoundSeed(
      type: BattleRoundType.closerToYear,
      title: 'Stechen: Wann war das?',
      prompt: 'Tiebreak for the win. ${event.datePrompt}',
      isTiebreaker: true,
      inputMode: BattleRoundInputMode.yearLockGuess,
      historicalEventTitle: event.title,
      historicalEventDateIso: event.date.toIso8601String(),
      historicalEventLocationLabel: event.locationLabel,
      historicalEventRegionLabel: event.regionLabel,
      historicalEventLat: event.lat,
      historicalEventLng: event.lng,
    );
  }

  String _inviteCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => letters[_random.nextInt(letters.length)],
    ).join();
  }
}
