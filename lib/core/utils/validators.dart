/// Client-side form validation utility methods.
///
/// Mengikuti backend Zod validation schema.
/// Semua method return `String?`:
/// - `null` = input valid
/// - non-null = error message (match backend messages)
class Validators {
  Validators._();

  // Regex patterns untuk password validation (match backend)
  static final _lowercaseRegex = RegExp(r'[a-z]');
  static final _uppercaseRegex = RegExp(r'[A-Z]');
  static final _digitRegex = RegExp(r'[0-9]');
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  /// Validasi field persona form (name, description, systemPrompt).
  ///
  /// Rules:
  /// - null atau whitespace-only → 'Field ini wajib diisi'
  /// - length > [maxLength] → 'Maksimal $maxLength karakter'
  /// - otherwise → null (valid)
  static String? validatePersonaField(String? value, int maxLength) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }
    if (value.length > maxLength) {
      return 'Maksimal $maxLength karakter';
    }
    return null;
  }

  /// Validasi field email.
  /// Match backend: required, valid email format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validasi password untuk registrasi & reset password.
  /// Match backend passwordSchema:
  /// - min 8 karakter
  /// - max 100 karakter
  /// - harus mengandung huruf kecil
  /// - harus mengandung huruf besar
  /// - harus mengandung angka
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (value.length > 100) {
      return 'Password maksimal 100 karakter';
    }
    if (!_lowercaseRegex.hasMatch(value)) {
      return 'Password harus mengandung huruf kecil';
    }
    if (!_uppercaseRegex.hasMatch(value)) {
      return 'Password harus mengandung huruf besar';
    }
    if (!_digitRegex.hasMatch(value)) {
      return 'Password harus mengandung angka';
    }
    return null;
  }

  /// Validasi password untuk login.
  /// Backend loginSchema hanya cek non-empty (tidak enforce complexity).
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    return null;
  }

  /// Validasi field nama.
  /// Match backend: min 1 (non-empty), max 100 karakter, trimmed.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length > 100) {
      return 'Nama maksimal 100 karakter';
    }
    return null;
  }

  /// Validasi field konfirmasi password.
  /// Cek empty dan match dengan password asli.
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  /// Validasi OTP code.
  /// Match backend: exactly 6 digits.
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kode OTP tidak boleh kosong';
    }
    if (value.length != 6) {
      return 'Kode OTP harus 6 digit';
    }
    return null;
  }

  /// Validasi old password untuk change password.
  /// Match backend changePasswordSchema: non-empty saja.
  static String? validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password lama tidak boleh kosong';
    }
    return null;
  }

  /// Validasi new password untuk change password.
  /// Sama dengan validatePassword + cek tidak sama dengan old password.
  static String? validateNewPassword(String? value, String? oldPassword) {
    final baseValidation = validatePassword(value);
    if (baseValidation != null) return baseValidation;

    if (value == oldPassword) {
      return 'Password baru tidak boleh sama dengan password lama';
    }
    return null;
  }
}
