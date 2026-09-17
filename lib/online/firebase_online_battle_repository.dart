import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../battle/battle_models.dart';
import '../battle/battle_targets.dart';
import 'async_battle_match_engine.dart';
import 'online_battle_repository.dart';
import 'online_identity.dart';
import 'online_models.dart';

class FirebaseOnlineIdentityGateway implements OnlineIdentityGateway {
  final FirebaseAuth _auth;

  FirebaseOnlineIdentityGateway(this._auth);

  @override
  Future<String> signIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;

    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }
}

class FirebaseOnlineBattleRepository implements OnlineBattleRepository {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  FirebaseOnlineBattleRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('battle_profiles');
  CollectionReference<Map<String, dynamic>> get _friendRequests =>
      _firestore.collection('battle_friend_requests');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('battle_invites');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('battle_matches');

  @override
  Future<OnlineBattleProfile?> fetchProfile(String userId) async {
    final snapshot = await _profiles.doc(userId).get();
    final data = snapshot.data();
    if (data == null) return null;
    return OnlineBattleProfile.fromJson(Map<String, Object?>.from(data));
  }

  @override
  Stream<OnlineBattleProfile?> watchProfile(String userId) {
    return _profiles.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return OnlineBattleProfile.fromJson(Map<String, Object?>.from(data));
    });
  }

  @override
  Future<void> saveProfile(OnlineBattleProfile profile) async {
    await _profiles.doc(profile.userId).set(profile.toJson());
  }

  @override
  Future<OnlineBattleProfile?> findProfileByFriendCode(
    String friendCode,
  ) async {
    final query = await _profiles
        .where('friendCode', isEqualTo: friendCode.toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return OnlineBattleProfile.fromJson(
      Map<String, Object?>.from(query.docs.first.data()),
    );
  }

  @override
  Stream<List<OnlineBattleProfile>> watchTopProfiles({int limit = 25}) {
    return _profiles
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => OnlineBattleProfile.fromJson(
                  Map<String, Object?>.from(doc.data()),
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<List<OnlineFriendRequest>> watchFriendRequestsForUser(String userId) {
    return _friendRequests
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = Map<String, Object?>.from(doc.data());
            data['id'] = doc.id;
            return OnlineFriendRequest.fromJson(data);
          }).toList(),
        );
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

    final participantKey = _participantKey(fromProfile.userId, target.userId);
    final existing = await _friendRequests
        .where('participantKey', isEqualTo: participantKey)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final data = Map<String, Object?>.from(existing.docs.first.data());
      data['id'] = existing.docs.first.id;
      final request = OnlineFriendRequest.fromJson(data);
      if (request.status == OnlineFriendRequestStatus.accepted) {
        throw StateError('Ihr seid bereits befreundet.');
      }
      if (request.status == OnlineFriendRequestStatus.pending) {
        throw StateError('There is already an open friend request.');
      }
    }

    final now = DateTime.now();
    final doc = _friendRequests.doc();
    final request = OnlineFriendRequest(
      id: doc.id,
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
    await doc.set({
      ...request.toJson(),
      'participantIds': [fromProfile.userId, target.userId],
      'participantKey': participantKey,
    });
    return request;
  }

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    final ref = _friendRequests.doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) throw StateError('Request not found.');
      final json = Map<String, Object?>.from(data);
      json['id'] = snapshot.id;
      final request = OnlineFriendRequest.fromJson(json);
      if (request.toUserId != userId) {
        throw StateError('This request does not belong to you.');
      }
      transaction.update(ref, {
        'status': OnlineFriendRequestStatus.accepted.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  Future<void> removeFriend({
    required String userId,
    required String friendUserId,
  }) async {
    final participantKey = _participantKey(userId, friendUserId);
    final existing = await _friendRequests
        .where('participantKey', isEqualTo: participantKey)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      throw StateError('Friendship not found.');
    }
    final doc = existing.docs.first;
    final data = Map<String, Object?>.from(doc.data());
    data['id'] = doc.id;
    final request = OnlineFriendRequest.fromJson(data);
    if (request.status != OnlineFriendRequestStatus.accepted) {
      throw StateError('Friendship not found.');
    }
    await _friendRequests.doc(doc.id).delete();
  }

  @override
  Stream<List<OnlineBattleInvite>> watchInvitesForUser(String userId) {
    return _invites
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = Map<String, Object?>.from(doc.data());
            data['id'] = doc.id;
            return OnlineBattleInvite.fromJson(data);
          }).toList(),
        );
  }

  @override
  Stream<List<AsyncBattleMatch>> watchMatchesForUser(String userId) {
    return _matches
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = Map<String, Object?>.from(doc.data());
                data['id'] = doc.id;
                return AsyncBattleMatch.fromJson(data);
              })
              .where((match) => !match.isHiddenFor(userId))
              .toList(),
        );
  }

  @override
  Future<OnlineBattleInvite> createInvite({
    required OnlineBattleProfile hostProfile,
    required String targetUserId,
    required String targetDisplayName,
    required List<AsyncBattleDraftSlot> hostDraftSlots,
  }) async {
    final now = DateTime.now();
    final doc = _invites.doc();
    final invite = OnlineBattleInvite(
      id: doc.id,
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
    await doc.set({
      ...invite.toJson(),
      'participantIds': [hostProfile.userId, targetUserId],
    });
    return invite;
  }

  @override
  Future<AsyncBattleMatch> createOrJoinRandomMatch({
    required OnlineBattleProfile playerProfile,
    required List<AsyncBattleDraftSlot> draftSlots,
    required List<AsyncBattleRoundSeed> rounds,
    required int maxOpenSearches,
    required int ratingRange,
  }) async {
    final query = await _matches
        .where('isRandomMatch', isEqualTo: true)
        .limit(40)
        .get();

    final candidates =
        query.docs
            .map((doc) {
              final data = Map<String, Object?>.from(doc.data());
              data['id'] = doc.id;
              return AsyncBattleMatch.fromJson(data);
            })
            .where(
              (match) =>
                  match.guest == null &&
                  match.host.userId != playerProfile.userId &&
                  !match.isCompleted &&
                  (match.hostRating - playerProfile.rating).abs() <=
                      ratingRange,
            )
            .toList()
          ..sort(
            (a, b) => (a.hostRating - playerProfile.rating).abs().compareTo(
              (b.hostRating - playerProfile.rating).abs(),
            ),
          );

    if (candidates.isNotEmpty) {
      final match = candidates.first;
      final ref = _matches.doc(match.id);
      return _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data == null) {
          throw StateError('Zufallsduell ist nicht mehr verfuegbar.');
        }
        final json = Map<String, Object?>.from(data);
        json['id'] = snapshot.id;
        final liveMatch = AsyncBattleMatch.fromJson(json);
        if (!liveMatch.isRandomMatch ||
            liveMatch.guest != null ||
            liveMatch.host.userId == playerProfile.userId) {
          throw StateError('Zufallsduell ist nicht mehr verfuegbar.');
        }
        final joined = AsyncBattleMatch(
          id: liveMatch.id,
          inviteCode: liveMatch.inviteCode,
          isRandomMatch: true,
          status: liveMatch.hostUsedCardIds.isEmpty
              ? AsyncBattleMatchStatus.ready
              : AsyncBattleMatchStatus.inProgress,
          host: liveMatch.host,
          guest: AsyncBattleMatchParticipant(
            userId: playerProfile.userId,
            displayName: playerProfile.displayName,
            deck: const [],
          ),
          hostRating: liveMatch.hostRating,
          guestRating: playerProfile.rating,
          hostDraftSlots: liveMatch.hostDraftSlots,
          guestDraftSlots: draftSlots,
          rounds: liveMatch.rounds,
          currentRoundIndex: liveMatch.currentRoundIndex,
          hostScore: liveMatch.hostScore,
          guestScore: liveMatch.guestScore,
          hostUsedCardIds: liveMatch.hostUsedCardIds,
          guestUsedCardIds: liveMatch.guestUsedCardIds,
          hostGuessSubmissions: liveMatch.hostGuessSubmissions,
          guestGuessSubmissions: liveMatch.guestGuessSubmissions,
          history: liveMatch.history,
          createdAt: liveMatch.createdAt,
          updatedAt: DateTime.now(),
        );
        transaction.update(ref, {
          ...joined.toJson(),
          'participantIds': [joined.host.userId, joined.guest!.userId],
        });
        return joined;
      });
    }

    final ownOpen = await _matches
        .where('isRandomMatch', isEqualTo: true)
        .where('host.userId', isEqualTo: playerProfile.userId)
        .limit(maxOpenSearches + 1)
        .get();
    final ownOpenCount = ownOpen.docs
        .map((doc) {
          final data = Map<String, Object?>.from(doc.data());
          data['id'] = doc.id;
          return AsyncBattleMatch.fromJson(data);
        })
        .where((match) => match.guest == null && !match.isCompleted)
        .length;
    if (ownOpenCount >= maxOpenSearches) {
      throw StateError('You already have $maxOpenSearches open random duels.');
    }

    final now = DateTime.now();
    final ref = _matches.doc();
    final match = AsyncBattleMatch(
      id: ref.id,
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
    await ref.set({
      ...match.toJson(),
      'participantIds': [playerProfile.userId],
    });
    return match;
  }

  @override
  Future<AsyncBattleMatch> acceptInvite({
    required String inviteId,
    required OnlineBattleProfile guestProfile,
    required List<AsyncBattleDraftSlot> guestDraftSlots,
    required List<AsyncBattleRoundSeed> rounds,
  }) async {
    final inviteDoc = await _invites.doc(inviteId).get();
    if (!inviteDoc.exists || inviteDoc.data() == null) {
      throw StateError('Battle invite not found.');
    }
    final inviteData = Map<String, Object?>.from(inviteDoc.data()!);
    inviteData['id'] = inviteDoc.id;
    final invite = OnlineBattleInvite.fromJson(inviteData);
    if (invite.status != OnlineBattleInviteStatus.open) {
      throw StateError('This battle invite is no longer open.');
    }
    if (invite.targetUserId != guestProfile.userId) {
      throw StateError('This battle invite does not belong to you.');
    }
    final now = DateTime.now();

    final batch = _firestore.batch();
    batch.update(inviteDoc.reference, {
      'status': OnlineBattleInviteStatus.accepted.name,
      'updatedAt': now.toIso8601String(),
    });

    final matchDoc = _matches.doc();
    final match = AsyncBattleMatch(
      id: matchDoc.id,
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
      hostRating: (await fetchProfile(invite.hostUserId))?.rating ?? 1000,
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
    batch.set(matchDoc, {
      ...match.toJson(),
      'participantIds': [invite.hostUserId, guestProfile.userId],
    });
    await batch.commit();
    return match;
  }

  @override
  Future<void> submitDraft({
    required String matchId,
    required String userId,
    required List<String> selectedCardIds,
  }) async {
    final ref = _matches.doc(matchId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) {
        throw StateError('Match not found.');
      }
      final json = Map<String, Object?>.from(data);
      json['id'] = snapshot.id;
      final match = AsyncBattleMatch.fromJson(json);
      final updated = _applyDraft(
        match: match,
        userId: userId,
        selectedCardIds: selectedCardIds,
      );
      transaction.update(ref, {
        ...updated.toJson(),
        'participantIds': [
          updated.host.userId,
          if (updated.guest != null) updated.guest!.userId,
        ],
      });
    });
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
    final ref = _matches.doc(matchId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) {
        throw StateError('Match not found.');
      }
      final json = Map<String, Object?>.from(data);
      json['id'] = snapshot.id;
      final match = AsyncBattleMatch.fromJson(json);
      final updated = _applyMove(
        match: match,
        userId: userId,
        cardId: cardId,
        guessedYear: guessedYear,
        guessedDateIso: guessedDateIso,
        guessedLat: guessedLat,
        guessedLng: guessedLng,
      );
      transaction.update(ref, {
        ...updated.toJson(),
        'participantIds': [
          updated.host.userId,
          if (updated.guest != null) updated.guest!.userId,
        ],
      });
    });
  }

  @override
  Future<void> leaveMatchForUser({
    required String matchId,
    required String userId,
  }) async {
    final ref = _matches.doc(matchId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) {
        throw StateError('Match not found.');
      }
      final json = Map<String, Object?>.from(data);
      json['id'] = snapshot.id;
      final match = AsyncBattleMatch.fromJson(json);
      if (!match.involvesUser(userId)) {
        throw StateError('This match does not belong to you.');
      }
      if (match.isHiddenFor(userId)) return;
      transaction.update(ref, {
        'hiddenForUserIds': [...match.hiddenForUserIds, userId],
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  Future<void> leaveAllOpenMatchesForUser({required String userId}) async {
    final snapshot = await _matches
        .where('participantIds', arrayContains: userId)
        .limit(100)
        .get();
    final batch = _firestore.batch();
    var changed = false;
    for (final doc in snapshot.docs) {
      final data = Map<String, Object?>.from(doc.data());
      data['id'] = doc.id;
      final match = AsyncBattleMatch.fromJson(data);
      if (match.isCompleted || match.isHiddenFor(userId)) {
        continue;
      }
      batch.update(doc.reference, {
        'hiddenForUserIds': [...match.hiddenForUserIds, userId],
        'updatedAt': DateTime.now().toIso8601String(),
      });
      changed = true;
    }
    if (changed) {
      await batch.commit();
    }
  }

  String _inviteCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => letters[_random.nextInt(letters.length)],
    ).join();
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
      final card = match
          .deckFor(userId)
          .cast<AsyncBattleDeckCard?>()
          .firstWhere((entry) => entry?.personId == cardId, orElse: () => null);
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
      if (currentRound.inputMode == BattleRoundInputMode.yearLockGuess &&
          guessedDateIso == null &&
          guessedYear == null) {
        throw StateError('Please enter a date.');
      }
      if (currentRound.inputMode == BattleRoundInputMode.mapGuess &&
          (guessedLat == null || guessedLng == null)) {
        throw StateError('Please place a map guess.');
      }
      final submission = AsyncBattleGuessSubmission(
        roundIndex: match.currentRoundIndex,
        guessedYear: guessedYear,
        guessedDateIso: guessedDateIso,
        guessedLat: guessedLat,
        guessedLng: guessedLng,
      );
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

  String _participantKey(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }
}
