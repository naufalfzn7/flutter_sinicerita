# Manual Test Guide — Tahap 4: Main Navigation & Profile

> **Tipe Test**: Blackbox Testing di Android Emulator
> **Prasyarat**: Backend berjalan (`npm run dev` di folder backend, port 5000), user sudah terdaftar dan bisa login dari tahap sebelumnya.
> **Catatan**: Pastikan `android:usesCleartextTraffic="true"` dan permission INTERNET sudah ada di AndroidManifest.xml.

---

## A. Bottom Navigation Shell

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| A1 | Tab default setelah login | 1. Login dengan akun valid<br>2. Perhatikan tab yang aktif | Tab "Beranda" aktif (highlighted), konten HomeScreen ditampilkan | ☐ |
| A2 | Navigasi ke tab Chat | 1. Dari Beranda, tap tab "Chat" | Tab Chat aktif (icon + label berubah warna), konten ChatScreen ditampilkan | ☐ |
| A3 | Navigasi ke tab Persona | 1. Tap tab "Persona" | Tab Persona aktif, konten PersonaScreen (grid) ditampilkan | ☐ |
| A4 | Navigasi ke tab Profil | 1. Tap tab "Profil" | Tab Profil aktif, konten ProfileScreen ditampilkan | ☐ |
| A5 | State preservation antar tab | 1. Di tab Persona, scroll ke bawah beberapa item<br>2. Pindah ke tab Beranda<br>3. Kembali ke tab Persona | Scroll position tetap di posisi sebelumnya, data tidak di-reload dari awal | ☐ |
| A6 | Bottom nav selalu terlihat | 1. Di setiap tab, scroll konten ke bawah | BottomNavigationBar tetap terlihat di bawah layar, tidak tertutup konten | ☐ |
| A7 | Highlight tab aktif | 1. Perhatikan warna icon dan label tab yang aktif vs yang tidak aktif | Tab aktif punya warna berbeda (lebih terang/bold) dibanding tab non-aktif | ☐ |

---

## B. Home Dashboard — Greeting

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| B1 | Greeting pagi (00:00–10:59) | 1. Set waktu emulator ke jam 08:00 (Settings > Date & Time > Set time)<br>2. Buka app, login | Tampil "Selamat pagi, {nama user}" | ☐ |
| B2 | Greeting siang (11:00–14:59) | 1. Set waktu emulator ke jam 12:00<br>2. Buka app / hot restart | Tampil "Selamat siang, {nama user}" | ☐ |
| B3 | Greeting sore (15:00–17:59) | 1. Set waktu emulator ke jam 16:00<br>2. Buka app / hot restart | Tampil "Selamat sore, {nama user}" | ☐ |
| B4 | Greeting malam (18:00–23:59) | 1. Set waktu emulator ke jam 20:00<br>2. Buka app / hot restart | Tampil "Selamat malam, {nama user}" | ☐ |
| B5 | Nama panjang di-truncate | 1. Edit nama user di backend/DB menjadi > 30 karakter<br>2. Login dan lihat greeting | Nama ditampilkan max 30 karakter + "..." | ☐ |

---

## C. Home Dashboard — Score Card

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| C1 | Score rendah (0–39) | 1. Set points user ke 25 di backend/DB<br>2. Login, lihat score card di Beranda | Circular progress 25%, angka "25" di tengah, warna merah, teks "Kamu butuh perhatian lebih, yuk cerita" | ☐ |
| C2 | Score sedang (40–69) | 1. Set points user ke 55<br>2. Refresh Beranda | Circular progress 55%, angka "55", warna kuning, teks "Keadaanmu cukup stabil, tetap semangat" | ☐ |
| C3 | Score tinggi (70–100) | 1. Set points user ke 85<br>2. Refresh Beranda | Circular progress 85%, angka "85", warna hijau, teks "Keadaanmu baik, pertahankan ya!" | ☐ |
| C4 | Shimmer saat loading | 1. Throttle network di emulator (slow connection)<br>2. Buka Beranda | Shimmer skeleton placeholder muncul sebelum data tampil | ☐ |

---

## D. Home Dashboard — Session Summary Cards

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| D1 | Summary cards tampil benar | 1. Pastikan user punya 2 sesi aktif, 1 sesi selesai, dan ada 5 persona di DB<br>2. Login, lihat Beranda | Tampil 3 card: "Sesi Aktif: 2", "Sesi Selesai: 1", "Persona Tersedia: 5" | ☐ |
| D2 | Summary cards saat data kosong | 1. User baru tanpa sesi<br>2. Login, lihat Beranda | Tampil "Sesi Aktif: 0", "Sesi Selesai: 0", "Persona Tersedia: {jumlah}" | ☐ |
| D3 | Pull-to-refresh update summary | 1. Di Beranda, catat angka summary<br>2. Buat sesi baru via tab lain<br>3. Kembali ke Beranda, pull-to-refresh | Angka "Sesi Aktif" bertambah 1 | ☐ |
| D4 | Error fetch menampilkan 0 | 1. Matikan backend<br>2. Buka Beranda | Summary cards tampil angka 0, muncul SnackBar merah dengan pesan error | ☐ |

---

## E. Home Dashboard — Quick Action & Daily Tips

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| E1 | Tombol "Mulai Cerita" | 1. Di Beranda, tap tombol "Mulai Cerita" | Tab aktif berpindah ke tab Persona | ☐ |
| E2 | Daily tip tampil | 1. Lihat Beranda | Ada card tips kesehatan mental dengan teks yang bermakna | ☐ |
| E3 | Daily tip konsisten seharian | 1. Catat teks tip<br>2. Tutup app, buka lagi | Teks tip sama persis (tidak berubah dalam hari yang sama) | ☐ |
| E4 | Daily tip berubah keesokan hari | 1. Catat teks tip hari ini<br>2. Ubah tanggal emulator ke besok<br>3. Buka app | Teks tip berbeda dari hari sebelumnya | ☐ |

---

## F. Chat Tab — Session List

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| F1 | TabBar Aktif/Selesai | 1. Tap tab "Chat" di bottom nav | Tampil TabBar dengan 2 tab: "Aktif" (default selected) dan "Selesai" | ☐ |
| F2 | List sesi aktif | 1. Pastikan ada sesi aktif<br>2. Lihat tab "Aktif" | Tampil list sesi dengan: nama persona, preview pesan (max 50 char), waktu relatif, badge "Aktif" | ☐ |
| F3 | List sesi selesai | 1. Pastikan ada sesi completed<br>2. Tap tab "Selesai" | Tampil list sesi dengan: nama persona, preview pesan, waktu relatif, badge "Selesai", score delta (misal "+5" atau "-3") | ☐ |
| F4 | Urutan sesi aktif | 1. Buat beberapa sesi aktif di waktu berbeda<br>2. Lihat tab Aktif | Sesi diurutkan dari yang paling baru di-update (terbaru di atas) | ☐ |
| F5 | Urutan sesi selesai | 1. Complete beberapa sesi di waktu berbeda<br>2. Lihat tab Selesai | Sesi diurutkan dari yang paling baru di-complete (terbaru di atas) | ☐ |
| F6 | Tap sesi aktif | 1. Tap salah satu sesi aktif | Navigasi ke chat screen untuk sesi tersebut | ☐ |
| F7 | Tap sesi selesai | 1. Tap salah satu sesi selesai | Navigasi ke chat view (read-only) untuk sesi tersebut | ☐ |
| F8 | Shimmer saat loading | 1. Throttle network<br>2. Buka tab Chat | Shimmer skeleton muncul sebelum data tampil | ☐ |
| F9 | Pull-to-refresh | 1. Di tab Aktif, pull down | Data sesi di-refresh dari backend | ☐ |
| F10 | Error fetch | 1. Matikan backend<br>2. Pull-to-refresh di tab Chat | SnackBar merah muncul dengan pesan error, data sebelumnya tetap tampil | ☐ |
| F11 | Waktu relatif — menit | 1. Buat sesi baru, kirim pesan<br>2. Tunggu 2 menit, lihat list | Tampil "2 menit lalu" | ☐ |
| F12 | Waktu relatif — jam | 1. Lihat sesi yang terakhir di-update 2 jam lalu | Tampil "2 jam lalu" | ☐ |
| F13 | Waktu relatif — tanggal | 1. Lihat sesi yang terakhir di-update > 24 jam lalu | Tampil tanggal format "dd MMM yyyy" | ☐ |

---

## G. Chat Tab — Swipe to Delete

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| G1 | Swipe kiri tampilkan delete | 1. Di tab Aktif, swipe kiri pada sesi aktif | Muncul tombol delete (merah) | ☐ |
| G2 | Konfirmasi delete | 1. Swipe kiri, tap tombol delete | Muncul dialog konfirmasi "Apakah kamu yakin ingin menghapus sesi ini?" | ☐ |
| G3 | Confirm delete berhasil | 1. Tap "Hapus" di dialog konfirmasi | Sesi hilang dari list, tidak ada error | ☐ |
| G4 | Cancel delete | 1. Swipe kiri, tap delete, lalu tap "Batal" di dialog | Dialog tertutup, sesi tetap ada di list, swipe action tertutup | ☐ |
| G5 | Delete gagal — revert | 1. Matikan backend<br>2. Swipe kiri, tap delete, confirm | Sesi sempat hilang lalu muncul kembali, SnackBar merah muncul | ☐ |
| G6 | Tidak bisa swipe sesi selesai | 1. Di tab "Selesai", coba swipe kiri pada sesi | Tidak ada tombol delete / tidak bisa di-swipe | ☐ |

---

## H. Chat Tab — Empty State

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| H1 | Empty state sesi aktif | 1. User tanpa sesi aktif<br>2. Buka tab Chat > Aktif | Tampil ilustrasi + teks "Belum ada sesi aktif" + tombol "Mulai Cerita" | ☐ |
| H2 | Tombol "Mulai Cerita" di empty state | 1. Tap "Mulai Cerita" di empty state | Tab berpindah ke Persona | ☐ |
| H3 | Empty state sesi selesai | 1. User tanpa sesi completed<br>2. Buka tab Chat > Selesai | Tampil ilustrasi + teks "Belum ada sesi yang selesai" | ☐ |
| H4 | Shimmer bukan empty state saat loading | 1. Throttle network, buka tab Chat | Yang tampil shimmer skeleton, BUKAN empty state | ☐ |

---

## I. Persona Tab — Grid List

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| I1 | Grid 2 kolom | 1. Tap tab Persona | Persona ditampilkan dalam grid 2 kolom | ☐ |
| I2 | Konten card persona | 1. Perhatikan setiap card | Tampil: avatar, nama, deskripsi (max 2 baris), jumlah upvote, jumlah downvote | ☐ |
| I3 | Tidak ada tombol vote di grid | 1. Perhatikan card di grid | TIDAK ada tombol vote (up/down) di card grid, hanya angka | ☐ |
| I4 | Infinite scroll — load more | 1. Pastikan ada > 10 persona di DB<br>2. Scroll ke bawah sampai habis | Saat mendekati bottom, loading indicator muncul, lalu persona baru muncul | ☐ |
| I5 | Infinite scroll — stop di akhir | 1. Scroll sampai semua persona ter-load | Tidak ada loading indicator lagi di bottom, scroll berhenti | ☐ |
| I6 | Shimmer first page | 1. Throttle network<br>2. Buka tab Persona pertama kali | Shimmer skeleton grid muncul | ☐ |
| I7 | Pull-to-refresh | 1. Di tab Persona, pull down | Data persona di-refresh dari page 1, list ter-replace | ☐ |
| I8 | Error fetch | 1. Matikan backend<br>2. Buka tab Persona | SnackBar merah muncul dengan pesan error | ☐ |
| I9 | Tap card navigasi ke detail | 1. Tap salah satu card persona | Navigasi ke PersonaDetailScreen | ☐ |

---

## J. Persona Detail Screen

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| J1 | Detail tampil lengkap | 1. Tap persona card<br>2. Lihat detail screen | Tampil: nama, avatar, deskripsi lengkap, jumlah upvote, jumlah downvote | ☐ |
| J2 | Shimmer saat loading detail | 1. Throttle network<br>2. Tap persona card | Shimmer skeleton muncul sebelum data tampil | ☐ |
| J3 | Vote UP (dari NONE) | 1. Pastikan belum pernah vote persona ini<br>2. Tap tombol UP | Tombol UP ter-highlight, angka upvote +1 | ☐ |
| J4 | Vote DOWN (dari NONE) | 1. Persona belum di-vote<br>2. Tap tombol DOWN | Tombol DOWN ter-highlight, angka downvote +1 | ☐ |
| J5 | Toggle off vote (UP → NONE) | 1. Persona sudah di-vote UP<br>2. Tap tombol UP lagi | Highlight hilang, angka upvote -1 | ☐ |
| J6 | Switch vote (UP → DOWN) | 1. Persona sudah di-vote UP<br>2. Tap tombol DOWN | Highlight pindah ke DOWN, upvote -1, downvote +1 | ☐ |
| J7 | Vote gagal — revert | 1. Matikan backend<br>2. Tap tombol vote | Angka sempat berubah lalu kembali ke semula, SnackBar merah muncul | ☐ |
| J8 | Jumlah sesi dengan persona | 1. Pastikan user punya 3 sesi dengan persona X<br>2. Buka detail persona X | Tampil info "3 sesi" (atau format serupa) | ☐ |
| J9 | Tombol "Mulai Chat" | 1. Lihat detail persona | Ada tombol "Mulai Chat" yang terlihat jelas | ☐ |
| J10 | Error fetch detail | 1. Matikan backend<br>2. Tap persona card | SnackBar merah muncul dengan pesan error | ☐ |

---

## K. Persona Detail — Start Chat

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| K1 | Mulai chat berhasil | 1. Di detail persona, tap "Mulai Chat" | Tombol disabled + loading, lalu navigasi ke chat screen baru | ☐ |
| K2 | Prevent double tap | 1. Tap "Mulai Chat" cepat 2x | Hanya 1 sesi yang dibuat (tombol disabled setelah tap pertama) | ☐ |
| K3 | Mulai chat gagal — persona tidak aktif | 1. Set persona isActive=false di DB<br>2. Tap "Mulai Chat" | SnackBar merah "Persona tidak aktif", tombol kembali enabled | ☐ |
| K4 | Mulai chat gagal — network error | 1. Matikan backend<br>2. Tap "Mulai Chat" | SnackBar merah dengan pesan error, tombol kembali enabled | ☐ |

---

## L. Profile Screen — Display

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| L1 | Profil tampil lengkap | 1. Tap tab Profil | Tampil: avatar (bulat), nama, email, points dengan circular progress, tanggal bergabung | ☐ |
| L2 | Avatar default jika null | 1. User tanpa avatar<br>2. Lihat profil | Tampil placeholder icon (bukan broken image) | ☐ |
| L3 | Format tanggal bergabung | 1. Lihat tanggal di profil | Format "dd MMMM yyyy" dalam Bahasa Indonesia (misal "01 Januari 2024") | ☐ |
| L4 | Points dengan circular progress | 1. Lihat section points di profil | Angka points di dalam circular progress indicator, fill proporsional | ☐ |
| L5 | Menu items tersedia | 1. Lihat profil | Ada 3 menu: "Edit Profil", "Ubah Password", "Keluar" | ☐ |
| L6 | Shimmer saat loading | 1. Throttle network<br>2. Buka tab Profil | Shimmer skeleton muncul sebelum data tampil | ☐ |

---

## M. Edit Profile Screen

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| M1 | Form pre-filled | 1. Tap "Edit Profil" | Form nama terisi nama saat ini, avatar menampilkan foto saat ini (atau placeholder) | ☐ |
| M2 | Pilih foto baru — preview | 1. Tap area avatar/tombol ganti foto<br>2. Pilih foto dari gallery | Preview foto baru tampil menggantikan foto lama | ☐ |
| M3 | Reject foto > 5MB | 1. Pilih foto berukuran > 5MB | SnackBar merah muncul, foto tidak terpasang | ☐ |
| M4 | Reject format non-JPEG/PNG | 1. Pilih file GIF atau format lain (jika bisa) | SnackBar merah muncul, file tidak terpasang | ☐ |
| M5 | Submit nama valid + foto baru | 1. Ubah nama menjadi "Nama Baru"<br>2. Pilih foto baru<br>3. Tap Submit/Simpan | Loading indicator, lalu kembali ke ProfileScreen, nama dan foto ter-update | ☐ |
| M6 | Submit hanya nama (tanpa ganti foto) | 1. Ubah nama saja<br>2. Tap Submit | Berhasil update, kembali ke ProfileScreen dengan nama baru | ☐ |
| M7 | Validasi nama kosong | 1. Hapus semua teks di field nama<br>2. Tap Submit | Muncul error inline di field nama, request TIDAK dikirim | ☐ |
| M8 | Validasi nama whitespace only | 1. Isi nama dengan spasi saja "   "<br>2. Tap Submit | Muncul error inline di field nama, request TIDAK dikirim | ☐ |
| M9 | Nama max 50 karakter | 1. Coba ketik > 50 karakter di field nama | Input dibatasi max 50 karakter (tidak bisa ketik lebih) | ☐ |
| M10 | Submit gagal — server error | 1. Matikan backend<br>2. Tap Submit | SnackBar merah dengan pesan error, tombol kembali enabled | ☐ |
| M11 | Tombol disabled saat loading | 1. Tap Submit (backend lambat) | Tombol Submit disabled + loading indicator selama proses | ☐ |

---

## N. Change Password Screen

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| N1 | Form 3 field password | 1. Tap "Ubah Password" di profil | Tampil 3 field: Password Lama, Password Baru, Konfirmasi Password Baru (semua obscured) | ☐ |
| N2 | Validasi — password lama kosong | 1. Kosongkan field password lama<br>2. Isi field lain valid<br>3. Tap Submit | Error inline "Password lama tidak boleh kosong" (atau serupa) | ☐ |
| N3 | Validasi — password baru < 8 char | 1. Isi password baru "abc"<br>2. Tap Submit | Error inline bahwa password minimal 8 karakter | ☐ |
| N4 | Validasi — password baru > 128 char | 1. Isi password baru > 128 karakter<br>2. Tap Submit | Error inline bahwa password maksimal 128 karakter | ☐ |
| N5 | Validasi — konfirmasi tidak cocok | 1. Isi password baru "password123"<br>2. Isi konfirmasi "password456"<br>3. Tap Submit | Error inline "Konfirmasi password tidak cocok" (atau serupa) | ☐ |
| N6 | Submit berhasil | 1. Isi password lama benar<br>2. Isi password baru valid (8+ char)<br>3. Isi konfirmasi sama<br>4. Tap Submit | SnackBar hijau "berhasil", navigasi kembali ke ProfileScreen | ☐ |
| N7 | Password lama salah (401) | 1. Isi password lama yang salah<br>2. Isi password baru valid<br>3. Tap Submit | SnackBar merah "Password lama salah" (pesan eksak dari backend) | ☐ |
| N8 | Server error | 1. Matikan backend<br>2. Tap Submit | SnackBar merah dengan pesan error | ☐ |
| N9 | Tombol disabled saat loading | 1. Tap Submit (backend lambat) | Tombol disabled + loading indicator | ☐ |
| N10 | Field obscured (hidden text) | 1. Ketik di semua field | Teks tersembunyi (dot/bullet), tidak terlihat plain text | ☐ |

---

## O. Logout

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| O1 | Dialog konfirmasi logout | 1. Di Profil, tap "Keluar" | Muncul dialog: title "Konfirmasi Logout", pesan "Apakah kamu yakin ingin keluar?", tombol "Batal" dan "Keluar" | ☐ |
| O2 | Cancel logout | 1. Tap "Keluar"<br>2. Tap "Batal" di dialog | Dialog tertutup, tetap di ProfileScreen | ☐ |
| O3 | Confirm logout berhasil | 1. Tap "Keluar"<br>2. Tap "Keluar" di dialog | Loading indicator, lalu navigasi ke LoginScreen | ☐ |
| O4 | Setelah logout tidak bisa back | 1. Setelah logout ke LoginScreen<br>2. Tekan tombol back device | Tetap di LoginScreen (tidak kembali ke MainScreen) | ☐ |
| O5 | Logout saat backend mati | 1. Matikan backend<br>2. Tap "Keluar" > "Keluar" | Tetap logout (clear token lokal), navigasi ke LoginScreen tanpa error SnackBar | ☐ |
| O6 | Token terhapus setelah logout | 1. Logout<br>2. Buka app lagi tanpa login | Masuk ke LoginScreen (bukan MainScreen) — token sudah dihapus | ☐ |

---

## P. Cross-Feature & Edge Cases

| No | Test Case | Langkah-langkah | Expected Result | Status |
|----|-----------|-----------------|-----------------|--------|
| P1 | Persona name di session list | 1. Buat sesi dengan persona "Aria"<br>2. Buka tab Chat | Nama "Aria" tampil di session list (bukan personaId) | ☐ |
| P2 | Score card update setelah sesi selesai | 1. Catat points di Beranda<br>2. Complete sesi (via backend/flow lain)<br>3. Pull-to-refresh Beranda | Points dan circular progress ter-update sesuai perubahan | ☐ |
| P3 | Navigasi deep: Persona → Detail → Chat → Back | 1. Tab Persona > tap card > "Mulai Chat" > chat screen<br>2. Tekan back | Kembali ke persona detail atau list (sesuai navigation stack) | ☐ |
| P4 | Rotate device (landscape) | 1. Di setiap screen utama, rotate emulator ke landscape | Layout tidak crash, konten tetap accessible (meski mungkin perlu scroll) | ☐ |
| P5 | Kill app dan buka lagi (token persist) | 1. Login, pastikan di MainScreen<br>2. Force close app<br>3. Buka app lagi | Langsung masuk MainScreen (token masih valid, tidak perlu login ulang) | ☐ |
| P6 | Network disconnect lalu reconnect | 1. Di Beranda, matikan network emulator<br>2. Pull-to-refresh (error)<br>3. Nyalakan network<br>4. Pull-to-refresh lagi | Pertama error SnackBar, kedua data berhasil di-load | ☐ |
| P7 | Multiple tab data consistency | 1. Di tab Persona, lihat jumlah persona<br>2. Pindah ke Beranda, lihat "Persona Tersedia" | Angka persona di Beranda konsisten dengan jumlah di tab Persona | ☐ |

---

## Ringkasan Total Test Cases

| Section | Jumlah Test |
|---------|-------------|
| A. Bottom Navigation Shell | 7 |
| B. Home — Greeting | 5 |
| C. Home — Score Card | 4 |
| D. Home — Summary Cards | 4 |
| E. Home — Quick Action & Tips | 4 |
| F. Chat — Session List | 13 |
| G. Chat — Swipe Delete | 6 |
| H. Chat — Empty State | 4 |
| I. Persona — Grid List | 9 |
| J. Persona Detail | 10 |
| K. Persona — Start Chat | 4 |
| L. Profile — Display | 6 |
| M. Edit Profile | 11 |
| N. Change Password | 10 |
| O. Logout | 6 |
| P. Cross-Feature & Edge Cases | 7 |
| **TOTAL** | **100** |

---

## Cara Menjalankan Test

1. **Pastikan backend berjalan**: `cd backend && npm run dev` (port 5000)
2. **Jalankan emulator**: `flutter emulators --launch <emulator_name>`
3. **Run app**: `flutter run`
4. **Siapkan data test**: Buat beberapa user, persona, dan sesi via API/Postman sebelum test
5. **Eksekusi test satu per satu**: Ikuti langkah di kolom "Langkah-langkah"
6. **Tandai status**: ☐ → ✅ (PASS) atau ❌ (FAIL + catat bug)

## Kriteria PASS Tahap 4

- **SEMUA** 100 test case harus berstatus ✅
- Tidak ada crash/exception yang tidak ter-handle
- Semua error message dari backend ditampilkan apa adanya (tidak diubah/diterjemahkan)
- Loading state (shimmer) muncul di semua screen yang fetch data
- Tidak ada double-submission (tombol disabled saat loading)
