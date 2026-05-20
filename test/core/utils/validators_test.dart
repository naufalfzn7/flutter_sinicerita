import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns error when null', () {
      expect(Validators.validateEmail(null), 'Email tidak boleh kosong');
    });

    test('returns error when empty string', () {
      expect(Validators.validateEmail(''), 'Email tidak boleh kosong');
    });

    test('returns error when whitespace only', () {
      expect(Validators.validateEmail('   '), 'Email tidak boleh kosong');
    });

    test('returns error for invalid format - no @', () {
      expect(Validators.validateEmail('invalidemail'), 'Format email tidak valid');
    });

    test('returns error for invalid format - no domain', () {
      expect(Validators.validateEmail('user@'), 'Format email tidak valid');
    });

    test('returns error for invalid format - no TLD', () {
      expect(Validators.validateEmail('user@domain'), 'Format email tidak valid');
    });

    test('returns null for valid email', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
    });

    test('returns null for valid email with dots', () {
      expect(Validators.validateEmail('user.name@example.co.id'), isNull);
    });

    test('returns null for valid email with hyphens', () {
      expect(Validators.validateEmail('user-name@my-domain.com'), isNull);
    });

    test('trims whitespace before validation', () {
      expect(Validators.validateEmail('  user@example.com  '), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns error when null', () {
      expect(Validators.validatePassword(null), 'Password tidak boleh kosong');
    });

    test('returns error when empty string', () {
      expect(Validators.validatePassword(''), 'Password tidak boleh kosong');
    });

    test('returns error when less than 8 characters', () {
      expect(Validators.validatePassword('Abcde1'), 'Password minimal 8 karakter');
    });

    test('returns error when more than 100 characters', () {
      final longPassword = 'Aa1${'x' * 99}';
      expect(Validators.validatePassword(longPassword), 'Password maksimal 100 karakter');
    });

    test('returns error when no lowercase letter', () {
      expect(Validators.validatePassword('ABCDEFG1'), 'Password harus mengandung huruf kecil');
    });

    test('returns error when no uppercase letter', () {
      expect(Validators.validatePassword('abcdefg1'), 'Password harus mengandung huruf besar');
    });

    test('returns error when no digit', () {
      expect(Validators.validatePassword('Abcdefgh'), 'Password harus mengandung angka');
    });

    test('returns null for valid password with all requirements', () {
      expect(Validators.validatePassword('Abcdefg1'), isNull);
    });

    test('returns null for complex valid password', () {
      expect(Validators.validatePassword('MyP4ssword'), isNull);
    });
  });

  group('Validators.validateLoginPassword', () {
    test('returns error when null', () {
      expect(Validators.validateLoginPassword(null), 'Password tidak boleh kosong');
    });

    test('returns error when empty string', () {
      expect(Validators.validateLoginPassword(''), 'Password tidak boleh kosong');
    });

    test('returns null for any non-empty string', () {
      expect(Validators.validateLoginPassword('a'), isNull);
    });

    test('returns null for short password (no complexity check)', () {
      expect(Validators.validateLoginPassword('123'), isNull);
    });
  });

  group('Validators.validateName', () {
    test('returns error when null', () {
      expect(Validators.validateName(null), 'Nama tidak boleh kosong');
    });

    test('returns error when empty string', () {
      expect(Validators.validateName(''), 'Nama tidak boleh kosong');
    });

    test('returns error when whitespace only', () {
      expect(Validators.validateName('   '), 'Nama tidak boleh kosong');
    });

    test('returns error when more than 100 characters', () {
      final longName = 'A' * 101;
      expect(Validators.validateName(longName), 'Nama maksimal 100 karakter');
    });

    test('returns null for valid name', () {
      expect(Validators.validateName('John'), isNull);
    });

    test('returns null for single character name', () {
      expect(Validators.validateName('A'), isNull);
    });

    test('returns null for exactly 100 characters', () {
      final name = 'A' * 100;
      expect(Validators.validateName(name), isNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('returns error when null', () {
      expect(
        Validators.validateConfirmPassword(null, 'Password1'),
        'Konfirmasi password tidak boleh kosong',
      );
    });

    test('returns error when empty string', () {
      expect(
        Validators.validateConfirmPassword('', 'Password1'),
        'Konfirmasi password tidak boleh kosong',
      );
    });

    test('returns error when does not match password', () {
      expect(
        Validators.validateConfirmPassword('different', 'Password1'),
        'Password tidak cocok',
      );
    });

    test('returns null when matches password', () {
      expect(
        Validators.validateConfirmPassword('Password1', 'Password1'),
        isNull,
      );
    });
  });

  group('Validators.validateOtp', () {
    test('returns error when null', () {
      expect(Validators.validateOtp(null), 'Kode OTP tidak boleh kosong');
    });

    test('returns error when empty string', () {
      expect(Validators.validateOtp(''), 'Kode OTP tidak boleh kosong');
    });

    test('returns error when less than 6 digits', () {
      expect(Validators.validateOtp('12345'), 'Kode OTP harus 6 digit');
    });

    test('returns error when more than 6 digits', () {
      expect(Validators.validateOtp('1234567'), 'Kode OTP harus 6 digit');
    });

    test('returns null for exactly 6 digits', () {
      expect(Validators.validateOtp('123456'), isNull);
    });
  });

  group('Validators.validateOldPassword', () {
    test('returns error when null', () {
      expect(Validators.validateOldPassword(null), 'Password lama tidak boleh kosong');
    });

    test('returns error when empty string', () {
      expect(Validators.validateOldPassword(''), 'Password lama tidak boleh kosong');
    });

    test('returns null for any non-empty string', () {
      expect(Validators.validateOldPassword('anything'), isNull);
    });
  });

  group('Validators.validateNewPassword', () {
    test('returns error when null', () {
      expect(
        Validators.validateNewPassword(null, 'OldPass1'),
        'Password tidak boleh kosong',
      );
    });

    test('returns error when empty', () {
      expect(
        Validators.validateNewPassword('', 'OldPass1'),
        'Password tidak boleh kosong',
      );
    });

    test('returns error when same as old password', () {
      expect(
        Validators.validateNewPassword('OldPass1', 'OldPass1'),
        'Password baru tidak boleh sama dengan password lama',
      );
    });

    test('returns error when missing complexity (no uppercase)', () {
      expect(
        Validators.validateNewPassword('newpass1', 'OldPass1'),
        'Password harus mengandung huruf besar',
      );
    });

    test('returns null for valid new password different from old', () {
      expect(
        Validators.validateNewPassword('NewPass1', 'OldPass1'),
        isNull,
      );
    });
  });
}
