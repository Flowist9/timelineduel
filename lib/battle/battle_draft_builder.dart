import 'dart:math';

import '../logic/game_session.dart';
import '../models/person.dart';
import 'battle_models.dart';

class BattleDraftBuildResult {
  final BattleDraftState? state;
  final List<BattleDraftSlotType> missingSlots;

  const BattleDraftBuildResult({
    required this.state,
    this.missingSlots = const [],
  });

  bool get canStartDraft => state != null;
}

class BattleDraftBuilder {
  final Random _random;

  BattleDraftBuilder({Random? random}) : _random = random ?? Random();

  BattleDraftBuildResult buildForSession(GameSession session) {
    final owned = session.unlockedPersons;
    final missingSlots = <BattleDraftSlotType>[];
    final slots = <BattleDraftSlot>[];

    for (final slotType in defaultBattleDraftSlots) {
      final pool = owned.where(slotType.allows).toList();
      if (pool.isEmpty) {
        missingSlots.add(slotType);
        continue;
      }

      final candidates = _pickCandidates(pool);
      slots.add(BattleDraftSlot(type: slotType, candidates: candidates));
    }

    if (missingSlots.isNotEmpty ||
        slots.length != defaultBattleDraftSlots.length) {
      return BattleDraftBuildResult(state: null, missingSlots: missingSlots);
    }

    return BattleDraftBuildResult(state: BattleDraftState(slots: slots));
  }

  List<Person> _pickCandidates(List<Person> pool) {
    final shuffled = [...pool]..shuffle(_random);
    final count = min(battleDraftChoicesPerSlot, shuffled.length);
    return shuffled.take(count).toList()
      ..sort((a, b) => a.birthYear.compareTo(b.birthYear));
  }
}
