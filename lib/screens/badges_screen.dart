import 'package:flutter/material.dart';

import '../data/persons.dart';
import '../logic/game_session.dart';
import '../models/game_badge.dart';
import '../models/person.dart';
import '../models/person_status.dart';
import '../widgets/person_portrait.dart';

class BadgesScreen extends StatelessWidget {
  final GameSession session;

  const BadgesScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final earnedSetBadges = session.earnedBadges
        .where((badge) => badge.kind == BadgeKind.collection)
        .toList();
    final lockedSetBadges = session.lockedBadges
        .where((badge) => badge.kind == BadgeKind.collection)
        .toList();
    final earnedPerformanceBadges = session.earnedBadges
        .where((badge) => badge.kind == BadgeKind.performance)
        .toList();
    final lockedPerformanceBadges = session.lockedBadges
        .where((badge) => badge.kind == BadgeKind.performance)
        .toList();
    final activeBoost = session.activeBoost;
    final activeBoostBadge = session.activeBoostBadge;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gridCount = screenWidth >= 560 ? 3 : 2;
    final gridAspectRatio = screenWidth >= 900 ? 0.66 : 0.56;

    Widget sectionTitle(String title, String subtitle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF8F0E3),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFE6D6BF), height: 1.35),
          ),
        ],
      );
    }

    Person? personById(String id) {
      for (final person in allPersons) {
        if (person.id == id) return person;
      }
      return null;
    }

    String redactedLoreForBadge(GameBadge badge) {
      var lore = badge.lore;
      final hiddenNames =
          badge.requiredPersonIds
              .where((id) => session.statusById[id] != PersonStatus.unlocked)
              .map(personById)
              .whereType<Person>()
              .map((person) => person.name)
              .toList()
            ..sort((a, b) => b.length.compareTo(a.length));

      for (final name in hiddenNames) {
        lore = lore.replaceAll(name, '???');
      }
      return lore;
    }

    Widget requiredPersonTile({Person? person, required PersonStatus status}) {
      final isUnlocked = status == PersonStatus.unlocked && person != null;
      final isDiscovered = status == PersonStatus.discovered;
      final title = isUnlocked
          ? person.name
          : isDiscovered
          ? 'Discovered member'
          : 'Hidden member';

      return Container(
        width: 92,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isUnlocked
              ? const Color(0xFF77552F).withValues(alpha: 0.10)
              : const Color(0xFF2C2017).withValues(alpha: 0.10),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFFA47A3C).withValues(alpha: 0.26)
                : const Color(0xFF77552F).withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUnlocked)
              PersonPortrait(
                person: person,
                width: 68,
                height: 68,
                borderRadius: 18,
                variant: PersonImageVariant.portrait,
              )
            else
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7A654B), Color(0xFF4B3929)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFF1E2CB),
                  size: 34,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF352618),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      );
    }

    void showBadgeDetails(GameBadge badge, {required bool earned}) {
      final progress = session.progressForBadge(badge);
      final progressLabel = session.progressLabelForBadge(badge);
      final requiredMembers = badge.requiredPersonIds.map((id) {
        final status = session.statusById[id] ?? PersonStatus.undiscovered;
        final person = status == PersonStatus.unlocked ? personById(id) : null;
        return (person: person, status: status);
      }).toList();

      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF1E2CB), Color(0xFFD6BA8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: badge.color.withValues(alpha: 0.45),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF140E0A).withValues(alpha: 0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                badge.color.withValues(alpha: 0.92),
                                const Color(0xFF77552F),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: badge.color.withValues(alpha: 0.28),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            badge.icon,
                            size: 34,
                            color: const Color(0xFFF8F0E3),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                badge.title,
                                style: const TextStyle(
                                  color: Color(0xFF2D2012),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                earned ? 'Unlocked' : progressLabel,
                                style: TextStyle(
                                  color: earned
                                      ? const Color(0xFF77552F)
                                      : const Color(0xFF6B5743),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      badge.description,
                      style: const TextStyle(
                        color: Color(0xFF352618),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFF77552F).withValues(alpha: 0.08),
                        border: Border.all(
                          color: const Color(
                            0xFF77552F,
                          ).withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        redactedLoreForBadge(badge),
                        style: const TextStyle(
                          color: Color(0xFF5A4431),
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    if (requiredMembers.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Required figures',
                        style: TextStyle(
                          color: Color(0xFF352618),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final member in requiredMembers)
                            requiredPersonTile(
                              person: member.person,
                              status: member.status,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: earned ? 1 : progress,
                        minHeight: 10,
                        backgroundColor: const Color(
                          0xFF77552F,
                        ).withValues(alpha: 0.14),
                        valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      earned ? 'Fully completed' : progressLabel,
                      style: const TextStyle(
                        color: Color(0xFF5A4431),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (badge.rewardBoost != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: badge.color.withValues(alpha: 0.12),
                          border: Border.all(
                            color: badge.color.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What this badge does',
                              style: TextStyle(
                                color: badge.color,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              badge.rewardBoost!.description,
                              style: const TextStyle(
                                color: Color(0xFF352618),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    Widget badgeTile(GameBadge badge, {required bool earned}) {
      final progress = session.progressLabelForBadge(badge);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => showBadgeDetails(badge, earned: earned),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: earned
                    ? [
                        badge.color.withValues(alpha: 0.34),
                        const Color(0xFF24170F),
                      ]
                    : [const Color(0xFF4A3828), const Color(0xFF21160F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: earned
                    ? badge.color.withValues(alpha: 0.42)
                    : const Color(0xFFE6D6BF).withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: badge.color.withValues(alpha: earned ? 0.2 : 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    earned
                        ? Icons.verified_rounded
                        : Icons.lock_outline_rounded,
                    size: 22,
                    color: earned
                        ? const Color(0xFFD4B06A)
                        : const Color(0xFFE6D6BF),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        badge.color,
                        earned
                            ? const Color(0xFF77552F)
                            : const Color(0xFF5B4937),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFFF6E8D2).withValues(alpha: 0.35),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: badge.color.withValues(alpha: 0.26),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    badge.icon,
                    size: 38,
                    color: const Color(0xFFF8F0E3),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        badge.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF8F0E3),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        earned ? 'Unlocked' : progress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: earned
                              ? const Color(0xFFD4B06A)
                              : const Color(0xFFE6D6BF),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: earned ? 1 : session.progressForBadge(badge),
                    minHeight: 8,
                    backgroundColor: const Color(
                      0xFF6A5642,
                    ).withValues(alpha: 0.35),
                    valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap for details',
                  style: TextStyle(
                    color: const Color(0xFFF1E2CB).withValues(alpha: 0.76),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildBadgeGrid(List<GameBadge> badges, {required bool earned}) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: badges.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: gridAspectRatio,
        ),
        itemBuilder: (context, index) {
          return badgeTile(badges[index], earned: earned);
        },
      );
    }

    Widget buildBadgeSection({
      required String title,
      required String subtitle,
      required List<GameBadge> earned,
      required List<GameBadge> locked,
    }) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xCC4C3929), Color(0xE62A1B12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFF1E2CB).withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(title, subtitle),
            const SizedBox(height: 16),
            if (earned.isNotEmpty) ...[
              const Text(
                'Unlocked',
                style: TextStyle(
                  color: Color(0xFFD4B06A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              buildBadgeGrid(earned, earned: true),
              const SizedBox(height: 18),
            ],
            const Text(
              'In progress',
              style: TextStyle(
                color: Color(0xFFF8F0E3),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            buildBadgeGrid(locked, earned: false),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Badges',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFFF8F0E3),
          elevation: 0,
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2C2017), Color(0xFF140E0A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: -60,
              right: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA47A3C).withValues(alpha: 0.22),
                      blurRadius: 90,
                      spreadRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF77552F), Color(0xFF3A291B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF9C6439,
                            ).withValues(alpha: 0.22),
                            blurRadius: 26,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Collection and badges',
                            style: TextStyle(
                              color: Color(0xFFF8F0E3),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Collect major trophies for historical sets and gameplay milestones. Tap a badge to see its effect, progress, and background.',
                            style: TextStyle(
                              color: Color(0xFFEADCC6),
                              height: 1.4,
                            ),
                          ),
                          if (activeBoost != null &&
                              activeBoostBadge != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: activeBoostBadge.color.withValues(
                                  alpha: 0.18,
                                ),
                                border: Border.all(
                                  color: activeBoostBadge.color.withValues(
                                    alpha: 0.32,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active boost: ${activeBoostBadge.title}',
                                    style: TextStyle(
                                      color: activeBoostBadge.color,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${activeBoost.chargesLeft} charges left',
                                    style: const TextStyle(
                                      color: Color(0xFFF8F0E3),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: const Color(
                                0xFFF1E2CB,
                              ).withValues(alpha: 0.08),
                            ),
                            child: TabBar(
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: const Color(0xFFD4B06A),
                              ),
                              labelColor: const Color(0xFF2D2012),
                              unselectedLabelColor: const Color(0xFFF8F0E3),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Sets'),
                                Tab(text: 'Milestones'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ListView(
                            children: [
                              buildBadgeSection(
                                title: 'Historical sets',
                                subtitle:
                                    'Eras, movements, and themed groups such as the Renaissance or Scientific Revolution.',
                                earned: earnedSetBadges,
                                locked: lockedSetBadges,
                              ),
                            ],
                          ),
                          ListView(
                            children: [
                              buildBadgeSection(
                                title: 'Milestones',
                                subtitle:
                                    'Streaks, perfect minigames, and other gameplay achievements.',
                                earned: earnedPerformanceBadges,
                                locked: lockedPerformanceBadges,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
