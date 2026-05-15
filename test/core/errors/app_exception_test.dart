import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/errors/app_exception.dart';

void main() {
  group('AppException.fromDioError', () {
    test('connectionTimeout → pesan timeout jaringan', () {
      final dioError = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Koneksi timeout. Periksa jaringan Anda.');
      expect(exception.statusCode, isNull);
    });

    test('receiveTimeout → pesan server tidak merespons', () {
      final dioError = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Server tidak merespons. Coba lagi nanti.');
      expect(exception.statusCode, isNull);
    });

    test('connectionError → pesan tidak dapat terhubung', () {
      final dioError = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/test'),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Tidak dapat terhubung ke server.');
      expect(exception.statusCode, isNull);
    });

    test('badResponse dengan message di body → gunakan message dari backend', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'success': false, 'message': 'Password salah'},
        ),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Password salah');
      expect(exception.statusCode, 401);
      expect(exception.data, isA<Map<String, dynamic>>());
    });

    test('badResponse tanpa message → map berdasarkan status code 400', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: 'Bad Request',
        ),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Permintaan tidak valid.');
      expect(exception.statusCode, 400);
    });

    test('badResponse tanpa message → map berdasarkan status code 401', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: null,
        ),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Sesi telah berakhir. Silakan login kembali.');
      expect(exception.statusCode, 401);
    });

    test('badResponse tanpa message → map berdasarkan status code 403', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 403,
          data: null,
        ),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Anda tidak memiliki akses.');
    });

    test('badResponse tanpa message → map berdasarkan status code 404', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
          data: null,
        ),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Data tidak ditemukan.');
    });

    test('badResponse tanpa message → map berdasarkan status code 500', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
          data: null,
        ),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Terjadi kesalahan pada server.');
    });

    test('badResponse tanpa message → status code tidak dikenal → pesan default', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 502,
          data: null,
        ),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Terjadi kesalahan. Coba lagi nanti.');
    });

    test('DioExceptionType lain (cancel, unknown) → pesan default', () {
      final dioError = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
      );

      final exception = AppException.fromDioError(dioError);

      expect(exception.message, 'Terjadi kesalahan. Coba lagi nanti.');
    });

    test('toString() mengembalikan message', () {
      const exception = AppException(message: 'Test error');

      expect(exception.toString(), 'Test error');
    });
  });
}
