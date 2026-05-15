---
inclusion: fileMatch
fileMatchPattern: "**/{api_client,api_endpoints,auth_provider,persona_provider,session_provider,app_exception}*.dart"
---

# Backend API Reference (untuk file yang berkomunikasi dengan backend)

## 📡 Source of Truth: Live Swagger Spec

Dokumentasi API paling lengkap dan selalu up-to-date ada di backend yang sedang jalan:

- **Swagger UI** (bisa dibrowse): `http://localhost:5000/api/docs`
- **Raw OpenAPI 3.0 JSON** (bisa di-fetch): `http://localhost:5000/api/docs.json`

> **Instruksi untuk AI Agent**: Jika butuh detail endpoint yang tidak tercakup di file ini (misalnya exact request/response schema, query params opsional, atau status code edge case), **fetch langsung** dari `http://localhost:5000/api/docs.json` menggunakan web_fetch tool. Swagger spec adalah sumber kebenaran tertinggi — file ini hanya ringkasan.

---

## Response Envelope (SEMUA endpoint)

```jsonc
// Sukses
{ "success": true, "message": "...", "data": <payload> }

// Sukses list (paginated)
{ "success": true, "message": "...", "data": [...], "meta": { "total": 50, "page": 1, "limit": 10, "totalPages": 5 } }

// Error umum
{ "success": false, "message": "..." }

// Validation error (Zod)
{ "success": false, "message": "Validation error", "errors": [{ "field": "email", "message": "Invalid email format" }] }
```

## Endpoint Reference Lengkap

### Auth (`/api/auth/*`) — Rate limited: 10 req / 15 min per IP

| Method | Path | Body | Sukses | Response `data` |
|--------|------|------|--------|-----------------|
| POST | `/api/auth/register` | `{ name, email, password }` | 201 | `{ id, name, email, role, points, avatarUrl, createdAt }` |
| POST | `/api/auth/login` | `{ email, password }` | 200 | `{ accessToken, refreshToken, user: {...} }` |
| POST | `/api/auth/refresh` | `{ refreshToken }` | 200 | `{ accessToken, refreshToken }` |
| POST | `/api/auth/logout` | `{ refreshToken }` | 200 | — (Bearer required) |
| POST | `/api/auth/forgot-password` | `{ email }` | 200 | — |
| POST | `/api/auth/verify-otp` | `{ email, code }` | 200 | — (`code` = 6 digit string) |
| POST | `/api/auth/reset-password` | `{ email, code, newPassword }` | 200 | — |

### Profile (`/api/me/*`)

| Method | Path | Content-Type | Body | Sukses |
|--------|------|--------------|------|--------|
| GET | `/api/me` | — | — | 200 → `{ id, name, email, role, points, avatarUrl, createdAt }` |
| PATCH | `/api/me` | **multipart/form-data** | `name?`, `image?` (field HARUS `image`) | 200 |
| PATCH | `/api/me/password` | application/json | `{ oldPassword, newPassword }` | 200 |

### Persona (`/api/personas/*`)

| Method | Path | Query/Body | Sukses |
|--------|------|------------|--------|
| GET | `/api/personas` | `?page=1&limit=10` | 200 → `data: Persona[]` + `meta` |
| GET | `/api/personas/:id` | — | 200 → Persona detail |
| POST | `/api/personas/:id/rate` | `{ type: "UP" \| "DOWN" \| "NONE" }` | 200 |

### Session (`/api/sessions/*`)

| Method | Path | Body/Query | Sukses | Response `data` |
|--------|------|------------|--------|-----------------|
| POST | `/api/sessions` | `{ personaId }` | **201** | Session object (TANPA persona) |
| GET | `/api/sessions` | `?status=active\|completed&page=1&limit=10` | 200 | Session[] + meta |
| GET | `/api/sessions/:id` | — | 200 | Session + `persona` object |
| GET | `/api/sessions/:id/messages` | `?page=1&limit=50` | 200 | Message[] (ASC) + meta |
| POST | `/api/sessions/:id/messages` | `{ content }` | **200** (bukan 201!) | `{ userMessage, aiReply }` |
| PATCH | `/api/sessions/:id/complete` | — (no body) | 200 | `{ session, scoreDelta, newPoints, summary }` |
| DELETE | `/api/sessions/:id` | — | 200 | Hanya session `active` |

## Validasi Server (Zod)

- `name`: min 1 char, trimmed
- `email`: valid format, lowercased
- `password` / `newPassword`: min 8 char
- `code` (OTP): exactly 6 chars
- `content` (message): min 1 char after trim
- `type` (rating): enum "UP" | "DOWN" | "NONE"

## JWT & Token

- `accessToken`: HS256, 15 menit
- `refreshToken`: random 64-byte hex, 7 hari, single-use rotation
- Header: `Authorization: Bearer <accessToken>`
- Refresh: POST `/api/auth/refresh` → token lama dihapus, baru dikeluarkan

## Error Messages Eksak (Gunakan langsung di SnackBar)

```
"Email already registered" (409)
"User tidak ditemukan" (401)
"Password salah" (401)
"Refresh token tidak valid" (401)
"Refresh token expired" (401)
"Email tidak ditemukan" (404)
"OTP tidak valid" (400)
"OTP expired" (400)
"OTP sudah digunakan" (400)
"Password lama salah" (401 — bukan 400!)
"Persona tidak aktif" (400)
"Persona tidak ditemukan" (404)
"Sesi sudah selesai" (400 untuk messages, 409 untuk complete)
"Sesi yang sudah selesai tidak dapat dihapus karena telah mempengaruhi skor kesehatan kamu." (400)
"Akses ditolak: sesi bukan milik Anda" (403)
"Too many requests, please try again later" (429)
```

## Data Models (dari Prisma schema)

### MessageRole enum: `'user'` | `'model'` (BUKAN 'assistant'!)
### SessionStatus enum: `'active'` | `'completed'`
### RatingType: `'UP'` | `'DOWN'` (API juga terima `'NONE'` untuk hapus)

### Score Rules
- `scoreDelta`: clamped [-20, +20]
- `newPoints`: clamp(currentPoints + scoreDelta, 0, 100)
- `previousPoints` TIDAK ada di response → hitung: `newPoints - scoreDelta`
