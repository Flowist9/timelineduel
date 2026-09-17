import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../localization/app_language.dart';
import '../logic/game_session.dart';
import '../logic/progression_catalog.dart';
import 'badges_screen.dart';
import 'daily_challenge_screen.dart';
import 'progression_screen.dart';

class OverviewScreen extends StatelessWidget {
  final GameSession session;
  final VoidCallback onPlay;

  const OverviewScreen({
    super.key,
    required this.session,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppPalette.pageGradient),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: session,
          builder: (context, _) {
            final progress = session.progressSnapshot;
            final next = ProgressionCatalog.milestones
                .where((milestone) => milestone.level > progress.level)
                .firstOrNull;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'TIMELINE DUEL',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppPalette.gold,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr(
                            'Geschichte wartet auf dich.',
                            'History is waiting for you.',
                          ),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            'Dein Wissen. Deine Sammlung. Dein nächstes Kapitel.',
                            'Your knowledge. Your collection. Your next chapter.',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppPalette.panelGradient,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppPalette.gold.withValues(alpha: .3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    'Level ${progress.level}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  Chip(
                                    avatar: const Icon(
                                      Icons.toll_rounded,
                                      size: 18,
                                      color: AppPalette.gold,
                                    ),
                                    label: Text(
                                      context.tr(
                                        '${progress.coins} Münzen',
                                        '${progress.coins} coins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: progress.levelProgress.clamp(0.0, 1.0),
                                minHeight: 9,
                                borderRadius: BorderRadius.circular(20),
                                semanticsLabel: context.tr(
                                  'Level-Fortschritt',
                                  'Level progress',
                                ),
                                semanticsValue:
                                    '${progress.xp} / ${progress.xpToNext} XP',
                              ),
                              const SizedBox(height: 10),
                              Text('${progress.xp} / ${progress.xpToNext} XP'),
                              const SizedBox(height: 22),
                              FilledButton.icon(
                                onPressed: onPlay,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(
                                  context.tr(
                                    'Weiterspielen',
                                    'Continue playing',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 480 ? 3 : 2;
                            final width =
                                (constraints.maxWidth - (columns - 1) * 12) /
                                columns;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _stat(
                                  context,
                                  width,
                                  Icons.style_rounded,
                                  '${progress.ownedCards}',
                                  context.tr(
                                    'Karten gesammelt',
                                    'Cards collected',
                                  ),
                                ),
                                _stat(
                                  context,
                                  width,
                                  Icons.check_circle_outline_rounded,
                                  '${(progress.accuracy * 100).round()}%',
                                  context.tr(
                                    'Richtige Antworten',
                                    'Answer accuracy',
                                  ),
                                ),
                                _stat(
                                  context,
                                  width,
                                  Icons.local_fire_department_rounded,
                                  '${progress.bestStreak}',
                                  context.tr('Beste Serie', 'Best streak'),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          context.tr('Dein nächster Schritt', 'Your next step'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _action(
                          context,
                          Icons.trending_up_rounded,
                          next == null
                              ? context.tr(
                                  'Alle Meilensteine erreicht',
                                  'All milestones reached',
                                )
                              : context.tr(
                                  'Nächste Freischaltung: Level ${next.level}',
                                  'Next unlock: level ${next.level}',
                                ),
                          context.tr(
                            'Entdecke neue Spielmodi und Fragetypen.',
                            'Explore new modes and question types.',
                          ),
                          () => open(ProgressionScreen(session: session)),
                        ),
                        const SizedBox(height: 12),
                        _action(
                          context,
                          Icons.event_available_rounded,
                          context.tr(
                            'Tägliche Herausforderung',
                            'Daily challenge',
                          ),
                          context.tr(
                            'Teste dein Wissen mit der heutigen Aufgabe.',
                            'Test your knowledge with today’s challenge.',
                          ),
                          () => open(DailyChallengeScreen(session: session)),
                        ),
                        const SizedBox(height: 12),
                        _action(
                          context,
                          Icons.workspace_premium_rounded,
                          context.tr('Deine Erfolge', 'Your achievements'),
                          context.tr(
                            '${progress.earnedBadges} von ${progress.totalBadges} Abzeichen verdient',
                            '${progress.earnedBadges} of ${progress.totalBadges} badges earned',
                          ),
                          () => open(BadgesScreen(session: session)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    double width,
    IconData icon,
    String value,
    String label,
  ) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppPalette.gold, size: 22),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    ),
  );

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      leading: Icon(icon, color: AppPalette.gold),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
