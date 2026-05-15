# Implementation Plan

## Overview

Tahap 1 — Fondasi: Setup awal project Flutter SiniCerita, termasuk inisialisasi project, konfigurasi dependencies, infrastruktur API client (Dio + JWT interceptor), secure token storage, error handling, dan verifikasi konektivitas ke backend via ping endpoint.

## Tasks

- [x] 1. Inisialisasi Project Flutter dan Dependencies
  - [x] 1.1. Run `flutter create` dengan nama project `sinicerita`, kemudian setup `pubspec.yaml` dengan semua dependencies yang diperlukan (dio: ^5.4.0, flutter_secure_storage: ^9.0.0, provider: ^6.1.0, go_router: ^13.0.0, cached_network_image: ^3.3.0, shimmer: ^3.0.0, image_picker: ^1.0.0, pin_code_fields: ^8.0.1, intl: ^0.19.0, equatable: ^2.0.5, collection: ^1.18.0)
  - [x] 1.2. Konfigurasi `android/app/src/main/AndroidManifest.xml` — tambahkan `<uses-permission android:name="android.permission.INTERNET"/>` dan `android:usesCleartextTraffic="true"` pada tag application
  - [x] 1.3. Buat directory structure `lib/core/api/`, `lib/core/errors/`, `lib/core/storage/`, `lib/core/utils/` dan hapus boilerplate code dari `lib/main.dart`
  - Requirements: Requirement 1
  - Dependencies: None
- [x] 2. Implementasi SecureStorage Wrapper
  - [x] 2.1. Buat file `lib/core/storage/secure_storage.dart` dengan class `SecureStorage` yang wrap `FlutterSecureStorage`. Implementasi methods: `getAccessToken()`, `getRefreshToken()`, `saveAccessToken(String)`, `saveRefreshToken(String)`, `clearAll()`. Gunakan keys `'access_token'` dan `'refresh_token'`.
  - Requirements: Requirement 4
  - Dependencies: Task 1
- [x] 3. Implementasi AppException Error Mapping
  - [x] 3.1. Buat file `lib/core/errors/app_exception.dart` dengan class `AppException implements Exception`. Implementasi `factory AppException.fromDioError(DioException error)` yang map: connectionTimeout → 'Koneksi timeout. Periksa jaringan Anda.', receiveTimeout → 'Server tidak merespons. Coba lagi nanti.', connectionError → 'Tidak dapat terhubung ke server.', badResponse dengan message → gunakan message dari response body, badResponse tanpa message → map berdasarkan status code, default → 'Terjadi kesalahan. Coba lagi nanti.'
  - Requirements: Requirement 7
  - Dependencies: Task 1
- [x] 4. Implementasi ApiEndpoints Constants
  - [x] 4.1. Buat file `lib/core/api/api_endpoints.dart` dengan `abstract class ApiEndpoints`. Definisikan: ping = '/ping' (TANPA /api/), semua auth endpoints dengan '/api/auth/' prefix, profile endpoints '/api/me' dan '/api/me/password', persona endpoints dengan static methods untuk path params, session endpoints dengan static methods untuk path params.
  - Requirements: Requirement 5
  - Dependencies: Task 1
- [x] 5. Implementasi ApiResponse Model
  - [x] 5.1. Buat file `lib/core/api/api_response.dart` dengan class `ApiResponse`, `ApiMeta`, dan `ApiFieldError`. Implementasi `factory fromJson(Map<String, dynamic> json)` untuk masing-masing. ApiResponse parse: success (bool), message (String), data (dynamic), meta (ApiMeta?), errors (List<ApiFieldError>?). ApiMeta parse: total, page, limit, totalPages. ApiFieldError parse: field, message.
  - Requirements: Requirement 6
  - Dependencies: Task 1
- [x] 6. Implementasi ApiClient dengan JWT Interceptor
  - [x] 6.1. Buat file `lib/core/api/api_client.dart` dengan class `ApiClient`. Setup Dio instance dengan baseUrl 'http://10.0.2.2:5000', headers Content-Type dan Accept 'application/json', connectTimeout 30 detik, receiveTimeout 30 detik.
  - [x] 6.2. Implementasi `QueuedInterceptorsWrapper` di ApiClient: onRequest — attach access token dari SecureStorage sebagai 'Authorization: Bearer <token>'. onError — jika 401 dan BUKAN endpoint /api/auth/*, attempt refresh dengan POST /api/auth/refresh (refreshToken di body), simpan token baru, retry request. Jika refresh gagal, clearAll tokens.
  - Requirements: Requirement 2, Requirement 3
  - Dependencies: Task 2, Task 3, Task 4, Task 5
- [x] 7. Implementasi Validators Utility
  - [x] 7.1. Buat file `lib/core/utils/validators.dart` dengan class `Validators` (private constructor). Implementasi static methods: validateEmail (cek empty + regex), validatePassword (cek empty + min 8 chars), validateName (cek empty), validateConfirmPassword (cek empty + match). Semua return String? (null = valid, non-null = error message dalam Bahasa Indonesia).
  - Requirements: Requirement 9
  - Dependencies: Task 1
- [x] 8. Setup Main.dart Entry Point
  - [x] 8.1. Update `lib/main.dart` dengan basic MaterialApp setup. Import core dependencies, buat minimal runApp dengan MaterialApp yang menampilkan placeholder screen. Ini akan di-expand di tahap selanjutnya dengan Provider dan GoRouter.
  - Requirements: Requirement 1
  - Dependencies: Task 6, Task 7
- [x] 9. Verifikasi Ping Connectivity
  - [x] 9.1. Tambahkan temporary test di main.dart atau buat simple screen yang memanggil `GET /ping` via ApiClient dan print hasilnya ke console. Verifikasi response `{ success: true, message: "pong" }`. Pastikan ApiClient, endpoint constant, dan network config berfungsi end-to-end.
  - Requirements: Requirement 8
  - Dependencies: Task 8

## Task Dependency Graph

```json
{
  "waves": [
    {"tasks": [1], "description": "Project initialization"},
    {"tasks": [2, 3, 4, 5, 7], "description": "Core components (parallel)"},
    {"tasks": [6], "description": "ApiClient with JWT Interceptor"},
    {"tasks": [8], "description": "Main.dart entry point"},
    {"tasks": [9], "description": "Ping connectivity verification"}
  ]
}
```

## Notes

- Task 1 harus selesai pertama karena semua task lain bergantung pada project structure
- Task 2-5 dan 7 bisa dikerjakan paralel setelah Task 1
- Task 6 membutuhkan semua core components (2-5) selesai
- Task 9 adalah verifikasi end-to-end terakhir
