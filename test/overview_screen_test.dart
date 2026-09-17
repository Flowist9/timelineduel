import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled4/design/app_theme.dart';
import 'package:untitled4/localization/app_language.dart';
import 'package:untitled4/logic/game_session.dart';
import 'package:untitled4/screens/overview_screen.dart';

void main() {
  for (final width in [320.0, 1000.0]) {
    testWidgets('overview fits width $width with large text', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var played = false;
      await tester.pumpWidget(
        AppLanguageScope(
          controller: AppLanguageController(),
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: Scaffold(
              body: OverviewScreen(
                session: GameSession(),
                onPlay: () => played = true,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final playButton = find.byWidgetPredicate(
        (widget) => widget is FilledButton,
      );
      await tester.ensureVisible(playButton);
      await tester.tap(playButton);
      expect(played, isTrue);
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
