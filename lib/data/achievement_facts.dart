import '../models/late_game_fact.dart';

// Prepared for future late-game quiz types. Not wired into gameplay yet.
final Map<String, LateGameChoiceFact> achievementFacts = {
  'owens': const LateGameChoiceFact(
    correct: ['Four gold medals at the 1936 Olympics'],
    wrong: [
      'The all-time Grand Slam singles record',
      'Seven straight Tour de France victories',
      'The first perfect 10 in Olympic gymnastics',
    ],
  ),
  'ali': const LateGameChoiceFact(
    correct: ['Legendary heavyweight boxing champion'],
    wrong: [
      'World record holder in the 100 meters',
      'Chicago Bulls MVP and scoring icon',
      'Multiple-time Wimbledon singles champion',
    ],
  ),
  'pele': const LateGameChoiceFact(
    correct: ['One of football\'s greatest-ever players'],
    wrong: [
      'The first person to walk on the Moon',
      'A record-setting champion in gymnastics',
      'A dominant multiple-time Formula 1 champion',
    ],
  ),
  'jordan': const LateGameChoiceFact(
    correct: ['Basketball legend of the NBA'],
    wrong: [
      'Four gold medals at the 1936 Olympics',
      'A repeated champion of the Tour de France',
      'The most decorated Olympic swimmer ever',
    ],
  ),
  'serena': const LateGameChoiceFact(
    correct: ['One of tennis history\'s greatest champions'],
    wrong: [
      'An Olympic icon in artistic gymnastics',
      'A world title holder in heavyweight boxing',
      'A pioneer of elite ski jumping',
    ],
  ),
  'bolt': const LateGameChoiceFact(
    correct: ['World records in the 100 and 200 meters'],
    wrong: [
      'A string of titles in figure skating',
      'Multiple Wimbledon singles championships',
      'Several heavyweight boxing world titles',
    ],
  ),
  'messi': const LateGameChoiceFact(
    correct: ['One of football\'s greatest modern careers'],
    wrong: [
      'A defining legend of the NBA',
      'The benchmark for sprint world records',
      'A repeated winner of the Tour de France',
    ],
  ),
  'ronaldo': const LateGameChoiceFact(
    correct: ['One of football history\'s most prolific stars'],
    wrong: [
      'A dominant Olympic swimming champion',
      'A multiple-time Formula 1 world champion',
      'A grandmaster who dominated world chess',
    ],
  ),
  'federer': const LateGameChoiceFact(
    correct: ['One of the greatest players in tennis history'],
    wrong: [
      'The face of modern 100-meter sprinting',
      'A multiple Olympic champion in boxing',
      'A legendary football star from Argentina',
    ],
  ),
  'biles': const LateGameChoiceFact(
    correct: ['Extraordinary achievements in artistic gymnastics'],
    wrong: [
      'The modern record holder at Wimbledon',
      'A pioneering woman in Formula 1 history',
      'A swimmer with world records across many events',
    ],
  ),
  'comaneci': const LateGameChoiceFact(
    correct: ['The first perfect 10 in Olympic gymnastics'],
    wrong: [
      'Four gold medals at the 1936 Olympics',
      'Long-standing world records in sprinting',
      'A run of major singles titles in tennis',
    ],
  ),

  'phelps': const LateGameChoiceFact(
    correct: ['Most decorated Olympian in history'],
    wrong: [
      'Seven Formula 1 world titles',
      'The first perfect 10 in Olympic gymnastics',
      'World records in the 100 and 200 meters',
    ],
  ),
  'schumacher': const LateGameChoiceFact(
    correct: ['Seven Formula 1 world championships'],
    wrong: [
      'A record number of Olympic swimming medals',
      'One hundred international cricket centuries',
      'A barefoot Olympic marathon victory',
    ],
  ),
  'senna': const LateGameChoiceFact(
    correct: ['Three Formula 1 world championships'],
    wrong: [
      'A record haul of Grand Slam singles titles',
      'The all-time medal record in Olympic swimming',
      "One of football's greatest-ever careers",
    ],
  ),
  'maradona': const LateGameChoiceFact(
    correct: ['Leading Argentina to the 1986 World Cup'],
    wrong: [
      'Seven world titles in Formula 1',
      'Four gold medals at the 1936 Olympics',
      'Olympic dominance in figure skating',
    ],
  ),
  'marta': const LateGameChoiceFact(
    correct: ["One of the greatest careers in women's football"],
    wrong: [
      'Olympic gold in figure skating',
      'The most Olympic medals in swimming history',
      'A famous barefoot marathon triumph',
    ],
  ),
  'yuna_kim': const LateGameChoiceFact(
    correct: ['Olympic gold in figure skating'],
    wrong: [
      'A record number of football World Cup goals',
      'One hundred international cricket centuries',
      'A string of Formula 1 world titles',
    ],
  ),
  'tendulkar': const LateGameChoiceFact(
    correct: ['One hundred international cricket centuries'],
    wrong: [
      'A historic Olympic marathon double',
      'The modern benchmark in figure skating',
      'A legendary run of heavyweight boxing titles',
    ],
  ),
  'abebe_bikila': const LateGameChoiceFact(
    correct: [
      'Barefoot Olympic marathon victory',
      'Two Olympic marathon golds',
    ],
    wrong: [
      'A record number of Grand Slam titles in tennis',
      'Seven Formula 1 world championships',
      'The all-time Olympic medal record in swimming',
    ],
  ),
  'bruce_lee': const LateGameChoiceFact(
    correct: ['Martial arts mastery and global action film stardom'],
    wrong: [
      'World heavyweight boxing champion',
      'Olympic gold in judo',
      'Tour de France champion',
    ],
  ),
  'amelia_earhart': const LateGameChoiceFact(
    correct: ['First woman to fly solo across the Atlantic'],
    wrong: [
      'First woman in space',
      'First woman to break the sound barrier',
      'First woman to complete a solo round-the-world flight',
    ],
  ),
  'spartacus': const LateGameChoiceFact(
    correct: ['Leading the largest slave revolt against Rome'],
    wrong: [
      'Winning the Roman gladiatorial championship',
      'Commanding Carthage\'s armies against Rome',
      'Leading the Celtic revolt in Britain',
    ],
  ),
  'tiger_woods': const LateGameChoiceFact(
    correct: [
      'Multiple major golf championships',
      'Transforming professional golf',
    ],
    wrong: [
      'Record Grand Slam titles in tennis',
      'Seven Formula 1 world titles',
      'Olympic swimming dominance',
    ],
  ),
  'djokovic': const LateGameChoiceFact(
    correct: ['Most Grand Slam singles titles in men\'s tennis history'],
    wrong: [
      'Most French Open titles in tennis history',
      'The longest consecutive winning streak in tennis',
      'Olympic gold in both singles and doubles tennis',
    ],
  ),
  'kobe': const LateGameChoiceFact(
    correct: ['Five NBA championships with the Los Angeles Lakers'],
    wrong: [
      'Six NBA championships with the Chicago Bulls',
      'Four NBA championships with the Boston Celtics',
      'Olympic gold medals across three Games',
    ],
  ),
  'lebron': const LateGameChoiceFact(
    correct: ['One of the greatest careers in basketball history'],
    wrong: [
      'Dominating football with World Cup wins',
      'Rewriting Olympic sprinting records',
      'Collecting Grand Slam titles across two decades',
    ],
  ),
  'mike_tyson': const LateGameChoiceFact(
    correct: ['Youngest heavyweight boxing world champion'],
    wrong: [
      'Olympic gold in boxing across three Games',
      'Undefeated world title reign spanning fifteen years',
      'Heavyweight champion who became a martial arts star',
    ],
  ),
  'nadal': const LateGameChoiceFact(
    correct: [
      'Record French Open titles',
      'Grand Slam success across all surfaces',
    ],
    wrong: [
      'Most Wimbledon titles in tennis history',
      'First player to win a calendar Grand Slam',
      'Most consecutive weeks as world number one',
    ],
  ),
  'neymar': const LateGameChoiceFact(
    correct: [
      'One of Brazil\'s most gifted footballers',
      'Champions League winner',
    ],
    wrong: [
      'Leading Brazil to the World Cup as top scorer',
      'Winning the Ballon d\'Or multiple times',
      'Becoming the highest scorer in football history',
    ],
  ),
  'ronaldinho': const LateGameChoiceFact(
    correct: [
      'Ballon d\'Or winner and Barcelona icon',
      'Legendary flair and creativity',
    ],
    wrong: [
      'Leading Brazil to the World Cup as captain',
      'Most goals in Champions League history',
      'Winning multiple Serie A titles in Italy',
    ],
  ),
  'ronaldo_nazario': const LateGameChoiceFact(
    correct: [
      'Two World Cup wins with Brazil',
      'Legendary goal-scoring record',
    ],
    wrong: [
      'Most Ballon d\'Or awards in history',
      'Most goals in Champions League history',
      'Leading Portugal to international glory',
    ],
  ),
  'zidane': const LateGameChoiceFact(
    correct: [
      'World Cup and Euro winner',
      'Ballon d\'Or and Champions League glory',
    ],
    wrong: [
      'Most goals ever scored in Ligue 1',
      'Winning three consecutive Ballon d\'Or awards',
      'Leading Algeria to the Africa Cup of Nations',
    ],
  ),
};
