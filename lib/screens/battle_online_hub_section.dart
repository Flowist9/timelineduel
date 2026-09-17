import 'package:flutter/material.dart';

import '../online/online_battle_controller.dart';
import '../online/online_models.dart';

class BattleOnlineHubSection extends StatelessWidget {
  final OnlineBattleController controller;
  final TextEditingController displayNameController;
  final TextEditingController friendCodeController;
  final bool showNameEditor;
  final VoidCallback onSaveName;
  final VoidCallback onStartEditingName;
  final VoidCallback onCancelEditingName;
  final VoidCallback onSendFriendRequest;
  final ValueChanged<String> onAcceptFriendRequest;
  final ValueChanged<OnlineBattleProfile> onInviteFriend;
  final ValueChanged<OnlineBattleInvite> onAcceptBattleInvite;
  final ValueChanged<AsyncBattleMatch> onOpenMatch;

  const BattleOnlineHubSection({
    super.key,
    required this.controller,
    required this.displayNameController,
    required this.friendCodeController,
    required this.showNameEditor,
    required this.onSaveName,
    required this.onStartEditingName,
    required this.onCancelEditingName,
    required this.onSendFriendRequest,
    required this.onAcceptFriendRequest,
    required this.onInviteFriend,
    required this.onAcceptBattleInvite,
    required this.onOpenMatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final profile = controller.profile;
        final incomingRequests = controller.incomingFriendRequests;
        final friends = controller.friends;
        final incomingInvites = controller.incomingBattleInvites;
        final currentName = profile?.displayName.trim().isNotEmpty == true
            ? profile!.displayName.trim()
            : 'No name yet';

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
              color: const Color(0xFFD4B06A).withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Color(0xFFD4B06A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Friends & async battles',
                      style: TextStyle(
                        color: Color(0xFFF7ECDD),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _StatusCapsule(
                    label: controller.usesFirebase ? 'Firebase' : 'Local',
                    color: controller.usesFirebase
                        ? const Color(0xFF5CCB8A)
                        : const Color(0xFFE39063),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Become friends first, then invite them directly to async battles.',
                style: TextStyle(
                  color: const Color(0xFFD8CBB8).withValues(alpha: 0.88),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
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
              const SizedBox(height: 14),
              if (showNameEditor) ...[
                _ProfileSetupCard(
                  firstSetup: controller.needsDisplayNameSetup,
                  displayNameController: displayNameController,
                  onSaveName: controller.isBootstrapping ? null : onSaveName,
                  onCancel: controller.needsDisplayNameSetup
                      ? null
                      : onCancelEditingName,
                ),
              ] else ...[
                _ProfileSummaryRow(
                  name: currentName,
                  friendCode: profile?.friendCode.isNotEmpty == true
                      ? profile!.friendCode
                      : '...',
                  onEditName: onStartEditingName,
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: friendCodeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: Color(0xFFF7ECDD),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
                decoration: _inputDecoration('Enter friend handle').copyWith(
                  suffixIcon: IconButton(
                    onPressed: controller.isBootstrapping
                        ? null
                        : onSendFriendRequest,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    color: const Color(0xFFD4B06A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Friend requests',
                trailing: '${incomingRequests.length}',
              ),
              const SizedBox(height: 8),
              if (incomingRequests.isEmpty)
                const _EmptyLine(label: 'No open requests.')
              else
                ...incomingRequests.map(
                  (request) => _ActionTile(
                    title: request.fromDisplayName,
                    subtitle: 'Code ${request.fromFriendCode}',
                    accent: const Color(0xFFD4B06A),
                    actionLabel: 'Accept',
                    onAction: () => onAcceptFriendRequest(request.id),
                  ),
                ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Friends', trailing: '${friends.length}'),
              const SizedBox(height: 8),
              if (friends.isEmpty)
                const _EmptyLine(
                  label:
                      'Add friends first. Only then can you invite them to battles.',
                )
              else
                ...friends.map(
                  (friend) => _ActionTile(
                    title: friend.displayName,
                    subtitle: 'Friend code ${friend.friendCode}',
                    accent: const Color(0xFF5CCB8A),
                    actionLabel: 'Invite',
                    onAction: () => onInviteFriend(friend),
                  ),
                ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Battle invites',
                trailing: '${incomingInvites.length}',
              ),
              const SizedBox(height: 8),
              if (incomingInvites.isEmpty)
                const _EmptyLine(label: 'No open battle invites.')
              else
                ...incomingInvites.map(
                  (invite) => _ActionTile(
                    title: invite.hostDisplayName,
                    subtitle: 'An async battle is waiting for you',
                    accent: const Color(0xFF5CCB8A),
                    actionLabel: 'Play',
                    onAction: () => onAcceptBattleInvite(invite),
                  ),
                ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Your matches',
                trailing: '${controller.matches.length}',
              ),
              const SizedBox(height: 8),
              if (controller.matches.isEmpty)
                const _EmptyLine(label: 'No async matches yet.')
              else
                ...controller.matches.map(
                  (match) => _ActionTile(
                    title: match.opponentNameFor(profile?.userId ?? ''),
                    subtitle:
                        '${match.rounds.length} rounds - ${match.status.name}',
                    accent: match.status == AsyncBattleMatchStatus.completed
                        ? const Color(0xFFD4B06A)
                        : theme.colorScheme.secondary,
                    actionLabel: 'Open',
                    onAction: () => onOpenMatch(match),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: const Color(0xFFD8CBB8).withValues(alpha: 0.85),
      ),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }
}

class _ProfileSetupCard extends StatelessWidget {
  final bool firstSetup;
  final TextEditingController displayNameController;
  final VoidCallback? onSaveName;
  final VoidCallback? onCancel;

  const _ProfileSetupCard({
    required this.firstSetup,
    required this.displayNameController,
    required this.onSaveName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstSetup ? 'Set your online name' : 'Change online name',
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            firstSetup
                ? 'Your friends will later see this name in invites and duels.'
                : 'This is how you appear to friends and in async battles.',
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.84),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: displayNameController,
            style: const TextStyle(color: Color(0xFFF7ECDD)),
            decoration: InputDecoration(
              labelText: 'Your online name',
              labelStyle: TextStyle(
                color: const Color(0xFFD8CBB8).withValues(alpha: 0.85),
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSaveName,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD4B06A),
                    foregroundColor: const Color(0xFF1B100A),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    firstSetup ? 'Set name' : 'Save',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(width: 10),
                TextButton(onPressed: onCancel, child: const Text('Cancel')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryRow extends StatelessWidget {
  final String name;
  final String friendCode;
  final VoidCallback onEditName;

  const _ProfileSummaryRow({
    required this.name,
    required this.friendCode,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            label: 'Your online profile',
            value: name,
            trailing: 'Code $friendCode',
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onEditName,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD4B06A),
            side: BorderSide(
              color: const Color(0xFFD4B06A).withValues(alpha: 0.34),
            ),
          ),
          icon: const Icon(Icons.edit_rounded),
          label: const Text(
            'Edit',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionTitle({required this.title, required this.trailing});

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
            ),
          ),
        ),
        _StatusCapsule(label: trailing, color: const Color(0xFFD4B06A)),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final String actionLabel;
  final VoidCallback onAction;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.18),
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
            onPressed: onAction,
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final String? trailing;

  const _InfoChip({required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFD8CBB8).withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF7ECDD),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: 4),
            Text(
              trailing!,
              style: TextStyle(
                color: const Color(0xFFD8CBB8).withValues(alpha: 0.78),
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

class _EmptyLine extends StatelessWidget {
  final String label;

  const _EmptyLine({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFFD8CBB8).withValues(alpha: 0.84),
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}

class _StatusCapsule extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusCapsule({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
