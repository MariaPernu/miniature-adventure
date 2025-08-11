import 'package:flutter/material.dart';

void main() {
  runApp(const MiniAdventureApp());
}

class MiniAdventureApp extends StatelessWidget {
  const MiniAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Health Integrator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true);
  }
}
