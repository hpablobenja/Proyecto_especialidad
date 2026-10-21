import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/presentation/widgets/modern_button.dart';

void main() {
  group('ModernButton Widget Tests', () {
    testWidgets('ModernButton muestra el texto proporcionado', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Botón de Prueba',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Botón de Prueba'), findsOneWidget);
    });

    testWidgets('ModernButton ejecuta onPressed al hacer tap', (WidgetTester tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Presioname',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernButton));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('ModernButton está deshabilitado cuando onPressed es null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernButton(
              text: 'Botón Deshabilitado',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, null);
    });
  });
}
