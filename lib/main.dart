import 'package:flutter/material.dart';

import 'order_support/support_page.dart';

void main() => runApp(const JevApp());

class JevApp extends StatelessWidget {
  const JevApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Jev Order Support',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6554c0)),
      scaffoldBackgroundColor: const Color(0xfff7f7fb),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: const OrderSupportPage(),
  );
}
