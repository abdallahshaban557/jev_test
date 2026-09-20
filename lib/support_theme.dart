import 'package:flutter/material.dart';

ThemeData supportTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6554c0)),
  scaffoldBackgroundColor: const Color(0xfff7f7fb),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
  ),
);
