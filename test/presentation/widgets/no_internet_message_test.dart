import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/presentation/widgets/no_internet_message.dart';

void main() {
  group('NoInternetMessage Widget Tests', () {
    testWidgets('NoInternetMessage muestra mensaje de error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoInternetMessage(),
          ),
        ),
      );

      expect(find.text('Sin acceso a internet'), findsOneWidget);
    });

    testWidgets('NoInternetMessage tiene icono de advertencia', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoInternetMessage(),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });
  });
}
