import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jev_choices/main.dart';
import 'package:jev_choices/choice_service.dart';

class FakeChoices extends ChoiceService {
  @override
  Future<ServiceOption> select({
    required String apiKey,
    required String prompt,
    required List<Map<String, String>> history,
  }) async => ServiceOption.stripe;
}

void main() {
  testWidgets('requires a key before sending', (tester) async {
    await tester.pumpWidget(const JevApp());
    await tester.enterText(find.byType(TextField).last, 'Accept a payment');
    await tester.tap(find.byTooltip('Ask Jev'));
    await tester.pump();
    expect(
      find.text('Add your Jev API key to start chatting.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a returned selection and clears chat', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ChatPage(service: FakeChoices())),
    );
    await tester.enterText(find.byType(TextField).first, 'test-key');
    await tester.enterText(find.byType(TextField).last, 'Accept a payment');
    await tester.tap(find.byTooltip('Ask Jev'));
    await tester.pumpAndSettle();
    expect(find.text('Select Stripe.'), findsOneWidget);
    expect(find.text('Returned choice: stripe'), findsOneWidget);
    await tester.tap(find.text('New chat'));
    await tester.pumpAndSettle();
    expect(find.text('Select Stripe.'), findsNothing);
    expect(find.text('One question. The right choice.'), findsOneWidget);
  });

  testWidgets('fits a narrow phone screen', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const JevApp());
    expect(tester.takeException(), isNull);
  });
}
