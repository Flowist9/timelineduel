import 'package:flutter/material.dart';

import '../battle/battle_shared.dart';
import '../design/app_theme.dart';

class BattleModeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final String actionLabel;
  final VoidCallback onAction;
  final bool enabled;

  const BattleModeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.actionLabel,
    required this.onAction,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.19),
            AppPalette.ink.withValues(alpha: 0.26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFFD8CBB8).withValues(alpha: 0.84),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: enabled ? onAction : null,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              disabledBackgroundColor: accent.withValues(alpha: 0.18),
              disabledForegroundColor: accent.withValues(alpha: 0.72),
              foregroundColor: AppPalette.ink,
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

class BattleOnlineGroupHeader extends StatelessWidget {
  final String title;
  final int count;

  const BattleOnlineGroupHeader({
    super.key,
    required this.title,
    required this.count,
  });

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
        BattlePill(label: '$count'),
      ],
    );
  }
}

class BattleOnlineEmptyTile extends StatelessWidget {
  final String label;

  const BattleOnlineEmptyTile({super.key, required this.label});

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

class BattleOnlineActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryAction;

  const BattleOnlineActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondaryAction,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (secondaryLabel != null && onSecondaryAction != null) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
