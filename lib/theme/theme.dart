import 'package:flutter/material.dart';

ThemeData buildVireLinkTheme() {
  const seed = Color(0xFFCEEFD1); // taustasävy
  final scheme = ColorScheme.fromSeed(seedColor: seed);

  return ThemeData(
    colorScheme: scheme.copyWith(surface: const Color(0xFFCEEFD1)),
    scaffoldBackgroundColor: const Color(0xFFCEEFD1),
    inputDecorationTheme: const InputDecorationTheme(
      border: UnderlineInputBorder(),
      hintStyle: TextStyle(color: Colors.black54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    useMaterial3: true,
  );
}
