import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

import '../battle/battle_session.dart';
import '../battle/battle_targets.dart';
import '../battle/battle_models.dart';
import '../battle/battle_shared.dart';
import '../design/app_theme.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../widgets/battle_card_hand.dart';
import '../models/person_rarity.dart';
import '../online/async_battle_match_engine.dart';
import '../online/online_battle_controller.dart';
import '../online/online_models.dart';
import 'battle_guess_widgets.dart';
import 'battle_reveal_content_widgets.dart';
import 'battle_reveal_host_widgets.dart';

class OnlineMatchScreen extends StatefulWidget {
  final OnlineBattleController controller;
  final String matchId;
  final AsyncBattleMatch? initialMatch;

  const OnlineMatchScreen({
    super.key,
    required this.controller,
    required this.matchId,
    this.initialMatch,
  });

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen> {
  final Map<int, String> _draftSelectionBySlot = {};
  final Set<int> _seenRevealRoundIndices = <int>{};
  final Set<int> _localSubmittedGuessRounds = <int>{};
  String? _pendingDraftMatchId;
  Map<int, String>? _submittedDraftSelectionBySlot;
  final List<String> _localSubmittedCardIds = [];
  AsyncBattleMatch? _pendingCompletedMatch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.ink,
      appBar: AppBar(
        backgroundColor: AppPalette.surfaceRaised,
        foregroundColor: AppPalette.parchment,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ONLINE BATTLE',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .6),
            ),
            Text(
              'ASYNC DUEL',
              style: TextStyle(
                color: AppPalette.gold,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Leave battle',
            onPressed: _leaveCurrentMatch,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final remoteMatch =
                widget.controller.matchById(widget.matchId) ??
                widget.initialMatch;
            if (remoteMatch != null &&
                remoteMatch.isCompleted &&
                _pendingCompletedMatch != null &&
                _pendingCompletedMatch!.id == remoteMatch.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _pendingCompletedMatch = null;
                });
              });
            }
            final match =
                _pendingCompletedMatch != null &&
                    _pendingCompletedMatch!.id == widget.matchId
                ? _pendingCompletedMatch!
                : remoteMatch;
            final uid = widget.controller.userId;
            if (match == null || uid == null) {
              return const Center(
                child: Text(
                  'Loading match...',
                  style: TextStyle(color: Color(0xFFF7ECDD)),
                ),
              );
            }

            final role = match.roleFor(uid);
            if (role == null) {
              return const Center(
                child: Text(
                  'You are not part of this match.',
                  style: TextStyle(color: Color(0xFFF7ECDD)),
                ),
              );
            }

            if (!match.hasOpponent && !match.isRandomMatch) {
              return _buildShell(
                child: _InfoPhase(
                  match: match,
                  userId: uid,
                  title: 'Waiting for opponent',
                  body:
                      'Share the invite code. As soon as your friend joins, the same battle flow starts for both of you.',
                  accent: const Color(0xFFD4B06A),
                  content: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Invite-Code',
                          style: TextStyle(
                            color: Color(0xFFD8CBB8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          match.inviteCode,
                          style: const TextStyle(
                            color: Color(0xFFF7ECDD),
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final draftSlots = _effectiveDraftSlots(match, uid);
            _seedDraftSelection(draftSlots);
            final localDraftCommitted =
                _pendingDraftMatchId == match.id ||
                _submittedDraftSelectionBySlot != null;
            final draftReady = _isDraftReady(match, uid, draftSlots);
            final controllerDraftReady = widget.controller
                .isDraftReadyForCurrentUser(match);
            if (_pendingDraftMatchId == match.id && controllerDraftReady) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _pendingDraftMatchId = null;
                  _submittedDraftSelectionBySlot = null;
                });
              });
            }
            _syncLocalSubmittedCards(match, uid);
            if (!draftReady) {
              if (localDraftCommitted) {
                return _buildShell(
                  child: _InfoPhase(
                    match: match,
                    userId: uid,
                    title: 'Saving draft',
                    body:
                        'Your deck has been submitted. As soon as the match update arrives, you move straight into round 1.',
                    accent: const Color(0xFFD4B06A),
                    content: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4B06A),
                      ),
                    ),
                  ),
                );
              }
              return _buildShell(
                child: _DraftPhase(
                  match: match,
                  userId: uid,
                  slots: draftSlots,
                  selectedBySlot: _draftSelectionBySlot,
                  onSelect: (slotIndex, cardId) {
                    setState(() {
                      _draftSelectionBySlot[slotIndex] = cardId;
                    });
                  },
                  onSubmit: () => _submitDraft(match, draftSlots),
                ),
              );
            }

            final effectiveUsedIds = _effectiveUsedCardIds(match, uid);
            final effectiveSubmittedRounds =
                match.submittedRoundCountFor(uid) +
                _localSubmittedGuessRounds.length;
            final pendingRoundReveal = role == AsyncBattleMatchRole.guest
                ? match.history.cast<AsyncBattleRoundOutcome?>().firstWhere(
                    (entry) =>
                        entry != null &&
                        !_seenRevealRoundIndices.contains(entry.roundIndex),
                    orElse: () => null,
                  )
                : null;
            final opponentFinishedNow = role == AsyncBattleMatchRole.host
                ? (match.guest == null
                      ? false
                      : match.submittedRoundCountFor(match.guest!.userId) >=
                            match.rounds.length)
                : match.submittedRoundCountFor(match.host.userId) >=
                      match.rounds.length;
            final allowLocalCompletedPreview =
                match.currentRound?.inputMode ==
                BattleRoundInputMode.cardSelection;
            final challengerImmediateReveal =
                role == AsyncBattleMatchRole.guest &&
                effectiveSubmittedRounds >= match.rounds.length &&
                opponentFinishedNow &&
                allowLocalCompletedPreview;
            final displayCompletedMatch = match.isCompleted
                ? match
                : challengerImmediateReveal
                ? _buildCompletedPreviewFromState(
                        match: match,
                        userId: uid,
                        effectiveUsedIds: effectiveUsedIds,
                        effectiveDraftSlots: draftSlots,
                      ) ??
                      _pendingCompletedMatch
                : _pendingCompletedMatch;

            if (pendingRoundReveal != null && !match.isCompleted) {
              return _buildShell(
                child: _RoundRevealPhase(
                  match: match,
                  userId: uid,
                  entry: pendingRoundReveal,
                  onContinue: () {
                    setState(() {
                      _seenRevealRoundIndices.add(
                        pendingRoundReveal.roundIndex,
                      );
                    });
                  },
                ),
              );
            }

            if (displayCompletedMatch != null &&
                displayCompletedMatch.id == match.id &&
                (displayCompletedMatch.isCompleted ||
                    challengerImmediateReveal)) {
              return _buildShell(
                child: _CompletedPhase(
                  match: displayCompletedMatch,
                  userId: uid,
                ),
              );
            }

            final canSubmit =
                !match.isCompleted &&
                draftReady &&
                effectiveSubmittedRounds < match.rounds.length;
            if (!canSubmit) {
              final myFinished =
                  effectiveSubmittedRounds >= match.rounds.length;
              final opponentFinished = opponentFinishedNow;
              final resolutionPending =
                  myFinished && opponentFinished && !match.isCompleted;
              return _buildShell(
                child: _InfoPhase(
                  match: match,
                  userId: uid,
                  title: resolutionPending
                      ? 'Preparing reveal'
                      : myFinished
                      ? 'Your run is finished'
                      : 'Waiting for opponent',
                  body: resolutionPending
                      ? 'Both runs are complete. The reveal screens are being prepared.'
                      : myFinished
                      ? match.isRandomMatch && !match.hasOpponent
                            ? 'Your first run is saved. This random duel is now waiting for a matching opponent.'
                            : 'Your first run is saved. Your opponent is now being notified that it is their turn.'
                      : match.isRandomMatch && !match.hasOpponent
                      ? 'Your run is saved. As soon as a suitable opponent is matched, they can finish this duel.'
                      : 'Your full run is saved. As soon as your opponent finishes, the duel will be resolved.',
                  accent: const Color(0xFFD4B06A),
                  content: resolutionPending
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4B06A),
                          ),
                        )
                      : _SubmittedCardsList(
                          match: match,
                          userId: uid,
                          effectiveUsedCardIds: effectiveUsedIds,
                          effectiveDraftSlots: draftSlots,
                        ),
                ),
              );
            }

            final nextRoundIndex = effectiveSubmittedRounds;
            final currentRound = match.rounds[nextRoundIndex];
            return _buildShell(
              child:
                  currentRound.inputMode == BattleRoundInputMode.cardSelection
                  ? _RunPhase(
                      match: match,
                      userId: uid,
                      roundIndex: nextRoundIndex,
                      round: currentRound,
                      availableCards: _availableCardsForMatch(
                        match,
                        uid,
                        draftSlots,
                      ),
                      onSubmitCard: (cardId) => _submitMove(
                        match: match,
                        roundIndex: nextRoundIndex,
                        cardId: cardId,
                      ),
                    )
                  : _GuessRunPhase(
                      match: match,
                      userId: uid,
                      roundIndex: nextRoundIndex,
                      round: currentRound,
                      onSubmitDateGuess: (value) => _submitMove(
                        match: match,
                        roundIndex: nextRoundIndex,
                        guessedYear: value.year,
                        guessedDateIso: value.toIso8601String(),
                      ),
                      onSubmitMapGuess: (point) => _submitMove(
                        match: match,
                        roundIndex: nextRoundIndex,
                        guessedLat: point.latitude,
                        guessedLng: point.longitude,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShell({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(gradient: AppPalette.pageGradient),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: child,
      ),
    );
  }

  Future<void> _submitDraft(
    AsyncBattleMatch match,
    List<AsyncBattleDraftSlot> slots,
  ) async {
    if (slots.length != _draftSelectionBySlot.length) return;
    final selectedIds = List.generate(
      slots.length,
      (index) => _draftSelectionBySlot[index] ?? '',
    );
    if (selectedIds.any((id) => id.isEmpty)) return;

    try {
      setState(() {
        _pendingDraftMatchId = match.id;
        _submittedDraftSelectionBySlot = Map<int, String>.from(
          _draftSelectionBySlot,
        );
      });
      await widget.controller.submitDraft(
        matchId: match.id,
        selectedCardIds: selectedIds,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved.')));
    } catch (error) {
      setState(() {
        _pendingDraftMatchId = null;
        _submittedDraftSelectionBySlot = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _submitMove({
    required AsyncBattleMatch match,
    required int roundIndex,
    String? cardId,
    int? guessedYear,
    String? guessedDateIso,
    double? guessedLat,
    double? guessedLng,
  }) async {
    try {
      final optimisticCompletedMatch = _buildCompletedPreview(
        match: match,
        userId: widget.controller.userId,
        cardId: cardId,
      );
      setState(() {
        if (cardId != null) {
          _localSubmittedCardIds.add(cardId);
        }
        if (cardId == null) {
          _localSubmittedGuessRounds.add(roundIndex);
        }
        _pendingCompletedMatch = optimisticCompletedMatch;
      });
      await widget.controller.submitMove(
        matchId: match.id,
        cardId: cardId,
        guessedYear: guessedYear,
        guessedDateIso: guessedDateIso,
        guessedLat: guessedLat,
        guessedLng: guessedLng,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cardId != null
                ? 'Card submitted for round ${roundIndex + 1}.'
                : 'Guess submitted for round ${roundIndex + 1}.',
          ),
        ),
      );
    } catch (error) {
      setState(() {
        if (cardId != null) {
          _localSubmittedCardIds.remove(cardId);
        } else {
          _localSubmittedGuessRounds.remove(roundIndex);
        }
        _pendingCompletedMatch = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _seedDraftSelection(List<AsyncBattleDraftSlot> slots) {
    if (_draftSelectionBySlot.isNotEmpty) return;
    for (var i = 0; i < slots.length; i += 1) {
      final selectedId = slots[i].selectedCardId;
      final fallback = slots[i].candidates.isNotEmpty
          ? slots[i].candidates.first.personId
          : null;
      if (selectedId != null || fallback != null) {
        _draftSelectionBySlot[i] = selectedId ?? fallback!;
      }
    }
  }

  List<AsyncBattleDraftSlot> _effectiveDraftSlots(
    AsyncBattleMatch match,
    String userId,
  ) {
    final slots = match.draftSlotsFor(userId);
    if (_submittedDraftSelectionBySlot == null) return slots;
    return List.generate(slots.length, (index) {
      final localSelectedId = _submittedDraftSelectionBySlot![index];
      if (localSelectedId == null) return slots[index];
      return slots[index].copyWith(selectedCardId: localSelectedId);
    });
  }

  bool _isDraftReady(
    AsyncBattleMatch match,
    String userId,
    List<AsyncBattleDraftSlot> effectiveSlots,
  ) {
    final controllerReady = widget.controller.isDraftReadyForCurrentUser(match);
    if (controllerReady) return true;
    if (_submittedDraftSelectionBySlot != null &&
        _submittedDraftSelectionBySlot!.length == battleDeckSize) {
      return true;
    }
    return effectiveSlots.length == battleDeckSize &&
        effectiveSlots.every((slot) => slot.isComplete);
  }

  List<AsyncBattleDeckCard> _availableCardsForMatch(
    AsyncBattleMatch match,
    String userId,
    List<AsyncBattleDraftSlot> effectiveSlots,
  ) {
    final fromController = widget.controller.availableCardsForMatch(match);
    final allowReuse = match.currentRound?.isTiebreaker ?? false;
    final effectiveUsedIds = _effectiveUsedCardIds(match, userId).toSet();
    if (fromController.isNotEmpty) {
      if (allowReuse) return fromController;
      return fromController
          .where((card) => !effectiveUsedIds.contains(card.personId))
          .toList();
    }

    final effectiveDeck = effectiveSlots
        .map((slot) {
          final selectedId = slot.selectedCardId;
          if (selectedId == null) return null;
          return slot.candidates.cast<AsyncBattleDeckCard?>().firstWhere(
            (card) => card?.personId == selectedId,
            orElse: () => null,
          );
        })
        .whereType<AsyncBattleDeckCard>()
        .toList();

    if (allowReuse) {
      return effectiveDeck;
    }

    return effectiveDeck
        .where((card) => !effectiveUsedIds.contains(card.personId))
        .toList();
  }

  List<String> _effectiveUsedCardIds(AsyncBattleMatch match, String userId) {
    final fromMatch = match.usedCardIdsFor(userId);
    if (_localSubmittedCardIds.isEmpty) return fromMatch;
    final merged = <String>[...fromMatch];
    for (final id in _localSubmittedCardIds) {
      if (!merged.contains(id)) {
        merged.add(id);
      }
    }
    return merged;
  }

  void _syncLocalSubmittedCards(AsyncBattleMatch match, String userId) {
    if (_localSubmittedCardIds.isEmpty) return;
    final remoteIds = match.usedCardIdsFor(userId).toSet();
    final nextLocal = _localSubmittedCardIds
        .where((id) => !remoteIds.contains(id))
        .toList();
    if (nextLocal.length == _localSubmittedCardIds.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _localSubmittedCardIds
          ..clear()
          ..addAll(nextLocal);
      });
    });
  }

  AsyncBattleMatch? _buildCompletedPreview({
    required AsyncBattleMatch match,
    required String? userId,
    String? cardId,
  }) {
    if (userId == null || match.isCompleted || cardId == null) return null;
    final role = match.roleFor(userId);
    if (role == null) return null;

    final myUsedIds = [...match.usedCardIdsFor(userId)];
    if (!myUsedIds.contains(cardId)) {
      myUsedIds.add(cardId);
    }
    final opponentFinished = role == AsyncBattleMatchRole.host
        ? match.guestUsedCardIds.length >= match.rounds.length
        : match.hostUsedCardIds.length >= match.rounds.length;
    if (!opponentFinished || myUsedIds.length < match.rounds.length) {
      return null;
    }

    final hostUsedIds = role == AsyncBattleMatchRole.host
        ? myUsedIds
        : match.hostUsedCardIds;
    final guestUsedIds = role == AsyncBattleMatchRole.guest
        ? myUsedIds
        : match.guestUsedCardIds;
    final guest = match.guest;
    if (guest == null) return null;

    final history = <AsyncBattleRoundOutcome>[];
    var hostScore = 0;
    var guestScore = 0;
    for (var i = 0; i < match.rounds.length; i += 1) {
      final hostCard = match.host.deck.firstWhere(
        (entry) => entry.personId == hostUsedIds[i],
      );
      final guestCard = guest.deck.firstWhere(
        (entry) => entry.personId == guestUsedIds[i],
      );
      final resolution = AsyncBattleMatchEngine.resolve(
        round: match.rounds[i],
        roundIndex: i,
        rounds: match.rounds,
        hostCard: hostCard,
        guestCard: guestCard,
      );
      hostScore += resolution.hostScoreDelta;
      guestScore += resolution.guestScoreDelta;
      history.add(
        AsyncBattleRoundOutcome(
          roundIndex: i,
          hostCardId: hostUsedIds[i],
          guestCardId: guestUsedIds[i],
          hostMetric: resolution.hostMetric,
          guestMetric: resolution.guestMetric,
          hostWon: resolution.hostWon,
          isDraw: resolution.isDraw,
          explanation: resolution.explanation,
        ),
      );
    }
    if (hostScore == guestScore) {
      return null;
    }

    return AsyncBattleMatch(
      id: match.id,
      inviteCode: match.inviteCode,
      isRandomMatch: match.isRandomMatch,
      status: AsyncBattleMatchStatus.completed,
      host: match.host,
      guest: guest,
      hostRating: match.hostRating,
      guestRating: match.guestRating,
      hostDraftSlots: match.hostDraftSlots,
      guestDraftSlots: match.guestDraftSlots,
      rounds: match.rounds,
      currentRoundIndex: match.rounds.length,
      hostScore: hostScore,
      guestScore: guestScore,
      hostUsedCardIds: hostUsedIds,
      guestUsedCardIds: guestUsedIds,
      hostGuessSubmissions: match.hostGuessSubmissions,
      guestGuessSubmissions: match.guestGuessSubmissions,
      history: history,
      createdAt: match.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  AsyncBattleMatch? _buildCompletedPreviewFromState({
    required AsyncBattleMatch match,
    required String userId,
    required List<String> effectiveUsedIds,
    required List<AsyncBattleDraftSlot> effectiveDraftSlots,
  }) {
    if (match.isCompleted || effectiveUsedIds.length < match.rounds.length) {
      return null;
    }
    final role = match.roleFor(userId);
    if (role == null || match.guest == null) return null;

    List<AsyncBattleDeckCard> effectiveDeckForCurrentUser() {
      final deck = match.deckFor(userId);
      if (deck.isNotEmpty) return deck;
      return effectiveDraftSlots
          .map((slot) {
            final selectedId = slot.selectedCardId;
            if (selectedId == null) return null;
            for (final candidate in slot.candidates) {
              if (candidate.personId == selectedId) return candidate;
            }
            return null;
          })
          .whereType<AsyncBattleDeckCard>()
          .toList();
    }

    final hostDeck = role == AsyncBattleMatchRole.host
        ? effectiveDeckForCurrentUser()
        : match.host.deck;
    final guestDeck = role == AsyncBattleMatchRole.guest
        ? effectiveDeckForCurrentUser()
        : match.guest!.deck;
    if (hostDeck.length < match.rounds.length ||
        guestDeck.length < match.rounds.length) {
      return null;
    }

    final hostUsedIds = role == AsyncBattleMatchRole.host
        ? effectiveUsedIds
        : match.hostUsedCardIds;
    final guestUsedIds = role == AsyncBattleMatchRole.guest
        ? effectiveUsedIds
        : match.guestUsedCardIds;
    if (hostUsedIds.length < match.rounds.length ||
        guestUsedIds.length < match.rounds.length) {
      return null;
    }

    final history = <AsyncBattleRoundOutcome>[];
    var hostScore = 0;
    var guestScore = 0;
    for (var i = 0; i < match.rounds.length; i += 1) {
      final hostCard = hostDeck.firstWhere(
        (entry) => entry.personId == hostUsedIds[i],
      );
      final guestCard = guestDeck.firstWhere(
        (entry) => entry.personId == guestUsedIds[i],
      );
      final resolution = AsyncBattleMatchEngine.resolve(
        round: match.rounds[i],
        roundIndex: i,
        rounds: match.rounds,
        hostCard: hostCard,
        guestCard: guestCard,
      );
      hostScore += resolution.hostScoreDelta;
      guestScore += resolution.guestScoreDelta;
      history.add(
        AsyncBattleRoundOutcome(
          roundIndex: i,
          hostCardId: hostUsedIds[i],
          guestCardId: guestUsedIds[i],
          hostMetric: resolution.hostMetric,
          guestMetric: resolution.guestMetric,
          hostWon: resolution.hostWon,
          isDraw: resolution.isDraw,
          explanation: resolution.explanation,
        ),
      );
    }
    if (hostScore == guestScore) {
      return null;
    }

    return AsyncBattleMatch(
      id: match.id,
      inviteCode: match.inviteCode,
      isRandomMatch: match.isRandomMatch,
      status: AsyncBattleMatchStatus.completed,
      host: match.host.copyWith(deck: hostDeck),
      guest: match.guest!.copyWith(deck: guestDeck),
      hostRating: match.hostRating,
      guestRating: match.guestRating,
      hostDraftSlots: match.hostDraftSlots,
      guestDraftSlots: match.guestDraftSlots,
      rounds: match.rounds,
      currentRoundIndex: match.rounds.length,
      hostScore: hostScore,
      guestScore: guestScore,
      hostUsedCardIds: hostUsedIds,
      guestUsedCardIds: guestUsedIds,
      hostGuessSubmissions: match.hostGuessSubmissions,
      guestGuessSubmissions: match.guestGuessSubmissions,
      history: history,
      createdAt: match.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _leaveCurrentMatch() async {
    try {
      await widget.controller.leaveMatch(widget.matchId);
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Battle left.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _InfoPhase extends StatelessWidget {
  final AsyncBattleMatch match;
  final String userId;
  final String title;
  final String body;
  final Color accent;
  final Widget content;

  const _InfoPhase({
    required this.match,
    required this.userId,
    required this.title,
    required this.body,
    required this.accent,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MatchHeader(match: match, userId: userId),
        const SizedBox(height: 16),
        _PhaseBanner(title: title, body: body, accent: accent),
        const SizedBox(height: 16),
        Expanded(child: BattlePanel(radius: 24, child: content)),
      ],
    );
  }
}

class _DraftPhase extends StatelessWidget {
  final AsyncBattleMatch match;
  final String userId;
  final List<AsyncBattleDraftSlot> slots;
  final Map<int, String> selectedBySlot;
  final void Function(int slotIndex, String cardId) onSelect;
  final VoidCallback onSubmit;

  const _DraftPhase({
    required this.match,
    required this.userId,
    required this.slots,
    required this.selectedBySlot,
    required this.onSelect,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCards = _selectedCards(slots, selectedBySlot);
    final ready =
        slots.isNotEmpty &&
        selectedBySlot.length == slots.length &&
        selectedBySlot.values.every((value) => value.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PhaseBanner(
          title: 'Draft - Battle vs ${match.opponentNameFor(userId)}',
          body: '4 slots, 1 card per slot',
          accent: const Color(0xFFD4B06A),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BattlePanel(
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your deck',
                        style: TextStyle(
                          color: Color(0xFFF7ECDD),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    _TinyPill(
                      label: '${selectedBySlot.length}/$battleDeckSize',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _LineupStrip(cards: selectedCards),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: slots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, slotIndex) {
                      final slot = slots[slotIndex];
                      return _OnlineDraftSlotPanel(
                        slotIndex: slotIndex,
                        slot: slot,
                        selectedCardId: selectedBySlot[slotIndex],
                        onSelect: (cardId) => onSelect(slotIndex, cardId),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: ready ? onSubmit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD4B06A),
                      foregroundColor: const Color(0xFF1B100A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text(
                      'Start battle',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RunPhase extends StatelessWidget {
  final AsyncBattleMatch match;
  final String userId;
  final int roundIndex;
  final AsyncBattleRoundSeed round;
  final List<AsyncBattleDeckCard> availableCards;
  final Future<void> Function(String) onSubmitCard;

  const _RunPhase({
    required this.match,
    required this.userId,
    required this.roundIndex,
    required this.round,
    required this.availableCards,
    required this.onSubmitCard,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _RoundTopBar(
          title: 'Round ${roundIndex + 1} of ${match.rounds.length}',
          subtitle: round.title,
          scoreLabel: _scoreLabel(match, userId),
        ),
        const SizedBox(height: 12),
        _RoundHero(
          round: round,
          roundIndex: roundIndex,
          total: match.rounds.length,
          availableCards: availableCards.length,
        ),
        const SizedBox(height: 20),
        BattleCardHand(
          key: ValueKey('online-hand-$roundIndex'),
          cards: availableCards.map(_deckCardToPerson).toList(),
          onPlay: (person) => onSubmitCard(person.id),
        ),
      ],
    );
  }
}

class _GuessRunPhase extends StatefulWidget {
  final AsyncBattleMatch match;
  final String userId;
  final int roundIndex;
  final AsyncBattleRoundSeed round;
  final ValueChanged<DateTime> onSubmitDateGuess;
  final ValueChanged<LatLng> onSubmitMapGuess;

  const _GuessRunPhase({
    required this.match,
    required this.userId,
    required this.roundIndex,
    required this.round,
    required this.onSubmitDateGuess,
    required this.onSubmitMapGuess,
  });

  @override
  State<_GuessRunPhase> createState() => _GuessRunPhaseState();
}

class _GuessRunPhaseState extends State<_GuessRunPhase> {
  late List<int> _digits;
  LatLng? _guessPoint;

  @override
  void initState() {
    super.initState();
    final eventDate = widget.round.historicalEventDateIso != null
        ? DateTime.parse(widget.round.historicalEventDateIso!).toUtc()
        : DateTime.utc(widget.round.yearTarget ?? 1900, 1, 1);
    _digits = [
      eventDate.day ~/ 10,
      eventDate.day % 10,
      eventDate.month ~/ 10,
      eventDate.month % 10,
      eventDate.year ~/ 1000,
      (eventDate.year ~/ 100) % 10,
      (eventDate.year ~/ 10) % 10,
      eventDate.year % 10,
    ];
  }

  DateTime? get _dateGuess {
    final day = (_digits[0] * 10) + _digits[1];
    final month = (_digits[2] * 10) + _digits[3];
    final year =
        (_digits[4] * 1000) +
        (_digits[5] * 100) +
        (_digits[6] * 10) +
        _digits[7];
    if (month < 1 || month > 12 || day < 1) return null;
    final candidate = DateTime.utc(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    final mySubmitted = widget.match.submittedRoundCountFor(widget.userId);
    final opponentId =
        widget.match.roleFor(widget.userId) == AsyncBattleMatchRole.host
        ? widget.match.guest?.userId
        : widget.match.host.userId;
    final opponentSubmitted = opponentId == null
        ? 0
        : widget.match.submittedRoundCountFor(opponentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoundTopBar(
          title:
              'Round ${widget.roundIndex + 1} of ${widget.match.rounds.length}',
          subtitle: widget.round.title,
          scoreLabel: _scoreLabel(widget.match, widget.userId),
        ),
        const SizedBox(height: 16),
        _RoundHero(
          round: widget.round,
          roundIndex: widget.roundIndex,
          total: widget.match.rounds.length,
          availableCards: 0,
        ),
        const SizedBox(height: 12),
        _StateChips(
          myCardsLeft: 0,
          opponentCardsLeft: max(
            0,
            widget.match.rounds.length - opponentSubmitted,
          ),
          scoreLabel: _scoreLabel(widget.match, widget.userId),
        ),
        const SizedBox(height: 14),
        Text(
          widget.round.inputMode == BattleRoundInputMode.yearLockGuess
              ? 'Guess the date'
              : 'Place your location guess',
          style: TextStyle(
            color: const Color(0xFFF7ECDD).withValues(alpha: 0.98),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.round.historicalEventTitle == null
              ? 'No card tiebreak. Your own estimate decides it now.'
              : widget.round.inputMode == BattleRoundInputMode.yearLockGuess
              ? 'Historical event: ${widget.round.historicalEventTitle}. Guess day, month, and year.'
              : 'Historical event: ${widget.round.historicalEventTitle}. Tap the location on a borders-only map.',
          style: TextStyle(
            color: const Color(0xFFD8CBB8).withValues(alpha: 0.84),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: widget.round.inputMode == BattleRoundInputMode.yearLockGuess
              ? BattlePanel(
                  radius: 24,
                  child: Column(
                    children: [
                      _TinyPill(
                        label:
                            '$mySubmitted/${widget.match.rounds.length} played',
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: BattleDateGuessPanel(
                          digits: _digits,
                          guessedDate: _dateGuess,
                          onDigitChanged: (index, value) =>
                              setState(() => _digits[index] = value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _dateGuess == null
                            ? null
                            : () => widget.onSubmitDateGuess(_dateGuess!),
                        icon: const Icon(Icons.dialpad_rounded),
                        label: const Text('Submit guess'),
                      ),
                    ],
                  ),
                )
              : BattlePanel(
                  radius: 24,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _TinyPill(
                          label:
                              '$mySubmitted/${widget.match.rounds.length} played',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: BattleMapGuessPanel(
                          selectedPoint: _guessPoint,
                          onTap: (point) => setState(() => _guessPoint = point),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _guessPoint == null
                            ? null
                            : () => widget.onSubmitMapGuess(_guessPoint!),
                        icon: const Icon(Icons.place_rounded),
                        label: const Text('Submit guess'),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _CompletedPhase extends StatelessWidget {
  final AsyncBattleMatch match;
  final String userId;

  const _CompletedPhase({required this.match, required this.userId});

  @override
  Widget build(BuildContext context) {
    final amHost = match.roleFor(userId) == AsyncBattleMatchRole.host;
    final myScore = amHost ? match.hostScore : match.guestScore;
    final opponentScore = amHost ? match.guestScore : match.hostScore;
    final winnerText = myScore == opponentScore
        ? 'Draw'
        : myScore > opponentScore
        ? 'You win'
        : '${match.opponentNameFor(userId)} wins';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MatchHeader(match: match, userId: userId),
        const SizedBox(height: 16),
        _PhaseBanner(
          title: winnerText,
          body:
              'Das Duell ist aufgeloest. Hier kannst du die vier Ergebnisse ansehen.',
          accent: myScore >= opponentScore
              ? const Color(0xFF5CCB8A)
              : const Color(0xFFE06A6A),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Column(
            children: [
              BattlePanel(
                radius: 24,
                child: Row(
                  children: [
                    Expanded(
                      child: _ScoreTile(label: 'Du', value: '$myScore'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ScoreTile(
                        label: match.opponentNameFor(userId),
                        value: '$opponentScore',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _CompletedRevealDeck(match: match, userId: userId),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundRevealPhase extends StatelessWidget {
  final AsyncBattleMatch match;
  final String userId;
  final AsyncBattleRoundOutcome entry;
  final VoidCallback onContinue;

  const _RoundRevealPhase({
    required this.match,
    required this.userId,
    required this.entry,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final result = _onlineOutcomeToBattleResult(
      match: match,
      entry: entry,
      userId: userId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MatchHeader(match: match, userId: userId),
        const SizedBox(height: 16),
        _PhaseBanner(
          title: 'Reveal round ${entry.roundIndex + 1}',
          body: 'The round is decided. After this, you continue immediately.',
          accent: const Color(0xFFD4B06A),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BattleRevealSequence(
            result: result,
            rarityColor: _onlineRarityColor,
            revealStageBuilder: (context, result) =>
                BattleRoundRevealContent(result: result),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4B06A),
              foregroundColor: const Color(0xFF1B100A),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: Icon(
              entry.roundIndex + 1 >= match.rounds.length
                  ? Icons.flag_rounded
                  : Icons.arrow_forward_rounded,
            ),
            label: Text(
              entry.roundIndex + 1 >= match.rounds.length
                  ? 'Zum Ergebnis'
                  : 'Next round',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletedRevealDeck extends StatefulWidget {
  final AsyncBattleMatch match;
  final String userId;

  const _CompletedRevealDeck({required this.match, required this.userId});

  @override
  State<_CompletedRevealDeck> createState() => _CompletedRevealDeckState();
}

class _CompletedRevealDeckState extends State<_CompletedRevealDeck> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.match.history.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = widget.match.history[_index];
    final result = _onlineOutcomeToBattleResult(
      match: widget.match,
      entry: current,
      userId: widget.userId,
    );

    return Column(
      children: [
        Expanded(
          child: BattleRevealSequence(
            key: ValueKey('${widget.match.id}-${current.roundIndex}'),
            result: result,
            rarityColor: _onlineRarityColor,
            revealStageBuilder: (context, result) =>
                BattleRoundRevealContent(result: result),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _index > 0
                    ? () => setState(() => _index -= 1)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF7ECDD),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _index + 1 < widget.match.history.length
                    ? () => setState(() => _index += 1)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD4B06A),
                  foregroundColor: const Color(0xFF1B100A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _index + 1 < widget.match.history.length
                      ? 'Round ${widget.match.history[_index + 1].roundIndex + 1}'
                      : 'Done',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubmittedCardsList extends StatelessWidget {
  final AsyncBattleMatch match;
  final String userId;
  final List<String> effectiveUsedCardIds;
  final List<AsyncBattleDraftSlot> effectiveDraftSlots;

  const _SubmittedCardsList({
    required this.match,
    required this.userId,
    required this.effectiveUsedCardIds,
    required this.effectiveDraftSlots,
  });

  @override
  Widget build(BuildContext context) {
    final deck = match.deckFor(userId);
    final fallbackDeck = effectiveDraftSlots
        .map((slot) {
          final selectedId = slot.selectedCardId;
          if (selectedId == null) return null;
          for (final candidate in slot.candidates) {
            if (candidate.personId == selectedId) {
              return candidate;
            }
          }
          return null;
        })
        .whereType<AsyncBattleDeckCard>()
        .toList();
    final availableCards = deck.isNotEmpty ? deck : fallbackDeck;
    final cards = effectiveUsedCardIds
        .map((id) {
          for (final card in availableCards) {
            if (card.personId == id) return card;
          }
          return null;
        })
        .whereType<AsyncBattleDeckCard>()
        .toList();

    return ListView.separated(
      itemCount: cards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final card = cards[index];
        return Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                card.portraitAsset,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Round ${index + 1}',
                    style: TextStyle(
                      color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_clock_rounded, color: Color(0xFFD4B06A)),
          ],
        );
      },
    );
  }
}

class _MatchHeader extends StatelessWidget {
  final AsyncBattleMatch match;
  final String userId;

  const _MatchHeader({required this.match, required this.userId});

  @override
  Widget build(BuildContext context) {
    final role = match.roleFor(userId);
    final myScore = role == AsyncBattleMatchRole.host
        ? match.hostScore
        : match.guestScore;
    final otherScore = role == AsyncBattleMatchRole.host
        ? match.guestScore
        : match.hostScore;

    return BattlePanel(
      radius: 24,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.opponentNameFor(userId),
                  style: const TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Code ${match.inviteCode}',
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.86),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _TinyPill(label: '$myScore:$otherScore'),
        ],
      ),
    );
  }
}

class _PhaseBanner extends StatelessWidget {
  final String title;
  final String body;
  final Color accent;

  const _PhaseBanner({
    required this.title,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: const Color(0xFFF7ECDD).withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundHero extends StatelessWidget {
  final AsyncBattleRoundSeed round;
  final int roundIndex;
  final int total;
  final int availableCards;

  const _RoundHero({
    required this.round,
    required this.roundIndex,
    required this.total,
    required this.availableCards,
  });

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFD4B06A);
    final showFocusPanel =
        round.type == BattleRoundType.closerToYear ||
        round.type == BattleRoundType.closerToLocation;
    return BattlePanel(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: accent.withValues(alpha: 0.16),
                  border: Border.all(color: accent.withValues(alpha: 0.32)),
                ),
                child: Icon(
                  battleRoundIcon(round.type),
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      round.prompt,
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      battleRoundHelperText(round.type),
                      style: TextStyle(
                        color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showFocusPanel) ...[
            const SizedBox(height: 10),
            _RoundSpotlightCard(round: round),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '$availableCards cards in deck',
              style: TextStyle(
                color: const Color(0xFFD8CBB8).withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String scoreLabel;

  const _RoundTopBar({
    required this.title,
    required this.subtitle,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BattleRoundTopBar(
      title: title,
      subtitle: subtitle,
      trailingLabel: scoreLabel,
    );
  }
}

class _StateChips extends StatelessWidget {
  final int myCardsLeft;
  final int opponentCardsLeft;
  final String scoreLabel;

  const _StateChips({
    required this.myCardsLeft,
    required this.opponentCardsLeft,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BattleStateChips(
      leftLabel: '$myCardsLeft cards',
      middleLabel: 'Opponent $opponentCardsLeft',
      rightLabel: scoreLabel,
    );
  }
}

class _RoundSpotlightCard extends StatelessWidget {
  final AsyncBattleRoundSeed round;

  const _RoundSpotlightCard({required this.round});

  @override
  Widget build(BuildContext context) {
    final title = switch (round.type) {
      BattleRoundType.closerToYear => '${round.yearTarget}',
      BattleRoundType.closerToLocation =>
        round.isTiebreaker ? 'Mystery map' : (round.locationLabel ?? ''),
      BattleRoundType.bornEarlier => 'Birth year',
      BattleRoundType.longerLife => 'Lifespan',
    };
    final eyebrow = switch (round.type) {
      BattleRoundType.closerToYear => 'Target year',
      BattleRoundType.closerToLocation =>
        round.isTiebreaker ? 'Historical target' : 'Target place',
      BattleRoundType.bornEarlier => 'Time rule',
      BattleRoundType.longerLife => 'Comparison',
    };
    final caption = switch (round.type) {
      BattleRoundType.closerToYear => 'Smaller difference wins.',
      BattleRoundType.closerToLocation =>
        round.isTiebreaker
            ? 'Shorter distance wins. Borders only, no place names.'
            : 'Shorter distance wins.',
      BattleRoundType.bornEarlier => 'Earlier wins.',
      BattleRoundType.longerLife => 'Longer wins.',
    };

    return BattleRoundSpotlightCard(
      eyebrow: eyebrow,
      title: title,
      subtitle: '',
      caption: caption,
      icon: battleRoundIcon(round.type),
    );
  }
}

BattleRoundResult _onlineOutcomeToBattleResult({
  required AsyncBattleMatch match,
  required AsyncBattleRoundOutcome entry,
  required String userId,
}) {
  final round = match.rounds[entry.roundIndex];
  final amHost = match.roleFor(userId) == AsyncBattleMatchRole.host;

  if (round.inputMode != BattleRoundInputMode.cardSelection) {
    return BattleRoundResult(
      roundNumber: entry.roundIndex + 1,
      definition: BattleRoundDefinition(
        type: round.type,
        title: round.title,
        prompt: round.prompt,
        isTiebreaker: round.isTiebreaker,
        inputMode: round.inputMode,
        yearTarget: round.yearTarget == null
            ? null
            : BattleYearTarget(
                label: round.yearLabel ?? round.title,
                year: round.yearTarget!,
                context: round.prompt,
              ),
        locationTarget: round.locationLat == null || round.locationLng == null
            ? null
            : BattleLocationTarget(
                label: round.locationLabel ?? round.title,
                regionLabel: '',
                lat: round.locationLat!,
                lng: round.locationLng!,
                context: round.prompt,
              ),
        historicalEventTarget:
            round.historicalEventTitle == null ||
                round.historicalEventDateIso == null ||
                round.historicalEventLat == null ||
                round.historicalEventLng == null ||
                round.historicalEventLocationLabel == null ||
                round.historicalEventRegionLabel == null
            ? null
            : BattleHistoricalEventTarget(
                title: round.historicalEventTitle!,
                date: DateTime.parse(round.historicalEventDateIso!).toUtc(),
                locationLabel: round.historicalEventLocationLabel!,
                regionLabel: round.historicalEventRegionLabel!,
                lat: round.historicalEventLat!,
                lng: round.historicalEventLng!,
                summary: round.prompt,
              ),
      ),
      playerCard: null,
      botCard: null,
      playerMetric: amHost ? entry.hostMetric : entry.guestMetric,
      botMetric: amHost ? entry.guestMetric : entry.hostMetric,
      playerWon: entry.isDraw
          ? false
          : (amHost ? entry.hostWon : !entry.hostWon),
      isDraw: entry.isDraw,
      explanation: entry.explanation,
      playerGuessedYear: amHost
          ? entry.hostGuessedYear
          : entry.guestGuessedYear,
      botGuessedYear: amHost ? entry.guestGuessedYear : entry.hostGuessedYear,
      playerGuessedDate: DateTime.tryParse(
        amHost
            ? (entry.hostGuessedDateIso ?? '')
            : (entry.guestGuessedDateIso ?? ''),
      )?.toUtc(),
      botGuessedDate: DateTime.tryParse(
        amHost
            ? (entry.guestGuessedDateIso ?? '')
            : (entry.hostGuessedDateIso ?? ''),
      )?.toUtc(),
      playerGuessLat: amHost ? entry.hostGuessLat : entry.guestGuessLat,
      playerGuessLng: amHost ? entry.hostGuessLng : entry.guestGuessLng,
      botGuessLat: amHost ? entry.guestGuessLat : entry.hostGuessLat,
      botGuessLng: amHost ? entry.guestGuessLng : entry.hostGuessLng,
    );
  }

  final hostCard = match.host.deck.firstWhere(
    (card) => card.personId == entry.hostCardId,
  );
  final guestCard = match.guest!.deck.firstWhere(
    (card) => card.personId == entry.guestCardId,
  );

  return BattleRoundResult(
    roundNumber: entry.roundIndex + 1,
    definition: BattleRoundDefinition(
      type: round.type,
      title: round.title,
      prompt: round.prompt,
      isTiebreaker: round.isTiebreaker,
      inputMode: round.inputMode,
      yearTarget: round.yearTarget == null
          ? null
          : BattleYearTarget(
              label: round.yearLabel ?? round.title,
              year: round.yearTarget!,
              context: round.prompt,
            ),
      locationTarget: round.locationLat == null || round.locationLng == null
          ? null
          : BattleLocationTarget(
              label: round.locationLabel ?? round.title,
              regionLabel: '',
              lat: round.locationLat!,
              lng: round.locationLng!,
              context: round.prompt,
            ),
    ),
    playerCard: _deckCardToPerson(amHost ? hostCard : guestCard),
    botCard: _deckCardToPerson(amHost ? guestCard : hostCard),
    playerMetric: amHost ? entry.hostMetric : entry.guestMetric,
    botMetric: amHost ? entry.guestMetric : entry.hostMetric,
    playerWon: entry.isDraw ? false : (amHost ? entry.hostWon : !entry.hostWon),
    isDraw: entry.isDraw,
    explanation: entry.explanation,
  );
}

Person _deckCardToPerson(AsyncBattleDeckCard card) {
  return Person(
    id: card.personId,
    name: card.name,
    birthYear: card.birthYear,
    deathYear: card.deathYear,
    category: card.category,
    hint: card.hintTag,
    portraitImageAsset: card.portraitAsset,
    vsImageAsset: card.vsAsset,
    birthLat: card.birthLat,
    birthLng: card.birthLng,
    birthCountry: '',
    rarity: card.rarity,
  );
}

class _RevealCard extends StatelessWidget {
  final String label;
  final AsyncBattleDeckCard card;

  const _RevealCard({required this.label, required this.card});

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              card.portraitAsset,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card.name,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String label;

  const _TinyPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFD4B06A).withValues(alpha: 0.12),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD4B06A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LineupStrip extends StatelessWidget {
  final List<AsyncBattleDeckCard> cards;

  const _LineupStrip({required this.cards});

  @override
  Widget build(BuildContext context) {
    return BattleLineupStrip(
      totalSlots: battleDeckSize,
      filledCards: cards
          .map(
            (card) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                card.portraitAsset,
                width: 60,
                height: 86,
                fit: BoxFit.cover,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OnlineDraftSlotPanel extends StatelessWidget {
  final int slotIndex;
  final AsyncBattleDraftSlot slot;
  final String? selectedCardId;
  final ValueChanged<String> onSelect;

  const _OnlineDraftSlotPanel({
    required this.slotIndex,
    required this.slot,
    required this.selectedCardId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
                ),
                child: Center(
                  child: Text(
                    '${slotIndex + 1}',
                    style: const TextStyle(
                      color: Color(0xFFD4B06A),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  slot.type.label,
                  style: const TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                '${slot.candidates.length} cards',
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: mobile ? 246 : 272,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slot.candidates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final card = slot.candidates[index];
                final selected = selectedCardId == card.personId;
                return AnimatedSlide(
                  duration: Duration(milliseconds: 170 + (index * 30)),
                  curve: Curves.easeOutCubic,
                  offset: selected ? Offset.zero : const Offset(0, 0.015),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 170),
                    curve: Curves.easeOutBack,
                    scale: selected ? 1.01 : 0.97,
                    child: SizedBox(
                      width: mobile ? 168 : 184,
                      child: _OnlineBattleFigureCard(
                        card: card,
                        selected: selected,
                        subtitle: card.hintTag,
                        compact: mobile,
                        deckMode: true,
                        onTap: () => onSelect(card.personId),
                        label: selected ? 'Selected' : slot.type.label,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleFigureCard extends StatelessWidget {
  final AsyncBattleDeckCard card;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _BattleFigureCard({
    required this.card,
    required this.label,
    required this.onTap,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD4B06A).withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4B06A).withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  card.portraitAsset,
                  width: 92,
                  height: 112,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TinyPill(label: label),
                    const SizedBox(height: 10),
                    Text(
                      card.name,
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.hintTag,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFFD4B06A)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineBattleFigureCard extends StatelessWidget {
  final AsyncBattleDeckCard card;
  final bool selected;
  final bool deckMode;
  final String label;
  final String subtitle;
  final bool compact;
  final VoidCallback onTap;

  const _OnlineBattleFigureCard({
    required this.card,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.compact,
    this.selected = false,
    this.deckMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _onlineRarityColor(card.rarity);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 24 : 30),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.24 : 0.12),
                blurRadius: selected ? 24 : 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 24 : 30),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.96)
                    : Colors.white.withValues(alpha: 0.10),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 24 : 30),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(card.portraitAsset, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.12),
                            Colors.black.withValues(alpha: 0.70),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.48, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: compact ? 10 : 14,
                    left: compact ? 10 : 14,
                    child: _OnlineTagPill(
                      icon: _onlineCategoryIcon(card.category),
                      label: compact ? 'Play' : label,
                    ),
                  ),
                  Positioned(
                    top: compact ? 10 : 14,
                    right: compact ? 10 : 14,
                    child: _OnlineMiniRarityBadge(rarity: card.rarity),
                  ),
                  Positioned(
                    left: compact ? 10 : 14,
                    right: compact ? 10 : 14,
                    bottom: compact ? 10 : 14,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 10 : 12,
                        compact ? 10 : 12,
                        compact ? 10 : 12,
                        compact ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(compact ? 14 : 18),
                        color: Colors.black.withValues(alpha: 0.28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFFF7ECDD),
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 12 : 14,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 8),
                          Wrap(
                            spacing: compact ? 6 : 8,
                            runSpacing: compact ? 6 : 8,
                            children: [
                              _OnlineTinyInfoPill(
                                label: _onlineCategoryLabel(card.category),
                              ),
                              _OnlineTinyInfoPill(label: subtitle),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: compact ? 8 : 12,
                      bottom: compact ? 78 : 98,
                      child: Container(
                        width: compact ? 26 : 36,
                        height: compact ? 26 : 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFD4B06A),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: const Color(0xFF1B100A),
                          size: compact ? 14 : 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlineTagPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OnlineTagPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFF7ECDD)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineTinyInfoPill extends StatelessWidget {
  final String label;

  const _OnlineTinyInfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFF7ECDD),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _OnlineMiniRarityBadge extends StatelessWidget {
  final PersonRarity rarity;

  const _OnlineMiniRarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    final color = _onlineRarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: color.withValues(alpha: 0.88)),
      ),
      child: Text(
        rarity.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

List<AsyncBattleDeckCard> _selectedCards(
  List<AsyncBattleDraftSlot> slots,
  Map<int, String> selectedBySlot,
) {
  final cards = <AsyncBattleDeckCard>[];
  for (var i = 0; i < slots.length; i += 1) {
    final selectedId = selectedBySlot[i];
    if (selectedId == null) continue;
    final match = slots[i].candidates.where(
      (card) => card.personId == selectedId,
    );
    if (match.isNotEmpty) {
      cards.add(match.first);
    }
  }
  return cards;
}

String _scoreLabel(AsyncBattleMatch match, String userId) {
  final role = match.roleFor(userId);
  final myScore = role == AsyncBattleMatchRole.host
      ? match.hostScore
      : match.guestScore;
  final otherScore = role == AsyncBattleMatchRole.host
      ? match.guestScore
      : match.hostScore;
  return '$myScore:$otherScore';
}

Color _onlineRarityColor(PersonRarity rarity) {
  switch (rarity) {
    case PersonRarity.common:
      return const Color(0xFFBEC3CD);
    case PersonRarity.rare:
      return const Color(0xFF54A5FF);
    case PersonRarity.epic:
      return const Color(0xFFC06CFF);
    case PersonRarity.legendary:
      return const Color(0xFFF0C45A);
  }
}

String _onlineCategoryLabel(Category category) {
  switch (category) {
    case Category.politician:
      return 'Politics';
    case Category.scientist:
      return 'Science';
    case Category.artist:
      return 'Art';
    case Category.athlete:
      return 'Sports';
  }
}

IconData _onlineCategoryIcon(Category category) {
  switch (category) {
    case Category.politician:
      return Icons.account_balance_rounded;
    case Category.scientist:
      return Icons.science_rounded;
    case Category.artist:
      return Icons.palette_rounded;
    case Category.athlete:
      return Icons.emoji_events_rounded;
  }
}
