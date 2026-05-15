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
      expect(Validators.validatePassword('1234567'), 'Password minimal 8 karakter');
    });

    test('returns error for 1 character', () {
      expect(Validators.validatePassword('a'), 'Password minimal 8 karakter');
    });

    test('returns null for exactly 8 characters', () {
      expect(Validators.validatePassword('12345678'), isNull);
    });

    test('returns null for more than 8 characters', () {
      expect(Validators.validatePassword('password123'), isNull);
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

    test('returns null for valid name', () {
      expect(Validators.validateName('John'), isNull);
    });

    test('returns null for single character name', () {
      expect(Validators.validateName('A'), isNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('returns error when null', () {
      expect(
        Validators.validateConfirmPassword(null, 'password123'),
        'Konfirmasi password tidak boleh kosong',
      );
    });

    test('returns error when empty string', () {
      expect(
        Validators.validateConfirmPassword('', 'password123'),
        'Konfirmasi password tidak boleh kosong',
      );
    });

    test('returns error when does not match password', () {
      expect(
        Validators.validateConfirmPassword('different', 'password123'),
        'Password tidak cocok',
      );
    });

    test('returns null when matches password', () {
      expect(
        Validators.validateConfirmPassword('password123', 'password123'),
        isNull,
      );
    });

    test('returns null when both are same string', () {
      expect(
        Validators.validateConfirmPassword('abcdefgh', 'abcdefgh'),
        isNull,
      );
    });
  });
}
