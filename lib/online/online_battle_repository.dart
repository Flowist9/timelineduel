import 'online_models.dart';

abstract class OnlineBattleRepository {
  Future<OnlineBattleProfile?> fetchProfile(String userId);

  Stream<OnlineBattleProfile?> watchProfile(String userId);

  Future<void> saveProfile(OnlineBattleProfile profile);

  Future<OnlineBattleProfile?> findProfileByFriendCode(String friendCode);

  Stream<List<OnlineBattleProfile>> watchTopProfiles({int limit = 25});

  Stream<List<OnlineFriendRequest>> watchFriendRequestsForUser(String userId);

  Future<OnlineFriendRequest> sendFriendRequest({
    required OnlineBattleProfile fromProfile,
    required String targetFriendCode,
  });

  Future<void> acceptFriendRequest({
    required String requestId,
    required String userId,
  });

  Future<void> removeFriend({
    required String userId,
    required String friendUserId,
  });

  Stream<List<OnlineBattleInvite>> watchInvitesForUser(String userId);

  Stream<List<AsyncBattleMatch>> watchMatchesForUser(String userId);

  Future<OnlineBattleInvite> createInvite({
    required OnlineBattleProfile hostProfile,
    required String targetUserId,
    required String targetDisplayName,
    required List<AsyncBattleDraftSlot> hostDraftSlots,
  });

  Future<AsyncBattleMatch> acceptInvite({
    required String inviteId,
    required OnlineBattleProfile guestProfile,
    required List<AsyncBattleDraftSlot> guestDraftSlots,
    required List<AsyncBattleRoundSeed> rounds,
  });

  Future<AsyncBattleMatch> createOrJoinRandomMatch({
    required OnlineBattleProfile playerProfile,
    required List<AsyncBattleDraftSlot> draftSlots,
    required List<AsyncBattleRoundSeed> rounds,
    required int maxOpenSearches,
    required int ratingRange,
  });

  Future<void> submitDraft({
    required String matchId,
    required String userId,
    required List<String> selectedCardIds,
  });

  Future<void> submitMove({
    required String matchId,
    required String userId,
    String? cardId,
    int? guessedYear,
    String? guessedDateIso,
    double? guessedLat,
    double? guessedLng,
  });

  Future<void> leaveMatchForUser({
    required String matchId,
    required String userId,
  });

  Future<void> leaveAllOpenMatchesForUser({required String userId});
}
