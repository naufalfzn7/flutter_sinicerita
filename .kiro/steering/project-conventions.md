---
inclusion: always
---

# SiniCerita Flutter — Project Conventions

## Bahasa & Naming

- Semua teks UI dalam **Bahasa Indonesia**
- Nama file: `snake_case.dart`
- Nama class: `PascalCase`
- Nama variabel/method: `camelCase`
- Folder: `snake_case`

## Architecture Rules

- **Provider pattern**: Satu `ChangeNotifier` per domain (auth, persona, session)
- **Tidak boleh** panggil API langsung dari widget — selalu lewat Provider
- **Model class** harus punya `factory fromJson(Map<String, dynamic> json)`
- **Error handling**: Tangkap `DioException` di Provider, convert ke `AppException`, expose `errorMessage` ke UI

## API Communication

- Base URL: `http://10.0.2.2:5000` (Android Emulator default)
- **WAJIB prefix `/api/`** untuk semua endpoint KECUALI `/ping`
- Response parsing: `response.data['data']` — BUKAN `response.data`
- List endpoint punya `meta`: `{ total, page, limit, totalPages }`
- Validation error punya `errors`: `[{ field, message }]`

## Token & Auth

- Simpan di `FlutterSecureStorage` (BUKAN SharedPreferences)
- JWT interceptor di Dio: auto-refresh saat 401 dari non-auth endpoint
- Refresh token = single-use rotation (simpan token baru setelah refresh)
- Gagal refresh → clear tokens → redirect ke login

## UI Standards

- Loading state: `Shimmer` skeleton placeholder (bukan spinner polos)
- Error: `SnackBar` merah dengan pesan eksak dari backend
- Success: `SnackBar` hijau
- Form validation: client-side dulu, baru hit API
- Tombol disabled saat loading (prevent double-tap)
- Pull-to-refresh di semua list screen

## File Organization

```
lib/core/     → Infrastructure (API, storage, errors, utils)
lib/models/   → Data classes (fromJson, immutable)
lib/providers/ → Business logic + state (ChangeNotifier)
lib/screens/  → Full-page widgets (satu file per screen)
lib/widgets/  → Reusable UI components
```

## Dependencies (Pinned)

- `dio: ^5.4.0` — HTTP client
- `flutter_secure_storage: ^9.0.0` — Token storage
- `provider: ^6.1.0` — State management
- `go_router: ^13.0.0` — Navigation
- `cached_network_image: ^3.3.0` — Image caching
- `shimmer: ^3.0.0` — Loading skeleton
- `image_picker: ^1.0.0` — Avatar upload
- `pin_code_fields: ^8.0.1` — OTP input
- `intl: ^0.19.0` — Date formatting
- `equatable: ^2.0.5` — Value equality
- `collection: ^1.18.0` — firstWhereOrNull

## Testing Protocol

- Setiap tahap punya Manual Emulator Test Guide
- SEMUA skenario test harus PASS sebelum lanjut tahap berikutnya
- Konfirmasi dengan: "Tahap X PASS semua"
