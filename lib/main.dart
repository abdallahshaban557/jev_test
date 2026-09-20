import 'package:flutter/material.dart';

import 'order_support/support_page.dart';
import 'support_theme.dart';

void main() => runApp(const JevApp());

class JevApp extends StatelessWidget {
  const JevApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Jev Order Support',
    debugShowCheckedModeBanner: false,
    theme: supportTheme(),
    home: const OrderSupportPage(),
  );
}
