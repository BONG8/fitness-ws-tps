import 'package:flutter_test/flutter_test.dart';
import 'package:fittness_app/main.dart';

void main() {
  testWidgets('App boots without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const FitnessApp());
    await tester.pump();
    expect(find.byType(FitnessApp), findsOneWidget);
  });
}
