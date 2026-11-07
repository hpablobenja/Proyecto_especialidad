import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/core/utils/validation_utils.dart';

void main() {
  group('ValidationUtils Tests', () {
    group('validateEmail', () {
      test('returns error when email is null', () {
        final result = ValidationUtils.validateEmail(null);
        expect(result, 'El correo electrónico no puede estar vacío.');
      });

      test('returns error when email is empty', () {
        final result = ValidationUtils.validateEmail('');
        expect(result, 'El correo electrónico no puede estar vacío.');
      });

      test('returns error when email is invalid - no @', () {
        final result = ValidationUtils.validateEmail('invalidemail');
        expect(result, 'Por favor, ingrese un correo electrónico válido.');
      });

      test('returns error when email is invalid - no domain', () {
        final result = ValidationUtils.validateEmail('user@');
        expect(result, 'Por favor, ingrese un correo electrónico válido.');
      });

      test('returns error when email is invalid - no TLD', () {
        final result = ValidationUtils.validateEmail('user@domain');
        expect(result, 'Por favor, ingrese un correo electrónico válido.');
      });

      test('returns null when email is valid', () {
        final result = ValidationUtils.validateEmail('test@example.com');
        expect(result, null);
      });

      test('returns null when email is valid with subdomain', () {
        final result = ValidationUtils.validateEmail('test@mail.example.com');
        expect(result, null);
      });

      test('returns null when email is valid with numbers', () {
        final result = ValidationUtils.validateEmail('user123@example.com');
        expect(result, null);
      });

      test('returns null when email is valid with dots', () {
        final result = ValidationUtils.validateEmail('first.last@example.com');
        expect(result, null);
      });

      test('returns null when email is valid with plus sign', () {
        final result = ValidationUtils.validateEmail('user+tag@example.com');
        expect(result, null);
      });
    });

    group('validatePassword', () {
      test('returns error when password is null', () {
        final result = ValidationUtils.validatePassword(null);
        expect(result, 'La contraseña no puede estar vacía.');
      });

      test('returns error when password is empty', () {
        final result = ValidationUtils.validatePassword('');
        expect(result, 'La contraseña no puede estar vacía.');
      });

      test('returns error when password is too short - 5 chars', () {
        final result = ValidationUtils.validatePassword('12345');
        expect(result, 'La contraseña debe tener al menos 6 caracteres.');
      });

      test('returns error when password is too short - 1 char', () {
        final result = ValidationUtils.validatePassword('a');
        expect(result, 'La contraseña debe tener al menos 6 caracteres.');
      });

      test('returns null when password has exactly 6 characters', () {
        final result = ValidationUtils.validatePassword('123456');
        expect(result, null);
      });

      test('returns null when password is longer than 6 characters', () {
        final result = ValidationUtils.validatePassword('password123');
        expect(result, null);
      });

      test('returns null when password has special characters', () {
        final result = ValidationUtils.validatePassword('p@ssw0rd!');
        expect(result, null);
      });

      test('returns null when password has spaces', () {
        final result = ValidationUtils.validatePassword('pass word');
        expect(result, null);
      });
    });

    group('validateRequiredTextWithLetters', () {
      test('returns error when value is null', () {
        final result = ValidationUtils.validateRequiredTextWithLetters(null);
        expect(result, 'Este campo es obligatorio.');
      });

      test('returns error when value is empty string', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('');
        expect(result, 'Este campo es obligatorio.');
      });

      test('returns error when value is only whitespace', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('   ');
        expect(result, 'Este campo es obligatorio.');
      });

      test('returns error when value contains only numbers', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('12345');
        expect(
          result,
          'Este campo debe contener letras, no solo números o símbolos.',
        );
      });

      test('returns error when value contains only symbols', () {
        final result = ValidationUtils.validateRequiredTextWithLetters(
          '!@#\$%',
        );
        expect(
          result,
          'Este campo debe contener letras, no solo números o símbolos.',
        );
      });

      test('returns error when value contains only numbers and symbols', () {
        final result = ValidationUtils.validateRequiredTextWithLetters(
          '123!@#',
        );
        expect(
          result,
          'Este campo debe contener letras, no solo números o símbolos.',
        );
      });

      test('returns null when value contains lowercase letters', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('test');
        expect(result, null);
      });

      test('returns null when value contains uppercase letters', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('TEST');
        expect(result, null);
      });

      test('returns null when value contains mixed case letters', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('Test');
        expect(result, null);
      });

      test('returns null when value contains letters and numbers', () {
        final result = ValidationUtils.validateRequiredTextWithLetters(
          'test123',
        );
        expect(result, null);
      });

      test('returns null when value contains letters and symbols', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('test!');
        expect(result, null);
      });

      test('returns null when value contains Spanish letters with accents', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('café');
        expect(result, null);
      });

      test('returns null when value contains ñ', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('año');
        expect(result, null);
      });

      test('returns null when value contains uppercase Spanish letters', () {
        final result = ValidationUtils.validateRequiredTextWithLetters('ÁÉÍÓÚ');
        expect(result, null);
      });

      test(
        'returns null when value has leading/trailing whitespace but contains letters',
        () {
          final result = ValidationUtils.validateRequiredTextWithLetters(
            '  test  ',
          );
          expect(result, null);
        },
      );

      test('uses custom field name in error message', () {
        final result = ValidationUtils.validateRequiredTextWithLetters(
          '123',
          fieldName: 'Nombre',
        );
        expect(
          result,
          'Nombre debe contener letras, no solo números o símbolos.',
        );
      });

      test('custom field name in empty error', () {
        final result = ValidationUtils.validateRequiredTextWithLetters(
          '',
          fieldName: 'Apellido',
        );
        expect(result, 'Apellido es obligatorio.');
      });
    });
  });
}
