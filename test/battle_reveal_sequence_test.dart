import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled4/battle/battle_models.dart';
import 'package:untitled4/battle/battle_session.dart';
import 'package:untitled4/data/persons.dart';
import 'package:untitled4/localization/app_language.dart';
import 'package:untitled4/screens/battle_reveal_host_widgets.dart';

void main() {
  for (final skip in [false, true]) {
    testWidgets('reveal reaches comparison promptly (skip: $skip)', (
      tester,
    ) async {
      final result = BattleRoundResult(
        roundNumber: 1,
        definition: const BattleRoundDefinition(
          type: BattleRoundType.bornEarlier,
          title: 'Earlier',
          prompt: 'Who was born earlier?',
        ),
        playerCard: allPersons[0],
        botCard: allPersons[1],
        playerMetric: 1,
        botMetric: 2,
        playerWon: true,
        isDraw: false,
        explanation: '',
      );
      await tester.pumpWidget(
        AppLanguageScope(
          controller: AppLanguageController(),
          child: MaterialApp(
            home: Scaffold(
              body: BattleRevealSequence(
                result: result,
                rarityColor: (_) => Colors.amber,
                revealStageBuilder: (_, _) => const Text('Comparison ready'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Comparison ready'), findsNothing);
      if (skip) {
        await tester.tap(find.byType(TextButton));
        await tester.pump();
      } else {
        await tester.pump(const Duration(milliseconds: 1400));
        expect(find.text('Comparison ready'), findsNothing);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Comparison ready'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  }
}
