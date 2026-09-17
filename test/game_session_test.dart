import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled4/logic/game_session.dart';
import 'package:untitled4/models/category.dart';
import 'package:untitled4/models/person_status.dart';

void main() {
  test('session starts without cards; HomeScreen grants the starter pack', () {
    final session = GameSession();

    expect(session.unlockedPersons, isEmpty);
    expect(session.discoveredNotUnlocked, isEmpty);
  });

  test('discoveries respect the max open discovery limit', () {
    final session = GameSession();

    final first = session.discoverFromCategory(Category.politician);
    final second = session.discoverFromCategory(Category.scientist);
    final third = session.discoverFromCategory(Category.artist);

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(third, isNull);
    expect(session.discoveredNotUnlocked, hasLength(2));
  });

  test('finishing all unlock steps fully unlocks a discovered person', () {
    final session = GameSession();
    final person = session.discoverFromCategory(Category.athlete);

    expect(person, isNotNull);
    expect(session.statusById[person!.id], PersonStatus.discovered);

    session.markStepDone(person, UnlockStep.birthYear);
    session.markStepDone(person, UnlockStep.map);
    session.markStepDone(person, UnlockStep.famousFor);

    expect(session.statusById[person.id], PersonStatus.unlocked);
    expect(session.lastUnlockedPersonId, person.id);
  });

  test('restores saved progress after creating a new session', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final session = GameSession();
    final person = session.discoverFromCategory(
      Category.scientist,
      instantUnlock: true,
    );
    session.addCoins(17);
    await session.save();

    final restored = await GameSession.load();

    expect(restored.hasStoredProgress, isTrue);
    expect(restored.coins, 17);
    expect(restored.statusById[person!.id], PersonStatus.unlocked);
  });
}
