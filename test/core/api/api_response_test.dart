import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/api/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('fromJson parses success response with data', () {
      final json = {
        'success': true,
        'message': 'Data berhasil diambil',
        'data': {'id': '123', 'name': 'Test'},
      };

      final response = ApiResponse.fromJson(json);

      expect(response.success, true);
      expect(response.message, 'Data berhasil diambil');
      expect(response.data, {'id': '123', 'name': 'Test'});
      expect(response.meta, isNull);
      expect(response.errors, isNull);
    });

    test('fromJson parses failure response without data', () {
      final json = {
        'success': false,
        'message': 'Email already registered',
        'data': null,
      };

      final response = ApiResponse.fromJson(json);

      expect(response.success, false);
      expect(response.message, 'Email already registered');
      expect(response.data, isNull);
    });

    test('fromJson parses response with meta (pagination)', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': [
          {'id': '1'},
          {'id': '2'},
        ],
        'meta': {
          'total': 50,
          'page': 1,
          'limit': 10,
          'totalPages': 5,
        },
      };

      final response = ApiResponse.fromJson(json);

      expect(response.success, true);
      expect(response.meta, isNotNull);
      expect(response.meta!.total, 50);
      expect(response.meta!.page, 1);
      expect(response.meta!.limit, 10);
      expect(response.meta!.totalPages, 5);
    });

    test('fromJson parses response with validation errors', () {
      final json = {
        'success': false,
        'message': 'Validation failed',
        'data': null,
        'errors': [
          {'field': 'email', 'message': 'Email tidak valid'},
          {'field': 'password', 'message': 'Password minimal 8 karakter'},
        ],
      };

      final response = ApiResponse.fromJson(json);

      expect(response.success, false);
      expect(response.errors, isNotNull);
      expect(response.errors!.length, 2);
      expect(response.errors![0].field, 'email');
      expect(response.errors![0].message, 'Email tidak valid');
      expect(response.errors![1].field, 'password');
      expect(response.errors![1].message, 'Password minimal 8 karakter');
    });

    test('fromJson parses response with both meta and errors', () {
      final json = {
        'success': false,
        'message': 'Error',
        'data': null,
        'meta': {
          'total': 0,
          'page': 1,
          'limit': 10,
          'totalPages': 0,
        },
        'errors': [
          {'field': 'name', 'message': 'Nama tidak boleh kosong'},
        ],
      };

      final response = ApiResponse.fromJson(json);

      expect(response.meta, isNotNull);
      expect(response.errors, isNotNull);
      expect(response.errors!.length, 1);
    });

    test('fromJson parses data as list', () {
      final json = {
        'success': true,
        'message': 'OK',
        'data': [
          {'id': '1', 'name': 'Persona A'},
          {'id': '2', 'name': 'Persona B'},
        ],
      };

      final response = ApiResponse.fromJson(json);

      expect(response.data, isList);
      expect((response.data as List).length, 2);
    });
  });

  group('ApiMeta', () {
    test('fromJson parses all pagination fields', () {
      final json = {
        'total': 100,
        'page': 3,
        'limit': 20,
        'totalPages': 5,
      };

      final meta = ApiMeta.fromJson(json);

      expect(meta.total, 100);
      expect(meta.page, 3);
      expect(meta.limit, 20);
      expect(meta.totalPages, 5);
    });
  });

  group('ApiFieldError', () {
    test('fromJson parses field and message', () {
      final json = {
        'field': 'email',
        'message': 'Format email tidak valid',
      };

      final error = ApiFieldError.fromJson(json);

      expect(error.field, 'email');
      expect(error.message, 'Format email tidak valid');
    });
  });
}
