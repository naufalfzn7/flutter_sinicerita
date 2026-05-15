import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';

/// Manual mock for FlutterSecureStorage that stores data in-memory.
/// Uses noSuchMethod to handle unneeded interface methods.
class MockFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};
  bool shouldThrow = false;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) throw Exception('Storage read error');
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) throw Exception('Storage write error');
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SecureStorage - first-launch flag', () {
    late MockFlutterSecureStorage mockStorage;
    late SecureStorage secureStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      secureStorage = SecureStorage(storage: mockStorage);
    });

    test('isFirstLaunchCompleted() returns false when key does not exist',
        () async {
      final result = await secureStorage.isFirstLaunchCompleted();

      expect(result, false);
    });

    test(
        'isFirstLaunchCompleted() returns true after setFirstLaunchCompleted() called',
        () async {
      await secureStorage.setFirstLaunchCompleted();

      final result = await secureStorage.isFirstLaunchCompleted();

      expect(result, true);
    });

    test(
        'isFirstLaunchCompleted() returns false when storage throws exception',
        () async {
      mockStorage.shouldThrow = true;

      final result = await secureStorage.isFirstLaunchCompleted();

      expect(result, false);
    });
  });
}
