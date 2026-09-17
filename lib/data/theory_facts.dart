import '../models/late_game_fact.dart';

// Prepared for future late-game quiz types. Not wired into gameplay yet.
final Map<String, LateGameChoiceFact> theoryFacts = {
  'einstein': const LateGameChoiceFact(
    correct: ['Relativity', 'Special relativity'],
    wrong: ['Natural selection', 'Heliocentrism', 'Plate tectonics'],
  ),
  'newton': const LateGameChoiceFact(
    correct: ['Universal gravitation', 'Laws of motion'],
    wrong: ['Uncertainty principle', 'Germ theory', 'Double helix model'],
  ),
  'darwin': const LateGameChoiceFact(
    correct: ['Evolution by natural selection'],
    wrong: ['General relativity', 'Special relativity', 'Heliocentrism'],
  ),
  'galileo': const LateGameChoiceFact(
    correct: ['Heliocentrism'],
    wrong: ['Continental drift', 'Radioactivity', 'Game theory'],
  ),
  'curie': const LateGameChoiceFact(
    correct: ['Radioactivity'],
    wrong: ['Quantum entanglement', 'Natural selection', 'Heliocentrism'],
  ),
  'tesla': const LateGameChoiceFact(
    correct: ['Alternating current systems'],
    wrong: ['Nuclear fission', 'Vaccination theory', 'Natural selection'],
  ),
  'turing': const LateGameChoiceFact(
    correct: ['Turing machine', 'Foundations of computer science'],
    wrong: ['Relativity', 'Double helix model', 'Heliocentrism'],
  ),
  'lovelace': const LateGameChoiceFact(
    correct: ['Early computer programming concepts'],
    wrong: ['Quantum mechanics', 'Natural selection', 'Radioactivity'],
  ),
  'hawking': const LateGameChoiceFact(
    correct: ['Black holes', 'Cosmology'],
    wrong: ['Heliocentrism', 'Periodic table', 'Natural selection'],
  ),
  'franklin': const LateGameChoiceFact(
    correct: ['DNA structure evidence'],
    wrong: ['Relativity', 'Game theory', 'Heliocentrism'],
  ),
  'katherine_johnson': const LateGameChoiceFact(
    correct: ['Orbital trajectory calculations'],
    wrong: ['Nuclear fission', 'Universal gravitation', 'Radioactivity'],
  ),

  'copernicus': const LateGameChoiceFact(
    correct: ['Heliocentrism'],
    wrong: ['Germ theory', 'Natural selection', 'Electromagnetic induction'],
  ),
  'kepler': const LateGameChoiceFact(
    correct: ['Laws of planetary motion'],
    wrong: ['Radioactivity', 'Plate tectonics', 'Quantum entanglement'],
  ),
  'pasteur': const LateGameChoiceFact(
    correct: ['Germ theory', 'Pasteurization'],
    wrong: ['Heliocentrism', 'General relativity', 'Continental drift'],
  ),
  'faraday': const LateGameChoiceFact(
    correct: ['Electromagnetic induction', 'Electromagnetism'],
    wrong: ['Natural selection', 'Double helix model', 'Cosmology'],
  ),
  'ibn_sina': const LateGameChoiceFact(
    correct: ['Classical medicine', 'Medical philosophy'],
    wrong: ['Special relativity', 'Heliocentrism', 'Nuclear fission'],
  ),
  'al_khwarizmi': const LateGameChoiceFact(
    correct: ['Algebra', 'Algorithms'],
    wrong: ['Radioactivity', 'Natural selection', 'Quantum mechanics'],
  ),
  'tu_youyou': const LateGameChoiceFact(
    correct: ['Artemisinin', 'Antimalarial therapy'],
    wrong: ['Universal gravitation', 'Heliocentrism', 'Plate tectonics'],
  ),
  'chien_shiung_wu': const LateGameChoiceFact(
    correct: ['Parity violation', 'Beta decay experiments'],
    wrong: ['Periodic table', 'Natural selection', 'Turing machine'],
  ),
  'aristotle': const LateGameChoiceFact(
    correct: ['Aristotelian logic', 'Natural philosophy'],
    wrong: ['Heliocentrism', 'Natural selection', 'Germ theory'],
  ),
  'alhazen': const LateGameChoiceFact(
    correct: ['Optics', 'Scientific method'],
    wrong: ['Algebra', 'Universal gravitation', 'Heliocentrism'],
  ),
  'averroes': const LateGameChoiceFact(
    correct: ['Aristotelian commentaries', 'Medical philosophy'],
    wrong: ['Heliocentrism', 'Radioactivity', 'Natural selection'],
  ),
  'blaise_pascal': const LateGameChoiceFact(
    correct: ['Probability theory', 'Pascal\'s law of fluid pressure'],
    wrong: ['Heliocentrism', 'Natural selection', 'Electromagnetic induction'],
  ),
  'bill_gates': const LateGameChoiceFact(
    correct: ['Personal computer software', 'Microsoft Windows'],
    wrong: ['World Wide Web', 'Natural selection', 'Quantum mechanics'],
  ),
  'carl_friedrich_gauss': const LateGameChoiceFact(
    correct: ['Gaussian mathematics', 'Number theory'],
    wrong: ['Radioactivity', 'Natural selection', 'Heliocentrism'],
  ),
  'emmy_noether': const LateGameChoiceFact(
    correct: ['Noether\'s theorem', 'Abstract algebra'],
    wrong: ['Radioactivity', 'Heliocentrism', 'Double helix model'],
  ),
  'erwin_schrodinger': const LateGameChoiceFact(
    correct: ['Wave mechanics', 'Schrödinger equation'],
    wrong: ['Heliocentrism', 'Natural selection', 'Radioactivity'],
  ),
  'fibonacci': const LateGameChoiceFact(
    correct: ['Fibonacci sequence', 'Hindu-Arabic numeral spread in Europe'],
    wrong: ['Heliocentrism', 'Natural selection', 'Electromagnetic induction'],
  ),
  'grace_hopper': const LateGameChoiceFact(
    correct: ['Computer programming languages', 'COBOL'],
    wrong: ['Radioactivity', 'Heliocentrism', 'Natural selection'],
  ),
  'hypatia': const LateGameChoiceFact(
    correct: ['Neoplatonic philosophy', 'Mathematics education'],
    wrong: ['Natural selection', 'Heliocentrism', 'Radioactivity'],
  ),
  'james_watson': const LateGameChoiceFact(
    correct: ['DNA double helix structure'],
    wrong: ['Natural selection', 'Heliocentrism', 'Electromagnetic induction'],
  ),
  'james_watt': const LateGameChoiceFact(
    correct: ['Steam engine improvements', 'Industrial thermodynamics'],
    wrong: ['Heliocentrism', 'Natural selection', 'Radioactivity'],
  ),
  'jeff_bezos': const LateGameChoiceFact(
    correct: ['E-commerce revolution', 'Cloud computing with AWS'],
    wrong: ['Social networking', 'Natural selection', 'Quantum mechanics'],
  ),
  'john_von_neumann': const LateGameChoiceFact(
    correct: ['Game theory', 'Von Neumann computer architecture'],
    wrong: ['Natural selection', 'Heliocentrism', 'Radioactivity'],
  ),
  'max_planck': const LateGameChoiceFact(
    correct: ['Quantum theory', 'Energy quanta'],
    wrong: ['Natural selection', 'Electromagnetic induction', 'Heliocentrism'],
  ),
  'niels_bohr': const LateGameChoiceFact(
    correct: ['Bohr atomic model', 'Quantum mechanics'],
    wrong: ['Heliocentrism', 'Natural selection', 'Germ theory'],
  ),
  'richard_feynman': const LateGameChoiceFact(
    correct: ['Quantum electrodynamics', 'Feynman diagrams'],
    wrong: ['Natural selection', 'Heliocentrism', 'Germ theory'],
  ),
  'sigmund_freud': const LateGameChoiceFact(
    correct: ['Psychoanalysis', 'Unconscious mind theory'],
    wrong: ['Natural selection', 'Heliocentrism', 'Electromagnetic induction'],
  ),
  'tim_berners_lee': const LateGameChoiceFact(
    correct: ['World Wide Web'],
    wrong: ['Quantum mechanics', 'Natural selection', 'Heliocentrism'],
  ),
  'tycho_brahe': const LateGameChoiceFact(
    correct: ['Precision astronomical observations'],
    wrong: ['Heliocentrism', 'Natural selection', 'Germ theory'],
  ),
  'werner_heisenberg': const LateGameChoiceFact(
    correct: ['Uncertainty principle', 'Matrix mechanics'],
    wrong: ['Natural selection', 'Heliocentrism', 'Radioactivity'],
  ),
  'elon_musk': const LateGameChoiceFact(
    correct: ['Electric vehicle innovation', 'Private space launch'],
    wrong: ['Social networking', 'Natural selection', 'World Wide Web'],
  ),
  'mark_zuckerberg': const LateGameChoiceFact(
    correct: ['Social networking', 'Facebook platform'],
    wrong: ['E-commerce revolution', 'Natural selection', 'World Wide Web'],
  ),
  'steve_jobs': const LateGameChoiceFact(
    correct: ['Personal computer revolution', 'Smartphone era'],
    wrong: ['Social networking', 'Natural selection', 'World Wide Web'],
  ),
  'alexander_fleming': const LateGameChoiceFact(
    correct: ['Penicillin'],
    wrong: ['Natural selection', 'Heliocentrism', 'Radioactivity'],
  ),
  'antoine_lavoisier': const LateGameChoiceFact(
    correct: ['Oxygen theory of combustion', 'Conservation of mass'],
    wrong: ['Natural selection', 'Heliocentrism', 'Electromagnetic induction'],
  ),
  'hedy_lamarr': const LateGameChoiceFact(
    correct: ['Frequency-hopping communication', 'Spread-spectrum concepts'],
    wrong: ['Natural selection', 'Heliocentrism', 'General relativity'],
  ),
  'plato': const LateGameChoiceFact(
    correct: ['Theory of Forms', 'Platonic idealism'],
    wrong: ['Social contract theory', 'Taoist non-action', 'Psychoanalysis'],
  ),
  'socrates': const LateGameChoiceFact(
    correct: ['Socratic method', 'Dialectical questioning'],
    wrong: ['Theory of Forms', 'Natural selection', 'Social contract theory'],
  ),
  'confucius': const LateGameChoiceFact(
    correct: ['Confucian ethics', 'Moral governance'],
    wrong: ['Legalism', 'Heliocentrism', 'Quantum mechanics'],
  ),
  'laozi': const LateGameChoiceFact(
    correct: ['Taoism', 'Wu wei'],
    wrong: [
      'Confucian ethics',
      'Social contract theory',
      'Universal gravitation',
    ],
  ),
  'rene_descartes': const LateGameChoiceFact(
    correct: ['Cartesian dualism', 'Analytic geometry'],
    wrong: ['Natural selection', 'Confucian ethics', 'Quantum theory'],
  ),
  'john_locke': const LateGameChoiceFact(
    correct: ['Liberalism', 'Natural rights theory'],
    wrong: ['Theory of Forms', 'Taoism', 'Psychoanalysis'],
  ),
  'jean_jacques_rousseau': const LateGameChoiceFact(
    correct: ['Social contract theory', 'Popular sovereignty'],
    wrong: ['Utilitarianism', 'Natural selection', 'Heliocentrism'],
  ),
  'immanuel_kant': const LateGameChoiceFact(
    correct: ['Categorical imperative', 'Transcendental idealism'],
    wrong: ['Theory of Forms', 'Psychoanalysis', 'Electromagnetic induction'],
  ),
  'thomas_aquinas': const LateGameChoiceFact(
    correct: ['Scholasticism', 'Natural theology'],
    wrong: [
      'Social contract theory',
      'Heliocentrism',
      'Evolution by natural selection',
    ],
  ),
  'simone_de_beauvoir': const LateGameChoiceFact(
    correct: ['Existential feminism', 'The ethics of ambiguity'],
    wrong: ['Psychoanalysis', 'Logical positivism', 'Heliocentrism'],
  ),
  'marco_polo': const LateGameChoiceFact(
    correct: ['Overland route to China', 'Description of the Far East'],
    wrong: [
      'Circumnavigation of the globe',
      'Sea route to India',
      'Discovery of the Americas',
    ],
  ),
  'columbus': const LateGameChoiceFact(
    correct: ['Discovery of the Americas', 'Transatlantic exploration'],
    wrong: [
      'First circumnavigation of the globe',
      'Sea route to Asia around Africa',
      'Mapping of the Pacific Ocean',
    ],
  ),
  'magellan': const LateGameChoiceFact(
    correct: ['First circumnavigation of the Earth'],
    wrong: [
      'Discovery of the Americas',
      'Sea route to India around Africa',
      'Overland route to China',
    ],
  ),
  'james_cook': const LateGameChoiceFact(
    correct: [
      'Pacific Ocean mapping',
      'First European contact with eastern Australia',
    ],
    wrong: [
      'Discovery of the Americas',
      'First circumnavigation of the globe',
      'Overland route to China and the Far East',
    ],
  ),
};
