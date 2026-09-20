import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jev_dart/jev_dart.dart';
import 'package:jev_choices/order_support/jev_ui_selector.dart';
import 'package:jev_choices/order_support/orders.dart';
import 'package:jev_choices/order_support/support_page.dart';
import 'package:jev_choices/order_support/support_view_model.dart';

class FixedSelector extends JevUiSelector {
  FixedSelector(this.selection);
  final UiSelection selection;
  int calls = 0;
  @override
  Future<UiSelection> select({
    required String apiKey,
    required String prompt,
    required List<Map<String, String>> history,
    required OrderRepository orders,
    String? selectedOrder,
  }) async {
    calls++;
    return selection;
  }
}

void main() {
  test('Jev receives UI and order choices and validates response', () async {
    final selector = JevUiSelector(
      clientFactory: (key) => TypeSafeClient(
        apiKey: key,
        allowBrowser: true,
        closeClient: true,
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          expect(
            (body['questions']['ui']['criteria'] as Map).keys,
            unorderedEquals(SupportUi.values.map((s) => s.name)),
          );
          expect(
            (body['questions']['order']['criteria'] as Map).keys,
            unorderedEquals(['1042', '1043', '1031', 'none']),
          );
          expect(body['state']['selected_order'], '1042');
          return http.Response(
            jsonEncode({
              'model': 'jev-latest',
              'usage': {'input_tokens': 1, 'output_tokens': 1},
              'answers': {
                'ui': {
                  'type': 'choice',
                  'choice': 'returnForm',
                  'confidence': 0.9,
                },
                'order': {
                  'type': 'choice',
                  'choice': '1042',
                  'confidence': 0.9,
                },
              },
            }),
            200,
          );
        }),
      ),
    );
    final result = await selector.select(
      apiKey: 'fake',
      prompt: 'Return it',
      history: [],
      orders: OrderRepository(),
      selectedOrder: '1042',
    );
    expect(result.ui, SupportUi.returnForm);
    expect(result.orderId, '1042');
  });

  test('all sample orders are returnable and submission is idempotent', () {
    final orders = OrderRepository();
    for (final order in orders.orders) {
      expect(order.toJson()['return_eligible'], isTrue);
      expect(
        orders.submitReturn(order.id, returnReasons.first),
        'DEMO-RMA-${order.id}',
      );
    }
    expect(
      () => orders.submitReturn('unknown', returnReasons.first),
      throwsFormatException,
    );
    expect(() => orders.submitReturn('1042', 'invalid'), throwsFormatException);
    expect(orders.submitReturn('1042', returnReasons.first), 'DEMO-RMA-1042');
    expect(orders.submitReturn('1042', returnReasons.last), 'DEMO-RMA-1042');
  });

  for (final ui in SupportUi.values) {
    testWidgets('GenUI renders ${ui.component} from the provider', (
      tester,
    ) async {
      final vm = SupportViewModel(
        selector: FixedSelector(UiSelection(ui, '1042')),
      )..apiKey = 'fake';
      await tester.pumpWidget(
        MaterialApp(home: OrderSupportPage(viewModel: vm)),
      );
      await vm.send('My question');
      await tester.pumpAndSettle();
      expect(find.byType(Surface), findsOneWidget);
      expect(vm.error, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    });
  }

  testWidgets(
    'return form dispatches through GenUI and shows demo confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final selector = FixedSelector(
        const UiSelection(SupportUi.returnForm, '1042'),
      );
      final vm = SupportViewModel(selector: selector)..apiKey = 'fake';
      await tester.pumpWidget(
        MaterialApp(home: OrderSupportPage(viewModel: vm)),
      );
      await vm.send('Return my backpack');
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(FilledButton, 'Submit demo return');
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(returnReasons.first).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(vm.orders.returnReference('1042'), 'DEMO-RMA-1042');
      expect(find.text('Demo return saved'), findsWidgets);
      expect(
        selector.calls,
        1,
      ); // A model cannot approve or execute the return.
      expect(vm.error, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );

  testWidgets('unknown order asks for a selection', (tester) async {
    final vm = SupportViewModel(
      selector: FixedSelector(const UiSelection(SupportUi.returnForm, null)),
    )..apiKey = 'fake';
    await tester.pumpWidget(MaterialApp(home: OrderSupportPage(viewModel: vm)));
    await vm.send('Return an order');
    await tester.pumpAndSettle();
    expect(find.text('Which order is this about?'), findsOneWidget);
    expect(find.text('Submit demo return'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
