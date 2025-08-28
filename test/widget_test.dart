import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virelink/app.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const VireLinkApp()); // Vain varmistetaan, että MaterialApp rakentuu ilman kaatumista
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
