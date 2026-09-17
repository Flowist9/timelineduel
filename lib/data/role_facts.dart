import '../models/late_game_fact.dart';

// Prepared for future late-game quiz types. Not wired into gameplay yet.
final Map<String, LateGameChoiceFact> roleFacts = {
  'caesar': const LateGameChoiceFact(
    correct: ['Roman dictator', 'General'],
    wrong: [
      'Athenian philosopher',
      'British prime minister',
      'Renaissance astronomer',
    ],
  ),
  'cleopatra': const LateGameChoiceFact(
    correct: ['Queen of Egypt', 'Ptolemaic ruler'],
    wrong: ['German chancellor', 'Tennis champion', 'Classical composer'],
  ),
  'napoleon': const LateGameChoiceFact(
    correct: ['French emperor'],
    wrong: [
      'American president',
      'Renaissance painter',
      'World champion boxer',
    ],
  ),
  'lincoln': const LateGameChoiceFact(
    correct: ['American president'],
    wrong: ['Egyptian queen', 'Theoretical physicist', 'Tennis icon'],
  ),
  'merkel': const LateGameChoiceFact(
    correct: ['German chancellor'],
    wrong: ['Roman emperor', 'Renaissance sculptor', 'Olympic sprint star'],
  ),
  'churchill': const LateGameChoiceFact(
    correct: ['British prime minister'],
    wrong: [
      'American president',
      'Romantic-era novelist',
      'Classical composer',
    ],
  ),
  'mandela': const LateGameChoiceFact(
    correct: ['Anti-apartheid leader', 'President of South Africa'],
    wrong: ['Renaissance sculptor', 'Ancient astronomer', 'Basketball legend'],
  ),
  'gandhi': const LateGameChoiceFact(
    correct: ['Leader of Indian independence'],
    wrong: ['French emperor', 'Modern physicist', 'Olympic boxing champion'],
  ),
  'obama': const LateGameChoiceFact(
    correct: ['44th U.S. president'],
    wrong: ['Egyptian king', 'Dutch master painter', 'Tennis superstar'],
  ),

  'washington': const LateGameChoiceFact(
    correct: ['First U.S. president', 'Revolutionary general'],
    wrong: ['French emperor', 'Ottoman sultan', 'Victorian novelist'],
  ),
  'lenin': const LateGameChoiceFact(
    correct: ['Revolutionary leader', 'Founder of the Soviet state'],
    wrong: ['Roman dictator', 'British queen', 'Formula 1 champion'],
  ),
  'mao': const LateGameChoiceFact(
    correct: ['Chinese communist leader', 'Chairman of the PRC'],
    wrong: ['Renaissance painter', 'Tennis champion', 'German physicist'],
  ),
  'degaulle': const LateGameChoiceFact(
    correct: ['Leader of Free France', 'French president'],
    wrong: ['Mughal emperor', 'Olympic sprinter', 'Dutch master painter'],
  ),
  'hatshepsut': const LateGameChoiceFact(
    correct: ['Pharaoh of Egypt', 'Ancient ruler'],
    wrong: ['British prime minister', 'Space mathematician', 'Tennis legend'],
  ),
  'elizabeth_i': const LateGameChoiceFact(
    correct: ['Queen of England', 'Tudor monarch'],
    wrong: ['Roman empress', 'Modern chemist', 'Olympic gymnast'],
  ),
  'catherine_great': const LateGameChoiceFact(
    correct: ['Empress of Russia'],
    wrong: [
      'Indian independence leader',
      'Baroque composer',
      'World champion boxer',
    ],
  ),
  'suleiman': const LateGameChoiceFact(
    correct: ['Ottoman sultan'],
    wrong: [
      'American president',
      'Impressionist painter',
      'Figure skating champion',
    ],
  ),
  'alexander_great': const LateGameChoiceFact(
    correct: ['Macedonian king', 'Conqueror of a vast empire'],
    wrong: ['Roman emperor', 'Persian king', 'Athenian statesman'],
  ),
  'genghis_khan': const LateGameChoiceFact(
    correct: ['Founder of the Mongol Empire', 'Great Khan'],
    wrong: ['Chinese emperor', 'Ottoman sultan', 'Viking chieftain'],
  ),
  'augustus': const LateGameChoiceFact(
    correct: ['First Roman emperor'],
    wrong: [
      'Roman general and dictator',
      'Athenian philosopher',
      'Carthaginian general',
    ],
  ),
  'joan_of_arc': const LateGameChoiceFact(
    correct: ['French heroine of the Hundred Years\' War'],
    wrong: ['English queen', 'Roman empress', 'Scottish independence leader'],
  ),
  'mlk_jr': const LateGameChoiceFact(
    correct: ['Civil rights leader', 'Baptist minister and activist'],
    wrong: [
      'US president',
      'South African president',
      'Indian independence leader',
    ],
  ),
  'hitler': const LateGameChoiceFact(
    correct: ['Nazi dictator', 'Chancellor of Germany'],
    wrong: ['Soviet leader', 'Italian fascist dictator', 'Japanese emperor'],
  ),
  'benazir_bhutto': const LateGameChoiceFact(
    correct: ['Prime minister of Pakistan'],
    wrong: [
      'President of India',
      'Prime minister of Israel',
      'President of Bangladesh',
    ],
  ),
  'ashoka': const LateGameChoiceFact(
    correct: ['Mauryan emperor', 'Buddhist convert and patron'],
    wrong: ['Mughal emperor', 'Gupta dynasty ruler', 'Han Chinese emperor'],
  ),
  'saladin': const LateGameChoiceFact(
    correct: ['Sultan of Egypt and Syria', 'Leader against the Crusaders'],
    wrong: ['Ottoman sultan', 'Mongolian khan', 'Byzantine emperor'],
  ),
  'john_f_kennedy': const LateGameChoiceFact(
    correct: ['35th US president'],
    wrong: [
      'US senator from Massachusetts only',
      'Vice president under Eisenhower',
      'Supreme Court chief justice',
    ],
  ),
  'malala': const LateGameChoiceFact(
    correct: ['Education activist', 'Nobel Peace Prize laureate'],
    wrong: [
      'Pakistani prime minister',
      'United Nations secretary-general',
      'World Health Organization director',
    ],
  ),
  'marcus_aurelius': const LateGameChoiceFact(
    correct: ['Roman emperor', 'Stoic philosopher-king'],
    wrong: [
      'Roman general and dictator',
      'Greek philosopher',
      'Byzantine emperor',
    ],
  ),
  'hammurabi': const LateGameChoiceFact(
    correct: ['Babylonian king', 'Lawgiver of ancient Mesopotamia'],
    wrong: ['Egyptian pharaoh', 'Persian emperor', 'Assyrian conqueror'],
  ),
  'qin_shi_huang': const LateGameChoiceFact(
    correct: ['First emperor of unified China'],
    wrong: [
      'Han dynasty founder',
      'Mongol ruler of China',
      'Tang dynasty emperor',
    ],
  ),
  'simon_bolivar': const LateGameChoiceFact(
    correct: ['Liberator of South American nations'],
    wrong: [
      'President of Mexico',
      'Brazilian independence leader',
      'Argentine general and president',
    ],
  ),
  'otto_von_bismarck': const LateGameChoiceFact(
    correct: ['Chancellor who unified Germany', 'Iron Chancellor'],
    wrong: ['Prussian king', 'Austrian emperor', 'German kaiser'],
  ),
  'rosa_parks': const LateGameChoiceFact(
    correct: ['Civil rights icon', 'Symbol of bus boycott resistance'],
    wrong: ['US senator', 'Governor of Alabama', 'Founder of the NAACP'],
  ),
  'theodore_roosevelt': const LateGameChoiceFact(
    correct: ['26th US president', 'Conservation champion'],
    wrong: [
      'US general in World War I',
      'Supreme Court justice',
      'Secretary of state',
    ],
  ),
  'cyrus_great': const LateGameChoiceFact(
    correct: ['Founder of the Persian Empire', 'Achaemenid king'],
    wrong: ['Babylonian king', 'Macedonian conqueror', 'Egyptian pharaoh'],
  ),
  'sun_tzu': const LateGameChoiceFact(
    correct: ['Military strategist', 'Author of The Art of War'],
    wrong: ['Chinese emperor', 'Confucian philosopher', 'Han dynasty general'],
  ),
  'boudicca': const LateGameChoiceFact(
    correct: ['Celtic queen', 'Leader of revolt against Rome'],
    wrong: ['Roman empress', 'Viking chieftain', 'Scottish clan leader'],
  ),
  'chandragupta_maurya': const LateGameChoiceFact(
    correct: ['Founder of the Maurya Empire'],
    wrong: [
      'Mughal dynasty founder',
      'Gupta empire ruler',
      'Buddhist monk-emperor',
    ],
  ),
  'cicero': const LateGameChoiceFact(
    correct: ['Roman senator and orator', 'Defender of the Republic'],
    wrong: ['Roman emperor', 'Greek philosopher', 'Roman general'],
  ),
  'cleisthenes': const LateGameChoiceFact(
    correct: ['Father of Athenian democracy', 'Greek reformer'],
    wrong: ['Spartan king', 'Roman senator', 'Macedonian ruler'],
  ),
  'darius_i': const LateGameChoiceFact(
    correct: ['Persian king', 'Organizer of the Achaemenid Empire'],
    wrong: ['Macedonian conqueror', 'Babylonian ruler', 'Egyptian pharaoh'],
  ),
  'fidel_castro': const LateGameChoiceFact(
    correct: ['Cuban revolutionary leader', 'Ruler of Cuba for decades'],
    wrong: [
      'Venezuelan president',
      'Chilean president',
      'Bolivian revolutionary leader',
    ],
  ),
  'golda_meir': const LateGameChoiceFact(
    correct: ['Prime minister of Israel'],
    wrong: [
      'President of Israel',
      'Prime minister of Egypt',
      'United Nations ambassador only',
    ],
  ),
  'greta_thunberg': const LateGameChoiceFact(
    correct: ['Climate activist', 'Youth movement icon'],
    wrong: [
      'United Nations secretary-general',
      'Greenpeace director',
      'Swedish prime minister',
    ],
  ),
  'han_wudi': const LateGameChoiceFact(
    correct: ['Han emperor who expanded China'],
    wrong: [
      'Founder of the Han dynasty',
      'First emperor of unified China',
      'Tang dynasty emperor',
    ],
  ),
  'hannibal_barca': const LateGameChoiceFact(
    correct: ['Carthaginian general', 'Commander against Rome'],
    wrong: ['Roman consul', 'Macedonian king', 'Persian general'],
  ),
  'henry_viii': const LateGameChoiceFact(
    correct: ['Tudor king of England', 'Founder of the Church of England'],
    wrong: ['Holy Roman Emperor', 'Scottish king', 'French king'],
  ),
  'ho_chi_minh': const LateGameChoiceFact(
    correct: ['Vietnamese revolutionary leader', 'President of North Vietnam'],
    wrong: [
      'Chinese communist leader',
      'Cambodian independence leader',
      'Korean revolutionary',
    ],
  ),
  'joseph_stalin': const LateGameChoiceFact(
    correct: ['Soviet dictator', 'General secretary of the Communist Party'],
    wrong: [
      'Founder of the Soviet Union',
      'Russian tsar',
      'East German leader',
    ],
  ),
  'indira_gandhi': const LateGameChoiceFact(
    correct: ['Prime minister of India'],
    wrong: [
      'First president of India',
      'First female governor-general',
      'President of the Indian National Congress only',
    ],
  ),
  'kim_il_sung': const LateGameChoiceFact(
    correct: ['Founder of North Korea', 'Supreme leader of North Korea'],
    wrong: [
      'South Korean president',
      'Chinese communist leader',
      'Vietnamese independence leader',
    ],
  ),
  'kublai_khan': const LateGameChoiceFact(
    correct: ['Mongol ruler of China', 'Founder of the Yuan dynasty'],
    wrong: [
      'Founder of the Mongol Empire',
      'Ottoman sultan',
      'Chinese Ming emperor',
    ],
  ),
  'mikhail_gorbachev': const LateGameChoiceFact(
    correct: ['Last leader of the Soviet Union'],
    wrong: [
      'First leader of the Soviet Union',
      'Soviet leader who built the Berlin Wall',
      'Russian president after the Soviet collapse',
    ],
  ),
  'napoleon_iii': const LateGameChoiceFact(
    correct: ['Emperor of the French Second Empire'],
    wrong: [
      'First Napoleon\'s brother and general',
      'President of the Third French Republic',
      'King of France after the Revolution',
    ],
  ),
  'otto_great': const LateGameChoiceFact(
    correct: ['First Holy Roman Emperor', 'Medieval German king'],
    wrong: [
      'Frankish king who became the first emperor',
      'Byzantine emperor',
      'Viking king of England',
    ],
  ),
  'pericles': const LateGameChoiceFact(
    correct: ['Athenian statesman', 'Leader of Athens\' golden age'],
    wrong: ['Spartan king', 'Macedonian ruler', 'Roman consul'],
  ),
  'queen_victoria': const LateGameChoiceFact(
    correct: ['British monarch', 'Empress of India'],
    wrong: ['French empress', 'Russian empress', 'Austrian empress'],
  ),
  'ramesses_ii': const LateGameChoiceFact(
    correct: ['Egyptian pharaoh', 'Ramesses the Great'],
    wrong: ['Assyrian king', 'Nubian pharaoh', 'Mesopotamian ruler'],
  ),
  'richard_lionheart': const LateGameChoiceFact(
    correct: ['Crusader king of England', 'Richard I of England'],
    wrong: [
      'Norman conqueror of England',
      'Signing king of the Magna Carta',
      'King who founded the Tudor dynasty',
    ],
  ),
  'ronald_reagan': const LateGameChoiceFact(
    correct: ['40th US president'],
    wrong: [
      'US vice president under Nixon',
      'Governor of New York',
      'Secretary of state under Nixon',
    ],
  ),
  'scipio_africanus': const LateGameChoiceFact(
    correct: ['Roman general who defeated Hannibal'],
    wrong: ['Roman emperor', 'Roman dictator', 'Carthaginian general'],
  ),
  'tokugawa_ieyasu': const LateGameChoiceFact(
    correct: ['Founder of the Tokugawa shogunate', 'Shogun of Japan'],
    wrong: [
      'Japanese emperor',
      'Samurai rebel who opposed the shogunate',
      'Daimyo who opened Japan to the West',
    ],
  ),
  'xi_jinping': const LateGameChoiceFact(
    correct: ['Chinese president and party leader'],
    wrong: [
      'Founder of the People\'s Republic of China',
      'Architect of China\'s economic reforms',
      'Chinese premier during the 2008 Olympics',
    ],
  ),
  'zhang_qian': const LateGameChoiceFact(
    correct: ['Han dynasty envoy', 'Pioneer of the Silk Road'],
    wrong: ['Chinese emperor', 'Mongol explorer', 'Tang dynasty diplomat'],
  ),
  'karl_grosse': const LateGameChoiceFact(
    correct: ['Charlemagne', 'Frankish king and Holy Roman Emperor'],
    wrong: [
      'Viking king of northern Europe',
      'Byzantine emperor',
      'First Holy Roman Emperor of the German nation',
    ],
  ),
  'che_guevara': const LateGameChoiceFact(
    correct: ['Revolutionary icon', 'Guerrilla leader in Latin America'],
    wrong: [
      'President of Cuba',
      'President of Argentina',
      'Leader of the Bolivarian Revolution',
    ],
  ),
  'roosevelt': const LateGameChoiceFact(
    correct: ['32nd US president', 'New Deal architect'],
    wrong: [
      'World War I general',
      'US secretary of state',
      'Supreme Court justice',
    ],
  ),
  'thatcher': const LateGameChoiceFact(
    correct: ['British prime minister', 'Iron Lady'],
    wrong: [
      'British queen',
      'European Commission president',
      'British foreign secretary',
    ],
  ),
  'mansa_musa': const LateGameChoiceFact(
    correct: ['Emperor of Mali', 'Richest ruler of the medieval world'],
    wrong: [
      'Founder of the Songhai Empire',
      'Sultan of Morocco',
      'Pharaoh of ancient Egypt',
    ],
  ),
};
