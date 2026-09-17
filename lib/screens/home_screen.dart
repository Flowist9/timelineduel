import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/ads_service.dart';
import '../data/persons.dart';
import '../design/app_theme.dart';
import '../localization/app_language.dart';
import '../logic/game_session.dart';
import '../models/category.dart';
import '../models/person.dart';
import '../monetization/purchase_service.dart';
import '../online/online_battle_controller.dart';
import '../widgets/reward_card_reveal_dialog.dart';
import 'badges_screen.dart';
import 'battle_screen.dart';
import 'battle_stats_screen.dart';
import 'collection_screen.dart';
import 'credits_screen.dart';
import 'daily_challenge_screen.dart';
import 'progression_screen.dart';
import 'friends_screen.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'map_screen.dart';
import 'overview_screen.dart';
import 'shop_screen.dart';
import 'timeline_screen.dart';

class HomeScreen extends StatefulWidget {
  final OnlineBattleController onlineController;
  final AdsService adsService;
  final PurchaseService purchaseService;
  final GameSession session;

  const HomeScreen({
    super.key,
    required this.onlineController,
    required this.adsService,
    required this.purchaseService,
    required this.session,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _starterPoliticianCommonPool = <String>[
    'benazir_bhutto',
    'thatcher',
    'degaulle',
    'golda_meir',
    'greta_thunberg',
    'ronald_reagan',
    'queen_victoria',
    'ho_chi_minh',
  ];
  static const _starterScientistCommonPool = <String>[
    'bill_gates',
    'max_planck',
    'amelia_earhart',
    'alhazen',
    'james_watt',
    'niels_bohr',
    'fibonacci',
    'steve_jobs',
  ];
  static const _starterArtistCommonPool = <String>[
    'walt_disney',
    'banksy',
    'austen',
    'rembrandt',
    'warhol',
    'george_orwell',
    'frederic_chopin',
    'virginia_woolf',
  ];
  static const _starterAthleteCommonPool = <String>[
    'federer',
    'biles',
    'maradona',
    'nadal',
    'djokovic',
    'lebron',
    'michael_jackson',
    'tiger_woods',
  ];
  static const _starterEpicPool = <String>[
    'curie',
    'churchill',
    'gandhi',
    'tesla',
    'picasso',
    'serena',
    'shakespeare',
    'elizabeth_i',
    'john_f_kennedy',
    'saladin',
  ];
  static const _firstRunOnboardingKey = 'first_run_onboarding_completed_v1';

  GameSession get session => widget.session;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _homeIndex = 2;
  final Set<int> _visitedTabs = {2};
  bool _onboardingRunning = false;
  late final List<String> _starterPackIds;

  late final List<Widget> _homeScreens;

  @override
  void initState() {
    super.initState();
    _starterPackIds = _buildStarterPackIds();
    if (!widget.session.hasStoredProgress) {
      widget.session.unlockPersonsByIds(_starterPackIds);
    }
    widget.purchaseService.attachSession(widget.session);
    _homeScreens = [
      GameScreen(
        session: widget.session,
        adsService: widget.adsService,
        showIntroTutorialOnStart: false,
      ),
      BattleScreen(
        session: widget.session,
        onlineController: widget.onlineController,
        adsService: widget.adsService,
      ),
      OverviewScreen(
        session: session,
        onPlay: () => setState(() => _homeIndex = 0),
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRunFirstRunOnboarding();
    });
  }

  @override
  Widget build(BuildContext context) {
    _visitedTabs.add(_homeIndex);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppPalette.ink,
      drawer: Drawer(
        backgroundColor: AppPalette.canvas,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: session,
            builder: (context, _) {
              final snapshot = session.progressSnapshot;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppPalette.goldBright,
                                    AppPalette.gold,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.history_edu_rounded,
                                color: AppPalette.ink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TIMELINE DUEL',
                                    style: TextStyle(
                                      color: AppPalette.parchment,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'YOUR HISTORY ARCHIVE',
                                    style: TextStyle(
                                      color: AppPalette.gold,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.tr(
                            'Dein Spielstand und alle Bereiche auf einen Blick.',
                            'Your progress and every area at a glance.',
                          ),
                          style: TextStyle(
                            color: AppPalette.mutedParchment,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: AppPalette.panelGradient,
                            border: Border.all(
                              color: AppPalette.gold.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _DrawerStatChip(
                                    label: 'Lv ${snapshot.level}',
                                    icon: Icons.auto_awesome_rounded,
                                  ),
                                  _DrawerStatChip(
                                    label: context.tr(
                                      '${snapshot.coins} Münzen',
                                      '${snapshot.coins} coins',
                                    ),
                                    icon: Icons.toll_rounded,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: snapshot.levelProgress.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD4B06A),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.xp} / ${snapshot.xpToNext} XP • ${snapshot.ownedCards} cards • ${snapshot.earnedBadges} badges',
                                style: TextStyle(
                                  color: AppPalette.mutedParchment,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        _DrawerSection(
                          label: context.tr(
                            'Spielen & Fortschritt',
                            'Play & progress',
                          ),
                        ),
                        _DrawerEntry(
                          label: context.tr('Fortschritt', 'Progression'),
                          icon: Icons.trending_up_rounded,
                          onTap: () => _openDrawerScreen(
                            ProgressionScreen(session: session),
                          ),
                        ),
                        _DrawerEntry(
                          label: context.tr('Tagesaufgabe', 'Daily Challenge'),
                          icon: Icons.event_available_rounded,
                          onTap: () => _openDrawerScreen(
                            DailyChallengeScreen(session: session),
                          ),
                        ),
                        _DrawerSection(
                          label: context.tr(
                            'Wettbewerb & Freunde',
                            'Competition & friends',
                          ),
                        ),
                        _DrawerEntry(
                          label: context.tr('Rangliste', 'Leaderboard'),
                          icon: Icons.emoji_events_rounded,
                          onTap: () => _openDrawerScreen(
                            LeaderboardScreen(
                              onlineController: widget.onlineController,
                            ),
                          ),
                        ),
                        _DrawerEntry(
                          label: context.tr('Freunde', 'Friends'),
                          icon: Icons.people_alt_rounded,
                          onTap: () => _openDrawerScreen(
                            FriendsScreen(
                              session: session,
                              onlineController: widget.onlineController,
                            ),
                          ),
                        ),
                        _DrawerEntry(
                          label: context.tr('Battle-Statistik', 'Battle stats'),
                          icon: Icons.analytics_rounded,
                          onTap: () => _openDrawerScreen(
                            BattleStatsScreen(
                              session: session,
                              onlineController: widget.onlineController,
                            ),
                          ),
                        ),
                        _DrawerEntry(
                          label: context.tr('Shop', 'Shop'),
                          icon: Icons.storefront_rounded,
                          onTap: () => _openDrawerScreen(
                            ShopScreen(
                              session: session,
                              adsService: widget.adsService,
                              purchaseService: widget.purchaseService,
                            ),
                          ),
                        ),
                        _DrawerSection(
                          label: context.tr('Dein Archiv', 'Your archive'),
                        ),
                        _DrawerEntry(
                          label: context.tr('Zeitstrahl', 'Timeline'),
                          icon: Icons.timeline_rounded,
                          onTap: () => _openDrawerScreen(
                            TimelineScreen(session: session),
                          ),
                        ),
                        _DrawerEntry(
                          label: context.tr('Sammlung', 'Collection'),
                          icon: Icons.collections_bookmark_rounded,
                          lockedLabel: session.canAccessCollection
                              ? null
                              : 'Lv 20',
                          onTap: () {
                            if (!session.canAccessCollection) {
                              _showLockedSnackBar(
                                context.tr(
                                  'Die Sammlung wird ab Level 20 freigeschaltet.',
                                  'Collection unlocks at level 20.',
                                ),
                              );
                              return;
                            }
                            _openDrawerScreen(
                              CollectionScreen(session: session),
                            );
                          },
                        ),
                        _DrawerEntry(
                          label: context.tr('Karte', 'Map'),
                          icon: Icons.public_rounded,
                          lockedLabel: session.canAccessMap ? null : 'Lv 30',
                          onTap: () {
                            if (!session.canAccessMap) {
                              _showLockedSnackBar(
                                context.tr(
                                  'Die Karte wird ab Level 30 freigeschaltet.',
                                  'Map unlocks at level 30.',
                                ),
                              );
                              return;
                            }
                            _openDrawerScreen(MapScreen(session: session));
                          },
                        ),
                        _DrawerEntry(
                          label: context.tr('Abzeichen', 'Badges'),
                          icon: Icons.workspace_premium_rounded,
                          onTap: () =>
                              _openDrawerScreen(BadgesScreen(session: session)),
                        ),
                        _DrawerSection(
                          label: context.tr('App & Sprache', 'App & language'),
                        ),
                        _DrawerEntry(
                          label: context.tr('Mitwirkende', 'Credits'),
                          icon: Icons.info_outline_rounded,
                          onTap: () => _openDrawerScreen(const CreditsScreen()),
                        ),
                        _DrawerEntry(
                          label: context.isGerman ? 'English' : 'Deutsch',
                          icon: Icons.language_rounded,
                          onTap: () {
                            context.languageController.setLocaleCode(
                              context.isGerman ? 'en' : 'de',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _homeIndex,
            children: [
              for (var index = 0; index < _homeScreens.length; index++)
                TickerMode(
                  enabled: index == _homeIndex,
                  child: _visitedTabs.contains(index)
                      ? _homeScreens[index]
                      : const SizedBox.shrink(),
                ),
            ],
          ),
          if (widget.onlineController.isOfflineMode)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(68, 12, 12, 0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Material(
                    color: const Color(0xFF553A1A),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        context.tr(
                          'Offline-Modus: Online-Battles sind derzeit nicht verfuegbar.',
                          'Offline mode: online battles are unavailable.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFF7ECDD),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withValues(alpha: 0.28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFFF7ECDD),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeBannerAd(adsService: widget.adsService),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            decoration: BoxDecoration(
              color: AppPalette.surfaceRaised,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppPalette.gold.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: NavigationBar(
              height: 72,
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppPalette.gold.withValues(alpha: 0.2),
              selectedIndex: _homeIndex,
              onDestinationSelected: (value) =>
                  setState(() => _homeIndex = value),
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.quiz_rounded),
                  selectedIcon: Icon(Icons.quiz_rounded),
                  label: context.tr('Quiz', 'Quiz'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_kabaddi_rounded),
                  selectedIcon: Icon(Icons.sports_kabaddi_rounded),
                  label: context.tr('Battle', 'Battle'),
                ),
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: context.tr('Übersicht', 'Overview'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _maybeRunFirstRunOnboarding() async {
    if (!mounted || _onboardingRunning) return;
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_firstRunOnboardingKey) ?? false;
    if (completed) return;

    _onboardingRunning = true;

    final revealedPeople = <Person>[];
    for (final id in _starterPackIds) {
      for (final person in allPersons) {
        if (person.id == id) {
          revealedPeople.add(person);
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() => _homeIndex = 0);
    await _showOnboardingDialog(
      title: 'Welcome to Timeline Duel',
      subtitle:
          'The game is built around three loops: answer Quiz questions, grow your archive, and turn your cards into Battle strategy.',
      lines: const [
        'Quiz is your main progression path and unlocks new question types every few levels.',
        'Every person you collect strengthens your archive, sets, and future Battle choices.',
        'Battle uses your cards in tactical duels, so collection and quiz knowledge feed directly into each other.',
      ],
      icon: Icons.auto_awesome_rounded,
      accent: const Color(0xFFD4B06A),
      cta: 'Show starter pack',
    );

    await _showOnboardingDialog(
      title: 'Starter pack',
      subtitle:
          'You begin with a curated 10-card starter pack: 8 commons and 2 epics drawn from well-known historical figures.',
      lines: const [
        'These cards are your first archive core.',
        'You will unlock more figures through level-ups, capsules, and progression milestones.',
      ],
      icon: Icons.redeem_rounded,
      accent: const Color(0xFFD4B06A),
      cta: 'Open starter pack',
    );

    for (var i = 0; i < revealedPeople.length; i++) {
      final person = revealedPeople[i];
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0xFF120B07),
        builder: (context) => RewardCardRevealDialog(
          eyebrow: 'Starter pack',
          title: person.name,
          subtitle: 'joins your opening archive.',
          confirmLabel: i == revealedPeople.length - 1
              ? 'Continue'
              : 'Next card',
          accentIcon: _categoryIcon(person.category),
          accentColor: _categoryColor(person.category),
          accentLabel: _categoryLabel(person.category),
          person: person,
          showOpeningPhase: i == 0,
          openingEyebrow: 'Starter pack',
          openingTitle: 'Opening your first cards',
          openingBody:
              'Your initial archive is being prepared so you can jump straight into the game.',
        ),
      );
    }

    if (!mounted) return;
    setState(() => _homeIndex = 0);
    await _showOnboardingDialog(
      title: 'How Quiz works',
      subtitle:
          'Quiz is your core progression mode. Correct answers drive XP, levels, coins, and new unlocks.',
      lines: const [
        'Answer history questions to gain XP and coins.',
        'Every 5 levels you unlock a new question type or progression milestone.',
        'Cards, sets, and later Battle strength all grow out of your Quiz progress.',
      ],
      icon: Icons.quiz_rounded,
      accent: const Color(0xFFD4B06A),
      cta: 'Show Battle',
    );

    if (!mounted) return;
    setState(() => _homeIndex = 1);
    await _showOnboardingDialog(
      title: 'How Battle works',
      subtitle:
          'Battle turns your collection into tactical duels. You bring cards, pick the best one for each round, and try to outscore your opponent.',
      lines: const [
        'A battle uses 4 rounds and can go to a tiebreak.',
        'Choose the right card for the round objective, not just your favorite figure.',
        'Legendary cards can change the rules with special Battle abilities.',
        'Battle fully unlocks at level 10, so Quiz is how you prepare for it.',
      ],
      icon: Icons.sports_kabaddi_rounded,
      accent: const Color(0xFF8DC8FF),
      cta: 'Start playing',
    );

    if (!mounted) return;
    setState(() => _homeIndex = 0);
    await prefs.setBool(_firstRunOnboardingKey, true);
    _onboardingRunning = false;
  }

  List<String> _buildStarterPackIds() {
    final politicianCommons = [..._starterPoliticianCommonPool]..shuffle();
    final scientistCommons = [..._starterScientistCommonPool]..shuffle();
    final artistCommons = [..._starterArtistCommonPool]..shuffle();
    final athleteCommons = [..._starterAthleteCommonPool]..shuffle();
    final epicPool = [..._starterEpicPool]..shuffle();
    return [
      ...politicianCommons.take(2),
      ...scientistCommons.take(2),
      ...artistCommons.take(2),
      ...athleteCommons.take(2),
      ...epicPool.take(2),
    ];
  }

  Future<void> _showOnboardingDialog({
    required String title,
    required String subtitle,
    required List<String> lines,
    required IconData icon,
    required Color accent,
    required String cta,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF120B07),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 34,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3A291B), Color(0xFF1A120D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -70,
                    right: -40,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.30),
                            accent.withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -24,
                    top: 110,
                    child: Transform.rotate(
                      angle: -0.24,
                      child: Container(
                        width: 84,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.14),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 22,
                    bottom: 92,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.22),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 42,
                    bottom: 112,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.10),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _OnboardingPatternPainter(accent: accent),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.18),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(icon, color: accent, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFF7ECDD),
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: const Color(
                              0xFFD8CBB8,
                            ).withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final line in lines) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  line,
                                  style: const TextStyle(
                                    color: Color(0xFFF7ECDD),
                                    height: 1.42,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: const Color(0xFF1B100A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              cta,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Color _categoryColor(Category category) => switch (category) {
    Category.politician => const Color(0xFFE39063),
    Category.scientist => const Color(0xFF6FA8FF),
    Category.artist => const Color(0xFFD17FE7),
    Category.athlete => const Color(0xFF4FD198),
  };

  IconData _categoryIcon(Category category) => switch (category) {
    Category.politician => Icons.account_balance_rounded,
    Category.scientist => Icons.science_rounded,
    Category.artist => Icons.palette_rounded,
    Category.athlete => Icons.emoji_events_rounded,
  };

  String _categoryLabel(Category category) => switch (category) {
    Category.politician => 'Politics',
    Category.scientist => 'Science',
    Category.artist => 'Art',
    Category.athlete => 'Sport',
  };

  void _openDrawerScreen(Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _OnboardingPatternPainter extends CustomPainter {
  final Color accent;

  const _OnboardingPatternPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    for (double y = 36; y < size.height; y += 44) {
      canvas.drawLine(
        Offset(size.width * 0.58, y),
        Offset(size.width + 20, y - 18),
        linePaint,
      );
    }

    for (double x = size.width * 0.56; x < size.width; x += 34) {
      for (double y = 28; y < size.height; y += 52) {
        canvas.drawCircle(Offset(x, y), 1.6, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingPatternPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _DrawerStatChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _DrawerStatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFD4B06A).withValues(alpha: 0.14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD4B06A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD4B06A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String label;

  const _DrawerSection({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppPalette.gold,
        letterSpacing: .8,
      ),
    ),
  );
}

class _DrawerEntry extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? lockedLabel;

  const _DrawerEntry({
    required this.label,
    required this.icon,
    required this.onTap,
    this.lockedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD8CBB8)),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFF7ECDD),
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: lockedLabel == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: Text(
                lockedLabel!,
                style: const TextStyle(
                  color: Color(0xFFD4B06A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }
}
