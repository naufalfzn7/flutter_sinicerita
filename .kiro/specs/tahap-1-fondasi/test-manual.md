# Test Manual — Tahap 1: Fondasi

## Prasyarat

- Backend sudah jalan (`npm run dev` di folder backend, port 5000)
- Android Emulator sudah running
- App sudah di-install ke emulator (`flutter run`)

---

## Test 1: Flutter Analyze Clean

**Langkah:**
```bash
flutter analyze
```

**Expected:** `No issues found!`

**Hasil Test:**
`$ flutter analyze
Analyzing flutter_sinicerita...                                         
No issues found! (ran in 1.3s)`

**Status:** ☐ PASS / ☐ FAIL

---

## Test 2: Unit Tests Pass

**Langkah:**
```bash
flutter test
```

**Expected:** Semua test pass (47+ tests), tidak ada failure.

**Hasil Test:**
`$ flutter test
00:01 +47: All tests passed! `

**Status:** ☐ PASS / ☐ FAIL

---

## Test 3: App Launch Tanpa Crash

**Langkah:**
1. Jalankan `flutter run` di emulator
2. Tunggu app terbuka

**Expected:**
- App terbuka tanpa crash
- Tampil screen "Ping Test" dengan AppBar "SiniCerita"
- Ada tombol "Panggil GET /ping"
- Teks "Belum ditest" terlihat

**Hasil Test:**:
`I/flutter ( 9130): === PING RESPONSE ===
I/flutter ( 9130): Status Code: 200
I/flutter ( 9130): success: true
I/flutter ( 9130): message: pong
I/flutter ( 9130): Full data: {success: true, message: pong}
I/flutter ( 9130): =====================

dan sudah bisa dibuka belum di test sudah telihat`

**Status:** ☐ PASS / ☐ FAIL

---

## Test 4: Ping Berhasil (Backend Hidup)

**Prasyarat:** Backend jalan di port 5000

**Langkah:**
1. Buka app di emulator
2. Tekan tombol "Panggil GET /ping"

**Expected:**
- Tombol disabled saat loading (ada spinner)
- Setelah selesai, tampil: `✅ Berhasil! Response: { success: true, message: "pong" }`
- Di console (logcat/debug console) terlihat:
  ```
  === PING RESPONSE ===
  Status Code: 200
  success: true
  message: pong
  Full data: {success: true, message: pong}
  =====================
  ```

  **Hasil Test:**:
`I/flutter ( 9130): === PING RESPONSE ===
I/flutter ( 9130): Status Code: 200
I/flutter ( 9130): success: true
I/flutter ( 9130): message: pong
I/flutter ( 9130): Full data: {success: true, message: pong}
I/flutter ( 9130): =====================`

**Status:** ☐ PASS / ☐ FAIL

---

## Test 5: Ping Gagal (Backend Mati)

**Prasyarat:** Backend TIDAK jalan (matikan dulu)

**Langkah:**
1. Matikan backend (stop `npm run dev`)
2. Buka app di emulator
3. Tekan tombol "Panggil GET /ping"

**Expected:**
- Tombol disabled saat loading
- Setelah timeout/gagal, tampil: `❌ Gagal: ...` dengan pesan error koneksi
- Di console terlihat error log

  **Hasil Test:**:
`I/flutter ( 9130): === PING ERROR ===
I/flutter ( 9130): Error: DioException [connection error]: The connection errored: Connection refused This indicates an error which most likely cannot be solved by the library.
I/flutter ( 9130): Error: SocketException: Connection refused (OS Error: Connection refused, errno = 111), address = 10.0.2.2, port = 47634
I/flutter ( 9130): ==================`

**Status:** ☐ PASS / ☐ FAIL

---

## Test 6: Double-Tap Prevention

**Langkah:**
1. Tekan tombol "Panggil GET /ping"
2. Segera tekan lagi sebelum response kembali

**Expected:**
- Tombol disabled (greyed out) saat request sedang berjalan
- Tidak ada request ganda yang terkirim

**Status:** ☐ PASS / ☐ FAIL

SUDAH BENAR

---

## Test 7: Verifikasi File Structure

**Langkah:**
Cek bahwa file-file berikut ada dan tidak kosong:

```
lib/core/api/api_client.dart
lib/core/api/api_endpoints.dart
lib/core/api/api_response.dart
lib/core/errors/app_exception.dart
lib/core/storage/secure_storage.dart
lib/core/utils/validators.dart
lib/screens/ping_test_screen.dart
lib/main.dart
```

**Expected:** Semua file ada dan berisi implementasi yang benar.

**Status:** ☐ PASS / ☐ FAIL

---

## Test 8: AndroidManifest Konfigurasi

**Langkah:**
Buka `android/app/src/main/AndroidManifest.xml` dan verifikasi:

**Expected:**
- Ada `<uses-permission android:name="android.permission.INTERNET"/>`
- Ada `android:usesCleartextTraffic="true"` di tag `<application>`

**Status:** ☐ PASS / ☐ FAIL

---

## Test 9: Dependencies Terpasang

**Langkah:**
```bash
flutter pub deps
```

**Expected:** Semua dependency berikut terinstall:
- dio ^5.4.0
- flutter_secure_storage ^9.0.0
- provider ^6.1.0
- go_router ^13.0.0
- cached_network_image ^3.3.0
- shimmer ^3.0.0
- image_picker ^1.0.0
- pin_code_fields ^8.0.1
- intl ^0.19.0
- equatable ^2.0.5
- collection ^1.18.0

**Status:** ☐ PASS / ☐ FAIL

---

## Ringkasan

| # | Test | Status |
|---|------|--------|
| 1 | Flutter Analyze Clean | ☐ |
| 2 | Unit Tests Pass | ☐ |
| 3 | App Launch Tanpa Crash | ☐ |
| 4 | Ping Berhasil (Backend Hidup) | ☐ |
| 5 | Ping Gagal (Backend Mati) | ☐ |
| 6 | Double-Tap Prevention | ☐ |
| 7 | Verifikasi File Structure | ☐ |
| 8 | AndroidManifest Konfigurasi | ☐ |
| 9 | Dependencies Terpasang | ☐ |

---

## Kriteria Lulus

**SEMUA 9 test harus PASS** sebelum lanjut ke Tahap 2 (Auth).

Konfirmasi dengan: **"Tahap 1 PASS semua"**
