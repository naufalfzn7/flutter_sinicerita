import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory AppException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const AppException(
          message: 'Koneksi timeout. Periksa jaringan Anda.',
        );

      case DioExceptionType.receiveTimeout:
        return const AppException(
          message: 'Server tidak merespons. Coba lagi nanti.',
        );

      case DioExceptionType.connectionError:
        return const AppException(
          message: 'Tidak dapat terhubung ke server.',
        );

      case DioExceptionType.badResponse:
        final responseData = error.response?.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('message')) {
          return AppException(
            message: responseData['message'] as String,
            statusCode: error.response?.statusCode,
            data: responseData,
          );
        }
        return AppException(
          message: _getMessageFromStatusCode(error.response?.statusCode),
          statusCode: error.response?.statusCode,
        );

      default:
        return const AppException(
          message: 'Terjadi kesalahan. Coba lagi nanti.',
        );
    }
  }

  static String _getMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Permintaan tidak valid.';
      case 401:
        return 'Sesi telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki akses.';
      case 404:
        return 'Data tidak ditemukan.';
      case 409:
        return 'Terjadi konflik data.';
      case 429:
        return 'Terlalu banyak permintaan. Coba lagi nanti.';
      case 500:
        return 'Terjadi kesalahan pada server.';
      default:
        return 'Terjadi kesalahan. Coba lagi nanti.';
    }
  }

  @override
  String toString() => message;
}
