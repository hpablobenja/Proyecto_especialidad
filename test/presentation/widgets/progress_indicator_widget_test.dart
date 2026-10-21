import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/presentation/widgets/progress_indicator_widget.dart';

void main() {
  group('ProgressIndicatorWidget Tests', () {
    testWidgets('ProgressIndicatorWidget muestra el porcentaje correcto', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(progress: 0.5, label: 'Progreso'),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('ProgressIndicatorWidget muestra 0% cuando el progreso es 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(progress: 0.0, label: 'Progreso'),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('ProgressIndicatorWidget muestra 100% cuando el progreso es 1', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(progress: 1.0, label: 'Progreso'),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });
  });
}
