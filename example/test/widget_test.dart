import 'package:flutter_test/flutter_test.dart';
import 'package:lid_effect_example/main.dart';

void main() {
  testWidgets('example opens with simulation controls', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Simulate angle'), findsOneWidget);
  });
}
