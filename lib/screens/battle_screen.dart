import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../ads/ads_service.dart';
import '../design/app_theme.dart';
import '../localization/app_language.dart';
import '../battle/battle_draft_builder.dart';
import '../battle/legendary_abilities.dart';
import '../battle/battle_models.dart';
import '../battle/battle_shared.dart';
import '../battle/battle_session.dart';
import '../logic/game_session.dart';
import '../logic/progression_catalog.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../models/person_rarity.dart';
import '../online/online_battle_controller.dart';
import '../online/online_models.dart';
import '../widgets/person_portrait.dart';
import '../widgets/battle_card_hand.dart';
import 'battle_guess_widgets.dart';
import 'battle_hub_widgets.dart';
import 'battle_reveal_content_widgets.dart';
import 'battle_reveal_host_widgets.dart';
import 'battle_round_widgets.dart';
import 'battle_status_widgets.dart';
import 'battle_summary_widgets.dart';
import 'online_match_screen.dart';

class BattleScreen extends StatefulWidget {
  final GameSession session;
  final OnlineBattleController onlineController;
  final AdsService adsService;

  const BattleScreen({
    super.key,
    required this.session,
    required this.onlineController,
    required this.adsService,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _OnlineBattleNotice {
  final String matchId;
  final String title;
  final String message;
  final IconData icon;
  final Color accent;

  const _OnlineBattleNotice({
    required this.matchId,
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
  });
}

class _BattleScreenState extends State<BattleScreen> {
  BattleDraftState? _draftState;
  BattleSession? _battleSession;
  List<BattleDraftSlotType> _missingSlots = const [];
  final Map<String, int> _knownOnlineProgress = {};
  _OnlineBattleNotice? _onlineNotice;
  BattleSession? _interstitialShownForBattle;
  BattleSession? _coinsGrantedForBattle;
  int? _preparedTiebreakRoundIndex;
  late List<int> _dateGuessDigits;
  LatLng? _tiebreakMapGuess;
  int _hubTabIndex = 0;
  bool _battleHeaderExpanded = false;

  @override
  void initState() {
    super.initState();
    _dateGuessDigits = [0, 1, 0, 1, 1, 9, 0, 0];
    widget.onlineController.addListener(_handleOnlineControllerChanged);
  }

  @override
  void dispose() {
    widget.onlineController.removeListener(_handleOnlineControllerChanged);
    super.dispose();
  }

  void _handleOnlineControllerChanged() {
    _maybeNotifyAboutOnlineMatches();
  }

  void _maybeNotifyAboutOnlineMatches() {
    if (!mounted) return;
    final uid = widget.onlineController.userId;
    if (uid == null) return;
    final activeMatchIds = widget.onlineController.matches
        .map((match) => match.id)
        .toSet();
    _knownOnlineProgress.removeWhere(
      (matchId, _) => !activeMatchIds.contains(matchId),
    );
    _OnlineBattleNotice? nextNotice;
    var nextPriority = -1;

    for (final match in widget.onlineController.matches) {
      final myProgress = match.usedCardIdsFor(uid).length;
      final opponentProgress = match.roleFor(uid) == AsyncBattleMatchRole.host
          ? match.guestUsedCardIds.length
          : match.hostUsedCardIds.length;
      final hasSeenMatch = _knownOnlineProgress.containsKey(match.id);
      final previousProgress = _knownOnlineProgress[match.id] ?? 0;
      _knownOnlineProgress[match.id] = opponentProgress;

      final shouldNotify =
          match.hasOpponent &&
          opponentProgress > previousProgress &&
          (hasSeenMatch || opponentProgress > 0) &&
          myProgress < match.rounds.length;
      final opponentTurnReadyNotify =
          match.hasOpponent &&
          opponentProgress >= match.rounds.length &&
          previousProgress < match.rounds.length &&
          myProgress < match.rounds.length &&
          !match.isCompleted;
      final revealReadyNotify =
          match.hasOpponent &&
          match.isCompleted &&
          opponentProgress > previousProgress &&
          myProgress >= match.rounds.length;
      if (revealReadyNotify) {
        nextNotice = _OnlineBattleNotice(
          matchId: match.id,
          title: context.tr('Battle update', 'Battle update'),
          message: context.tr(
            '${match.opponentNameFor(uid)} is done - check how the duel ended.',
            '${match.opponentNameFor(uid)} is done - check how the duel ended.',
          ),
          icon: Icons.emoji_events_rounded,
          accent: const Color(0xFFD4B06A),
        );
        nextPriority = 3;
      } else if (opponentTurnReadyNotify) {
        if (nextPriority < 2) {
          nextNotice = _OnlineBattleNotice(
            matchId: match.id,
            title: context.tr('Your turn', 'Your turn'),
            message: context.tr(
              '${match.opponentNameFor(uid)} is done - it is your turn now.',
              '${match.opponentNameFor(uid)} is done - it is your turn now.',
            ),
            icon: Icons.play_circle_fill_rounded,
            accent: const Color(0xFF6FA8FF),
          );
          nextPriority = 2;
        }
      } else if (shouldNotify && nextPriority < 1) {
        nextNotice = _OnlineBattleNotice(
          matchId: match.id,
          title: context.tr('New async battle', 'New async battle'),
          message: context.tr(
            '${match.opponentNameFor(uid)} has prepared an async match for you.',
            '${match.opponentNameFor(uid)} has prepared an async match for you.',
          ),
          icon: Icons.notifications_active_rounded,
          accent: const Color(0xFF8DC8FF),
        );
        nextPriority = 1;
      }
    }

    final hasCurrentNotice =
        _onlineNotice != null &&
        activeMatchIds.contains(_onlineNotice!.matchId);
    if (nextNotice != null) {
      final changed =
          _onlineNotice?.matchId != nextNotice.matchId ||
          _onlineNotice?.title != nextNotice.title ||
          _onlineNotice?.message != nextNotice.message;
      if (changed) {
        setState(() {
          _onlineNotice = nextNotice;
        });
      }
    } else if (!hasCurrentNotice && _onlineNotice != null) {
      setState(() {
        _onlineNotice = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final canAccess = widget.session.canAccessBattleMode;
        final activeBattleSession = canAccess ? _battleSession : null;
        final activeDraftState = canAccess ? _draftState : null;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(gradient: AppPalette.pageGradient),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    if (activeDraftState == null && activeBattleSession == null)
                      _buildHeader(context),
                    if (activeDraftState == null && activeBattleSession == null)
                      const SizedBox(height: 14),
                    Expanded(
                      child: !canAccess
                          ? _buildLockedView(context)
                          : activeBattleSession != null
                          ? _buildBattleContent(context, activeBattleSession)
                          : activeDraftState != null
                          ? _buildDraftView(context, activeDraftState)
                          : _buildHubView(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final inActiveFlow =
        widget.session.canAccessBattleMode &&
        (_battleSession != null || _draftState != null);
    final title = widget.session.canAccessBattleMode && _battleSession != null
        ? 'Battle'
        : widget.session.canAccessBattleMode && _draftState != null
        ? 'Draft'
        : context.tr('Battle Mode', 'Battle Mode');
    final badge = widget.session.canAccessBattleMode
        ? '${widget.session.ownedCardCount} cards'
        : 'Lv 10';

    if (inActiveFlow) {
      return _buildPanel(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFD4B06A).withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFD4B06A),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF7ECDD),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            if (!compact) ...[
              BattleSlimInfoPill(
                icon: Icons.style_rounded,
                label: context.tr('4 cards', '4 cards'),
              ),
              SizedBox(width: 8),
              BattleSlimInfoPill(
                icon: Icons.timelapse_rounded,
                label: context.tr('4 rounds + tiebreak', '4 rounds + tiebreak'),
              ),
              SizedBox(width: 8),
            ],
            BattlePill(label: badge),
          ],
        ),
      );
    }

    return _buildPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _battleHeaderExpanded = !_battleHeaderExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: const Color(
                              0xFFD4B06A,
                            ).withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFD4B06A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Color(0xFFF7ECDD),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _battleHeaderExpanded
                                    ? 'Tap to collapse'
                                    : 'Tap to expand battle rules',
                                style: TextStyle(
                                  color: const Color(
                                    0xFFD8CBB8,
                                  ).withValues(alpha: 0.78),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        BattlePill(label: badge),
                        const SizedBox(width: 8),
                        Icon(
                          _battleHeaderExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFFD4B06A),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _battleHeaderExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'Turn quiz knowledge into tactical duels',
                            'Turn quiz knowledge into tactical duels',
                          ),
                          style: TextStyle(
                            color: const Color(
                              0xFFD8CBB8,
                            ).withValues(alpha: 0.86),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        BattleStatusRow(
                          items: [
                            BattleStatusItem(
                              icon: Icons.style_rounded,
                              label: context.tr(
                                '4 cards per battle',
                                '4 cards per battle',
                              ),
                            ),
                            BattleStatusItem(
                              icon: Icons.timelapse_rounded,
                              label: context.tr(
                                '4 rounds + tiebreak',
                                '4 rounds + tiebreak',
                              ),
                            ),
                            BattleStatusItem(
                              icon: Icons.school_rounded,
                              label: context.tr(
                                'Quiz stays your core progression',
                                'Quiz stays your core progression',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xFFD4B06A).withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFD4B06A),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFF7ECDD),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(
                          'Turn quiz knowledge into tactical duels',
                          'Turn quiz knowledge into tactical duels',
                        ),
                        style: TextStyle(
                          color: const Color(
                            0xFFD8CBB8,
                          ).withValues(alpha: 0.86),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BattleStatusRow(
                    items: [
                      BattleStatusItem(
                        icon: Icons.style_rounded,
                        label: context.tr(
                          '4 cards per battle',
                          '4 cards per battle',
                        ),
                      ),
                      BattleStatusItem(
                        icon: Icons.timelapse_rounded,
                        label: context.tr(
                          '4 rounds + tiebreak',
                          '4 rounds + tiebreak',
                        ),
                      ),
                      BattleStatusItem(
                        icon: Icons.school_rounded,
                        label: context.tr(
                          'Quiz stays your core progression',
                          'Quiz stays your core progression',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                BattlePill(label: badge),
              ],
            ),
    );
  }

  Widget _buildLockedView(BuildContext context) {
    final currentLevel = widget.session.level;
    final target =
        ProgressionCatalog.featureUnlockLevel(AppFeature.battle) ?? 10;
    final progress = (currentLevel / target).clamp(0.0, 1.0);

    return _buildPanel(
      key: const ValueKey('battle-locked'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Battle unlocks at level 10',
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 24,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Quiz builds your collection first. At level 10, offline and online duels open with drafting, rounds, and tiebreaks.',
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.92),
              height: 1.45,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _ProgressPanel(
            current: currentLevel,
            target: target,
            progress: progress.clamp(0.0, 1.0),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _FeatureChip(
                icon: Icons.layers_rounded,
                label: '4 cards per battle',
              ),
              _FeatureChip(
                icon: Icons.block_rounded,
                label: 'Each card only once',
              ),
              _FeatureChip(
                icon: Icons.emoji_events_rounded,
                label: '4 rounds + tiebreak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHubView(BuildContext context) {
    return _buildPanel(
      key: const ValueKey('battle-hub'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHubTabBar(),
          const SizedBox(height: 10),
          Text(
            _hubTabIndex == 0
                ? 'Start a local draft and play immediately on this device.'
                : 'Jump into async duels and manage your active matches here.',
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.90),
              height: 1.35,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: _hubTabIndex == 0
                  ? _buildOfflineHubSection(context)
                  : _buildOnlineHubSection(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTabBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildHubTabButton(
              label: context.tr('Offline', 'Offline'),
              icon: Icons.sports_martial_arts_rounded,
              selected: _hubTabIndex == 0,
              onTap: () => setState(() => _hubTabIndex = 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildHubTabButton(
              label: context.tr('Online', 'Online'),
              icon: Icons.public_rounded,
              selected: _hubTabIndex == 1,
              onTap: () => setState(() => _hubTabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTabButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = selected ? const Color(0xFFD4B06A) : const Color(0xFFD8CBB8);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? const Color(0xFFD4B06A).withValues(alpha: 0.14)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? const Color(0xFFD4B06A).withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFFF7ECDD) : accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineHubSection(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('battle-hub-offline'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BattleModeTile(
            title: context.tr('Offline Battle', 'Offline Battle'),
            subtitle: 'Draft locally and play right away on this device.',
            accent: const Color(0xFFD4B06A),
            actionLabel: context.tr('Start offline', 'Start offline'),
            onAction: _startDraft,
          ),
          const SizedBox(height: 12),
          _buildCompactBattleInfo(
            items: const [
              (icon: Icons.layers_rounded, label: '4 category slots'),
              (icon: Icons.block_rounded, label: 'Each card only once'),
              (icon: Icons.emoji_events_rounded, label: '4 rounds + tiebreak'),
            ],
          ),
          if (_missingSlots.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: const Color(0xFF5D2A17).withValues(alpha: 0.42),
                border: Border.all(
                  color: const Color(0xFFE39063).withValues(alpha: 0.50),
                ),
              ),
              child: const Text(
                'You are currently missing at least one category for a draft. Unlock more categories in quiz first.',
                style: TextStyle(
                  color: Color(0xFFF7ECDD),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeckPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Battle Deck Preview', 'Battle Deck Preview'),
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              'Your cards stay the visual focus. The draft starts directly from your collection.',
              'Your cards stay the visual focus. The draft starts directly from your collection.',
            ),
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: min(4, widget.session.unlockedPersons.length),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final person = widget.session.unlockedPersons[index];
                return SizedBox(
                  width: 170,
                  child: _BattleFigureCard(
                    person: person,
                    label: context.tr('Collection', 'Collection'),
                    subtitle: battleTagForPersonId(person.id, person.hint),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineHubSection(BuildContext context) {
    final controller = widget.onlineController;
    final openMatches = controller.matches
        .where((match) => !match.isCompleted)
        .toList();
    final completedMatches = controller.matches
        .where((match) => match.isCompleted)
        .take(5)
        .toList();
    final profile = controller.profile;

    return SingleChildScrollView(
      key: const ValueKey('battle-hub-online'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color:
                      (controller.usesFirebase
                              ? const Color(0xFF5CCB8A)
                              : const Color(0xFFE39063))
                          .withValues(alpha: 0.14),
                  border: Border.all(
                    color:
                        (controller.usesFirebase
                                ? const Color(0xFF5CCB8A)
                                : const Color(0xFFE39063))
                            .withValues(alpha: 0.34),
                  ),
                ),
                child: Text(
                  controller.usesFirebase
                      ? 'Firebase'
                      : context.tr('Local', 'Local'),
                  style: TextStyle(
                    color: controller.usesFirebase
                        ? const Color(0xFF5CCB8A)
                        : const Color(0xFFE39063),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          BattleModeTile(
            title: context.tr('Online vs random', 'Online vs random'),
            subtitle:
                'Searches for a fitting Elo match or creates your own async duel.',
            accent: const Color(0xFF6FA8FF),
            actionLabel: context.tr(
              'Find random opponent',
              'Find random opponent',
            ),
            onAction: _startRandomBattle,
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              controller.errorMessage!,
              style: const TextStyle(
                color: Color(0xFFE39063),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_onlineNotice != null) ...[
            const SizedBox(height: 12),
            _buildOnlineNoticeCard(context, _onlineNotice!),
          ],
          const SizedBox(height: 12),
          _buildOnlineMatchesCard(
            openMatches,
            completedMatches,
            profile?.userId ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBattleInfo({
    required List<({IconData icon, String label})> items,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          _FeatureChip(icon: item.icon, label: item.label),
      ],
    );
  }

  Widget _buildOnlineNoticeCard(
    BuildContext context,
    _OnlineBattleNotice notice,
  ) {
    return _buildPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: notice.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: notice.accent.withValues(alpha: 0.32)),
            ),
            child: Icon(notice.icon, color: notice.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: const TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notice.message,
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.9),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openOnlineNoticeMatch(notice),
                      style: FilledButton.styleFrom(
                        backgroundColor: notice.accent,
                        foregroundColor: const Color(0xFF1B100A),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(context.tr('Open', 'Open')),
                    ),
                    TextButton.icon(
                      onPressed: _dismissOnlineNotice,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(context.tr('Dismiss', 'Dismiss')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineMatchesCard(
    List<AsyncBattleMatch> openMatches,
    List<AsyncBattleMatch> completedMatches,
    String userId,
  ) {
    final hasAnyMatches = openMatches.isNotEmpty || completedMatches.isNotEmpty;

    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: BattleOnlineGroupHeader(
                  title: context.tr('Your online duels', 'Your online duels'),
                  count: openMatches.length + completedMatches.length,
                ),
              ),
              if (openMatches.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _leaveAllOpenMatches,
                  child: Text(
                    context.tr(
                      'Leave all open matches',
                      'Leave all open matches',
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (!hasAnyMatches)
            BattleOnlineEmptyTile(
              label: context.tr(
                'No active online duels yet. Find a random opponent to start your first async match.',
                'No active online duels yet. Find a random opponent to start your first async match.',
              ),
            )
          else ...[
            if (openMatches.isNotEmpty)
              ...openMatches.map(
                (match) => BattleOnlineActionTile(
                  title: match.opponentNameFor(userId),
                  subtitle: _onlineMatchStatusLabel(match, userId),
                  accent: const Color(0xFF6FA8FF),
                  actionLabel: context.tr('Open', 'Open'),
                  onAction: () => _openOnlineMatch(match),
                  secondaryLabel: context.tr('Leave', 'Leave'),
                  onSecondaryAction: () => _leaveMatch(match),
                ),
              ),
            if (completedMatches.isNotEmpty) ...[
              if (openMatches.isNotEmpty) const SizedBox(height: 12),
              Text(
                context.tr('Completed', 'Completed'),
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...completedMatches.map(
                (match) => BattleOnlineActionTile(
                  title: match.opponentNameFor(userId),
                  subtitle: _onlineMatchResultLabel(match, userId),
                  accent: const Color(0xFFD4B06A),
                  actionLabel: context.tr('Open', 'Open'),
                  onAction: () => _openOnlineMatch(match),
                ),
              ),
              Text(
                context.tr(
                  'Only the latest 5 completed duels are shown.',
                  'Only the latest 5 completed duels are shown.',
                ),
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.76),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDraftView(BuildContext context, BattleDraftState draftState) {
    final mobile = MediaQuery.sizeOf(context).width < 640;

    return _buildPanel(
      key: const ValueKey('battle-draft'),
      padding: EdgeInsets.fromLTRB(
        mobile ? 10 : 12,
        mobile ? 10 : 12,
        mobile ? 10 : 12,
        mobile ? 10 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Draft',
                  style: TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              BattlePill(
                label: '${draftState.selectedCards.length}/$battleDeckSize',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '4 slots, 1 card per slot',
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: draftState.slots.length,
              separatorBuilder: (_, __) => SizedBox(height: mobile ? 12 : 16),
              itemBuilder: (context, slotIndex) {
                final slot = draftState.slots[slotIndex];
                return _DraftSlotPanel(
                  slotIndex: slotIndex,
                  slot: slot,
                  onSelect: (person) => _selectDraftCard(slotIndex, person),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _DraftSelectionStrip(cards: draftState.selectedCards),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _draftState = null),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: draftState.isReady ? _beginBattle : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD4B06A),
                  foregroundColor: const Color(0xFF1B100A),
                  padding: EdgeInsets.symmetric(
                    horizontal: mobile ? 16 : 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.flash_on_rounded),
                label: Text(
                  mobile ? 'Start' : 'Start battle',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBattleContent(BuildContext context, BattleSession session) {
    if (session.isFinished && !session.isShowingResult) {
      _maybeShowBattleInterstitial(session);
      return _buildSummaryView(context, session);
    }
    if (session.isShowingResult && session.lastResult != null) {
      return _buildResultView(context, session.lastResult!, session);
    }
    return _buildChooseCardView(context, session);
  }

  Widget _buildChooseCardView(BuildContext context, BattleSession session) {
    final round = session.currentRound;
    _prepareTiebreakState(round, session.currentRoundIndex);
    if (round.usesDirectGuess) {
      return _buildDirectGuessView(context, session, round);
    }
    return ListView(
      padding: const EdgeInsets.only(top: 44, bottom: 12),
      children: [
        BattleRoundHeader(session: session),
        const SizedBox(height: 12),
        _RoundMissionCard(round: round),
        const SizedBox(height: 20),
        BattleCardHand(
          key: ValueKey('hand-${session.currentRoundIndex}'),
          cards: session.availablePlayerCards,
          onPlay: _playCard,
        ),
      ],
    );
  }

  Widget _buildDirectGuessView(
    BuildContext context,
    BattleSession session,
    BattleRoundDefinition round,
  ) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    final compactMobile = MediaQuery.sizeOf(context).width < 430;

    return _buildPanel(
      key: ValueKey('battle-guess-${session.currentRoundIndex}'),
      padding: EdgeInsets.fromLTRB(
        compactMobile ? 10 : 16,
        compactMobile ? 10 : 16,
        compactMobile ? 10 : 16,
        compactMobile ? 10 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BattleRoundHeader(session: session),
          SizedBox(height: compactMobile ? 8 : 14),
          _TiebreakMissionCard(
            round: round,
            scorePanel: !mobile
                ? BattleScorePanelWidget(session: session)
                : null,
          ),
          SizedBox(height: compactMobile ? 8 : 14),
          Expanded(
            child: round.inputMode == BattleRoundInputMode.yearLockGuess
                ? BattleDateGuessPanel(
                    digits: _dateGuessDigits,
                    guessedDate: _guessedDateFromDigits,
                    invalidHint: 'Spin to a valid date',
                    validHint: 'Adjust the wheels, then lock it in',
                    onDigitChanged: (index, value) {
                      setState(() {
                        _dateGuessDigits[index] = value;
                      });
                    },
                  )
                : BattleMapGuessPanel(
                    selectedPoint: _tiebreakMapGuess,
                    emptyHint: 'Tap once to place your guess',
                    onTap: (point) {
                      setState(() {
                        _tiebreakMapGuess = point;
                      });
                    },
                  ),
          ),
          SizedBox(height: mobile ? 10 : 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _submitDirectGuess(round),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4B06A),
                foregroundColor: const Color(0xFF1B100A),
                padding: EdgeInsets.symmetric(
                  horizontal: mobile ? 18 : 22,
                  vertical: mobile ? 14 : 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: Icon(
                round.inputMode == BattleRoundInputMode.yearLockGuess
                    ? Icons.dialpad_rounded
                    : Icons.place_rounded,
              ),
              label: const Text(
                'Submit guess',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(
    BuildContext context,
    BattleRoundResult result,
    BattleSession session,
  ) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    final accent = result.isDraw
        ? const Color(0xFFD4B06A)
        : result.playerWon
        ? const Color(0xFF5CCB8A)
        : const Color(0xFFE39063);
    final roundDetail =
        result.definition.type == BattleRoundType.closerToYear &&
            result.definition.yearTarget != null
        ? 'Target event: ${result.definition.yearTarget!.label} (${result.definition.yearTarget!.year})'
        : result.definition.title;

    return _buildPanel(
      key: ValueKey('battle-result ${result.roundNumber}'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RevealStageFrame(
            accent: accent,
            padding: EdgeInsets.fromLTRB(
              mobile ? 12 : 16,
              mobile ? 12 : 16,
              mobile ? 12 : 16,
              mobile ? 12 : 16,
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: mobile ? 220 : 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Round ${result.roundNumber}',
                        style: TextStyle(
                          color: const Color(0xFFF7ECDD),
                          fontWeight: FontWeight.w800,
                          fontSize: mobile ? 19 : 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roundDetail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(
                            0xFFD8CBB8,
                          ).withValues(alpha: 0.90),
                          fontWeight: FontWeight.w700,
                          fontSize: mobile ? 13 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: mobile ? 10 : 12),
          Expanded(
            child: BattleRevealSequence(
              result: result,
              rarityColor: _rarityColor,
              revealStageBuilder: (context, result) =>
                  BattleRoundRevealContent(result: result),
            ),
          ),
          SizedBox(height: mobile ? 10 : 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DelayedBattleScorePill(result: result, session: session),
              FilledButton.icon(
                onPressed: _continueAfterResult,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD4B06A),
                  foregroundColor: const Color(0xFF1B100A),
                  padding: EdgeInsets.symmetric(
                    horizontal: mobile ? 18 : 22,
                    vertical: mobile ? 13 : 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(
                  session.pendingTiebreakAfterResult
                      ? Icons.local_fire_department_rounded
                      : session.currentRoundIndex + 1 >= session.rounds.length
                      ? Icons.flag_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  session.pendingTiebreakAfterResult
                      ? 'To tiebreak'
                      : session.currentRoundIndex + 1 >= session.rounds.length
                      ? 'To results'
                      : 'Next round',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView(BuildContext context, BattleSession session) {
    _awardBattleCoinsIfNeeded(session);
    final resultLabel = session.playerScore == session.botScore
        ? 'Battle ends in a draw'
        : session.playerScore > session.botScore
        ? 'You win the battle'
        : 'The bot wins the battle';

    return _buildPanel(
      key: const ValueKey('battle-summary'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Battle Summary',
                        style: TextStyle(
                          color: Color(0xFFF7ECDD),
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resultLabel,
                        style: TextStyle(
                          color: const Color(
                            0xFFD8CBB8,
                          ).withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                BattlePill(label: '${session.playerScore}:${session.botScore}'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lineup recap',
                    style: TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: session.playerDeck.map((person) {
                      final used = session.history.any(
                        (entry) => entry.playerCard?.id == person.id,
                      );
                      return Container(
                        width: 72,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _rarityColor(
                              person.rarity,
                            ).withValues(alpha: used ? 0.85 : 0.25),
                            width: 1.4,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Opacity(
                            opacity: used ? 1 : 0.42,
                            child: PersonPortrait(
                              person: person,
                              variant: PersonImageVariant.vs,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Round log',
                    style: TextStyle(
                      color: Color(0xFFF7ECDD),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...session.history.map((result) {
                    final outcome = result.isDraw
                        ? 'Draw'
                        : result.playerWon
                        ? 'Win'
                        : 'Loss';
                    final color = result.isDraw
                        ? const Color(0xFFD8CBB8)
                        : result.playerWon
                        ? const Color(0xFFD4B06A)
                        : const Color(0xFFE39063);
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: Colors.black.withValues(alpha: 0.14),
                        border: Border.all(
                          color: color.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Round ${result.roundNumber} - ${result.definition.title}',
                                  style: const TextStyle(
                                    color: Color(0xFFF7ECDD),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                outcome,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.isDirectGuessRound
                                ? 'Tiebreak without cards'
                                : '${result.playerCard!.name} vs ${result.botCard!.name}',
                            style: TextStyle(
                              color: const Color(
                                0xFFD8CBB8,
                              ).withValues(alpha: 0.90),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.explanation,
                            style: TextStyle(
                              color: const Color(
                                0xFFD8CBB8,
                              ).withValues(alpha: 0.82),
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.icon(
                onPressed: _resetBattle,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD4B06A),
                  foregroundColor: const Color(0xFF1B100A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.replay_rounded),
                label: const Text(
                  'New Battle',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startDraft() {
    final result = BattleDraftBuilder().buildForSession(widget.session);
    setState(() {
      _missingSlots = result.missingSlots;
      _draftState = result.state;
    });
  }

  void _selectDraftCard(int slotIndex, Person person) {
    final state = _draftState;
    if (state == null) return;
    final updatedSlots = [...state.slots];
    updatedSlots[slotIndex] = updatedSlots[slotIndex].copyWith(
      selected: person,
    );
    setState(() {
      _draftState = BattleDraftState(slots: updatedSlots);
    });
  }

  void _beginBattle() {
    final state = _draftState;
    if (state == null || !state.isReady) return;
    final battle = BattleSessionFactory().create(
      session: widget.session,
      playerDeck: state.selectedCards,
    );
    setState(() {
      _battleSession = battle;
      _draftState = null;
    });
  }

  Future<void> _startRandomBattle() async {
    try {
      final match = await widget.onlineController.startRandomMatchmaking(
        session: widget.session,
      );
      if (!mounted) return;
      _openOnlineMatch(match);
      final message = match.hasOpponent
          ? 'Found a matching random duel.'
          : 'No opponent was free. Your own random duel has been created.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _leaveMatch(AsyncBattleMatch match) async {
    try {
      await widget.onlineController.leaveMatch(match.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Battle removed from your list.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _leaveAllOpenMatches() async {
    try {
      await widget.onlineController.leaveAllOpenMatches();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All open battles were removed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String _onlineMatchStatusLabel(AsyncBattleMatch match, String userId) {
    final mySubmitted = match.usedCardIdsFor(userId).length;
    final opponentSubmitted = match.roleFor(userId) == AsyncBattleMatchRole.host
        ? match.guestUsedCardIds.length
        : match.hostUsedCardIds.length;

    if (!match.hasOpponent) {
      return 'Waiting for opponent - $mySubmitted/${match.rounds.length} rounds played';
    }
    if (mySubmitted >= match.rounds.length &&
        opponentSubmitted < match.rounds.length) {
      return 'Your run is finished - opponent is up';
    }
    if (mySubmitted < match.rounds.length &&
        opponentSubmitted >= match.rounds.length) {
      return 'Opponent is done - your turn';
    }
    return '$mySubmitted:$opponentSubmitted rounds submitted';
  }

  String _onlineMatchResultLabel(AsyncBattleMatch match, String userId) {
    final amHost = match.roleFor(userId) == AsyncBattleMatchRole.host;
    final myScore = amHost ? match.hostScore : match.guestScore;
    final opponentScore = amHost ? match.guestScore : match.hostScore;
    final result = myScore == opponentScore
        ? 'Draw'
        : myScore > opponentScore
        ? 'Win'
        : 'Loss';
    return '$myScore:$opponentScore - $result';
  }

  void _dismissOnlineNotice() {
    if (_onlineNotice == null) return;
    setState(() {
      _onlineNotice = null;
    });
  }

  void _openOnlineNoticeMatch(_OnlineBattleNotice notice) {
    final matches = widget.onlineController.matches.where(
      (candidate) => candidate.id == notice.matchId,
    );
    if (matches.isEmpty) {
      _dismissOnlineNotice();
      return;
    }
    final match = matches.first;
    _dismissOnlineNotice();
    _openOnlineMatch(match);
  }

  void _openOnlineMatch(AsyncBattleMatch match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnlineMatchScreen(
          controller: widget.onlineController,
          matchId: match.id,
          initialMatch: match,
        ),
      ),
    );
  }

  void _playCard(Person person) {
    final session = _battleSession;
    if (session == null) return;
    setState(() {
      session.playRound(person);
    });
  }

  void _continueAfterResult() {
    final session = _battleSession;
    if (session == null) return;
    setState(() {
      session.advanceAfterResult();
      _preparedTiebreakRoundIndex = null;
      _tiebreakMapGuess = null;
    });
  }

  void _resetBattle() {
    setState(() {
      _battleSession = null;
      _draftState = null;
      _interstitialShownForBattle = null;
      _coinsGrantedForBattle = null;
      _preparedTiebreakRoundIndex = null;
      _tiebreakMapGuess = null;
    });
  }

  void _prepareTiebreakState(BattleRoundDefinition round, int roundIndex) {
    if (!round.usesDirectGuess || _preparedTiebreakRoundIndex == roundIndex) {
      return;
    }
    _preparedTiebreakRoundIndex = roundIndex;
    _tiebreakMapGuess = null;
    final targetDate =
        round.historicalEventTarget?.date ?? DateTime.utc(1900, 1, 1);
    final random = Random(
      DateTime.now().microsecondsSinceEpoch ^
          roundIndex ^
          targetDate.year ^
          (targetDate.month << 8) ^
          (targetDate.day << 16),
    );
    final yearFloor = max(1, targetDate.year - 220);
    final yearCeiling = min(2025, targetDate.year + 220);
    final yearSpan = max(1, yearCeiling - yearFloor + 1);
    DateTime seededDate;
    do {
      final year = yearFloor + random.nextInt(yearSpan);
      final month = 1 + random.nextInt(12);
      final day = 1 + random.nextInt(28);
      seededDate = DateTime.utc(year, month, day);
    } while (seededDate.year == targetDate.year &&
        seededDate.month == targetDate.month &&
        seededDate.day == targetDate.day);
    _dateGuessDigits = [
      seededDate.day ~/ 10,
      seededDate.day % 10,
      seededDate.month ~/ 10,
      seededDate.month % 10,
      seededDate.year ~/ 1000,
      (seededDate.year ~/ 100) % 10,
      (seededDate.year ~/ 10) % 10,
      seededDate.year % 10,
    ];
  }

  DateTime? get _guessedDateFromDigits {
    final day = (_dateGuessDigits[0] * 10) + _dateGuessDigits[1];
    final month = (_dateGuessDigits[2] * 10) + _dateGuessDigits[3];
    final year =
        (_dateGuessDigits[4] * 1000) +
        (_dateGuessDigits[5] * 100) +
        (_dateGuessDigits[6] * 10) +
        _dateGuessDigits[7];
    if (month < 1 || month > 12 || day < 1) return null;
    final candidate = DateTime.utc(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }

  void _submitDirectGuess(BattleRoundDefinition round) {
    final session = _battleSession;
    if (session == null) return;
    if (round.inputMode == BattleRoundInputMode.mapGuess &&
        _tiebreakMapGuess == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please place your map guess first.')),
      );
      return;
    }
    setState(() {
      if (round.inputMode == BattleRoundInputMode.yearLockGuess) {
        final guessedDate = _guessedDateFromDigits;
        if (guessedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid date first.')),
          );
          return;
        }
        session.playDateTiebreakGuess(guessedDate);
      } else {
        final guess = _tiebreakMapGuess!;
        session.playLocationTiebreakGuess(
          guessedLat: guess.latitude,
          guessedLng: guess.longitude,
        );
      }
    });
  }

  void _maybeShowBattleInterstitial(BattleSession session) {
    if (identical(_interstitialShownForBattle, session)) return;
    _interstitialShownForBattle = session;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.adsService.showInterstitialForCompletedBattle());
    });
  }

  void _awardBattleCoinsIfNeeded(BattleSession session) {
    if (identical(_coinsGrantedForBattle, session)) return;
    _coinsGrantedForBattle = session;
    final playerWon = session.playerScore > session.botScore;
    final isDraw = session.playerScore == session.botScore;
    widget.session.recordOfflineBattleRounds(session.history);
    widget.session.recordBattleResult(won: playerWon, draw: isDraw);
    if (playerWon) {
      widget.session.addCoins(20);
    } else if (isDraw) {
      widget.session.addCoins(10);
    } else {
      widget.session.addCoins(6);
    }
  }
}

class _TiebreakMissionCard extends StatelessWidget {
  final BattleRoundDefinition round;
  final Widget? scorePanel;

  const _TiebreakMissionCard({required this.round, this.scorePanel});

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    final compact = MediaQuery.sizeOf(context).width < 430;
    final accent = const Color(0xFFD4B06A);
    final title = round.inputMode == BattleRoundInputMode.yearLockGuess
        ? 'Tiebreak for the win'
        : 'Tiebreak location guess';
    final body = round.historicalEventTarget == null
        ? 'No card matchup now. Your estimate decides the battle.'
        : round.inputMode == BattleRoundInputMode.yearLockGuess
        ? '${round.historicalEventTarget!.title}. Set day, month, and year.'
        : '${round.historicalEventTarget!.title}. Tap the location on the borders-only map.';

    return _RevealStageFrame(
      accent: accent,
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 12 : 16,
        compact ? 12 : 16,
        compact ? 12 : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 44 : 50,
            height: compact ? 44 : 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withValues(alpha: 0.16),
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            child: Icon(
              round.inputMode == BattleRoundInputMode.yearLockGuess
                  ? Icons.event_available_rounded
                  : Icons.public_rounded,
              color: accent,
              size: compact ? 20 : 24,
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 18 : 22,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    fontSize: compact ? 12.5 : 13.5,
                  ),
                ),
              ],
            ),
          ),
          if (scorePanel != null) ...[
            const SizedBox(width: 16),
            SizedBox(width: 220, child: scorePanel!),
          ],
        ],
      ),
    );
  }
}

class _DelayedBattleScorePill extends StatefulWidget {
  final BattleRoundResult result;
  final BattleSession session;

  const _DelayedBattleScorePill({required this.result, required this.session});

  @override
  State<_DelayedBattleScorePill> createState() =>
      _DelayedBattleScorePillState();
}

class _DelayedBattleScorePillState extends State<_DelayedBattleScorePill> {
  bool _showUpdatedScore = false;

  Duration get _delay {
    if (widget.result.isDirectGuessRound) {
      return const Duration(milliseconds: 1500);
    }
    switch (widget.result.definition.type) {
      case BattleRoundType.closerToLocation:
        return const Duration(milliseconds: 5350);
      case BattleRoundType.longerLife:
        return const Duration(milliseconds: 3100);
      case BattleRoundType.closerToYear:
      case BattleRoundType.bornEarlier:
        return const Duration(milliseconds: 3650);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(_delay, () {
      if (mounted) {
        setState(() => _showUpdatedScore = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final previousPlayerScore =
        widget.session.playerScore - widget.result.playerScoreDelta;
    final previousBotScore =
        widget.session.botScore - widget.result.botScoreDelta;
    final playerScore = _showUpdatedScore
        ? widget.session.playerScore
        : previousPlayerScore;
    final botScore = _showUpdatedScore
        ? widget.session.botScore
        : previousBotScore;
    return BattlePill(label: 'Score $playerScore:$botScore');
  }
}

class _HubIntro extends StatelessWidget {
  final List<BattleDraftSlotType> missingSlots;
  final VoidCallback onStartDraft;

  const _HubIntro({required this.missingSlots, required this.onStartDraft});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Draft your team for four knowledge duels',
          style: TextStyle(
            color: Color(0xFFF7ECDD),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Battle is not a spreadsheet mode. You only see name, portrait, category, rarity, and a small thematic tag. Winning comes from memory, timing, and smart card sequencing.',
          style: TextStyle(
            color: const Color(0xFFD8CBB8).withValues(alpha: 0.92),
            height: 1.45,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _RuleCard(
              icon: Icons.auto_awesome_motion_rounded,
              title: 'Draft instead of meta deck',
              body:
                  'Before each battle, choose 1 card from several offers per slot.',
            ),
            _RuleCard(
              icon: Icons.change_circle_rounded,
              title: 'Four different slots',
              body: 'Politics, science, art, and sports keep the draft varied.',
            ),
            _RuleCard(
              icon: Icons.hourglass_top_rounded,
              title: 'Use once',
              body:
                  'Each of the 4 cards can only be played in one round per battle.',
            ),
          ],
        ),
        if (missingSlots.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFF5D2A17).withValues(alpha: 0.42),
              border: Border.all(
                color: const Color(0xFFE39063).withValues(alpha: 0.50),
              ),
            ),
            child: Text(
              'You are currently missing at least one category for a draft. Unlock more categories in quiz first.',
              style: const TextStyle(
                color: Color(0xFFF7ECDD),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onStartDraft,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD4B06A),
            foregroundColor: const Color(0xFF1B100A),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: const Icon(Icons.style_rounded),
          label: const Text(
            'Start draft',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _DraftSlotPanel extends StatelessWidget {
  final int slotIndex;
  final BattleDraftSlot slot;
  final ValueChanged<Person> onSelect;

  const _DraftSlotPanel({
    required this.slotIndex,
    required this.slot,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, mobile ? 12 : 14),
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
                final person = slot.candidates[index];
                final selected = slot.selected?.id == person.id;
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
                      child: _BattleFigureCard(
                        person: person,
                        selected: selected,
                        label: selected ? 'Selected' : slot.type.label,
                        subtitle: battleTagForPersonId(person.id, person.hint),
                        onTap: () => onSelect(person),
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

class _DraftSelectionStrip extends StatelessWidget {
  final List<Person> cards;

  const _DraftSelectionStrip({required this.cards});

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;

    return BattleLineupStrip(
      totalSlots: battleDeckSize,
      filledCards: cards
          .map(
            (card) => Container(
              width: mobile ? 56 : 64,
              height: mobile ? 78 : 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _rarityColor(card.rarity),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _rarityColor(card.rarity).withValues(alpha: 0.16),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: PersonPortrait(
                  person: card,
                  variant: PersonImageVariant.vs,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RoundMissionCard extends StatelessWidget {
  final BattleRoundDefinition round;
  final int? availableCards;
  final Widget? scorePanel;

  const _RoundMissionCard({
    required this.round,
    this.availableCards,
    this.scorePanel,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 640;
    final accent = const Color(0xFFD4B06A);
    final showFocusPanel =
        round.type == BattleRoundType.closerToYear ||
        round.type == BattleRoundType.closerToLocation;

    return _RevealStageFrame(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: mobile ? 48 : 56,
                height: mobile ? 48 : 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: accent.withValues(alpha: 0.16),
                  border: Border.all(color: accent.withValues(alpha: 0.32)),
                ),
                child: Icon(
                  battleRoundIcon(round.type),
                  color: accent,
                  size: mobile ? 22 : 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      round.prompt,
                      style: TextStyle(
                        color: const Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: mobile ? 22 : 28,
                        height: 1.05,
                      ),
                    ),
                    if (!mobile) const SizedBox(height: 4),
                    if (!mobile && !showFocusPanel)
                      Text(
                        battleRoundHelperText(round.type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(
                            0xFFD8CBB8,
                          ).withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                  ],
                ),
              ),
              if (scorePanel != null) ...[
                const SizedBox(width: 16),
                SizedBox(width: 220, child: scorePanel!),
              ],
            ],
          ),
          if (showFocusPanel) ...[
            const SizedBox(height: 10),
            BattleRoundFocusPanel(round: round),
          ] else if (availableCards != null && !mobile) ...[
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

class _BattleFigureCard extends StatelessWidget {
  final Person person;
  final bool selected;
  final bool deckMode;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _BattleFigureCard({
    required this.person,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.deckMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    final color = _rarityColor(person.rarity);
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
          child: _CardShell(
            person: person,
            selected: selected,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PersonPortrait(
                    person: person,
                    variant: PersonImageVariant.vs,
                    borderRadius: compact ? 24 : 30,
                  ),
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
                  child: _TagPill(
                    icon: _categoryIcon(person.category),
                    label: compact ? 'Play' : label,
                  ),
                ),
                Positioned(
                  top: compact ? 10 : 14,
                  right: compact ? 10 : 14,
                  child: _MiniRarityBadge(rarity: person.rarity),
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
                          person.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFF7ECDD),
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
                            _TinyInfoPill(
                              label: _categoryLabel(person.category),
                            ),
                            _TinyInfoPill(label: subtitle),
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
                        color: Color(0xFF1B100A),
                        size: compact ? 14 : 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Person person;
  final Widget child;
  final bool selected;

  const _CardShell({
    required this.person,
    required this.child,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(person.rarity);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Color.lerp(color, Colors.black, 0.30)!,
            const Color(0xFF1A110D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withValues(alpha: selected ? 1 : 0.74),
          width: selected ? 1.9 : 1.4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _OrnateFramePainter(color: color)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrnateFramePainter extends CustomPainter {
  final Color color;

  const _OrnateFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = rect.deflate(8);
    final framePaint = Paint()
      ..color = color.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(outer, const Radius.circular(24)));
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, framePaint);

    final top = Path()
      ..moveTo(outer.left + outer.width * 0.2, outer.top + 10)
      ..quadraticBezierTo(
        outer.center.dx,
        outer.top - 2,
        outer.right - outer.width * 0.2,
        outer.top + 10,
      );
    final bottom = Path()
      ..moveTo(outer.left + outer.width * 0.2, outer.bottom - 10)
      ..quadraticBezierTo(
        outer.center.dx,
        outer.bottom + 2,
        outer.right - outer.width * 0.2,
        outer.bottom - 10,
      );
    canvas.drawPath(top, framePaint);
    canvas.drawPath(bottom, framePaint);
  }

  @override
  bool shouldRepaint(covariant _OrnateFramePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _LockedPreviewStack extends StatelessWidget {
  final GameSession session;

  const _LockedPreviewStack({required this.session});

  @override
  Widget build(BuildContext context) {
    final cards = session.unlockedPersons.take(3).toList();
    return SizedBox(
      height: 420,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 18,
            left: 10,
            right: 10,
            child: Container(
              height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD4B06A).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                  radius: 0.9,
                ),
              ),
            ),
          ),
          for (var i = 0; i < max(cards.length, 3); i++)
            Positioned(
              left: 24 + (i * 74),
              top: 28 + (i.isEven ? 8 : 0),
              child: Transform.rotate(
                angle: i == 0
                    ? -0.16
                    : i == 1
                    ? 0.0
                    : 0.16,
                child: SizedBox(
                  width: 170,
                  height: 250,
                  child: cards.length > i
                      ? _BattleFigureCard(
                          person: cards[i],
                          label: 'Quiz',
                          subtitle: cards[i].hint,
                          onTap: () {},
                        )
                      : _PlaceholderCard(index: i + 1),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: 0.24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: const Text(
                  'Battle opens at level 10',
                  style: TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubStage extends StatelessWidget {
  final GameSession session;

  const _HubStage({required this.session});

  @override
  Widget build(BuildContext context) {
    final cards = session.unlockedPersons.take(4).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Battle Deck Preview', 'Battle Deck Preview'),
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cards stay at the center. The draft should feel like assembling a small tactical hand.',
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: List.generate(4, (index) {
                final person = index < cards.length ? cards[index] : null;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 3 ? 0 : 12),
                    child: Transform.translate(
                      offset: Offset(0, index.isEven ? 0 : 16),
                      child: person == null
                          ? _PlaceholderCard(index: index + 1)
                          : _BattleFigureCard(
                              person: person,
                              label: 'Slot ${index + 1}',
                              subtitle: battleTagForPersonId(
                                person.id,
                                person.hint,
                              ),
                              onTap: () {},
                            ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final int index;

  const _PlaceholderCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.black.withValues(alpha: 0.22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style_rounded, color: Color(0xFFD4B06A), size: 34),
            const SizedBox(height: 10),
            Text(
              'Slot $index',
              style: const TextStyle(
                color: Color(0xFFF7ECDD),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final int current;
  final int target;
  final double progress;

  const _ProgressPanel({
    required this.current,
    required this.target,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Battle unlock step',
                  style: TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '$current/$target',
                style: const TextStyle(
                  color: Color(0xFFD4B06A),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 16,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD4B06A)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${max(0, target - current)} levels left until Battle Mode.',
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _RuleCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFD4B06A).withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: const Color(0xFFD4B06A)),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.84),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: const Color(0xFFD4B06A)),
          SizedBox(width: compact ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TagPill({required this.icon, required this.label});

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

class _TinyInfoPill extends StatelessWidget {
  final String label;

  const _TinyInfoPill({required this.label});

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

class _MiniRarityBadge extends StatelessWidget {
  final PersonRarity rarity;

  const _MiniRarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(rarity);
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

class _RevealStageFrame extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  const _RevealStageFrame({
    required this.child,
    required this.accent,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.03),
            Colors.black.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.38, 1],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget _buildPanel({Key? key, required Widget child, EdgeInsets? padding}) {
  return Container(
    key: key,
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: AppPalette.panelGradient,
      border: Border.all(color: AppPalette.gold.withValues(alpha: 0.16)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: child,
  );
}

Color _rarityColor(PersonRarity rarity) {
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

String _categoryLabel(Category category) {
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

IconData _categoryIcon(Category category) {
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

String _roundLabel(BattleRoundType type) {
  switch (type) {
    case BattleRoundType.closerToYear:
      return 'Closer to the year';
    case BattleRoundType.closerToLocation:
      return 'Closer to the place';
    case BattleRoundType.longerLife:
      return 'Longer lifespan';
    case BattleRoundType.bornEarlier:
      return 'Born earlier';
  }
}

String _resultMetricLabel(BattleRoundType type, double value) {
  switch (type) {
    case BattleRoundType.closerToYear:
      return '${value.toStringAsFixed(0)} years away';
    case BattleRoundType.closerToLocation:
      return '${value.toStringAsFixed(0)} km away';
    case BattleRoundType.longerLife:
      return '${value.toStringAsFixed(0)} years lifespan';
    case BattleRoundType.bornEarlier:
      return 'Birth year ${value.toStringAsFixed(0)}';
  }
}

String _formatYear(int year) {
  if (year < 0) {
    return '${year.abs()} BC';
  }
  return '$year';
}
