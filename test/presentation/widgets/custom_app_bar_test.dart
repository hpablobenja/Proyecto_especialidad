import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/presentation/widgets/custom_app_bar.dart';

void main() {
  group('CustomAppBar Widget Tests', () {
    testWidgets('CustomAppBar acepta parámetro title', (WidgetTester tester) async {
      expect(() => const CustomAppBar(title: 'Título'), returnsNormally);
    });

    testWidgets('CustomAppBar acepta parámetro titleColor', (WidgetTester tester) async {
      expect(() => const CustomAppBar(title: 'Título', titleColor: Colors.white), returnsNormally);
    });

    testWidgets('CustomAppBar implementa PreferredSizeWidget', (WidgetTester tester) async {
      final appBar = const CustomAppBar(title: 'Título');
      expect(appBar, isA<PreferredSizeWidget>());
    });
  });
}
