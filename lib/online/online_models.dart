import '../battle/battle_models.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../models/person_rarity.dart';
import '../battle/legendary_abilities.dart';

enum OnlineBackendKind { firebase, localFallback }

enum OnlineBattleInviteStatus { open, accepted, revoked }

enum AsyncBattleMatchStatus { waitingForOpponent, ready, inProgress, completed }

enum AsyncBattleMatchRole { host, guest }

enum OnlineFriendRequestStatus { pending, accepted, declined }

class OnlineBattleProfile {
  final String userId;
  final String displayName;
  final String friendCode;
  final int rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OnlineBattleProfile({
    required this.userId,
    required this.displayName,
    required this.friendCode,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  OnlineBattleProfile copyWith({
    String? displayName,
    String? friendCode,
    int? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OnlineBattleProfile(
      userId: userId,
      displayName: displayName ?? this.displayName,
      friendCode: friendCode ?? this.friendCode,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'friendCode': friendCode,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OnlineBattleProfile.fromJson(Map<String, Object?> json) {
    return OnlineBattleProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Player',
      friendCode: json['friendCode'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 1000,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OnlineFriendRequest {
  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String fromFriendCode;
  final String toUserId;
  final String toDisplayName;
  final String toFriendCode;
  final OnlineFriendRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OnlineFriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.fromFriendCode,
    required this.toUserId,
    required this.toDisplayName,
    required this.toFriendCode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool involves(String userId) => fromUserId == userId || toUserId == userId;

  bool isIncomingFor(String userId) => toUserId == userId;

  bool isAcceptedFor(String userId) =>
      status == OnlineFriendRequestStatus.accepted && involves(userId);

  String otherUserId(String userId) =>
      fromUserId == userId ? toUserId : fromUserId;

  String otherDisplayName(String userId) =>
      fromUserId == userId ? toDisplayName : fromDisplayName;

  String otherFriendCode(String userId) =>
      fromUserId == userId ? toFriendCode : fromFriendCode;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromDisplayName': fromDisplayName,
      'fromFriendCode': fromFriendCode,
      'toUserId': toUserId,
      'toDisplayName': toDisplayName,
      'toFriendCode': toFriendCode,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OnlineFriendRequest.fromJson(Map<String, Object?> json) {
    return OnlineFriendRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      fromDisplayName: json['fromDisplayName'] as String? ?? 'Player',
      fromFriendCode: json['fromFriendCode'] as String? ?? '',
      toUserId: json['toUserId'] as String,
      toDisplayName: json['toDisplayName'] as String? ?? 'Player',
      toFriendCode: json['toFriendCode'] as String? ?? '',
      status: OnlineFriendRequestStatus.values.byName(
        json['status'] as String? ?? OnlineFriendRequestStatus.pending.name,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AsyncBattleDeckCard {
  final String personId;
  final String name;
  final Category category;
  final String portraitAsset;
  final String vsAsset;
  final String hintTag;
  final PersonRarity rarity;
  final int birthYear;
  final int? deathYear;
  final double? birthLat;
  final double? birthLng;

  const AsyncBattleDeckCard({
    required this.personId,
    required this.name,
    required this.category,
    required this.portraitAsset,
    required this.vsAsset,
    required this.hintTag,
    required this.rarity,
    required this.birthYear,
    required this.deathYear,
    required this.birthLat,
    required this.birthLng,
  });

  factory AsyncBattleDeckCard.fromPerson(Person person) {
    return AsyncBattleDeckCard(
      personId: person.id,
      name: person.name,
      category: person.category,
      portraitAsset: person.portraitAsset,
      vsAsset: person.vsAsset,
      hintTag: battleTagForPersonId(person.id, person.hint),
      rarity: person.rarity,
      birthYear: person.birthYear,
      deathYear: person.deathYear,
      birthLat: person.birthLat,
      birthLng: person.birthLng,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'personId': personId,
      'name': name,
      'category': category.name,
      'portraitAsset': portraitAsset,
      'vsAsset': vsAsset,
      'hintTag': hintTag,
      'rarity': rarity.name,
      'birthYear': birthYear,
      'deathYear': deathYear,
      'birthLat': birthLat,
      'birthLng': birthLng,
    };
  }

  factory AsyncBattleDeckCard.fromJson(Map<String, Object?> json) {
    return AsyncBattleDeckCard(
      personId: json['personId'] as String,
      name: json['name'] as String,
      category: Category.values.byName(json['category'] as String),
      portraitAsset: json['portraitAsset'] as String,
      vsAsset:
          json['vsAsset'] as String? ??
          (json['portraitAsset'] as String).replaceFirst('/portrait/', '/vs/'),
      hintTag: json['hintTag'] as String? ?? '',
      rarity: PersonRarity.values.byName(json['rarity'] as String),
      birthYear: (json['birthYear'] as num).toInt(),
      deathYear: (json['deathYear'] as num?)?.toInt(),
      birthLat: (json['birthLat'] as num?)?.toDouble(),
      birthLng: (json['birthLng'] as num?)?.toDouble(),
    );
  }
}

class AsyncBattleDraftSlot {
  final BattleDraftSlotType type;
  final List<AsyncBattleDeckCard> candidates;
  final String? selectedCardId;

  const AsyncBattleDraftSlot({
    required this.type,
    required this.candidates,
    required this.selectedCardId,
  });

  bool get isComplete => selectedCardId != null;

  AsyncBattleDraftSlot copyWith({
    List<AsyncBattleDeckCard>? candidates,
    String? selectedCardId,
    bool clearSelected = false,
  }) {
    return AsyncBattleDraftSlot(
      type: type,
      candidates: candidates ?? this.candidates,
      selectedCardId: clearSelected
          ? null
          : (selectedCardId ?? this.selectedCardId),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'type': type.name,
      'candidates': candidates.map((card) => card.toJson()).toList(),
      'selectedCardId': selectedCardId,
    };
  }

  factory AsyncBattleDraftSlot.fromJson(Map<String, Object?> json) {
    return AsyncBattleDraftSlot(
      type: BattleDraftSlotType.values.byName(json['type'] as String),
      candidates: (json['candidates'] as List<Object?>? ?? const [])
          .map(
            (item) => AsyncBattleDeckCard.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
      selectedCardId: json['selectedCardId'] as String?,
    );
  }
}

class AsyncBattleRoundSeed {
  final BattleRoundType type;
  final String title;
  final String prompt;
  final bool isTiebreaker;
  final BattleRoundInputMode inputMode;
  final String? yearLabel;
  final int? yearTarget;
  final String? locationLabel;
  final double? locationLat;
  final double? locationLng;
  final String? historicalEventTitle;
  final String? historicalEventDateIso;
  final String? historicalEventLocationLabel;
  final String? historicalEventRegionLabel;
  final double? historicalEventLat;
  final double? historicalEventLng;

  const AsyncBattleRoundSeed({
    required this.type,
    required this.title,
    required this.prompt,
    this.isTiebreaker = false,
    this.inputMode = BattleRoundInputMode.cardSelection,
    this.yearLabel,
    this.yearTarget,
    this.locationLabel,
    this.locationLat,
    this.locationLng,
    this.historicalEventTitle,
    this.historicalEventDateIso,
    this.historicalEventLocationLabel,
    this.historicalEventRegionLabel,
    this.historicalEventLat,
    this.historicalEventLng,
  });

  Map<String, Object?> toJson() {
    return {
      'type': type.name,
      'title': title,
      'prompt': prompt,
      'isTiebreaker': isTiebreaker,
      'inputMode': inputMode.name,
      'yearLabel': yearLabel,
      'yearTarget': yearTarget,
      'locationLabel': locationLabel,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'historicalEventTitle': historicalEventTitle,
      'historicalEventDateIso': historicalEventDateIso,
      'historicalEventLocationLabel': historicalEventLocationLabel,
      'historicalEventRegionLabel': historicalEventRegionLabel,
      'historicalEventLat': historicalEventLat,
      'historicalEventLng': historicalEventLng,
    };
  }

  factory AsyncBattleRoundSeed.fromJson(Map<String, Object?> json) {
    return AsyncBattleRoundSeed(
      type: BattleRoundType.values.byName(json['type'] as String),
      title: json['title'] as String,
      prompt: json['prompt'] as String,
      isTiebreaker: json['isTiebreaker'] as bool? ?? false,
      inputMode: BattleRoundInputMode.values.byName(
        json['inputMode'] as String? ?? BattleRoundInputMode.cardSelection.name,
      ),
      yearLabel: json['yearLabel'] as String?,
      yearTarget: (json['yearTarget'] as num?)?.toInt(),
      locationLabel: json['locationLabel'] as String?,
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      historicalEventTitle: json['historicalEventTitle'] as String?,
      historicalEventDateIso: json['historicalEventDateIso'] as String?,
      historicalEventLocationLabel:
          json['historicalEventLocationLabel'] as String?,
      historicalEventRegionLabel: json['historicalEventRegionLabel'] as String?,
      historicalEventLat: (json['historicalEventLat'] as num?)?.toDouble(),
      historicalEventLng: (json['historicalEventLng'] as num?)?.toDouble(),
    );
  }
}

class AsyncBattleGuessSubmission {
  final int roundIndex;
  final int? guessedYear;
  final String? guessedDateIso;
  final double? guessedLat;
  final double? guessedLng;

  const AsyncBattleGuessSubmission({
    required this.roundIndex,
    this.guessedYear,
    this.guessedDateIso,
    this.guessedLat,
    this.guessedLng,
  });

  Map<String, Object?> toJson() {
    return {
      'roundIndex': roundIndex,
      'guessedYear': guessedYear,
      'guessedDateIso': guessedDateIso,
      'guessedLat': guessedLat,
      'guessedLng': guessedLng,
    };
  }

  factory AsyncBattleGuessSubmission.fromJson(Map<String, Object?> json) {
    return AsyncBattleGuessSubmission(
      roundIndex: (json['roundIndex'] as num).toInt(),
      guessedYear: (json['guessedYear'] as num?)?.toInt(),
      guessedDateIso: json['guessedDateIso'] as String?,
      guessedLat: (json['guessedLat'] as num?)?.toDouble(),
      guessedLng: (json['guessedLng'] as num?)?.toDouble(),
    );
  }
}

class OnlineBattleInvite {
  final String id;
  final String inviteCode;
  final String hostUserId;
  final String hostDisplayName;
  final String? targetUserId;
  final String? targetDisplayName;
  final OnlineBattleInviteStatus status;
  final List<AsyncBattleDraftSlot> hostDraftSlots;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OnlineBattleInvite({
    required this.id,
    required this.inviteCode,
    required this.hostUserId,
    required this.hostDisplayName,
    required this.targetUserId,
    required this.targetDisplayName,
    required this.status,
    required this.hostDraftSlots,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'inviteCode': inviteCode,
      'hostUserId': hostUserId,
      'hostDisplayName': hostDisplayName,
      'targetUserId': targetUserId,
      'targetDisplayName': targetDisplayName,
      'status': status.name,
      'hostDraftSlots': hostDraftSlots.map((slot) => slot.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OnlineBattleInvite.fromJson(Map<String, Object?> json) {
    return OnlineBattleInvite(
      id: json['id'] as String,
      inviteCode: json['inviteCode'] as String,
      hostUserId: json['hostUserId'] as String,
      hostDisplayName: json['hostDisplayName'] as String,
      targetUserId: json['targetUserId'] as String?,
      targetDisplayName: json['targetDisplayName'] as String?,
      status: OnlineBattleInviteStatus.values.byName(
        json['status'] as String? ?? OnlineBattleInviteStatus.open.name,
      ),
      hostDraftSlots: (json['hostDraftSlots'] as List<Object?>? ?? const [])
          .map(
            (item) => AsyncBattleDraftSlot.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AsyncBattleMatchParticipant {
  final String userId;
  final String displayName;
  final List<AsyncBattleDeckCard> deck;

  const AsyncBattleMatchParticipant({
    required this.userId,
    required this.displayName,
    required this.deck,
  });

  AsyncBattleMatchParticipant copyWith({
    String? displayName,
    List<AsyncBattleDeckCard>? deck,
  }) {
    return AsyncBattleMatchParticipant(
      userId: userId,
      displayName: displayName ?? this.displayName,
      deck: deck ?? this.deck,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'deck': deck.map((card) => card.toJson()).toList(),
    };
  }

  factory AsyncBattleMatchParticipant.fromJson(Map<String, Object?> json) {
    return AsyncBattleMatchParticipant(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      deck: (json['deck'] as List<Object?>? ?? const [])
          .map(
            (item) => AsyncBattleDeckCard.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class AsyncBattleRoundOutcome {
  final int roundIndex;
  final String? hostCardId;
  final String? guestCardId;
  final double hostMetric;
  final double guestMetric;
  final bool hostWon;
  final bool isDraw;
  final String explanation;
  final int? hostGuessedYear;
  final int? guestGuessedYear;
  final String? hostGuessedDateIso;
  final String? guestGuessedDateIso;
  final double? hostGuessLat;
  final double? hostGuessLng;
  final double? guestGuessLat;
  final double? guestGuessLng;

  const AsyncBattleRoundOutcome({
    required this.roundIndex,
    required this.hostCardId,
    required this.guestCardId,
    required this.hostMetric,
    required this.guestMetric,
    required this.hostWon,
    required this.isDraw,
    required this.explanation,
    this.hostGuessedYear,
    this.guestGuessedYear,
    this.hostGuessedDateIso,
    this.guestGuessedDateIso,
    this.hostGuessLat,
    this.hostGuessLng,
    this.guestGuessLat,
    this.guestGuessLng,
  });

  Map<String, Object?> toJson() {
    return {
      'roundIndex': roundIndex,
      'hostCardId': hostCardId,
      'guestCardId': guestCardId,
      'hostMetric': hostMetric,
      'guestMetric': guestMetric,
      'hostWon': hostWon,
      'isDraw': isDraw,
      'explanation': explanation,
      'hostGuessedYear': hostGuessedYear,
      'guestGuessedYear': guestGuessedYear,
      'hostGuessedDateIso': hostGuessedDateIso,
      'guestGuessedDateIso': guestGuessedDateIso,
      'hostGuessLat': hostGuessLat,
      'hostGuessLng': hostGuessLng,
      'guestGuessLat': guestGuessLat,
      'guestGuessLng': guestGuessLng,
    };
  }

  factory AsyncBattleRoundOutcome.fromJson(Map<String, Object?> json) {
    return AsyncBattleRoundOutcome(
      roundIndex: (json['roundIndex'] as num).toInt(),
      hostCardId: json['hostCardId'] as String?,
      guestCardId: json['guestCardId'] as String?,
      hostMetric: (json['hostMetric'] as num).toDouble(),
      guestMetric: (json['guestMetric'] as num).toDouble(),
      hostWon: json['hostWon'] as bool? ?? false,
      isDraw: json['isDraw'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
      hostGuessedYear: (json['hostGuessedYear'] as num?)?.toInt(),
      guestGuessedYear: (json['guestGuessedYear'] as num?)?.toInt(),
      hostGuessedDateIso: json['hostGuessedDateIso'] as String?,
      guestGuessedDateIso: json['guestGuessedDateIso'] as String?,
      hostGuessLat: (json['hostGuessLat'] as num?)?.toDouble(),
      hostGuessLng: (json['hostGuessLng'] as num?)?.toDouble(),
      guestGuessLat: (json['guestGuessLat'] as num?)?.toDouble(),
      guestGuessLng: (json['guestGuessLng'] as num?)?.toDouble(),
    );
  }
}

class AsyncBattleMatch {
  final String id;
  final String inviteCode;
  final bool isRandomMatch;
  final AsyncBattleMatchStatus status;
  final AsyncBattleMatchParticipant host;
  final AsyncBattleMatchParticipant? guest;
  final int hostRating;
  final int? guestRating;
  final List<AsyncBattleDraftSlot> hostDraftSlots;
  final List<AsyncBattleDraftSlot> guestDraftSlots;
  final List<AsyncBattleRoundSeed> rounds;
  final int currentRoundIndex;
  final int hostScore;
  final int guestScore;
  final List<String> hostUsedCardIds;
  final List<String> guestUsedCardIds;
  final List<AsyncBattleGuessSubmission> hostGuessSubmissions;
  final List<AsyncBattleGuessSubmission> guestGuessSubmissions;
  final List<AsyncBattleRoundOutcome> history;
  final List<String> hiddenForUserIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AsyncBattleMatch({
    required this.id,
    required this.inviteCode,
    required this.isRandomMatch,
    required this.status,
    required this.host,
    required this.guest,
    required this.hostRating,
    required this.guestRating,
    required this.hostDraftSlots,
    required this.guestDraftSlots,
    required this.rounds,
    required this.currentRoundIndex,
    required this.hostScore,
    required this.guestScore,
    required this.hostUsedCardIds,
    required this.guestUsedCardIds,
    required this.hostGuessSubmissions,
    required this.guestGuessSubmissions,
    required this.history,
    this.hiddenForUserIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool involvesUser(String userId) {
    return host.userId == userId || guest?.userId == userId;
  }

  String opponentNameFor(String userId) {
    if (host.userId == userId) {
      return guest?.displayName ?? 'Wartet auf Gegner';
    }
    return host.displayName;
  }

  bool get hasOpponent => guest != null;

  bool get isCompleted => status == AsyncBattleMatchStatus.completed;

  bool get hostFinishedRun =>
      submittedRoundCountFor(host.userId) >= rounds.length;

  bool get guestFinishedRun => guest == null
      ? false
      : submittedRoundCountFor(guest!.userId) >= rounds.length;

  bool isHiddenFor(String userId) => hiddenForUserIds.contains(userId);

  bool get hostDraftReady =>
      hostDraftSlots.length == battleDeckSize &&
      hostDraftSlots.every((slot) => slot.isComplete);

  bool get guestDraftReady =>
      guestDraftSlots.length == battleDeckSize &&
      guestDraftSlots.every((slot) => slot.isComplete);

  bool get isTiebreakPending =>
      !isCompleted &&
      rounds.length > battleDeckSize &&
      currentRoundIndex >= battleDeckSize;

  AsyncBattleRoundSeed? get currentRound {
    if (currentRoundIndex < 0 || currentRoundIndex >= rounds.length) {
      return null;
    }
    return rounds[currentRoundIndex];
  }

  AsyncBattleMatchRole? roleFor(String userId) {
    if (host.userId == userId) return AsyncBattleMatchRole.host;
    if (guest?.userId == userId) return AsyncBattleMatchRole.guest;
    return null;
  }

  bool hasSubmittedFor(String userId) {
    final role = roleFor(userId);
    if (role == AsyncBattleMatchRole.host) return hostFinishedRun;
    if (role == AsyncBattleMatchRole.guest) return guestFinishedRun;
    return false;
  }

  List<AsyncBattleDeckCard> deckFor(String userId) {
    if (host.userId == userId) return host.deck;
    if (guest?.userId == userId) return guest!.deck;
    return const [];
  }

  List<AsyncBattleDraftSlot> draftSlotsFor(String userId) {
    if (host.userId == userId) return hostDraftSlots;
    if (guest?.userId == userId) return guestDraftSlots;
    return const [];
  }

  List<String> usedCardIdsFor(String userId) {
    if (host.userId == userId) return hostUsedCardIds;
    if (guest?.userId == userId) return guestUsedCardIds;
    return const [];
  }

  List<AsyncBattleGuessSubmission> guessSubmissionsFor(String userId) {
    if (host.userId == userId) return hostGuessSubmissions;
    if (guest?.userId == userId) return guestGuessSubmissions;
    return const [];
  }

  bool hasGuessSubmissionFor(String userId, int roundIndex) {
    return guessSubmissionsFor(
      userId,
    ).any((entry) => entry.roundIndex == roundIndex);
  }

  int submittedRoundCountFor(String userId) {
    return usedCardIdsFor(userId).length + guessSubmissionsFor(userId).length;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'inviteCode': inviteCode,
      'isRandomMatch': isRandomMatch,
      'status': status.name,
      'host': host.toJson(),
      'guest': guest?.toJson(),
      'hostRating': hostRating,
      'guestRating': guestRating,
      'hostDraftSlots': hostDraftSlots.map((slot) => slot.toJson()).toList(),
      'guestDraftSlots': guestDraftSlots.map((slot) => slot.toJson()).toList(),
      'rounds': rounds.map((round) => round.toJson()).toList(),
      'currentRoundIndex': currentRoundIndex,
      'hostScore': hostScore,
      'guestScore': guestScore,
      'hostUsedCardIds': hostUsedCardIds,
      'guestUsedCardIds': guestUsedCardIds,
      'hostGuessSubmissions': hostGuessSubmissions
          .map((entry) => entry.toJson())
          .toList(),
      'guestGuessSubmissions': guestGuessSubmissions
          .map((entry) => entry.toJson())
          .toList(),
      'history': history.map((entry) => entry.toJson()).toList(),
      'hiddenForUserIds': hiddenForUserIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AsyncBattleMatch.fromJson(Map<String, Object?> json) {
    return AsyncBattleMatch(
      id: json['id'] as String,
      inviteCode: json['inviteCode'] as String,
      isRandomMatch: json['isRandomMatch'] as bool? ?? false,
      status: AsyncBattleMatchStatus.values.byName(
        json['status'] as String? ??
            AsyncBattleMatchStatus.waitingForOpponent.name,
      ),
      host: AsyncBattleMatchParticipant.fromJson(
        Map<String, Object?>.from(json['host'] as Map),
      ),
      guest: json['guest'] == null
          ? null
          : AsyncBattleMatchParticipant.fromJson(
              Map<String, Object?>.from(json['guest'] as Map),
            ),
      hostRating: (json['hostRating'] as num?)?.toInt() ?? 1000,
      guestRating: (json['guestRating'] as num?)?.toInt(),
      hostDraftSlots: (json['hostDraftSlots'] as List<Object?>? ?? const [])
          .map(
            (item) => AsyncBattleDraftSlot.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
      guestDraftSlots: (json['guestDraftSlots'] as List<Object?>? ?? const [])
          .map(
            (item) => AsyncBattleDraftSlot.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
      rounds: (json['rounds'] as List<Object?>? ?? const [])
          .map(
            (item) => AsyncBattleRoundSeed.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
      currentRoundIndex: (json['currentRoundIndex'] as num?)?.toInt() ?? 0,
      hostScore: (json['hostScore'] as num?)?.toInt() ?? 0,
      guestScore: (json['guestScore'] as num?)?.toInt() ?? 0,
      hostUsedCardIds: (json['hostUsedCardIds'] as List<Object?>? ?? const [])
          .map((item) => '$item')
          .toList(),
      guestUsedCardIds: (json['guestUsedCardIds'] as List<Object?>? ?? const [])
          .map((item) => '$item')
          .toList(),
      hostGuessSubmissions:
          (json['hostGuessSubmissions'] as List<Object?>? ?? const [])
              .map(
                (item) => AsyncBattleGuessSubmission.fromJson(
                  Map<String, Object?>.from(item as Map),
                ),
              )
              .toList(),
      guestGuessSubmissions:
          (json['guestGuessSubmissions'] as List<Object?>? ?? const [])
              .map(
                (item) => AsyncBattleGuessSubmission.fromJson(
                  Map<String, Object?>.from(item as Map),
                ),
              )
              .toList(),
      history: (json['history'] as List<Object?>? ?? const [])
          .map(
            (item) => AsyncBattleRoundOutcome.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(),
      hiddenForUserIds: (json['hiddenForUserIds'] as List<Object?>? ?? const [])
          .map((item) => '$item')
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
