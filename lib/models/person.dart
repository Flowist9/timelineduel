import 'category.dart';
import 'person_rarity.dart';
import '../data/person_asset_overrides.dart';

class Person {
  final String id;
  final String name;
  final int birthYear;
  final DateTime? birthDate;
  final int? deathYear;
  final Category category;

  // Kurzbeschreibung / bekannt fuer
  final String hint;

  // Optional ueberschreibbare Bildpfade
  final String? imageAsset;
  final String? portraitImageAsset;
  final String? vsImageAsset;

  final double? birthLat;
  final double? birthLng;
  final String? birthPlaceLabel;
  final String birthCountry;
  final PersonRarity rarity;

  const Person({
    required this.id,
    required this.name,
    required this.birthYear,
    this.birthDate,
    required this.deathYear,
    required this.category,
    required this.hint,
    this.imageAsset,
    this.portraitImageAsset,
    this.vsImageAsset,
    this.birthLat,
    this.birthLng,
    this.birthPlaceLabel,
    required this.birthCountry,
    required this.rarity,
  });

  String get portraitAsset =>
      portraitImageAsset ??
      imageAsset ??
      portraitAssetOverrides[id] ??
      'assets/persons/portrait/$id.jpg';

  String get vsAsset =>
      vsImageAsset ??
      imageAsset ??
      vsAssetOverrides[id] ??
      'assets/persons/vs/$id.jpg';

  int get rarityWeight => rarity.weight;
}
