# AGENTS.md

<!-- tags: ai-context, flutter, dart, sinicerita, mobile-app -->

> Panduan navigasi untuk AI agent yang bekerja di project Flutter SiniCerita.

## Project Summary

Flutter mobile app untuk SiniCerita — platform kesehatan mental berbasis chatbot AI. User ngobrol dengan persona AI (Google Gemini via backend), sesi dianalisis untuk perubahan emosional (score delta -20 s/d +20), dan health points (0–100) di-track per user.

**Stack**: Flutter 3.x · Dart · Dio · Provider · GoRouter · FlutterSecureStorage

**Backend**: Express 5 REST API (terpisah, dokumentasi di `dokumentasi-backend/`)

## Directory Map (Target)

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart          # Dio instance + JWT interceptor (token rotation)
│   │   ├── api_endpoints.dart       # Semua URL constant (DENGAN /api/ prefix!)
│   │   └── api_response.dart        # Wrapper { success, message, data, meta, errors }
│   ├── errors/
│   │   └── app_exception.dart       # DioException → AppException mapping
│   ├── storage/
│   │   └── secure_storage.dart      # FlutterSecureStorage wrapper (access/refresh token)
│   └── utils/
│       └── validators.dart          # Client-side form validation
│
├── models/
│   ├── user_model.dart              # { id, name, email, role, points, avatarUrl, createdAt }
│   ├── persona_model.dart           # { id, name, description, systemPrompt?, avatarUrl, isActive, upvotes, downvotes }
│   ├── session_model.dart           # { id, userId, personaId, status, scoreDelta?, analysisSummary?, ... }
│   └── message_model.dart           # { id, sessionId, role('user'|'model'), content, createdAt }
│
├── providers/
│   ├── auth_provider.dart           # AuthStatus, login, register, logout, fetchMe, checkAuthStatus
│   ├── persona_provider.dart        # List personas, detail, rating (optimistic update)
│   └── session_provider.dart        # CRUD sessions, messages, complete session
│
├── screens/
│   ├── auth/                        # splash, login, register, forgot_password/
│   ├── main/main_screen.dart        # BottomNavigationBar (Home, Persona, Profil)
│   ├── home/home_screen.dart        # TabBar: Aktif / Selesai (session history)
│   ├── persona/                     # list + detail
│   ├── chat/                        # chat_screen + session_summary_screen
│   └── profile/                     # profile + edit_profile
│
├── widgets/
│   ├── common/                      # loading_overlay, error_snackbar, app_button
│   └── chat/                        # chat_bubble, typing_indicator
│
└── main.dart                        # GoRouter + MultiProvider + MaterialApp.router
```

## Key Patterns & Conventions

- **State management**: Provider (ChangeNotifier) — satu provider per domain (auth, persona, session)
- **HTTP client**: Dio dengan `QueuedInterceptorsWrapper` untuk JWT auto-refresh
- **Token storage**: `flutter_secure_storage` — JANGAN simpan di SharedPreferences
- **Navigation**: `go_router` dengan redirect guard berdasarkan `AuthStatus`
- **Error handling**: `DioException` → `AppException.fromDioError()` → tampilkan `message` di SnackBar
- **Response parsing**: `response.data['data']` (bukan `response.data` langsung)
- **Bahasa UI**: Indonesia (Bahasa Indonesia) untuk semua teks user-facing
- **Pagination**: cursor-based via `?page=N&limit=M`, response punya `meta.totalPages`
- **Optimistic update**: Rating persona di-update lokal dulu, revert jika API gagal
- **Loading state**: Shimmer skeleton (bukan CircularProgressIndicator polos)

## Backend API Quick Reference

**Base URL dev:**
- Android Emulator: `http://10.0.2.2:5000`
- iOS Simulator: `http://localhost:5000`
- Physical Device: `http://<IP-LAN>:5000`

**KRITIS — Prefix `/api/`**: Semua endpoint pakai `/api/` KECUALI `/ping`.

| Domain | Endpoints |
|--------|-----------|
| Auth | `/api/auth/register`, `/login`, `/refresh`, `/logout`, `/forgot-password`, `/verify-otp`, `/reset-password` |
| Profile | `/api/me` (GET/PATCH multipart), `/api/me/password` (PATCH JSON) |
| Persona | `/api/personas` (GET paginated), `/api/personas/:id` (GET), `/api/personas/:id/rate` (POST) |
| Session | `/api/sessions` (POST/GET), `/api/sessions/:id` (GET/DELETE), `/api/sessions/:id/messages` (GET/POST), `/api/sessions/:id/complete` (PATCH) |

**Response envelope**: `{ success: bool, message: string, data: any, meta?: {...}, errors?: [...] }`

## Implementation Stages

| Tahap | Fokus | Endpoint Utama |
|-------|-------|----------------|
| 1 | Fondasi: project setup, Dio, interceptor, ping test | `GET /ping` |
| 2 | Auth: register, login, token persistence | `POST /auth/register`, `/login`, `GET /me` |
| 3 | Forgot password & OTP | `/forgot-password`, `/verify-otp`, `/reset-password` |
| 4 | Main nav & profil | `GET/PATCH /me`, `PATCH /me/password`, logout |
| 5 | Persona list & rating | `GET /personas`, `/personas/:id`, `/personas/:id/rate` |
| 6 | Chat room (core) | `POST /sessions`, `GET/POST /sessions/:id/messages` |
| 7 | Session completion & scoring | `PATCH /sessions/:id/complete` |
| 8 | Session history & delete | `GET /sessions`, `DELETE /sessions/:id` |
| 9 | Polish: token rotation, error handling, skeleton, animation | Full E2E |

## Documentation References

- **Implementation plan lengkap**: `flutter-implementation.md` (di root workspace)
- **Backend docs**: `dokumentasi-backend/` folder:
  - `AGENTS.md` — backend agent guide
  - `interfaces.md` — API endpoint reference lengkap
  - `data_models.md` — database schema & relationships
  - `workflows.md` — sequence diagrams semua flow
  - `architecture.md` — system design backend

## Error Messages dari Backend (Eksak)

| Endpoint | Status | Message |
|----------|--------|---------|
| register | 409 | "Email already registered" |
| login | 401 | "User tidak ditemukan" / "Password salah" |
| refresh | 401 | "Refresh token tidak valid" / "Refresh token expired" |
| forgot-password | 404 | "Email tidak ditemukan" |
| verify-otp | 400 | "OTP tidak valid" / "OTP expired" / "OTP sudah digunakan" |
| me/password | 401 | "Password lama salah" |
| sessions (create) | 400/404 | "Persona tidak aktif" / "Persona tidak ditemukan" |
| sessions/messages | 400 | "Sesi sudah selesai" |
| sessions/complete | 409 | "Sesi sudah selesai" |
| sessions (delete) | 400 | "Sesi yang sudah selesai tidak dapat dihapus..." |
| generic | 403 | "Akses ditolak: sesi bukan milik Anda" |

## Live API Documentation (Source of Truth)

Jika butuh referensi endpoint yang lebih lengkap dari ringkasan di file ini, **langsung cek Swagger spec backend**:

- **Swagger UI** (browsable): `http://localhost:5000/api/docs`
- **Raw OpenAPI JSON** (fetchable): `http://localhost:5000/api/docs.json`

> Swagger spec adalah sumber kebenaran tertinggi untuk request/response schema, query params, status codes, dan edge cases. Dokumentasi di file ini dan steering files adalah ringkasan untuk quick reference.

**Cara pakai untuk AI Agent:**
1. Jika ragu tentang detail endpoint → fetch `http://localhost:5000/api/docs.json`
2. Pastikan backend sedang jalan (`npm run dev` di folder backend) sebelum fetch
3. Jika backend tidak jalan, gunakan referensi di `dokumentasi-backend/interfaces.md` sebagai fallback

## Custom Instructions

- Selalu ikuti tahap implementasi di `flutter-implementation.md` secara berurutan
- Jangan skip tahap — setiap tahap punya test checklist yang harus PASS
- Gunakan pesan error eksak dari backend untuk SnackBar (jangan terjemahkan/ubah)
- MessageRole adalah `'user'` dan `'model'` (BUKAN `'assistant'`)
- `PATCH /api/me` menggunakan `multipart/form-data` dengan field name `image` (bukan `avatar`/`file`)
- `PATCH /api/me/password` return **401** untuk password lama salah (bukan 400)
- `DELETE /api/sessions/:id` hanya untuk session `active` — completed return 400
- `PATCH /api/sessions/:id/complete` return **409** jika sudah completed (bukan 400)
- Tidak ada endpoint `PUT` di backend — selalu pakai `PATCH`
- `POST /api/sessions/:id/messages` return status **200** (bukan 201)
