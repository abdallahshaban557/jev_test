import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jev_choices/order_support/jev_ui_selector.dart';
import 'package:jev_choices/order_support/orders.dart';

const live = bool.fromEnvironment('RUN_LIVE_JEV');

void main() {
  test(
    'live Jev selects the return form and named order',
    () async {
      final config =
          jsonDecode(File('jev.local.json').readAsStringSync()) as Map;
      final key = config['JEV_API_KEY'] as String? ?? '';
      if (key.trim().isEmpty) {
        fail('Set JEV_API_KEY in jev.local.json for live checks.');
      }
      final selector = JevUiSelector();
      final orders = OrderRepository();
      final cases = [
        ('return a backpack', SupportUi.returnForm, '1042', null),
        ('I want to return my headphones', SupportUi.returnForm, '1043', null),
        ('Return order #1031', SupportUi.returnForm, '1031', null),
        ('Return order #9999', SupportUi.returnForm, null, '1042'),
        ('I want to return an item', SupportUi.returnForm, null, null),
        ('Return it', SupportUi.returnForm, '1042', '1042'),
        ('What is the return policy?', SupportUi.returnPolicy, null, null),
      ];
      final failures = <String>[];
      for (var i = 0; i < cases.length; i++) {
        final c = cases[i];
        final result = await selector.select(
          apiKey: key,
          prompt: c.$1,
          history: [],
          orders: orders,
          selectedOrder: c.$4,
        );
        // Only synthetic case IDs and decision labels are logged, never the key.
        debugPrint(
          'Case ${i + 1}: ui=${result.ui.name}, order=${result.orderId ?? 'none'}',
        );
        if (result.ui != c.$2 || result.orderId != c.$3) {
          failures.add(
            'Case ${i + 1}: expected ${c.$2.name}/${c.$3 ?? 'none'}, got ${result.ui.name}/${result.orderId ?? 'none'}',
          );
        }
      }
      orders.dispose();
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
    skip: !live,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
