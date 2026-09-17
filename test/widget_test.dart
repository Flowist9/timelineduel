import 'package:flutter_test/flutter_test.dart';
import 'package:untitled4/ads/ads_service.dart';
import 'package:untitled4/main.dart';

void main() {
  testWidgets('app shows the main navigation', (tester) async {
    await tester.pumpWidget(MyApp(adsService: AdsService()));
    await tester.pumpAndSettle();

    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Battle'), findsOneWidget);
  });
}
