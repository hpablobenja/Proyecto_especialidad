import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/core/utils/firebase_utils.dart';

void main() {
  group('FirebaseUtils Tests', () {
    group('handleFirebaseAuthError', () {
      test('returns correct message for user-not-found error', () {
        final error = FirebaseAuthException(code: 'user-not-found');
        final result = FirebaseUtils.handleFirebaseAuthError(error);
        expect(result, 'No se encontró un usuario con ese correo electrónico.');
      });

      test('returns correct message for wrong-password error', () {
        final error = FirebaseAuthException(code: 'wrong-password');
        final result = FirebaseUtils.handleFirebaseAuthError(error);
        expect(result, 'Contraseña incorrecta. Por favor, intente de nuevo.');
      });

      test('returns correct message for email-already-in-use error', () {
        final error = FirebaseAuthException(code: 'email-already-in-use');
        final result = FirebaseUtils.handleFirebaseAuthError(error);
        expect(result, 'El correo electrónico ya está en uso.');
      });

      test('returns correct message for invalid-email error', () {
        final error = FirebaseAuthException(code: 'invalid-email');
        final result = FirebaseUtils.handleFirebaseAuthError(error);
        expect(result, 'La dirección de correo electrónico es inválida.');
      });

      test('returns default message for unknown error code', () {
        final error = FirebaseAuthException(code: 'unknown-error');
        final result = FirebaseUtils.handleFirebaseAuthError(error);
        expect(result, 'Ocurrió un error inesperado. Por favor, intente de nuevo más tarde.');
      });

      test('returns default message for empty code', () {
        final error = FirebaseAuthException(code: '');
        final result = FirebaseUtils.handleFirebaseAuthError(error);
        expect(result, 'Ocurrió un error inesperado. Por favor, intente de nuevo más tarde.');
      });

      test('returns default message for weak-password error', () {
        final error = FirebaseAuthException(code: 'weak-password');
        final result = FirebaseUtils.handleFirebaseAuthError(error);
        expect(result, 'Ocurrió un error inesperado. Por favor, intente de nuevo más tarde.');
      });

      test('returns default message for too-many-requests error', () {
        final error = FirebaseAuthException(code: 'too-many-requests');
        final result = FirebaseUtils.handleFirebaseAuthError(error);
        expect(result, 'Ocurrió un error inesperado. Por favor, intente de nuevo más tarde.');
      });

      test('handles error with message', () {
        final error = FirebaseAuthException(code: 'user-not-found', message: 'Custom message');
        final result = FirebaseUtils.handleFirebaseAuthError(error);
        expect(result, 'No se encontró un usuario con ese correo electrónico.');
      });
    });
  });
}
