// test back_home_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/presentation/widgets/back_home_button.dart';

void main() {
  group('BackHomeButton Widget Tests', () {
    testWidgets('BackHomeButton acepta parámetros opcionales', (
      WidgetTester tester,
    ) async {
      expect(() => const BackHomeButton(), returnsNormally);
    });

    testWidgets('BackHomeButton acepta onPressed callback', (
      WidgetTester tester,
    ) async {
      expect(() => BackHomeButton(onPressed: () {}), returnsNormally);
    });

    testWidgets('BackHomeButton acepta isVisible parámetro', (
      WidgetTester tester,
    ) async {
      expect(() => const BackHomeButton(isVisible: false), returnsNormally);
    });
  });
}
