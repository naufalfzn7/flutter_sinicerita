# Requirements Document

## Introduction

Fitur ini menambahkan tampilan detail pada sesi chat yang sudah selesai (completed) di tab "Selesai" pada ChatListScreen. Saat ini, tab "Selesai" hanya menampilkan daftar sesi tanpa informasi detail hasil analisis. Fitur ini memungkinkan user melihat detail lengkap sesi yang sudah selesai — termasuk perubahan skor (scoreDelta), ringkasan analisis AI (analysisSummary), dan perbandingan poin sebelum/sesudah — melalui screen detail yang bisa diakses dari list item sesi selesai.

## Glossary

- **Session_Detail_Screen**: Screen baru yang menampilkan informasi lengkap sesi yang sudah selesai, termasuk skor, analisis AI, dan metadata sesi
- **Score_Delta**: Perubahan skor kesehatan mental yang dihasilkan dari analisis AI terhadap percakapan dalam sesi (range -20 sampai +20)
- **Analysis_Summary**: Ringkasan teks dari analisis AI terhadap percakapan user dalam sesi
- **Health_Points**: Skor kesehatan mental user (range 0–100) yang berubah berdasarkan Score_Delta setiap sesi
- **Session_Provider**: Provider (ChangeNotifier) yang mengelola state sesi chat termasuk fetch, create, delete, dan complete
- **Completed_Session**: Sesi chat dengan status 'completed' yang sudah dianalisis oleh AI dan memiliki Score_Delta serta Analysis_Summary
- **Persona_Provider**: Provider yang mengelola data persona AI termasuk nama dan avatar

## Requirements

### Requirement 1: Navigasi ke Detail Sesi Selesai

**User Story:** Sebagai user, saya ingin bisa mengetuk item sesi selesai di tab "Selesai" untuk melihat detail lengkapnya, sehingga saya bisa mengetahui hasil analisis dari sesi tersebut.

#### Acceptance Criteria

1. WHEN user mengetuk item sesi selesai di tab "Selesai", THE Session_Detail_Screen SHALL ditampilkan melalui GoRouter dengan session ID dari item yang dipilih sebagai path parameter
2. THE Session_Detail_Screen SHALL menerima session ID sebagai parameter navigasi dan menggunakannya untuk mengambil data detail sesi
3. WHEN Session_Detail_Screen dibuka, THE Session_Provider SHALL memanggil GET /api/sessions/:id dan mem-parse hasil dari response.data['data'] menjadi Session_Model yang berisi field persona (object), scoreDelta, analysisSummary, startedAt, dan completedAt
4. WHILE Session_Provider sedang memuat data detail sesi (isLoading bernilai true), THE Session_Detail_Screen SHALL menampilkan loading skeleton (shimmer) sebagai placeholder konten
5. IF request GET /api/sessions/:id gagal karena network error atau server error, THEN THE Session_Detail_Screen SHALL menampilkan pesan error dari backend dalam SnackBar merah dan menampilkan state kosong dengan tombol "Coba Lagi" yang memanggil ulang fetch detail sesi
6. IF request GET /api/sessions/:id mengembalikan status 404 atau 403, THEN THE Session_Detail_Screen SHALL menampilkan pesan error dari backend dalam SnackBar merah dan menavigasi user kembali ke daftar sesi

### Requirement 2: Tampilan Perubahan Skor

**User Story:** Sebagai user, saya ingin melihat perubahan skor kesehatan mental dari sesi yang sudah selesai, sehingga saya bisa memahami dampak percakapan terhadap kondisi mental saya.

#### Acceptance Criteria

1. THE Session_Detail_Screen SHALL menampilkan Score_Delta (range -20 sampai +20) dengan ukuran font minimal 24sp dan color coding: hijau untuk nilai positif (Score_Delta > 0), merah untuk nilai negatif (Score_Delta < 0), abu-abu untuk nol (Score_Delta == 0)
2. THE Session_Detail_Screen SHALL menampilkan prefix "+" untuk Score_Delta positif, prefix "-" untuk Score_Delta negatif (bawaan angka), dan tanpa prefix untuk Score_Delta nol
3. THE Session_Detail_Screen SHALL menampilkan perbandingan poin sebelum dan sesudah sesi dalam format "{previousPoints} poin → {newPoints} poin" di mana kedua nilai berada dalam range 0-100
4. THE Session_Detail_Screen SHALL menghitung previousPoints menggunakan formula: newPoints dikurangi Score_Delta, di mana newPoints dan scoreDelta berasal dari response backend session completion
5. IF scoreDelta bernilai null (sesi belum selesai), THEN THE Session_Detail_Screen SHALL menyembunyikan seluruh komponen perubahan skor (Score_Delta, color coding, dan perbandingan poin)

### Requirement 3: Tampilan Ringkasan Analisis AI

**User Story:** Sebagai user, saya ingin membaca ringkasan analisis AI dari sesi yang sudah selesai, sehingga saya bisa mendapatkan insight tentang percakapan saya.

#### Acceptance Criteria

1. WHILE session status adalah "completed", THE Session_Detail_Screen SHALL menampilkan Analysis_Summary dalam Card widget dengan judul "Analisis AI"
2. IF Analysis_Summary melebihi tinggi area tampil Card, THEN THE Session_Detail_Screen SHALL membuat konten Analysis_Summary dapat di-scroll secara vertikal di dalam Card tersebut
3. IF Analysis_Summary bernilai null, empty string, atau hanya berisi whitespace, THEN THE Session_Detail_Screen SHALL menampilkan teks placeholder "Analisis tidak tersedia" di dalam Card "Analisis AI"
4. WHILE session status adalah "active", THE Session_Detail_Screen SHALL menyembunyikan Card "Analisis AI"

### Requirement 4: Tampilan Metadata Sesi

**User Story:** Sebagai user, saya ingin melihat informasi konteks sesi seperti nama persona dan waktu sesi, sehingga saya bisa mengidentifikasi sesi mana yang sedang saya lihat.

#### Acceptance Criteria

1. THE Session_Detail_Screen SHALL menampilkan nama persona yang di-resolve melalui Persona_Provider menggunakan personaId dari sesi
2. THE Session_Detail_Screen SHALL menampilkan tanggal dan waktu sesi dimulai menggunakan field createdAt dari backend, diformat dengan intl package menggunakan locale 'id_ID' (contoh output: "1 Januari 2024, 14:30")
3. IF sesi memiliki status 'completed', THEN THE Session_Detail_Screen SHALL menampilkan tanggal dan waktu sesi selesai menggunakan field updatedAt dari backend, diformat dengan intl package menggunakan locale 'id_ID' (contoh output: "1 Januari 2024, 15:00")
4. IF sesi memiliki status 'active', THEN THE Session_Detail_Screen SHALL menyembunyikan informasi waktu selesai
5. IF Persona_Provider gagal me-resolve personaId (persona tidak ditemukan atau request gagal), THEN THE Session_Detail_Screen SHALL menampilkan teks fallback sebagai pengganti nama persona

### Requirement 5: Navigasi Kembali dan Lihat Chat

**User Story:** Sebagai user, saya ingin bisa kembali ke daftar sesi atau melihat riwayat chat dari sesi tersebut, sehingga saya bisa navigasi dengan mudah.

#### Acceptance Criteria

1. THE Session_Detail_Screen SHALL menampilkan tombol back di posisi leading AppBar yang memanggil GoRouter pop() untuk kembali ke halaman sebelumnya dalam navigation stack
2. THE Session_Detail_Screen SHALL menampilkan tombol berlabel "Lihat Riwayat Chat" yang terlihat tanpa perlu scroll
3. WHEN user mengetuk tombol "Lihat Riwayat Chat", THE Session_Detail_Screen SHALL menavigasi ke route /chat/:sessionId menggunakan session ID dari sesi yang sedang ditampilkan
4. WHILE ChatScreen menampilkan sesi dengan status "completed", THE ChatScreen SHALL menampilkan seluruh riwayat pesan dalam mode read-only dengan field input pesan disembunyikan atau di-disable sehingga user tidak dapat mengirim pesan baru
5. IF navigasi ke /chat/:sessionId gagal karena sessionId tidak ditemukan, THEN THE System SHALL menampilkan pesan error di SnackBar dan tetap berada di Session_Detail_Screen

### Requirement 6: Penanganan Error

**User Story:** Sebagai user, saya ingin mendapatkan feedback yang jelas jika terjadi error saat memuat detail sesi, sehingga saya tahu apa yang terjadi.

#### Acceptance Criteria

1. IF request GET /api/sessions/:id gagal dengan response dari server (status 4xx/5xx), THEN THE Session_Detail_Screen SHALL menampilkan pesan error dari backend (field `message` dalam response envelope) secara as-is dalam SnackBar merah selama 4 detik
2. IF request GET /api/sessions/:id gagal karena tidak ada koneksi jaringan atau timeout, THEN THE Session_Detail_Screen SHALL menampilkan pesan generik koneksi error dalam SnackBar merah dan menampilkan state error berupa teks pesan error serta tombol berlabel "Coba Lagi" yang saat ditekan akan mengulangi request GET /api/sessions/:id
3. IF sesi tidak ditemukan (response status 404), THEN THE Session_Detail_Screen SHALL menampilkan pesan error dari backend dalam SnackBar merah dan menampilkan state error berupa teks pesan error serta tombol berlabel "Kembali" yang saat ditekan menavigasi user ke halaman daftar sesi
4. IF request GET /api/sessions/:id mengembalikan status 403, THEN THE Session_Detail_Screen SHALL menampilkan pesan "Akses ditolak: sesi bukan milik Anda" dalam SnackBar merah dan menampilkan state error dengan tombol berlabel "Kembali" yang saat ditekan menavigasi user ke halaman daftar sesi

### Requirement 7: Indikator Detail pada List Item Sesi Selesai

**User Story:** Sebagai user, saya ingin melihat indikasi visual pada item sesi selesai di list bahwa ada detail yang bisa dilihat, sehingga saya tahu bahwa item tersebut bisa diketuk untuk informasi lebih lanjut.

#### Acceptance Criteria

1. THE SessionListTile untuk Completed_Session SHALL menampilkan preview Analysis_Summary sebagai subtitle, dipotong maksimal 50 karakter dengan ellipsis ("...") di akhir jika teks melebihi batas tersebut
2. IF Analysis_Summary bernilai null atau string kosong, THEN THE SessionListTile SHALL menampilkan teks placeholder "Analisis tidak tersedia" sebagai subtitle
3. THE SessionListTile untuk Completed_Session SHALL menampilkan Score_Delta dengan format prefix tanda ("+N" untuk positif, "-N" untuk negatif, "0" untuk nol) dan color coding: hijau (green) untuk nilai positif (> 0), merah (red) untuk nilai negatif (< 0), dan abu-abu (grey) untuk nilai nol, ditampilkan di samping status badge
4. THE SessionListTile untuk Completed_Session SHALL menampilkan chevron icon (arrow_forward_ios) di trailing untuk mengindikasikan navigasi ke detail
