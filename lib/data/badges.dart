import 'package:flutter/material.dart';

import '../models/game_badge.dart';

const badgeXpSurge = BadgeBoost(
  type: BadgeBoostType.xpSurge,
  name: 'Renaissance Surge',
  description: '+5 XP on the next 5 correct answers.',
  charges: 5,
);

const badgeStreakShield = BadgeBoost(
  type: BadgeBoostType.streakShield,
  name: 'Archive Shield',
  description: 'Your next mistake will not break the streak.',
  charges: 1,
);

const badgeMapGrace = BadgeBoost(
  type: BadgeBoostType.mapGrace,
  name: 'Cartographer Grace',
  description: 'Map tolerance is more forgiving for 3 attempts.',
  charges: 3,
);

const allBadges = <GameBadge>[
  GameBadge(
    id: 'renaissance_circle',
    title: 'Renaissance Circle',
    description:
        'Collect defining figures of the Renaissance and early modern era.',
    lore:
        'Leonardo, Galileo, and Shakespeare capture an age of artistic, scientific, and literary transformation.',
    kind: BadgeKind.collection,
    icon: Icons.auto_stories_rounded,
    color: Color(0xFFA47A3C),
    requiredPersonIds: ['leonardo', 'galileo', 'shakespeare'],
    rewardBoost: badgeXpSurge,
  ),
  GameBadge(
    id: 'high_renaissance',
    title: 'High Renaissance',
    description: 'Unite the great masters of the Italian Renaissance.',
    lore:
        'Leonardo and Michelangelo embody the creative peak of an era crowded with genius.',
    kind: BadgeKind.collection,
    icon: Icons.palette_rounded,
    color: Color(0xFF9C6439),
    requiredPersonIds: ['leonardo', 'michelangelo'],
  ),
  GameBadge(
    id: 'scientific_revolution',
    title: 'Scientific Revolution',
    description: 'Unlock the thinkers who reshaped modern science.',
    lore:
        'Galileo, Newton, Curie, and Einstein mark enormous leaps in humanity\'s understanding of the world.',
    kind: BadgeKind.collection,
    icon: Icons.biotech_rounded,
    color: Color(0xFF77552F),
    requiredPersonIds: ['galileo', 'newton', 'curie', 'einstein'],
    rewardBoost: badgeStreakShield,
  ),
  GameBadge(
    id: 'codebreakers',
    title: 'Codebreakers',
    description: 'Collect pioneers of logic, code, and computation.',
    lore:
        'Ada Lovelace, Alan Turing, Grace Hopper, Katherine Johnson, and Tim Berners-Lee connect mathematics to the digital age.',
    kind: BadgeKind.collection,
    icon: Icons.memory_rounded,
    color: Color(0xFF8D7858),
    requiredPersonIds: [
      'lovelace',
      'turing',
      'grace_hopper',
      'katherine_johnson',
      'tim_berners_lee',
    ],
  ),
  GameBadge(
    id: 'modern_statesmen',
    title: 'Modern Statesmen',
    description: 'Bring together major political figures of the modern era.',
    lore:
        'Churchill, Mandela, Obama, and Merkel represent very different chapters of twentieth- and twenty-first-century leadership.',
    kind: BadgeKind.collection,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFC3A374),
    requiredPersonIds: ['churchill', 'mandela', 'obama', 'merkel'],
  ),
  GameBadge(
    id: 'sporting_icons',
    title: 'Sporting Icons',
    description: 'Collect legendary athletes from the biggest global sports.',
    lore:
        'Ali, Pele, Jordan, and Serena stand for dominance in four very different arenas.',
    kind: BadgeKind.collection,
    icon: Icons.emoji_events_rounded,
    color: Color(0xFF9C6439),
    requiredPersonIds: ['ali', 'pele', 'jordan', 'serena'],
    rewardBoost: badgeMapGrace,
  ),
  GameBadge(
    id: 'track_and_field_legends',
    title: 'Track Legends',
    description: 'Collect icons of athletics and gymnastics.',
    lore:
        'Owens, Bolt, Biles, and Comaneci represent speed, precision, and unforgettable records.',
    kind: BadgeKind.collection,
    icon: Icons.speed_rounded,
    color: Color(0xFF6F6A45),
    requiredPersonIds: ['owens', 'bolt', 'biles', 'comaneci'],
  ),
  GameBadge(
    id: 'world_conquerors',
    title: 'World Conquerors',
    description: 'Assemble empire-builders who changed the map by force.',
    lore:
        'Alexander, Genghis Khan, Cyrus, and Qin Shi Huang reshaped vast regions through conquest and consolidation.',
    kind: BadgeKind.collection,
    icon: Icons.public_rounded,
    color: Color(0xFF7A5030),
    requiredPersonIds: [
      'alexander_great',
      'genghis_khan',
      'cyrus_great',
      'qin_shi_huang',
    ],
  ),
  GameBadge(
    id: 'ancient_strategists',
    title: 'Ancient Strategists',
    description:
        'Collect commanders and thinkers who turned warfare into strategy.',
    lore:
        'Alexander, Caesar, Hannibal, and Sun Tzu still define what ambition, logistics, and battlefield genius look like.',
    kind: BadgeKind.collection,
    icon: Icons.gavel_rounded,
    color: Color(0xFF8B623E),
    requiredPersonIds: [
      'alexander_great',
      'caesar',
      'hannibal_barca',
      'sun_tzu',
    ],
  ),
  GameBadge(
    id: 'philosophers_circle',
    title: 'Philosophers Circle',
    description: 'Collect thinkers who built the foundations of philosophy.',
    lore:
        'Socrates, Plato, Aristotle, and Confucius anchor traditions that still shape ethics, logic, and politics.',
    kind: BadgeKind.collection,
    icon: Icons.psychology_alt_rounded,
    color: Color(0xFF8B6A3D),
    requiredPersonIds: ['socrates', 'plato', 'aristotle', 'confucius'],
  ),
  GameBadge(
    id: 'enlightenment_minds',
    title: 'Enlightenment Minds',
    description: 'Bring together major voices of reason and political theory.',
    lore:
        'Locke, Rousseau, Kant, and Voltaire each helped redefine liberty, reason, and the modern individual.',
    kind: BadgeKind.collection,
    icon: Icons.lightbulb_rounded,
    color: Color(0xFFB38A53),
    requiredPersonIds: [
      'john_locke',
      'jean_jacques_rousseau',
      'immanuel_kant',
      'voltaire',
    ],
  ),
  GameBadge(
    id: 'quantum_pioneers',
    title: 'Quantum Pioneers',
    description: 'Collect the minds who transformed twentieth-century physics.',
    lore:
        'Planck, Bohr, Heisenberg, and Schrodinger turned the atomic world into a new intellectual frontier.',
    kind: BadgeKind.collection,
    icon: Icons.science_rounded,
    color: Color(0xFF6E5A44),
    requiredPersonIds: [
      'max_planck',
      'niels_bohr',
      'werner_heisenberg',
      'erwin_schrodinger',
    ],
  ),
  GameBadge(
    id: 'women_of_science',
    title: 'Women of Science',
    description:
        'Collect women whose discoveries and inventions changed the world.',
    lore:
        'Curie, Lovelace, Katherine Johnson, Grace Hopper, and Hedy Lamarr prove how many scientific revolutions depended on overlooked brilliance.',
    kind: BadgeKind.collection,
    icon: Icons.bolt_rounded,
    color: Color(0xFF8A6648),
    requiredPersonIds: [
      'curie',
      'lovelace',
      'katherine_johnson',
      'grace_hopper',
      'hedy_lamarr',
    ],
  ),
  GameBadge(
    id: 'football_royalty',
    title: 'Football Royalty',
    description: 'Collect global icons of world football.',
    lore:
        'Pele, Messi, Maradona, and Zidane each became a symbol of footballing greatness for a generation.',
    kind: BadgeKind.collection,
    icon: Icons.sports_soccer_rounded,
    color: Color(0xFF8A5B31),
    requiredPersonIds: ['pele', 'messi', 'maradona', 'zidane'],
  ),
  GameBadge(
    id: 'tennis_titans',
    title: 'Tennis Titans',
    description: 'Collect the great champions of the modern tennis era.',
    lore:
        'Serena, Federer, Nadal, and Djokovic define one of the strongest eras any sport has seen.',
    kind: BadgeKind.collection,
    icon: Icons.sports_tennis_rounded,
    color: Color(0xFF8E7554),
    requiredPersonIds: ['serena', 'federer', 'nadal', 'djokovic'],
  ),
  GameBadge(
    id: 'voices_of_change',
    title: 'Voices of Change',
    description: 'Collect leaders whose activism reshaped society.',
    lore:
        'Gandhi, Rosa Parks, Martin Luther King Jr., and Malala turned moral conviction into lasting public change.',
    kind: BadgeKind.collection,
    icon: Icons.campaign_rounded,
    color: Color(0xFFA06B46),
    requiredPersonIds: ['gandhi', 'rosa_parks', 'mlk_jr', 'malala'],
  ),
  GameBadge(
    id: 'crowned_rulers',
    title: 'Crowned Rulers',
    description: 'Collect monarchs who defined their kingdoms for generations.',
    lore:
        'Joan of Arc, Elizabeth I, Catherine the Great, and Queen Victoria each became inseparable from the age they ruled or embodied.',
    kind: BadgeKind.collection,
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFF9B744B),
    requiredPersonIds: [
      'joan_of_arc',
      'elizabeth_i',
      'catherine_great',
      'queen_victoria',
    ],
  ),
  GameBadge(
    id: 'baroque_and_classical',
    title: 'Baroque and Classical',
    description: 'Bring together giants of European concert music.',
    lore:
        'Bach, Mozart, and Beethoven trace a line from baroque mastery to classical perfection and beyond.',
    kind: BadgeKind.collection,
    icon: Icons.music_note_rounded,
    color: Color(0xFF7D5D42),
    requiredPersonIds: ['johann_sebastian_bach', 'mozart', 'beethoven'],
  ),
  GameBadge(
    id: 'masters_of_paint',
    title: 'Masters of Paint',
    description: 'Collect artists whose images reshaped visual culture.',
    lore:
        'Rembrandt, Van Gogh, Picasso, Frida Kahlo, and Leonardo show how painting keeps reinventing what a portrait, myth, or self can be.',
    kind: BadgeKind.collection,
    icon: Icons.brush_rounded,
    color: Color(0xFF86563C),
    requiredPersonIds: ['rembrandt', 'vangogh', 'picasso', 'kahlo', 'leonardo'],
  ),
  GameBadge(
    id: 'literary_giants',
    title: 'Literary Giants',
    description: 'Collect writers who shaped the modern canon.',
    lore:
        'Shakespeare, Austen, Hemingway, and Orwell each changed how readers imagine language, society, and character.',
    kind: BadgeKind.collection,
    icon: Icons.menu_book_rounded,
    color: Color(0xFF7A6147),
    requiredPersonIds: ['shakespeare', 'austen', 'hemingway', 'orwell'],
  ),
  GameBadge(
    id: 'cinema_and_animation',
    title: 'Cinema and Animation',
    description: 'Collect creators who shaped visual storytelling on screen.',
    lore:
        'Walt Disney, Stanley Kubrick, Hayao Miyazaki, and Banksy bridge fantasy, cinema, and modern image-making.',
    kind: BadgeKind.collection,
    icon: Icons.movie_creation_rounded,
    color: Color(0xFF8A6246),
    requiredPersonIds: [
      'walt_disney',
      'stanley_kubrick',
      'hayao_miyazaki',
      'banksy',
    ],
  ),
  GameBadge(
    id: 'modern_visionaries',
    title: 'Modern Visionaries',
    description: 'Collect builders of the connected and digital world.',
    lore:
        'Bill Gates, Tim Berners-Lee, Steve Jobs, and Hedy Lamarr link computing, design, and communications in surprising ways.',
    kind: BadgeKind.collection,
    icon: Icons.devices_rounded,
    color: Color(0xFF776149),
    requiredPersonIds: [
      'bill_gates',
      'tim_berners_lee',
      'steve_jobs',
      'hedy_lamarr',
    ],
  ),
  GameBadge(
    id: 'flight_and_frontiers',
    title: 'Flight and Frontiers',
    description: 'Collect figures who pushed geography and technology outward.',
    lore:
        'Amelia Earhart, Katherine Johnson, Hedy Lamarr, and Leonardo each widened the horizon between imagination and engineering.',
    kind: BadgeKind.collection,
    icon: Icons.flight_takeoff_rounded,
    color: Color(0xFF86644C),
    requiredPersonIds: [
      'amelia_earhart',
      'katherine_johnson',
      'hedy_lamarr',
      'leonardo',
    ],
  ),
  GameBadge(
    id: 'steady_historian',
    title: 'Steady Historian',
    description: 'Reach a streak of 5 correct answers.',
    lore: 'Consistency is the first step from curiosity to mastery.',
    kind: BadgeKind.performance,
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFC3A374),
    requiredStreak: 5,
  ),
  GameBadge(
    id: 'unstoppable_chronicler',
    title: 'Unstoppable Chronicler',
    description: 'Hold a streak of 10 correct answers.',
    lore: 'When chronology starts to flow, knowledge turns into instinct.',
    kind: BadgeKind.performance,
    icon: Icons.whatshot_rounded,
    color: Color(0xFFDCBA82),
    requiredStreak: 10,
  ),
  GameBadge(
    id: 'timeline_savant',
    title: 'Timeline Savant',
    description: 'Answer 25 quiz questions correctly.',
    lore: 'Every correct placement makes history feel more intuitive.',
    kind: BadgeKind.performance,
    icon: Icons.history_edu_rounded,
    color: Color(0xFFDCBA82),
    requiredCorrectAnswers: 25,
  ),
  GameBadge(
    id: 'archive_master',
    title: 'Archive Master',
    description: 'Answer 50 quiz questions correctly.',
    lore: 'Endurance turns isolated facts into a reliable historical instinct.',
    kind: BadgeKind.performance,
    icon: Icons.library_books_rounded,
    color: Color(0xFFA47A3C),
    requiredCorrectAnswers: 50,
  ),
  GameBadge(
    id: 'master_sorter',
    title: 'Master Sorter',
    description: 'Perfect 3 sorting mini-games.',
    lore:
        'When chronology becomes intuitive, you stop recalling history and start structuring it.',
    kind: BadgeKind.performance,
    icon: Icons.reorder_rounded,
    color: Color(0xFFA47A3C),
    requiredPerfectSorts: 3,
  ),
  GameBadge(
    id: 'chronology_architect',
    title: 'Chronology Architect',
    description: 'Perfect 6 sorting rounds.',
    lore:
        'The best historians do not just remember timelines, they build them in their heads.',
    kind: BadgeKind.performance,
    icon: Icons.view_timeline_rounded,
    color: Color(0xFF77552F),
    requiredPerfectSorts: 6,
  ),
  GameBadge(
    id: 'map_pathfinder',
    title: 'Map Pathfinder',
    description: 'Hit 3 birthplaces within the target radius.',
    lore:
        'Once places attach to biographies, history becomes spatial as well as chronological.',
    kind: BadgeKind.performance,
    icon: Icons.explore_rounded,
    color: Color(0xFF77552F),
    requiredMapSuccesses: 3,
  ),
  GameBadge(
    id: 'world_navigator',
    title: 'World Navigator',
    description: 'Hit 6 birthplaces in map mode.',
    lore:
        'Finding locations confidently means reading history across space, not just time.',
    kind: BadgeKind.performance,
    icon: Icons.public_rounded,
    color: Color(0xFF8D7858),
    requiredMapSuccesses: 6,
  ),
];
