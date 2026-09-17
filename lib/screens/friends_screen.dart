import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../logic/game_session.dart';
import '../online/online_battle_controller.dart';
import '../online/online_models.dart';

class FriendsScreen extends StatefulWidget {
  final GameSession session;
  final OnlineBattleController onlineController;

  const FriendsScreen({
    super.key,
    required this.session,
    required this.onlineController,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final TextEditingController _handleController;

  @override
  void initState() {
    super.initState();
    _handleController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onlineController.needsDisplayNameSetup) {
        _showNameDialog(force: true);
      }
    });
  }

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  String _handleFor(OnlineBattleProfile profile) {
    return '${profile.displayName}#${profile.friendCode}';
  }

  String _extractFriendCode(String input) {
    final trimmed = input.trim();
    if (!trimmed.contains('#')) {
      throw StateError(
        context.tr(
          'Bitte gib einen vollstaendigen Handle wie Name#AB12CD ein.',
          'Please enter a full handle like Name#AB12CD.',
        ),
      );
    }
    final code = trimmed.split('#').last.trim().toUpperCase();
    if (code.isEmpty) {
      throw StateError(
        context.tr(
          'Der Handle ist unvollstaendig.',
          'The handle is incomplete.',
        ),
      );
    }
    return code;
  }

  Future<void> _showNameDialog({bool force = false}) async {
    if (!mounted) return;
    final screenContext = context;
    final initial = widget.onlineController.profile?.displayName ?? '';
    final controller = TextEditingController(text: initial);

    await showDialog<void>(
      context: screenContext,
      barrierDismissible: !force,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF24150D),
          title: Text(
            force
                ? screenContext.tr('Online-Namen festlegen', 'Set online name')
                : screenContext.tr(
                    'Online-Namen aendern',
                    'Change online name',
                  ),
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Color(0xFFF7ECDD)),
            decoration: InputDecoration(
              labelText: screenContext.tr('Dein Name', 'Your name'),
              labelStyle: TextStyle(color: Color(0xFFD8CBB8)),
            ),
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.tr('Abbrechen', 'Cancel')),
              ),
            FilledButton(
              onPressed: () async {
                try {
                  await widget.onlineController.updateDisplayName(
                    controller.text,
                  );
                  if (!mounted) return;
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        screenContext.tr(
                          'Online-Name gespeichert.',
                          'Online name saved.',
                        ),
                      ),
                    ),
                  );
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    screenContext,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              child: Text(
                force
                    ? screenContext.tr('Festlegen', 'Set name')
                    : screenContext.tr('Speichern', 'Save'),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _sendFriendRequest() async {
    try {
      await widget.onlineController.sendFriendRequest(
        _extractFriendCode(_handleController.text),
      );
      _handleController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Freundschaftsanfrage gesendet.',
              'Friend request sent.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _acceptFriendRequest(String requestId) async {
    try {
      await widget.onlineController.acceptFriendRequest(requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Freund hinzugefuegt.', 'Friend added.')),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _inviteFriend(OnlineBattleProfile friend) async {
    try {
      final invite = await widget.onlineController.createInvite(
        session: widget.session,
        friend: friend,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Einladung an ${friend.displayName} gesendet. Code ${invite.inviteCode}',
              'Invite sent to ${friend.displayName}. Code ${invite.inviteCode}',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _removeFriend(OnlineBattleProfile friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF24150D),
          title: Text(
            context.tr('Freund entfernen', 'Remove friend'),
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            context.tr(
              '${friend.displayName} aus deiner Freundesliste entfernen?',
              'Remove ${friend.displayName} from your friends list?',
            ),
            style: const TextStyle(color: Color(0xFFD8CBB8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr('Abbrechen', 'Cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAF5C56),
                foregroundColor: const Color(0xFFF7ECDD),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.tr('Entfernen', 'Remove')),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await widget.onlineController.removeFriend(friend.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              '${friend.displayName} entfernt.',
              '${friend.displayName} removed.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _showFriendDetails(OnlineBattleProfile friend) async {
    final stats = widget.onlineController.statsForFriend(friend.userId);
    final friendship = widget.onlineController.friendshipFor(friend.userId);
    final friendSince = friendship?.updatedAt ?? stats.friendsSince;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B2418).withValues(alpha: 0.97),
                    const Color(0xFF170D09).withValues(alpha: 0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFD4B06A).withValues(alpha: 0.24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(
                              0xFF5CCB8A,
                            ).withValues(alpha: 0.14),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF5CCB8A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.displayName,
                                style: const TextStyle(
                                  color: Color(0xFFF7ECDD),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _handleFor(friend),
                                style: TextStyle(
                                  color: const Color(
                                    0xFFD8CBB8,
                                  ).withValues(alpha: 0.84),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFD8CBB8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StatsCard(
                      title: 'Spielerprofil',
                      children: [
                        _StatLine(label: 'Elo', value: '${stats.rating}'),
                        _StatLine(
                          label: 'Freund seit',
                          value: friendSince == null
                              ? 'Unbekannt'
                              : _friendlyDate(friendSince),
                        ),
                        _StatLine(
                          label: 'Offene Duelle',
                          value: '${stats.openMatches}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatsCard(
                      title: 'Gegen dich',
                      children: [
                        _StatLine(
                          label: 'Abgeschlossen',
                          value: '${stats.completedMatches}',
                        ),
                        _StatLine(
                          label: 'Siege',
                          value: '${stats.wins}',
                          accent: const Color(0xFF5CCB8A),
                        ),
                        _StatLine(
                          label: 'Niederlagen',
                          value: '${stats.losses}',
                          accent: const Color(0xFFAF5C56),
                        ),
                        _StatLine(
                          label: 'Unentschieden',
                          value: '${stats.draws}',
                        ),
                        _StatLine(
                          label: 'Rundenbilanz',
                          value: '${stats.roundsWon}:${stats.roundsLost}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _inviteFriend(friend);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD4B06A),
                              foregroundColor: const Color(0xFF1B100A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.sports_martial_arts_rounded),
                            label: const Text(
                              'Einladen',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _removeFriend(friend);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFAF5C56),
                              side: BorderSide(
                                color: const Color(
                                  0xFFAF5C56,
                                ).withValues(alpha: 0.45),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.person_remove_rounded),
                            label: const Text(
                              'Entfernen',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
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

  String _friendlyDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.onlineController,
      builder: (context, _) {
        final profile = widget.onlineController.profile;
        final requests = widget.onlineController.incomingFriendRequests;
        final friends = widget.onlineController.friends;
        final progress = widget.session.progressSnapshot;
        final onlineStats = widget.onlineController.overallStats;
        final leaderboard = widget.onlineController.leaderboard;
        final rank = widget.onlineController.leaderboardRank;

        return Scaffold(
          backgroundColor: const Color(0xFF120B07),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFFF7ECDD),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          context.tr('Freunde', 'Friends'),
                          style: TextStyle(
                            color: Color(0xFFF7ECDD),
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _OwnProfileCard(
                    profile: profile,
                    rank: rank,
                    onlineStats: onlineStats,
                    onEditName: () => _showNameDialog(),
                    handleFor: _handleFor,
                  ),
                  const SizedBox(height: 14),
                  _StatsOverviewCard(
                    progress: progress,
                    onlineStats: onlineStats,
                  ),
                  const SizedBox(height: 14),
                  _SectionHeader(
                    title: context.tr('Elo Leaderboard', 'Elo Leaderboard'),
                    count: leaderboard.length,
                  ),
                  const SizedBox(height: 8),
                  if (leaderboard.isEmpty)
                    _CardShell(
                      child: Text(
                        context.tr(
                          'Noch keine Rangliste verfuegbar.',
                          'No leaderboard available yet.',
                        ),
                        style: TextStyle(
                          color: Color(0xFFD8CBB8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    _LeaderboardCard(
                      profiles: leaderboard,
                      currentUserId: widget.onlineController.userId,
                    ),
                  const SizedBox(height: 14),
                  _CardShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Freund hinzufuegen', 'Add friend'),
                          style: TextStyle(
                            color: Color(0xFFF7ECDD),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _handleController,
                          style: const TextStyle(color: Color(0xFFF7ECDD)),
                          decoration: InputDecoration(
                            hintText: context.tr(
                              'Handle eingeben, z. B. Florian#AB12CD',
                              'Enter a handle, e.g. Florian#AB12CD',
                            ),
                            hintStyle: TextStyle(
                              color: const Color(
                                0xFFD8CBB8,
                              ).withValues(alpha: 0.6),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            suffixIcon: IconButton(
                              onPressed: _sendFriendRequest,
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              color: const Color(0xFFD4B06A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionHeader(
                    title: context.tr('Anfragen', 'Requests'),
                    count: requests.length,
                  ),
                  const SizedBox(height: 8),
                  if (requests.isEmpty)
                    _CardShell(
                      child: Text(
                        context.tr(
                          'Keine offenen Freundschaftsanfragen.',
                          'No open friend requests.',
                        ),
                        style: TextStyle(
                          color: Color(0xFFD8CBB8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ...requests.map(
                      (request) => _ActionTile(
                        title: request.fromDisplayName,
                        subtitle:
                            '${request.fromDisplayName}#${request.fromFriendCode}',
                        actionLabel: context.tr('Annehmen', 'Accept'),
                        accent: const Color(0xFFD4B06A),
                        onTap: () => _acceptFriendRequest(request.id),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _SectionHeader(
                    title: context.tr('Freundesliste', 'Friends list'),
                    count: friends.length,
                  ),
                  const SizedBox(height: 8),
                  if (friends.isEmpty)
                    _CardShell(
                      child: Text(
                        context.tr(
                          'Noch keine Freunde. Fuge zuerst jemanden ueber den Handle hinzu.',
                          'No friends yet. Add someone first using their handle.',
                        ),
                        style: TextStyle(
                          color: Color(0xFFD8CBB8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ...friends.map((friend) {
                      final stats = widget.onlineController.statsForFriend(
                        friend.userId,
                      );
                      return _FriendTile(
                        friend: friend,
                        subtitle: _handleFor(friend),
                        recordLabel:
                            '${stats.wins}-${stats.draws}-${stats.losses}',
                        onInvite: () => _inviteFriend(friend),
                        onTap: () => _showFriendDetails(friend),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;

  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B2418).withValues(alpha: 0.88),
            const Color(0xFF21120B).withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4B06A).withValues(alpha: 0.20),
        ),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
            border: Border.all(
              color: const Color(0xFFD4B06A).withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFFD4B06A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF7ECDD),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.84),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: const Color(0xFF1B100A),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final OnlineBattleProfile friend;
  final String subtitle;
  final String recordLabel;
  final VoidCallback onInvite;
  final VoidCallback onTap;

  const _FriendTile({
    required this.friend,
    required this.subtitle,
    required this.recordLabel,
    required this.onInvite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF5CCB8A).withValues(alpha: 0.14),
          ),
          child: const Icon(Icons.person_rounded, color: Color(0xFF5CCB8A)),
        ),
        title: Text(
          friend.displayName,
          style: const TextStyle(
            color: Color(0xFFF7ECDD),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFD4B06A).withValues(alpha: 0.12),
                  ),
                  child: Text(
                    'Elo ${friend.rating}',
                    style: const TextStyle(
                      color: Color(0xFFD4B06A),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recordLabel,
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Einladen',
              onPressed: onInvite,
              icon: const Icon(
                Icons.sports_martial_arts_rounded,
                color: Color(0xFFD4B06A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnProfileCard extends StatelessWidget {
  final OnlineBattleProfile? profile;
  final int? rank;
  final OnlineBattleStats onlineStats;
  final VoidCallback onEditName;
  final String Function(OnlineBattleProfile profile) handleFor;

  const _OwnProfileCard({
    required this.profile,
    required this.rank,
    required this.onlineStats,
    required this.onEditName,
    required this.handleFor,
  });

  @override
  Widget build(BuildContext context) {
    final handle = profile == null
        ? 'Wird vorbereitet...'
        : handleFor(profile!);
    final rankLabel = rank == null
        ? context.tr('Noch unplatziert', 'Unranked')
        : 'Rang #$rank';

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Dein Profil', 'Your profile'),
                      style: TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      handle,
                      style: const TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onEditName,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Name aendern'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStatPill(label: 'Elo ${onlineStats.rating}'),
              _MiniStatPill(label: rankLabel),
              _MiniStatPill(label: '${onlineStats.wins} Online-Siege'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'Freundschaftsanfragen laufen nur ueber vollstaendige Handles.',
              'Friend requests work only through full handles.',
            ),
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

class _LeaderboardCard extends StatelessWidget {
  final List<OnlineBattleProfile> profiles;
  final String? currentUserId;

  const _LeaderboardCard({required this.profiles, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          for (var i = 0; i < profiles.length; i++) ...[
            _LeaderboardRow(
              rank: i + 1,
              profile: profiles[i],
              highlight: profiles[i].userId == currentUserId,
            ),
            if (i != profiles.length - 1)
              Divider(height: 18, color: Colors.white.withValues(alpha: 0.08)),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final OnlineBattleProfile profile;
  final bool highlight;

  const _LeaderboardRow({
    required this.rank,
    required this.profile,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight
        ? const Color(0xFF5CCB8A)
        : const Color(0xFFD4B06A);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: highlight
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withValues(alpha: 0.10),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Text(
              '$rank',
              style: TextStyle(color: accent, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.displayName,
                        style: const TextStyle(
                          color: Color(0xFFF7ECDD),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (highlight)
                      Text(
                        'DU',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '#${profile.friendCode}',
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${profile.rating}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsOverviewCard extends StatelessWidget {
  final PlayerProgressSnapshot progress;
  final OnlineBattleStats onlineStats;

  const _StatsOverviewCard({required this.progress, required this.onlineStats});

  @override
  Widget build(BuildContext context) {
    final accuracyLabel = progress.totalAnswers == 0
        ? context.tr('Noch keine Quizdaten', 'No quiz data yet')
        : '${(progress.accuracy * 100).round()}% Genauigkeit';
    final totalBattleWins = progress.offlineBattlesWon + onlineStats.wins;
    final totalBattlesPlayed =
        progress.offlineBattlesPlayed +
        onlineStats.completedMatches +
        onlineStats.openMatches;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Dein Fortschritt', 'Your progress'),
            style: TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStatPill(label: 'Lv ${progress.level}'),
              _MiniStatPill(label: '${progress.coins} Coins'),
              _MiniStatPill(label: '${progress.ownedCards} cards'),
              _MiniStatPill(label: '${progress.earnedBadges} Badges'),
              _MiniStatPill(label: '$totalBattleWins Siege'),
            ],
          ),
          const SizedBox(height: 12),
          _StatLine(label: 'Quiz', value: accuracyLabel),
          _StatLine(
            label: 'XP / Level',
            value:
                '${progress.xp} / ${progress.xpToNext} • Lv ${progress.level}',
          ),
          _StatLine(
            label: context.tr('Battles gesamt', 'Battles total'),
            value: '$totalBattlesPlayed Spiele • $totalBattleWins Siege',
          ),
          _StatLine(
            label: context.tr('Offline Battle', 'Offline Battle'),
            value:
                '${progress.offlineBattlesWon}-${progress.offlineBattlesDrawn}-${progress.offlineBattlesLost}',
          ),
          _StatLine(
            label: context.tr('Online Battle', 'Online Battle'),
            value:
                '${onlineStats.wins}-${onlineStats.draws}-${onlineStats.losses}',
          ),
          _StatLine(
            label: context.tr('Fragetypen', 'Question types'),
            value:
                '${progress.questionTypesUnlocked} aktiv (+${progress.premiumQuestionUnlocks} Premium)',
          ),
        ],
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  final String label;

  const _MiniStatPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFD4B06A).withValues(alpha: 0.12),
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

class _StatsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _StatsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _StatLine({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFFD8CBB8).withValues(alpha: 0.84),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent ?? const Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
