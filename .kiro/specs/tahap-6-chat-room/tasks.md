# Implementation Plan: Tahap 6 — Chat Room

## Overview

Implementasi fitur inti chat room pada aplikasi SiniCerita. Mencakup MessageModel, ekstensi SessionProvider untuk chat, widget ChatBubble & TypingIndicator, ChatScreen dengan full chat UI, navigasi dari PersonaDetailScreen, dan registrasi route GoRouter. Semua mengikuti pola Provider + Dio yang sudah established di project.

## Tasks

- [x] 1. Data model dan core interfaces
  - [x] 1.1 Buat MessageModel data class di `lib/models/message_model.dart`
    - Class extends Equatable dengan field final: id, sessionId, role, content, createdAt
    - Factory constructor `fromJson(Map<String, dynamic> json)` yang parse createdAt dari ISO 8601 string
    - Method `toJson()` untuk serialization (dibutuhkan untuk testing round-trip)
    - Getter `isUser` (role == 'user') dan `isModel` (role == 'model')
    - Throw exception jika field wajib null atau tidak ada di fromJson
    - Equatable props: [id, sessionId, role, content, createdAt]
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 9.4_

  - [x] 1.2 Write property test: MessageModel serialization round-trip
    - **Property 1: MessageModel serialization round-trip**
    - Gunakan package `glados` untuk generate arbitrary MessageModel instances
    - Verifikasi `MessageModel.fromJson(model.toJson()) == model` untuk semua valid instances
    - **Validates: Requirements 1.1, 1.2, 1.5, 9.4**

  - [x] 1.3 Write property test: Role getter mutual exclusivity
    - **Property 2: Role getter mutual exclusivity**
    - Untuk setiap MessageModel dengan role 'user' atau 'model', tepat satu dari isUser/isModel bernilai true
    - **Validates: Requirements 1.3, 1.4**

  - [x] 1.4 Write property test: Missing field rejection
    - **Property 3: Missing field rejection**
    - Untuk setiap valid message JSON dengan satu atau lebih field dihapus, fromJson harus throw exception
    - **Validates: Requirements 1.6**

- [x] 2. Tambahkan endpoint constants
  - [x] 2.1 Tambahkan endpoint constants di `lib/core/api/api_endpoints.dart`
    - Tambahkan `static String sessionMessages(String id) => '/api/sessions/$id/messages'`
    - Tambahkan `static const String sessions = '/api/sessions'` (jika belum ada)
    - _Requirements: 9.1, 9.2_

- [x] 3. Extend SessionProvider untuk chat
  - [x] 3.1 Tambahkan state fields dan methods chat di `lib/providers/session_provider.dart`
    - Tambahkan fields: `_messages` (List<MessageModel>), `_isTyping` (bool), `_isSendingMessage` (bool), `_currentChatSessionId` (String?)
    - Tambahkan getters: messages, isTyping, isSendingMessage
    - Implement `fetchMessages(String sessionId)`: clear messages, set isLoading true, GET /api/sessions/:id/messages?page=1&limit=50, parse response.data['data'] sebagai List, sort ascending by createdAt, handle DioException → AppException
    - Implement `sendMessage(String sessionId, String content)`: set isSendingMessage true, add optimistic user message, set isTyping true, POST /api/sessions/:id/messages body {content}, parse response.data['data']['userMessage'] dan response.data['data']['aiReply'], replace optimistic msg, add aiReply, reset states. On error: remove optimistic msg, reset states, set errorMessage
    - Implement `createSession(String personaId)`: POST /api/sessions body {personaId}, return session data
    - Implement `clearChatState()`: reset semua chat-related state
    - Validasi response.data['data'] type (Map untuk POST, List untuk GET), throw AppException jika invalid
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3.1, 3.2, 3.3, 9.1, 9.2, 9.3, 9.5_

  - [x] 3.2 Write property test: Fetch messages produces sorted list
    - **Property 4: Fetch messages produces sorted list**
    - Untuk setiap list pesan dari backend (dalam urutan apapun), setelah fetchMessages selesai, messages list harus sorted ascending by createdAt
    - **Validates: Requirements 2.4, 3.3**

  - [x] 3.3 Write property test: Send message adds both messages on success
    - **Property 5: Send message adds both messages on success**
    - Untuk setiap valid content dan successful API response, setelah sendMessage selesai, messages list harus mengandung userMessage dan aiReply
    - **Validates: Requirements 2.5, 2.7, 9.3**

  - [x] 3.4 Write property test: Error state consistency after failed send
    - **Property 6: Error state consistency after failed send**
    - Untuk setiap DioException saat sendMessage, state akhir: isTyping=false, isSendingMessage=false, errorMessage!=null, optimistic message dihapus
    - **Validates: Requirements 2.8, 4.9**

  - [x] 3.5 Write property test: Error state consistency after failed fetch
    - **Property 7: Error state consistency after failed fetch**
    - Untuk setiap DioException saat fetchMessages, state akhir: isLoading=false, errorMessage!=null
    - **Validates: Requirements 2.9, 3.5**

  - [x] 3.6 Write property test: Invalid response data throws AppException
    - **Property 11: Invalid response data throws AppException**
    - Untuk setiap response dimana data['data'] null atau bukan tipe yang diharapkan, provider harus throw AppException
    - **Validates: Requirements 9.5**

  - [x] 3.7 Write property test: GET messages response parsing
    - **Property 10: GET messages response parsing extracts data and meta correctly**
    - Untuk setiap valid paginated response envelope, provider harus extract message list dari data['data'] dan metadata dari data['meta']
    - **Validates: Requirements 9.2**

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Buat widget ChatBubble dan TypingIndicator
  - [x] 5.1 Buat ChatBubble widget di `lib/widgets/chat/chat_bubble.dart`
    - StatelessWidget menerima MessageModel dan isUser flag
    - Align kanan untuk user (CrossAxisAlignment.end), kiri untuk model (CrossAxisAlignment.start)
    - Warna background berbeda untuk user vs model
    - Max width 75% dari lebar layar menggunakan ConstrainedBox/FractionallySizedBox
    - Tampilkan content text dengan padding yang sesuai
    - _Requirements: 5.1, 5.2_

  - [x] 5.2 Buat TypingIndicator widget di `lib/widgets/chat/typing_indicator.dart`
    - StatefulWidget dengan AnimationController untuk animasi tiga titik berkedip
    - Align ke sisi kiri (sama seperti pesan AI)
    - Gunakan AnimatedBuilder atau AnimatedOpacity untuk efek berkedip
    - _Requirements: 4.3_

- [x] 6. Buat ChatScreen
  - [x] 6.1 Buat ChatScreen widget di `lib/screens/chat/chat_screen.dart`
    - StatefulWidget menerima sessionId via constructor
    - initState: panggil fetchMessages(sessionId) pada SessionProvider
    - AppBar dengan judul nama persona (dari session/persona data)
    - ListView dengan reverse:true untuk menampilkan pesan (terbaru di bawah)
    - ScrollController untuk auto-scroll ke pesan terbaru saat pesan baru ditambahkan
    - Shimmer skeleton saat isLoading true
    - Empty state text di tengah saat messages kosong dan tidak loading
    - Render ChatBubble untuk setiap message
    - Render TypingIndicator saat isTyping true
    - _Requirements: 3.1, 3.4, 3.6, 5.3, 5.4, 5.6, 5.7_

  - [x] 6.2 Implement input area dan send logic di ChatScreen
    - TextField fixed di bawah layar dengan TextEditingController
    - IconButton kirim di sebelah kanan TextField
    - Disable tombol kirim saat input kosong/whitespace-only (via onChanged + setState)
    - Disable tombol kirim saat isSendingMessage true
    - Disable tombol kirim dan tampilkan indikator saat content > 5000 karakter setelah trim
    - Trim content sebelum kirim ke sendMessage
    - Clear TextField setelah pesan berhasil dikirim
    - Restore content ke TextField jika sendMessage gagal (network error)
    - Tampilkan SnackBar merah untuk semua error dari provider
    - _Requirements: 4.1, 4.2, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 8.1, 8.2, 8.3, 8.4_

  - [x] 6.3 Write property test: Input validation controls send button state
    - **Property 8: Input validation controls send button state**
    - Untuk setiap input string, tombol kirim enabled jika dan hanya jika trimmed length antara 1-5000 karakter
    - **Validates: Requirements 8.1, 8.2, 8.4**

  - [x] 6.4 Write property test: Content is trimmed before sending
    - **Property 9: Content is trimmed before sending**
    - Untuk setiap input string dengan leading/trailing whitespace, content yang dikirim ke sendMessage adalah versi trimmed
    - **Validates: Requirements 8.3**

- [x] 7. Navigasi dan integrasi
  - [x] 7.1 Tambahkan route `/chat/:sessionId` di GoRouter configuration (`lib/main.dart` atau router config file)
    - Route path: '/chat/:sessionId'
    - Extract sessionId dari GoRouterState.pathParameters
    - Pass sessionId ke ChatScreen constructor
    - _Requirements: 7.1, 7.2, 7.3_

  - [x] 7.2 Implement createSession dan navigasi dari PersonaDetailScreen
    - Tambahkan tombol "Mulai Sesi" di PersonaDetailScreen (jika belum ada)
    - On tap: panggil createSession(personaId) pada SessionProvider
    - Disable tombol saat createSession sedang berlangsung
    - On success: navigate ke '/chat/${sessionId}' menggunakan context.push
    - On error: tampilkan SnackBar merah dengan pesan error dari AppException
    - Handle error "Persona tidak aktif" dan "Persona tidak ditemukan"
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [x] 7.3 Handle error navigasi di ChatScreen
    - Jika fetchMessages gagal dengan error "Sesi tidak ditemukan" atau "Akses ditolak", tampilkan SnackBar dan navigate back
    - Implement back button di AppBar yang memanggil context.pop()
    - _Requirements: 7.2, 7.4_

- [x] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Unit tests dan widget tests
  - [x] 9.1 Write unit tests untuk MessageModel di `test/models/message_model_test.dart`
    - Test fromJson dengan data valid
    - Test fromJson dengan field null/missing throws exception
    - Test isUser getter untuk role 'user'
    - Test isModel getter untuk role 'model'
    - Test Equatable equality
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

  - [x] 9.2 Write unit tests untuk SessionProvider chat methods di `test/providers/session_provider_chat_test.dart`
    - Test initial state: messages kosong, isTyping false, isSendingMessage false
    - Test fetchMessages success: messages terisi, isLoading false
    - Test fetchMessages error: errorMessage terisi, isLoading false
    - Test fetchMessages empty: messages kosong, tidak error
    - Test sendMessage success: userMessage + aiReply ditambahkan
    - Test sendMessage network error: optimistic message dihapus, error state
    - Test sendMessage "Sesi sudah selesai": optimistic message dihapus
    - Test sendMessage "Akses ditolak": optimistic message dihapus
    - Test createSession success dan error
    - Mock Dio responses menggunakan mockito atau mocktail
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 9.1, 9.2, 9.3, 9.5_

  - [x] 9.3 Write widget tests untuk ChatScreen di `test/screens/chat_screen_test.dart`
    - Test Shimmer ditampilkan saat loading
    - Test empty state saat messages kosong
    - Test user bubble di kanan, AI bubble di kiri
    - Test tombol kirim disabled saat input kosong
    - Test tombol kirim disabled saat isSendingMessage true
    - Test TypingIndicator muncul saat isTyping true
    - Test SnackBar merah saat ada error
    - Test input validation (> 5000 chars disabled)
    - Mock SessionProvider menggunakan Provider override
    - _Requirements: 3.4, 3.6, 4.3, 4.6, 5.1, 5.2, 5.3, 5.7, 8.1, 8.4_

- [x] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using `glados` package
- Unit tests validate specific examples and edge cases
- Response parsing WAJIB menggunakan `response.data['data']` (bukan `response.data` langsung)
- Message role adalah `'user'` dan `'model'` (BUKAN `'assistant'`)
- POST /api/sessions/:id/messages return status 200 (bukan 201)
- Semua teks UI dalam Bahasa Indonesia

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.1"] },
    { "id": 1, "tasks": ["1.2", "1.3", "1.4", "3.1"] },
    { "id": 2, "tasks": ["3.2", "3.3", "3.4", "3.5", "3.6", "3.7", "5.1", "5.2"] },
    { "id": 3, "tasks": ["6.1"] },
    { "id": 4, "tasks": ["6.2", "6.3", "6.4"] },
    { "id": 5, "tasks": ["7.1"] },
    { "id": 6, "tasks": ["7.2", "7.3"] },
    { "id": 7, "tasks": ["9.1", "9.2", "9.3"] }
  ]
}
```
