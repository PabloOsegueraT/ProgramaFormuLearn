import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// importa tu app real:
import 'package:formulearn/src/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Construir la app
    await tester.pumpWidget(const FormuLearnApp());

    // Verifica que hay un MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
