@echo off
echo Ejecutando pruebas funcionales del proyecto RedMaestra...
echo.

flutter test test/widget_test.dart test/providers_test.dart test/login_screen_test_simple.dart test/entities_test.dart test/usecases_test.dart --reporter=expanded

echo.
echo Pruebas funcionales completadas.
pause
