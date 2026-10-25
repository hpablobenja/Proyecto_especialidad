import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redmaestra1/presentation/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Wait for initialization to complete
      themeProvider = ThemeProvider();
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      themeProvider.dispose();
    });

    test('ThemeProvider initializes with default theme mode', () {
      expect(themeProvider.themeMode, isNotNull);
      expect(themeProvider.isLoading, isA<bool>());
    });

    test('isDarkMode returns true when themeMode is dark', () async {
      await themeProvider.setDarkMode();
      expect(themeProvider.isDarkMode, true);
    });

    test('isDarkMode returns false when themeMode is light', () async {
      await themeProvider.setLightMode();
      expect(themeProvider.isDarkMode, false);
    });

    test('toggleTheme switches between light and dark', () async {
      await themeProvider.setLightMode();
      expect(themeProvider.themeMode, ThemeMode.light);
      
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.dark);
      
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    test('setLightMode sets themeMode to light', () async {
      await themeProvider.setDarkMode();
      await themeProvider.setLightMode();
      
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    test('setDarkMode sets themeMode to dark', () async {
      await themeProvider.setLightMode();
      await themeProvider.setDarkMode();
      
      expect(themeProvider.themeMode, ThemeMode.dark);
    });

    test('setSystemMode sets themeMode to system', () async {
      await themeProvider.setSystemMode();
      
      expect(themeProvider.themeMode, ThemeMode.system);
    });

    test('setThemeMode with same mode does not notify listeners', () async {
      await themeProvider.setLightMode();
      var notificationCount = 0;
      
      themeProvider.addListener(() {
        notificationCount++;
      });
      
      await themeProvider.setThemeMode(ThemeMode.light);
      expect(notificationCount, 0);
    });

    test('setThemeMode with different mode notifies listeners', () async {
      await themeProvider.setLightMode();
      var notificationCount = 0;
      
      themeProvider.addListener(() {
        notificationCount++;
      });
      
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(notificationCount, 1);
    });

    test('getThemeModeString returns correct string for light mode', () async {
      await themeProvider.setLightMode();
      expect(themeProvider.getThemeModeString(), 'Claro');
    });

    test('getThemeModeString returns correct string for dark mode', () async {
      await themeProvider.setDarkMode();
      expect(themeProvider.getThemeModeString(), 'Oscuro');
    });

    test('getThemeModeString returns correct string for system mode', () async {
      await themeProvider.setSystemMode();
      expect(themeProvider.getThemeModeString(), 'Sistema');
    });

    test('getThemeModeIcon returns correct icon for light mode', () async {
      await themeProvider.setLightMode();
      expect(themeProvider.getThemeModeIcon(), Icons.light_mode);
    });

    test('getThemeModeIcon returns correct icon for dark mode', () async {
      await themeProvider.setDarkMode();
      expect(themeProvider.getThemeModeIcon(), Icons.dark_mode);
    });

    test('getThemeModeIcon returns correct icon for system mode', () async {
      await themeProvider.setSystemMode();
      expect(themeProvider.getThemeModeIcon(), Icons.brightness_auto);
    });

    test('multiple theme changes work correctly', () async {
      await themeProvider.setLightMode();
      expect(themeProvider.themeMode, ThemeMode.light);
      
      await themeProvider.setDarkMode();
      expect(themeProvider.themeMode, ThemeMode.dark);
      
      await themeProvider.setSystemMode();
      expect(themeProvider.themeMode, ThemeMode.system);
      
      await themeProvider.setLightMode();
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    test('themeMode getter returns current theme mode', () async {
      await themeProvider.setDarkMode();
      expect(themeProvider.themeMode, ThemeMode.dark);
      
      await themeProvider.setLightMode();
      expect(themeProvider.themeMode, ThemeMode.light);
    });

    test('isLoading getter returns boolean', () {
      expect(themeProvider.isLoading, isA<bool>());
    });
  });
}
