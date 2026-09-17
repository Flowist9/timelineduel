import '../models/category.dart';
import '../models/person.dart';
import '../models/person_rarity.dart';
import 'legendary_abilities.dart';

const int battleDeckSize = 4;
const int battleDraftChoicesPerSlot = 4;

const List<BattleDraftSlotType> defaultBattleDraftSlots = [
  BattleDraftSlotType.politician,
  BattleDraftSlotType.scientist,
  BattleDraftSlotType.artist,
  BattleDraftSlotType.athlete,
];

enum BattlePhase { locked, hub, draft, roundIntro, chooseCard, result, summary }

enum BattleRoundType { closerToYear, closerToLocation, longerLife, bornEarlier }

enum BattleRoundInputMode { cardSelection, yearLockGuess, mapGuess }

enum BattleDraftSlotType { politician, scientist, artist, athlete, wildcard }

extension BattleDraftSlotTypeX on BattleDraftSlotType {
  String get label => switch (this) {
    BattleDraftSlotType.politician => 'Politics',
    BattleDraftSlotType.scientist => 'Science',
    BattleDraftSlotType.artist => 'Art',
    BattleDraftSlotType.athlete => 'Sports',
    BattleDraftSlotType.wildcard => 'Wildcard',
  };

  bool allows(Person person) {
    return switch (this) {
      BattleDraftSlotType.politician => person.category == Category.politician,
      BattleDraftSlotType.scientist => person.category == Category.scientist,
      BattleDraftSlotType.artist => person.category == Category.artist,
      BattleDraftSlotType.athlete => person.category == Category.athlete,
      BattleDraftSlotType.wildcard => true,
    };
  }
}

class BattleCardViewModel {
  final String id;
  final String name;
  final Category category;
  final String portraitAsset;
  final String hintTag;
  final PersonRarity rarity;

  const BattleCardViewModel({
    required this.id,
    required this.name,
    required this.category,
    required this.portraitAsset,
    required this.hintTag,
    required this.rarity,
  });

  factory BattleCardViewModel.fromPerson(Person person) {
    return BattleCardViewModel(
      id: person.id,
      name: person.name,
      category: person.category,
      portraitAsset: person.portraitAsset,
      hintTag: battleTagForPersonId(person.id, person.hint),
      rarity: person.rarity,
    );
  }
}

class BattleDraftSlot {
  final BattleDraftSlotType type;
  final List<Person> candidates;
  final Person? selected;

  const BattleDraftSlot({
    required this.type,
    required this.candidates,
    this.selected,
  });

  bool get isComplete => selected != null;

  BattleDraftSlot copyWith({
    List<Person>? candidates,
    Person? selected,
    bool clearSelected = false,
  }) {
    return BattleDraftSlot(
      type: type,
      candidates: candidates ?? this.candidates,
      selected: clearSelected ? null : (selected ?? this.selected),
    );
  }
}

class BattleDraftState {
  final List<BattleDraftSlot> slots;

  const BattleDraftState({required this.slots});

  bool get isReady =>
      slots.length == battleDeckSize && slots.every((slot) => slot.isComplete);

  List<Person> get selectedCards =>
      slots.map((slot) => slot.selected).whereType<Person>().toList();
}
