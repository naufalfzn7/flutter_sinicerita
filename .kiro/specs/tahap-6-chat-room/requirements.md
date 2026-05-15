# Requirements Document

## Introduction

Tahap 6 mengimplementasikan fitur inti chat room pada aplikasi SiniCerita — platform kesehatan mental berbasis chatbot AI. Fitur ini memungkinkan pengguna memulai sesi percakapan dengan persona AI (Google Gemini via backend), mengirim pesan, menerima balasan AI secara real-time, dan melihat riwayat pesan dalam sesi. Chat room adalah fitur utama yang menjadi inti pengalaman pengguna di SiniCerita.

## Glossary

- **Chat_Screen**: Halaman utama percakapan yang menampilkan daftar pesan dalam format bubble layout antara pengguna dan persona AI
- **Session_Provider**: ChangeNotifier yang mengelola state sesi chat termasuk daftar pesan, status loading, dan indikator typing
- **Message_Model**: Data class yang merepresentasikan satu pesan dalam sesi, memiliki field id, sessionId, role, content, dan createdAt
- **Typing_Indicator**: Widget animasi yang ditampilkan saat menunggu balasan AI dari backend
- **Chat_Bubble**: Widget yang menampilkan satu pesan dalam bentuk gelembung dengan alignment berbeda berdasarkan role pengirim
- **Backend_API**: REST API Express 5 yang menyediakan endpoint untuk membuat sesi, mengirim pesan, dan mengambil riwayat pesan
- **Persona_Detail_Screen**: Halaman detail persona yang sudah ada, memiliki tombol "Mulai Sesi" untuk memulai percakapan baru
- **Message_Role**: Enum yang menentukan pengirim pesan, bernilai 'user' untuk pengguna atau 'model' untuk AI (bukan 'assistant')
- **Shimmer_Skeleton**: Placeholder animasi loading berbentuk skeleton yang digunakan sebagai indikator loading (bukan spinner biasa)

## Requirements

### Requirement 1: Message Data Model

**User Story:** Sebagai developer, saya ingin memiliki data class Message yang terstruktur, sehingga pesan dari backend dapat di-parse dan ditampilkan dengan konsisten di UI.

#### Acceptance Criteria

1. THE Message_Model SHALL memiliki field immutable (final): id (String, format UUID), sessionId (String, format UUID), role (String, bernilai 'user' atau 'model'), content (String, minimal 1 karakter), dan createdAt (DateTime)
2. THE Message_Model SHALL menyediakan factory constructor fromJson yang menerima Map<String, dynamic> dengan key 'id', 'sessionId', 'role', 'content', dan 'createdAt' (ISO 8601 string) lalu mengembalikan instance Message_Model
3. WHEN role bernilai 'user', THE Message_Model SHALL mengembalikan true pada getter isUser dan false pada getter isModel
4. WHEN role bernilai 'model', THE Message_Model SHALL mengembalikan true pada getter isModel dan false pada getter isUser
5. THE Message_Model SHALL menggunakan Equatable dengan props berisi seluruh field (id, sessionId, role, content, createdAt) untuk perbandingan value equality antar instance
6. IF fromJson menerima Map dengan field wajib yang null atau tidak ada, THEN THE Message_Model SHALL melempar exception saat konstruksi instance

### Requirement 2: Session Provider Extension untuk Chat

**User Story:** Sebagai developer, saya ingin Session_Provider memiliki kemampuan mengelola pesan dalam sesi, sehingga widget dapat mengakses state chat secara reaktif tanpa memanggil API langsung.

#### Acceptance Criteria

1. THE Session_Provider SHALL menyimpan daftar Message_Model untuk sesi yang sessionId-nya sedang aktif ditampilkan di Chat_Screen, dengan nilai awal berupa list kosong
2. THE Session_Provider SHALL menyediakan state isTyping yang bernilai true saat menunggu balasan AI dari backend, dengan nilai awal false
3. THE Session_Provider SHALL menyediakan state isSendingMessage yang bernilai true saat proses pengiriman pesan sedang berlangsung, dengan nilai awal false
4. WHEN fetchMessages dipanggil dengan sessionId, THE Session_Provider SHALL mengosongkan daftar pesan saat ini, mengatur isLoading menjadi true, memanggil GET /api/sessions/:id/messages, dan menyimpan hasilnya ke daftar pesan lalu mengatur isLoading menjadi false
5. WHEN sendMessage dipanggil dengan sessionId dan content, THE Session_Provider SHALL mengatur isSendingMessage menjadi true, memanggil POST /api/sessions/:id/messages dengan body { content }, dan menambahkan userMessage serta aiReply dari response.data['data'] ke daftar pesan
6. WHILE isSendingMessage bernilai true, THE Session_Provider SHALL mengatur isTyping menjadi true setelah pesan pengguna ditambahkan ke daftar pesan
7. WHEN sendMessage berhasil menerima response, THE Session_Provider SHALL mengatur isTyping menjadi false, mengatur isSendingMessage menjadi false, dan menambahkan aiReply ke daftar pesan
8. IF sendMessage gagal karena DioException, THEN THE Session_Provider SHALL mengkonversi error menjadi AppException, menyimpan pesan error ke errorMessage, mengatur isTyping menjadi false, dan mengatur isSendingMessage menjadi false
9. WHEN fetchMessages gagal karena DioException, THEN THE Session_Provider SHALL mengkonversi error menjadi AppException, menyimpan pesan error ke errorMessage, dan mengatur isLoading menjadi false

### Requirement 3: Fetch Riwayat Pesan

**User Story:** Sebagai pengguna, saya ingin melihat riwayat pesan saat membuka chat room, sehingga saya dapat melanjutkan percakapan dari titik terakhir.

#### Acceptance Criteria

1. WHEN Chat_Screen pertama kali dibuka (widget mount), THE Session_Provider SHALL mengosongkan daftar pesan sebelumnya lalu memanggil fetchMessages dengan sessionId untuk mengambil pesan dari backend
2. THE Session_Provider SHALL mengirim query parameter page=1 dan limit=50 pada request fetchMessages
3. WHEN fetchMessages berhasil, THE Session_Provider SHALL menyimpan daftar pesan terurut ascending berdasarkan createdAt, menggantikan seluruh daftar pesan sebelumnya
4. WHILE fetchMessages sedang berlangsung, THE Chat_Screen SHALL menampilkan Shimmer_Skeleton sebagai placeholder loading dan menyembunyikan area daftar pesan
5. IF fetchMessages gagal karena error apapun (network error, timeout, atau error response dari backend), THEN THE Chat_Screen SHALL menampilkan pesan error dari AppException dalam SnackBar merah dengan pesan eksak dari backend
6. WHEN fetchMessages berhasil dan daftar pesan kosong (sesi baru tanpa riwayat), THE Chat_Screen SHALL menampilkan area chat kosong tanpa Shimmer_Skeleton dan tanpa pesan error, siap menerima input pengguna

### Requirement 4: Kirim Pesan dan Terima Balasan AI

**User Story:** Sebagai pengguna, saya ingin mengirim pesan dan menerima balasan dari persona AI, sehingga saya dapat melakukan percakapan untuk mendukung kesehatan mental saya.

#### Acceptance Criteria

1. WHEN pengguna mengetik pesan dan menekan tombol kirim, THE Chat_Screen SHALL memanggil sendMessage pada Session_Provider dengan content pesan (minimal 1 karakter dan maksimal 1000 karakter setelah trim)
2. WHEN sendMessage dipanggil, THE Chat_Screen SHALL langsung menampilkan pesan pengguna di daftar chat sebagai bubble di sisi kanan sebelum menerima response dari backend
3. WHILE menunggu balasan AI, THE Chat_Screen SHALL menampilkan Typing_Indicator di sisi kiri daftar chat
4. WHEN backend mengembalikan response 200 dengan userMessage dan aiReply, THE Chat_Screen SHALL menghapus Typing_Indicator dan menampilkan aiReply sebagai bubble di sisi kiri
5. WHEN pesan berhasil dikirim, THE Chat_Screen SHALL mengosongkan text field input
6. WHILE isSendingMessage bernilai true, THE Chat_Screen SHALL menonaktifkan tombol kirim untuk mencegah pengiriman ganda
7. IF backend mengembalikan error "Sesi sudah selesai", THEN THE Chat_Screen SHALL menampilkan pesan error tersebut dalam SnackBar merah
8. IF backend mengembalikan error "Akses ditolak: sesi bukan milik Anda", THEN THE Chat_Screen SHALL menampilkan pesan error tersebut dalam SnackBar merah
9. IF sendMessage gagal karena network error atau error backend selain kriteria 7-8, THEN THE Chat_Screen SHALL menghapus pesan pengguna yang sudah ditampilkan secara optimistik dari daftar chat, mengembalikan content pesan ke text field input, dan menampilkan pesan error dalam SnackBar merah
10. IF backend mengembalikan error "Sesi sudah selesai" atau "Akses ditolak: sesi bukan milik Anda", THEN THE Chat_Screen SHALL menghapus pesan pengguna yang sudah ditampilkan secara optimistik dari daftar chat

### Requirement 5: Chat UI Layout

**User Story:** Sebagai pengguna, saya ingin tampilan chat yang jelas dan mudah dibaca, sehingga saya dapat membedakan pesan saya dan pesan AI dengan nyaman.

#### Acceptance Criteria

1. THE Chat_Screen SHALL menampilkan pesan dengan role 'user' sebagai Chat_Bubble yang di-align ke sisi kanan layar dengan warna background berbeda dari pesan AI, dan lebar maksimum 75% dari lebar layar
2. THE Chat_Screen SHALL menampilkan pesan dengan role 'model' sebagai Chat_Bubble yang di-align ke sisi kiri layar dengan warna background berbeda dari pesan pengguna, dan lebar maksimum 75% dari lebar layar
3. THE Chat_Screen SHALL menampilkan daftar pesan dalam ListView dengan reverse:true yang dapat di-scroll secara vertikal, menampilkan pesan terbaru di bagian bawah
4. WHEN pesan baru ditambahkan ke daftar, THE Chat_Screen SHALL melakukan auto-scroll ke pesan terbaru di bagian bawah menggunakan ScrollController
5. THE Chat_Screen SHALL menampilkan text field input yang fixed di bagian bawah layar dengan tombol kirim berupa IconButton di sebelah kanan text field
6. THE Chat_Screen SHALL menampilkan AppBar dengan judul berupa nama persona yang terkait dengan sesi chat saat ini
7. IF daftar pesan kosong saat Chat_Screen dibuka, THEN THE Chat_Screen SHALL menampilkan pesan teks di tengah layar yang mengindikasikan bahwa percakapan belum dimulai

### Requirement 6: Membuat Sesi Baru dari Persona Detail

**User Story:** Sebagai pengguna, saya ingin memulai sesi chat baru dari halaman detail persona, sehingga saya dapat langsung mengobrol dengan persona AI yang saya pilih.

#### Acceptance Criteria

1. WHEN pengguna menekan tombol "Mulai Sesi" di Persona_Detail_Screen, THE Session_Provider SHALL memanggil POST /api/sessions dengan body { personaId }
2. WHEN createSession berhasil mengembalikan response 201 dengan data sesi, THE Persona_Detail_Screen SHALL melakukan navigasi ke Chat_Screen dengan sessionId dari response
3. WHILE createSession sedang berlangsung, THE Persona_Detail_Screen SHALL menonaktifkan tombol "Mulai Sesi" dan WHEN createSession selesai (berhasil atau gagal), THE Persona_Detail_Screen SHALL mengaktifkan kembali tombol "Mulai Sesi"
4. IF backend mengembalikan error "Persona tidak aktif", THEN THE Persona_Detail_Screen SHALL menampilkan pesan error tersebut dalam SnackBar merah
5. IF backend mengembalikan error "Persona tidak ditemukan", THEN THE Persona_Detail_Screen SHALL menampilkan pesan error tersebut dalam SnackBar merah
6. IF createSession gagal karena network error (timeout atau tidak ada koneksi), THEN THE Persona_Detail_Screen SHALL menampilkan pesan error dari AppException dalam SnackBar merah

### Requirement 7: Navigasi Chat Room

**User Story:** Sebagai pengguna, saya ingin dapat mengakses chat room melalui navigasi yang konsisten, sehingga saya dapat masuk dan keluar dari percakapan dengan mudah.

#### Acceptance Criteria

1. THE Chat_Screen SHALL terdaftar sebagai route di GoRouter dengan path pattern '/chat/:sessionId' dan menerima sessionId sebagai parameter constructor
2. WHEN pengguna menekan tombol back di AppBar Chat_Screen, THE Chat_Screen SHALL memanggil context.pop() untuk kembali ke halaman sebelumnya dalam navigation stack (Persona_Detail_Screen atau Home_Screen)
3. WHEN Chat_Screen dibuka dengan sessionId yang terdapat di backend dan milik pengguna saat ini, THE Chat_Screen SHALL memanggil fetchMessages pada Session_Provider dan menampilkan pesan untuk sesi tersebut
4. IF Chat_Screen dibuka dengan sessionId yang tidak ditemukan di backend atau bukan milik pengguna, THEN THE Chat_Screen SHALL menampilkan pesan error dari backend dalam SnackBar merah dan melakukan navigasi kembali ke halaman sebelumnya

### Requirement 8: Input Validation

**User Story:** Sebagai pengguna, saya ingin mendapat feedback yang jelas saat input tidak valid, sehingga saya tahu apa yang perlu diperbaiki sebelum mengirim pesan.

#### Acceptance Criteria

1. WHILE text field input kosong atau hanya berisi whitespace, THE Chat_Screen SHALL menonaktifkan tombol kirim, dan mengaktifkannya kembali secara reaktif melalui onChanged saat pengguna mengetik minimal 1 karakter non-whitespace
2. WHEN pengguna mencoba mengirim pesan kosong, THE Chat_Screen SHALL mencegah pengiriman tanpa memanggil API
3. WHEN pengguna menekan tombol kirim, THE Chat_Screen SHALL melakukan trim pada content pesan sebelum mengirimnya ke Session_Provider
4. IF panjang content pesan setelah trim melebihi 5000 karakter, THEN THE Chat_Screen SHALL menonaktifkan tombol kirim dan menampilkan indikator bahwa batas karakter telah terlampaui

### Requirement 9: Response Parsing yang Benar

**User Story:** Sebagai developer, saya ingin response dari backend di-parse dengan benar sesuai format envelope, sehingga tidak terjadi error parsing saat runtime.

#### Acceptance Criteria

1. WHEN menerima response dari POST /api/sessions/:id/messages, THE Session_Provider SHALL mengambil data dari response.data['data'] (bukan response.data langsung)
2. WHEN menerima response dari GET /api/sessions/:id/messages, THE Session_Provider SHALL mengambil daftar pesan dari response.data['data'] sebagai List dan metadata paginasi (total, page, limit, totalPages) dari response.data['meta']
3. WHEN menerima response dari POST /api/sessions/:id/messages, THE Session_Provider SHALL mem-parse field response.data['data']['userMessage'] dan response.data['data']['aiReply'] masing-masing menjadi instance Message_Model menggunakan factory fromJson
4. WHEN mem-parse field createdAt dari response JSON, THE Message_Model SHALL mengkonversi nilai ISO 8601 string (contoh: "2024-01-15T10:30:00.000Z") menjadi DateTime menggunakan DateTime.parse
5. IF response.data['data'] bernilai null atau bukan tipe yang diharapkan (Map untuk POST, List untuk GET), THEN THE Session_Provider SHALL melempar AppException dengan pesan error yang menjelaskan format response tidak valid
