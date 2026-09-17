import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled4/data/persons.dart';
import 'package:untitled4/localization/app_language.dart';
import 'package:untitled4/widgets/battle_card_hand.dart';

void main() {
  testWidgets(
    'hand previews before playing and prevents duplicate submission',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cards = allPersons.take(4).toList();
      final pending = Completer<void>();
      var plays = 0;
      await tester.pumpWidget(
        AppLanguageScope(
          controller: AppLanguageController(),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BattleCardHand(
                  cards: cards,
                  onPlay: (person) async {
                    expect(person.id, cards.last.id);
                    plays++;
                    await pending.future;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      final button = find.byWidgetPredicate((widget) => widget is FilledButton);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      final card = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == cards.last.name,
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(plays, 0);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(plays, 1);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      pending.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
