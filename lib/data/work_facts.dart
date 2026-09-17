import '../models/late_game_fact.dart';

// Prepared for future late-game quiz types. Not wired into gameplay yet.
final Map<String, LateGameChoiceFact> workFacts = {
  'leonardo': const LateGameChoiceFact(
    correct: ['Mona Lisa', 'The Last Supper'],
    wrong: ['The Magic Flute', 'Hamlet', 'Starry Night'],
  ),
  'shakespeare': const LateGameChoiceFact(
    correct: ['Hamlet', 'Romeo and Juliet'],
    wrong: ['The Iliad', 'Mona Lisa', 'The Magic Flute'],
  ),
  'mozart': const LateGameChoiceFact(
    correct: ['The Magic Flute', 'Eine kleine Nachtmusik'],
    wrong: ['Guernica', 'War and Peace', 'The Last Supper'],
  ),
  'vangogh': const LateGameChoiceFact(
    correct: ['Starry Night', 'Sunflowers'],
    wrong: ['David', 'Faust', 'The Royal Game'],
  ),
  'kahlo': const LateGameChoiceFact(
    correct: ['The Two Fridas', 'Self-Portrait with Thorn Necklace'],
    wrong: ['The Birth of Venus', 'Nineteen Eighty-Four', 'Eroica Symphony'],
  ),
  'beethoven': const LateGameChoiceFact(
    correct: ['Ninth Symphony', 'Fur Elise'],
    wrong: ['The School of Athens', 'Don Quixote', 'The Birth of Tragedy'],
  ),
  'picasso': const LateGameChoiceFact(
    correct: ['Guernica', 'Les Demoiselles d\'Avignon'],
    wrong: ['Starry Night', 'The Odyssey', 'The Magic Flute'],
  ),
  'rembrandt': const LateGameChoiceFact(
    correct: ['The Night Watch', 'The Jewish Bride'],
    wrong: ['David', 'The Metamorphosis', 'Das Kapital'],
  ),
  'austen': const LateGameChoiceFact(
    correct: ['Pride and Prejudice', 'Emma'],
    wrong: ['The Physicists', 'The School of Athens', 'Thus Spoke Zarathustra'],
  ),
  'hemingway': const LateGameChoiceFact(
    correct: ['The Old Man and the Sea', 'A Farewell to Arms'],
    wrong: ['Guernica', 'Eroica Symphony', 'The Judgement of Paris'],
  ),
  'michelangelo': const LateGameChoiceFact(
    correct: ['David', 'The Creation of Adam'],
    wrong: ['Hamlet', 'Starry Night', 'Don Giovanni'],
  ),

  'monet': const LateGameChoiceFact(
    correct: ['Impression, Sunrise', 'Water Lilies'],
    wrong: ['Guernica', 'The Divine Comedy', 'The Persistence of Memory'],
  ),
  'dali': const LateGameChoiceFact(
    correct: ['The Persistence of Memory', 'The Elephants'],
    wrong: ['Water Lilies', 'Oliver Twist', 'Marilyn Diptych'],
  ),
  'dickens': const LateGameChoiceFact(
    correct: ['Oliver Twist', 'A Christmas Carol'],
    wrong: [
      'The Divine Comedy',
      "Campbell's Soup Cans",
      'The Creation of Adam',
    ],
  ),
  'warhol': const LateGameChoiceFact(
    correct: ["Campbell's Soup Cans", 'Marilyn Diptych'],
    wrong: ['The Tale of Genji', 'Impression, Sunrise', 'Great Expectations'],
  ),
  'dante': const LateGameChoiceFact(
    correct: ['The Divine Comedy'],
    wrong: ['The Odyssey', 'Gitanjali', 'The Creation of Adam'],
  ),
  'murasaki': const LateGameChoiceFact(
    correct: ['The Tale of Genji'],
    wrong: ['Hamlet', 'Gitanjali', 'The Iliad'],
  ),
  'tagore': const LateGameChoiceFact(
    correct: ['Gitanjali'],
    wrong: ['The Tale of Genji', 'A Christmas Carol', 'Water Lilies'],
  ),
  'homer': const LateGameChoiceFact(
    correct: ['The Iliad', 'The Odyssey'],
    wrong: ['The Aeneid', 'The Divine Comedy', 'Hamlet'],
  ),
  'confucius': const LateGameChoiceFact(
    correct: ['The Analects'],
    wrong: ['The Tao Te Ching', 'The Art of War', 'The Tale of Genji'],
  ),
  'elvis_presley': const LateGameChoiceFact(
    correct: ['Hound Dog', 'Jailhouse Rock'],
    wrong: ['Thriller', 'Bohemian Rhapsody', 'Imagine'],
  ),
  'frederic_chopin': const LateGameChoiceFact(
    correct: ['Nocturnes', 'Piano études and preludes'],
    wrong: ['Swan Lake', 'The Nutcracker', 'Ninth Symphony'],
  ),
  'friedrich_schiller': const LateGameChoiceFact(
    correct: ['William Tell', 'Ode to Joy (text)'],
    wrong: ['Faust', 'The Magic Flute', 'The Divine Comedy'],
  ),
  'fyodor_dostoevsky': const LateGameChoiceFact(
    correct: ['Crime and Punishment', 'The Brothers Karamazov'],
    wrong: ['War and Peace', 'Anna Karenina', 'Dead Souls'],
  ),
  'gabriel_garcia_marquez': const LateGameChoiceFact(
    correct: ['One Hundred Years of Solitude', 'Love in the Time of Cholera'],
    wrong: ['The House of the Spirits', 'Ficciones', 'Pedro Páramo'],
  ),
  'george_orwell': const LateGameChoiceFact(
    correct: ['Nineteen Eighty-Four', 'Animal Farm'],
    wrong: ['Brave New World', 'Lord of the Flies', 'The Trial'],
  ),
  'goethe': const LateGameChoiceFact(
    correct: ['Faust', 'The Sorrows of Young Werther'],
    wrong: ['William Tell', 'The Tin Drum', 'The Magic Mountain'],
  ),
  'hayao_miyazaki': const LateGameChoiceFact(
    correct: ['Spirited Away', 'My Neighbor Totoro'],
    wrong: ['Akira', 'Ghost in the Shell', 'Princess Mononoke only'],
  ),
  'hedy_lamarr': const LateGameChoiceFact(
    correct: ['Samson and Delilah', 'Frequency-hopping patent'],
    wrong: ['Casablanca', 'Some Like It Hot', 'All About Eve'],
  ),
  'immanuel_kant': const LateGameChoiceFact(
    correct: [
      'Critique of Pure Reason',
      'Groundwork of the Metaphysics of Morals',
    ],
    wrong: [
      'The Social Contract',
      'Discourse on Method',
      'Thus Spoke Zarathustra',
    ],
  ),
  'jean_jacques_rousseau': const LateGameChoiceFact(
    correct: ['The Social Contract', 'Emile'],
    wrong: ['Candide', 'Critique of Pure Reason', 'The Prince'],
  ),
  'jk_rowling': const LateGameChoiceFact(
    correct: ['Harry Potter series'],
    wrong: [
      'The Hunger Games',
      'His Dark Materials',
      'The Chronicles of Narnia',
    ],
  ),
  'johann_sebastian_bach': const LateGameChoiceFact(
    correct: ['Brandenburg Concertos', 'Mass in B minor'],
    wrong: ['The Magic Flute', 'Ninth Symphony', 'Water Music'],
  ),
  'john_locke': const LateGameChoiceFact(
    correct: [
      'Two Treatises of Government',
      'An Essay Concerning Human Understanding',
    ],
    wrong: [
      'The Social Contract',
      'Critique of Pure Reason',
      'Discourse on Method',
    ],
  ),
  'laozi': const LateGameChoiceFact(
    correct: ['Tao Te Ching'],
    wrong: ['The Analects', 'The Art of War', 'Book of Changes'],
  ),
  'leo_tolstoy': const LateGameChoiceFact(
    correct: ['War and Peace', 'Anna Karenina'],
    wrong: ['Crime and Punishment', 'The Brothers Karamazov', 'Dead Souls'],
  ),
  'marilyn_monroe': const LateGameChoiceFact(
    correct: ['Some Like It Hot', 'Gentlemen Prefer Blondes'],
    wrong: ['Breakfast at Tiffany\'s', 'Roman Holiday', 'All About Eve'],
  ),
  'michael_jackson': const LateGameChoiceFact(
    correct: ['Thriller', 'Billie Jean'],
    wrong: ['Purple Rain', 'Hound Dog', 'Bohemian Rhapsody'],
  ),
  'nicole_kidman': const LateGameChoiceFact(
    correct: ['Moulin Rouge!', 'The Hours'],
    wrong: ['Pretty Woman', 'Titanic', 'Erin Brockovich'],
  ),
  'pablo_neruda': const LateGameChoiceFact(
    correct: ['Twenty Love Poems and a Song of Despair', 'Canto General'],
    wrong: [
      'One Hundred Years of Solitude',
      'In Cold Blood',
      'The House of the Spirits',
    ],
  ),
  'plato': const LateGameChoiceFact(
    correct: ['The Republic', 'Symposium'],
    wrong: ['The Nicomachean Ethics', 'The Analects', 'The Social Contract'],
  ),
  'rene_descartes': const LateGameChoiceFact(
    correct: ['Discourse on Method', 'Meditations on First Philosophy'],
    wrong: ['Critique of Pure Reason', 'The Social Contract', 'Leviathan'],
  ),
  'simone_de_beauvoir': const LateGameChoiceFact(
    correct: ['The Second Sex', 'The Mandarins'],
    wrong: [
      'The Feminine Mystique',
      'A Vindication of the Rights of Woman',
      'The Bell Jar',
    ],
  ),
  'socrates': const LateGameChoiceFact(
    correct: ['Socratic dialogues (via Plato)', 'Apology'],
    wrong: ['The Republic', 'The Nicomachean Ethics', 'The Social Contract'],
  ),
  'stanley_kubrick': const LateGameChoiceFact(
    correct: ['2001: A Space Odyssey', 'A Clockwork Orange'],
    wrong: ['Apocalypse Now', 'Blade Runner', 'The Godfather'],
  ),
  'tchaikovsky': const LateGameChoiceFact(
    correct: ['Swan Lake', 'The Nutcracker'],
    wrong: ['The Four Seasons', 'Water Music', 'Peer Gynt'],
  ),
  'thomas_aquinas': const LateGameChoiceFact(
    correct: ['Summa Theologica'],
    wrong: ['The City of God', 'Confessions', 'The Divine Comedy'],
  ),
  'virginia_woolf': const LateGameChoiceFact(
    correct: ['Mrs Dalloway', 'To the Lighthouse'],
    wrong: ['Middlemarch', 'Jane Eyre', 'The Hours'],
  ),
  'voltaire': const LateGameChoiceFact(
    correct: ['Candide', 'Philosophical Letters'],
    wrong: [
      'The Social Contract',
      'Discourse on Method',
      'The Spirit of the Laws',
    ],
  ),
  'walt_disney': const LateGameChoiceFact(
    correct: ['Snow White and the Seven Dwarfs', 'Fantasia'],
    wrong: ['Bambi only', 'Dumbo only', 'Toy Story'],
  ),
  'chris_hemsworth': const LateGameChoiceFact(
    correct: ['Thor (MCU films)', 'Extraction'],
    wrong: ['The Dark Knight', 'Logan', 'Avengers: Age of Ultron as Iron Man'],
  ),
  'hugh_jackman': const LateGameChoiceFact(
    correct: ['Logan', 'The Greatest Showman'],
    wrong: ['Thor', 'Iron Man', 'Deadpool'],
  ),
};
