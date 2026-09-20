import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jev_choices/main.dart';

void main() {
  testWidgets('fits a narrow phone screen', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const JevApp());
    expect(tester.takeException(), isNull);
  });
}
