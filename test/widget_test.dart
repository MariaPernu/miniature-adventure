import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miniature_adventure/main.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const MyApp());
    // Vain varmistetaan, että MaterialApp rakentuu ilman kaatumista
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
