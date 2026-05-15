---
inclusion: always
---

# Common Pitfalls — Hindari Bug Ini!

## 🔥 #1: Lupa Prefix `/api/`

```dart
// ❌ SALAH — akan 404
static const String login = '/auth/login';

// ✅ BENAR
static const String login = '/api/auth/login';
```

Satu-satunya endpoint TANPA `/api/` adalah `/ping`.

## 🔥 #2: Response Parsing

```dart
// ❌ SALAH — response.data adalah Map envelope
final user = UserModel.fromJson(response.data);

// ✅ BENAR — ambil payload dari dalam envelope
final user = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
```

## 🔥 #3: MessageRole Bukan 'assistant'

```dart
// ❌ SALAH
bool get isAI => role == 'assistant';

// ✅ BENAR — backend pakai 'model' (dari Gemini SDK)
bool get isModel => role == 'model';
```

## 🔥 #4: Upload Avatar Field Name

```dart
// ❌ SALAH
'avatar': await MultipartFile.fromFile(...)
'file': await MultipartFile.fromFile(...)

// ✅ BENAR — backend expect field name 'image'
'image': await MultipartFile.fromFile(...)
```

## 🔥 #5: Status Code yang Tidak Standar

| Endpoint | Status | Catatan |
|----------|--------|---------|
| `POST /sessions/:id/messages` | **200** | Bukan 201! |
| `PATCH /me/password` (wrong old) | **401** | Bukan 400! |
| `PATCH /sessions/:id/complete` (already done) | **409** | Bukan 400! |

## 🔥 #6: Refresh Token di Body (Bukan Header)

```dart
// ❌ SALAH — refresh token bukan di Authorization header
headers: {'Authorization': 'Bearer $refreshToken'}

// ✅ BENAR — kirim di body
data: {'refreshToken': refreshToken}
```

## 🔥 #7: Interceptor Loop

Jangan trigger refresh untuk endpoint `/api/auth/*`:
```dart
final isAuthEndpoint = path.contains('/api/auth/');
if (err.response?.statusCode == 401 && !isAuthEndpoint) {
  // baru refresh di sini
}
```

## 🔥 #8: previousPoints Tidak Ada di Response

```dart
// Backend response: { scoreDelta, newPoints, summary }
// previousPoints TIDAK dikirim!

// ✅ Hitung manual:
final previousPoints = newPoints - scoreDelta;
```

## 🔥 #9: Session List Tidak Include Persona Object

`GET /api/sessions` hanya return `personaId` (string).
Untuk tampilkan nama/avatar persona di list, resolve via `personaProvider.getById(session.personaId)`.
Pastikan persona list sudah di-fetch sebelum render HomeScreen.

## 🔥 #10: Android Emulator Network

- Pakai `10.0.2.2` (BUKAN `localhost`) untuk akses host machine
- Tambahkan `android:usesCleartextTraffic="true"` di AndroidManifest.xml
- Tambahkan `<uses-permission android:name="android.permission.INTERNET"/>`

## 💡 Pro Tip: Cek Swagger Kalau Ragu

Jika ada ketidakjelasan soal endpoint (params, response shape, status code), jangan nebak — fetch langsung:

```
http://localhost:5000/api/docs.json   ← Raw OpenAPI spec (JSON)
http://localhost:5000/api/docs        ← Swagger UI (browser)
```

Pastikan backend jalan dulu (`npm run dev` di folder backend, port 5000).
