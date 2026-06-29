import 'package:flutter_test/flutter_test.dart';
import 'package:cliente/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialesYaApp());
    expect(find.byType(MaterialesYaApp), findsOneWidget);
  });
}
