import 'package:flutter/material.dart';

enum BadgeKind { collection, performance }

enum BadgeBoostType { xpSurge, streakShield, mapGrace }

class BadgeBoost {
  final BadgeBoostType type;
  final String name;
  final String description;
  final int charges;

  const BadgeBoost({
    required this.type,
    required this.name,
    required this.description,
    required this.charges,
  });
}

class GameBadge {
  final String id;
  final String title;
  final String description;
  final String lore;
  final BadgeKind kind;
  final IconData icon;
  final Color color;
  final List<String> requiredPersonIds;
  final int? requiredStreak;
  final int? requiredCorrectAnswers;
  final int? requiredPerfectSorts;
  final int? requiredMapSuccesses;
  final BadgeBoost? rewardBoost;

  const GameBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.lore,
    required this.kind,
    required this.icon,
    required this.color,
    this.requiredPersonIds = const [],
    this.requiredStreak,
    this.requiredCorrectAnswers,
    this.requiredPerfectSorts,
    this.requiredMapSuccesses,
    this.rewardBoost,
  });
}

class ActiveBadgeBoost {
  final BadgeBoostType type;
  final String sourceBadgeId;
  int chargesLeft;

  ActiveBadgeBoost({
    required this.type,
    required this.sourceBadgeId,
    required this.chargesLeft,
  });

  bool get isActive => chargesLeft > 0;
}
