// lib/core/utils/validation_utils.dart

class ValidationUtils {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'El correo electrónico no puede estar vacío.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return 'Por favor, ingrese un correo electrónico válido.';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña no puede estar vacía.';
    }
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  /// Valida que el texto no esté vacío y contenga al menos una letra (no solo números o símbolos)
  static String? validateRequiredTextWithLetters(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio.';
    }
    final trimmed = value.trim();
    // Verifica si contiene al menos una letra (incluye tildes y caracteres en español)
    final hasLetters = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]').hasMatch(trimmed);
    if (!hasLetters) {
      return '$fieldName debe contener letras, no solo números o símbolos.';
    }
    return null;
  }
}
