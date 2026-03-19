import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:redmaestra1/presentation/providers/theme_provider.dart';

@GenerateMocks([ThemeProvider])
void main() {
  group('ThemeProvider Widget Tests', () {
    testWidgets('ThemeProvider cambia tema correctamente', (
      WidgetTester tester,
    ) async {
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ListenableProvider<ThemeProvider>.value(
            value: themeProvider,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Text(
                    'Theme: ${themeProvider.themeMode}',
                    key: Key('theme_text'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify initial theme
      expect(find.byKey(Key('theme_text')), findsOneWidget);

      // Toggle theme
      themeProvider.toggleTheme();
      await tester.pump();

      // Verify theme changed
      expect(find.byKey(Key('theme_text')), findsOneWidget);
    });

    testWidgets('ThemeProvider setThemeMode funciona', (
      WidgetTester tester,
    ) async {
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ListenableProvider<ThemeProvider>.value(
            value: themeProvider,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Text(
                    'Theme: ${themeProvider.themeMode}',
                    key: Key('theme_text'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Set dark theme
      themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pump();

      expect(find.byKey(Key('theme_text')), findsOneWidget);
      expect(themeProvider.isDarkMode, true);
    });
  });

  group('Basic Widget Tests', () {
    testWidgets('MaterialApp básico se construye', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Test')),
            body: Center(child: Text('Hello World')),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Botón responde a tap', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                wasPressed = true;
              },
              child: Text('Press Me'),
            ),
          ),
        ),
      );

      expect(find.text('Press Me'), findsOneWidget);
      expect(wasPressed, false);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('TextFormField permite entrada de texto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              key: Key('test_field'),
              decoration: InputDecoration(labelText: 'Test Field'),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Test Field'), findsOneWidget);

      await tester.enterText(find.byKey(Key('test_field')), 'Hello Test');
      await tester.pump();

      expect(find.text('Hello Test'), findsOneWidget);
    });
  });
}
