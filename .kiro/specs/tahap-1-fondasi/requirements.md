# Requirements Document

## Introduction

Tahap 1 — Fondasi: Setup awal project Flutter SiniCerita, termasuk inisialisasi project, konfigurasi dependencies, infrastruktur API client (Dio + JWT interceptor), secure token storage, error handling, dan verifikasi konektivitas ke backend via ping endpoint. Tahap ini membangun pondasi teknis yang akan digunakan oleh semua tahap berikutnya.

## Glossary

- **App**: Aplikasi Flutter SiniCerita yang berjalan di Android Emulator
- **API_Client**: Instance Dio HTTP client yang dikonfigurasi dengan base URL dan interceptor
- **JWT_Interceptor**: QueuedInterceptorsWrapper pada Dio yang menangani auto-refresh access token saat menerima 401 dari non-auth endpoint
- **Secure_Storage**: Wrapper class di atas FlutterSecureStorage untuk menyimpan dan mengambil access token serta refresh token
- **API_Response**: Model wrapper yang merepresentasikan response envelope dari backend `{ success, message, data, meta?, errors? }`
- **AppException**: Class error yang di-mapping dari DioException, berisi message yang bisa ditampilkan ke user
- **Backend**: Express 5 REST API server yang berjalan di host machine (diakses via `10.0.2.2:5000` dari Android Emulator)
- **Access_Token**: JWT short-lived (~15 menit) untuk autentikasi request
- **Refresh_Token**: JWT single-use (7 hari TTL) untuk mendapatkan access token baru

## Requirements

### Requirement 1: Inisialisasi Project Flutter

**User Story:** As a developer, I want to initialize a Flutter project with proper structure, so that I have a clean foundation to build the SiniCerita app.

#### Acceptance Criteria

1. WHEN the project is created, THE App SHALL have a valid `pubspec.yaml` with app name `sinicerita` and all required dependencies pinned to specified versions
2. WHEN the project is created, THE App SHALL have the target directory structure under `lib/core/` with subdirectories `api/`, `errors/`, `storage/`, and `utils/`
3. WHEN the project is built for Android, THE App SHALL have `INTERNET` permission declared in `AndroidManifest.xml`
4. WHEN the project is built for Android targeting HTTP backend, THE App SHALL have `android:usesCleartextTraffic="true"` configured in `AndroidManifest.xml`

### Requirement 2: API Client Configuration

**User Story:** As a developer, I want a configured Dio HTTP client, so that all API calls use consistent base URL, headers, and timeout settings.

#### Acceptance Criteria

1. THE API_Client SHALL use base URL `http://10.0.2.2:5000` for all requests
2. THE API_Client SHALL set default `Content-Type` header to `application/json`
3. THE API_Client SHALL set default `Accept` header to `application/json`
4. WHEN a request is made, THE API_Client SHALL apply a connect timeout of 30 seconds
5. WHEN a request is made, THE API_Client SHALL apply a receive timeout of 30 seconds

### Requirement 3: JWT Interceptor dengan Token Rotation

**User Story:** As a developer, I want automatic token refresh on 401 responses, so that users stay authenticated without manual re-login.

#### Acceptance Criteria

1. WHEN a request receives a 401 response from a non-auth endpoint, THE JWT_Interceptor SHALL attempt to refresh the access token by sending the refresh token in the request body to `/api/auth/refresh`
2. WHEN a token refresh succeeds, THE JWT_Interceptor SHALL store the new access token and new refresh token in Secure_Storage
3. WHEN a token refresh succeeds, THE JWT_Interceptor SHALL retry the original failed request with the new access token
4. IF a token refresh fails, THEN THE JWT_Interceptor SHALL clear all stored tokens from Secure_Storage
5. WHEN a request is made to any `/api/auth/*` endpoint, THE JWT_Interceptor SHALL NOT attempt token refresh on 401 responses
6. WHEN an access token exists in Secure_Storage, THE JWT_Interceptor SHALL attach it as `Authorization: Bearer <token>` header to outgoing requests
7. WHILE a token refresh is in progress, THE JWT_Interceptor SHALL queue subsequent 401 requests and resolve them after refresh completes (using QueuedInterceptorsWrapper)

### Requirement 4: Secure Token Storage

**User Story:** As a developer, I want tokens stored securely on device, so that user credentials are protected from unauthorized access.

#### Acceptance Criteria

1. THE Secure_Storage SHALL use FlutterSecureStorage as the underlying storage mechanism
2. WHEN storing an access token, THE Secure_Storage SHALL persist it with a consistent key identifier
3. WHEN storing a refresh token, THE Secure_Storage SHALL persist it with a consistent key identifier
4. WHEN reading a token, THE Secure_Storage SHALL return null if no token exists for the given key
5. WHEN clearing tokens, THE Secure_Storage SHALL remove both access token and refresh token from storage

### Requirement 5: API Endpoints Constants

**User Story:** As a developer, I want all API endpoint URLs defined as constants, so that URL management is centralized and consistent.

#### Acceptance Criteria

1. THE API_Endpoints SHALL define the ping endpoint as `/ping` (without `/api/` prefix)
2. THE API_Endpoints SHALL define all auth endpoints with `/api/auth/` prefix (register, login, refresh, logout, forgot-password, verify-otp, reset-password)
3. THE API_Endpoints SHALL define all profile endpoints with `/api/` prefix (`/api/me`, `/api/me/password`)
4. THE API_Endpoints SHALL define all persona endpoints with `/api/` prefix (`/api/personas`, `/api/personas/:id`, `/api/personas/:id/rate`)
5. THE API_Endpoints SHALL define all session endpoints with `/api/` prefix (`/api/sessions`, `/api/sessions/:id`, `/api/sessions/:id/messages`, `/api/sessions/:id/complete`)

### Requirement 6: API Response Wrapper

**User Story:** As a developer, I want a typed response model, so that I can consistently parse backend responses across the app.

#### Acceptance Criteria

1. THE API_Response SHALL parse the `success` field as a boolean from the response envelope
2. THE API_Response SHALL parse the `message` field as a string from the response envelope
3. THE API_Response SHALL parse the `data` field as a dynamic value from the response envelope
4. THE API_Response SHALL parse the optional `meta` field containing pagination information (total, page, limit, totalPages)
5. THE API_Response SHALL parse the optional `errors` field as a list of validation error objects (field, message)

### Requirement 7: Error Mapping (DioException → AppException)

**User Story:** As a developer, I want DioExceptions mapped to user-friendly AppExceptions, so that error messages are consistent and displayable in the UI.

#### Acceptance Criteria

1. WHEN a DioException with type `connectionTimeout` occurs, THE AppException SHALL produce message "Koneksi timeout. Periksa jaringan Anda."
2. WHEN a DioException with type `receiveTimeout` occurs, THE AppException SHALL produce message "Server tidak merespons. Coba lagi nanti."
3. WHEN a DioException with type `connectionError` occurs, THE AppException SHALL produce message "Tidak dapat terhubung ke server."
4. WHEN a DioException with a response body containing `message` field occurs, THE AppException SHALL use that message directly (preserving backend error messages)
5. WHEN a DioException with type `badResponse` occurs without a parseable message, THE AppException SHALL produce a generic message based on status code
6. IF an unknown error occurs, THEN THE AppException SHALL produce message "Terjadi kesalahan. Coba lagi nanti."

### Requirement 8: Ping Connectivity Test

**User Story:** As a developer, I want to verify backend connectivity via a ping endpoint, so that I can confirm the API client is properly configured.

#### Acceptance Criteria

1. WHEN a GET request is sent to `/ping`, THE API_Client SHALL receive a response with `{ success: true, message: "pong" }`
2. WHEN the ping request succeeds, THE App SHALL confirm that the base URL and network configuration are correct
3. IF the ping request fails due to network error, THEN THE AppException SHALL map it to an appropriate connectivity error message

### Requirement 9: Form Validation Helpers

**User Story:** As a developer, I want reusable form validation functions, so that client-side validation is consistent across all screens.

#### Acceptance Criteria

1. WHEN validating an email field, THE Validators SHALL return an error message if the input is empty or not a valid email format
2. WHEN validating a password field, THE Validators SHALL return an error message if the input is less than 8 characters
3. WHEN validating a name field, THE Validators SHALL return an error message if the input is empty
4. WHEN validating a confirm password field, THE Validators SHALL return an error message if it does not match the original password

