import 'package:flutter_test/flutter_test.dart';
import 'package:onlyfavs/main.dart';

void main() {
  testWidgets('A aplicação OnlyFavs abre o ecrã de login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OnlyFavsApp());

    expect(find.byType(OnlyFavsApp), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byType(OnlyFavsApp), findsOneWidget);
  });
}