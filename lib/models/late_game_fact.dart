class LateGameChoiceFact {
  final List<String> correct;
  final List<String> wrong;

  const LateGameChoiceFact({required this.correct, required this.wrong});
}

class PersonImageClue {
  final String assetPath;
  final String description;

  const PersonImageClue({required this.assetPath, required this.description});
}
