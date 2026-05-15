# Implementation Plan: Tahap 4 — Main Navigation & Profile

## Overview

Implementasi shell navigasi utama SiniCerita setelah login berhasil. Menggantikan placeholder MainScreen dengan BottomNavigationBar 4 tab (Beranda, Chat, Persona, Profil) beserta seluruh screen, provider, dan model yang dibutuhkan. Menggunakan IndexedStack untuk state preservation antar tab, Provider pattern untuk state management, dan Dio untuk komunikasi API.

## Tasks

- [x] 1. Data models dan pure functions
  - [x] 1.1 Create SessionModel di `lib/models/session_model.dart`
    - Implement `SessionModel` class extending `Equatable` with fields: id, userId, personaId, status, scoreDelta, analysisSummary, createdAt, updatedAt, completedAt
    - Implement `factory SessionModel.fromJson(Map<String, dynamic> json)` with proper DateTime parsing
    - Implement `props` getter for value equality
    - _Requirements: 16.1, 16.7_

  - [x] 1.2 Create PersonaModel di `lib/models/persona_model.dart`
    - Implement `PersonaModel` class extending `Equatable` with fields: id, name, description, systemPrompt, avatarUrl, isActive, upvotes, downvotes, userRating
    - Implement `factory PersonaModel.fromJson(Map<String, dynamic> json)`
    - Implement `copyWith` method for optimistic update (upvotes, downvotes, userRating)
    - Implement `props` getter for value equality
    - _Requirements: 17.1, 17.3_

  - [x] 1.3 Create pure utility functions di `lib/core/utils/home_helpers.dart`
    - Implement `String getGreeting(int hour, String? userName)` — time-based greeting with name truncation at 30 chars
    - Implement `int getDailyTipIndex(DateTime date, int tipsCount)` — deterministic daily tip index using day-of-year modulo
    - Implement `({String text, String colorCategory}) getScoreStatus(int points)` — score status text and color category mapping
    - Implement `String formatRelativeTime(DateTime dateTime, DateTime now)` — relative time formatting in Bahasa Indonesia
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.7, 3.3, 3.4, 3.5, 5.4, 6.2, 6.3_

  - [x] 1.4 Write property tests for getGreeting (Property 1)
    - **Property 1: Greeting function produces correct time-based greeting with proper name handling**
    - Test with random hour (0-23), random nullable string (0-100 chars)
    - Verify correct prefix per time range, no name suffix when null/empty, truncation at 30 chars
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.7**

  - [x] 1.5 Write property tests for getScoreStatus (Property 2)
    - **Property 2: Score status mapping returns correct text and color category for all point values**
    - Test with random int (0-100)
    - Verify correct text and colorCategory per range (0-39 red, 40-69 yellow, 70-100 green)
    - **Validates: Requirements 3.2, 3.3, 3.4, 3.5**

  - [x] 1.6 Write property tests for getDailyTipIndex (Property 3)
    - **Property 3: Daily tip index is deterministic and bounded**
    - Test with random DateTime and random array length (1-30)
    - Verify determinism (same date → same index), bounds [0, tipsCount), different index for consecutive days
    - **Validates: Requirements 5.4**

  - [x] 1.7 Write property tests for formatRelativeTime and session ordering (Property 4)
    - **Property 4: Session lists are correctly ordered by their respective timestamp fields**
    - Test with random list of timestamps, verify descending order after sort
    - Also test formatRelativeTime with random DateTimes for correct output categories
    - **Validates: Requirements 6.2, 6.3**

- [x] 2. SessionProvider implementation
  - [x] 2.1 Create SessionProvider di `lib/providers/session_provider.dart`
    - Implement `SessionProvider extends ChangeNotifier` with ApiClient dependency
    - State: `_activeSessions`, `_completedSessions`, `_isLoading`, `_errorMessage`, pagination tracking per status
    - Implement `fetchSessions({required String status, int page, int limit})` — GET /api/sessions with query params, parse from `response.data['data']`, track meta pagination
    - Implement `createSession(String personaId)` — POST /api/sessions, add to active list on success
    - Implement `deleteSession(String sessionId)` — DELETE /api/sessions/:id with optimistic removal and revert on failure
    - Implement `clearError()` method
    - Follow Provider pattern: isLoading toggle, DioException → AppException, notifyListeners()
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 16.7_

  - [x] 2.2 Write property tests for pagination hasMorePages (Property 5)
    - **Property 5: Pagination hasMorePages is correctly computed from page metadata**
    - Test with random positive int pairs (currentPage, totalPages)
    - Verify hasMorePages == (currentPage < totalPages)
    - **Validates: Requirements 9.5, 16.2**

  - [x] 2.3 Write property tests for session CRUD invariants (Property 9)
    - **Property 9: Session CRUD maintains list invariants**
    - Test create adds to list (+1 length), delete removes from list (-1 length)
    - **Validates: Requirements 16.3, 16.4**

  - [x] 2.4 Write property tests for session deletion optimistic revert (Property 10)
    - **Property 10: Session deletion optimistic revert restores original list on failure**
    - Test that on simulated failure, list is restored to exact original state
    - **Validates: Requirements 7.4**

- [x] 3. PersonaProvider implementation
  - [x] 3.1 Create PersonaProvider di `lib/providers/persona_provider.dart`
    - Implement `PersonaProvider extends ChangeNotifier` with ApiClient dependency
    - State: `_personas`, `_selectedPersona`, `_isLoading`, `_isLoadingDetail`, `_errorMessage`, `_currentPage`, `_totalPages`
    - Implement `fetchPersonas({int page, int limit})` — GET /api/personas, parse from `response.data['data']` and `response.data['meta']`
    - Implement `fetchNextPage()` — append next page to existing list
    - Implement `refreshPersonas()` — reset to page 1 and replace list
    - Implement `fetchPersonaDetail(String id)` — GET /api/personas/:id
    - Implement `ratePersona(String id, String type)` — POST /api/personas/:id/rate with optimistic update and revert on failure
    - Implement `getById(String id)` — resolve persona from local list (for session list display)
    - Implement `clearError()` method
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.6, 17.7, 17.8_

  - [x] 3.2 Write property tests for vote state machine (Property 6)
    - **Property 6: Vote state machine produces correct count transitions**
    - Test all transitions: NONE→UP, NONE→DOWN, UP→DOWN, DOWN→UP, UP→UP (toggle), DOWN→DOWN (toggle)
    - Verify correct increment/decrement of upvotes and downvotes
    - **Validates: Requirements 10.6, 10.7, 17.3**

  - [x] 3.3 Write property tests for vote revert (Property 7)
    - **Property 7: Failed vote reverts optimistic update to previous state**
    - Test that after optimistic update + simulated failure, state reverts to original
    - **Validates: Requirements 10.8, 17.4**

  - [x] 3.4 Write property tests for session count per persona (Property 8)
    - **Property 8: Session count per persona is correctly computed by filtering**
    - Test with random session list and random personaId, verify count matches filter
    - **Validates: Requirements 10.9**

- [x] 4. Checkpoint — Models and Providers
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. MainScreen navigation shell
  - [x] 5.1 Rewrite MainScreen di `lib/screens/main/main_screen.dart`
    - Replace placeholder with StatefulWidget containing BottomNavigationBar + IndexedStack
    - 4 tabs: Beranda (Icons.home), Chat (Icons.chat_bubble), Persona (Icons.people), Profil (Icons.person)
    - Default active tab: index 0 (Beranda)
    - IndexedStack preserves state of all 4 child screens
    - Expose `switchTab(int index)` method accessible by child widgets (via InheritedWidget or findAncestorStateOfType)
    - Active tab highlighted with differentiated color for icon and label
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 5.2 Register SessionProvider and PersonaProvider in `lib/main.dart`
    - Add `ChangeNotifierProvider` for SessionProvider and PersonaProvider in MultiProvider
    - Pass ApiClient instance to both providers
    - _Requirements: 16.1, 17.1_

  - [x] 5.3 Update GoRouter routes in `lib/main.dart`
    - Add routes for `/persona-detail/:id`, `/edit-profile`, `/change-password`
    - Ensure `/main` route uses the new MainScreen
    - Add route for chat screen navigation (placeholder path for now)
    - _Requirements: 1.1, 10.1, 12.4_

- [x] 6. HomeScreen implementation
  - [x] 6.1 Create HomeScreen di `lib/screens/home/home_screen.dart`
    - Implement time-based greeting using `getGreeting()` pure function with user name from AuthProvider
    - Implement ScoreCardWidget showing circular progress indicator with points, status text, and color from `getScoreStatus()`
    - Implement session summary cards (Sesi Aktif, Sesi Selesai, Persona Tersedia) fetching from SessionProvider and PersonaProvider
    - Implement "Mulai Cerita" quick action button that switches to Persona tab
    - Implement Daily Tip card using `getDailyTipIndex()` with local array of 7+ tips
    - Implement shimmer loading states for score card and summary cards
    - Implement pull-to-refresh to re-fetch session and persona data
    - Handle error states: show zero counts and error SnackBar on fetch failure
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 6.2 Create ScoreCardWidget di `lib/widgets/common/score_card_widget.dart`
    - Circular progress indicator with fill proportional to points/100
    - Points integer displayed inside the circle
    - Status text below based on score range
    - Color coding: red (0-39), yellow (40-69), green (70-100)
    - Shimmer skeleton variant for loading state
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.7_

- [x] 7. ChatScreen implementation
  - [x] 7.1 Create ChatScreen (chat list) di `lib/screens/chat/chat_list_screen.dart`
    - Implement TabBar with "Aktif" (default) and "Selesai" tabs
    - Active tab: list sessions with status "active" ordered by updatedAt descending
    - Completed tab: list sessions with status "completed" ordered by completedAt descending
    - Each item shows: persona name (resolved via PersonaProvider.getById), last message preview (truncated 50 chars), relative time, status badge
    - Completed items also show scoreDelta with sign prefix (+5, -3)
    - Implement shimmer loading states
    - Implement pull-to-refresh per tab
    - Handle error: show SnackBar, retain previous data
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

  - [x] 7.2 Implement swipe-to-delete on active sessions
    - Swipe left reveals delete button (Dismissible or flutter_slidable pattern)
    - Tap delete shows confirmation dialog
    - Confirm: optimistic delete via SessionProvider.deleteSession()
    - Failure: show error SnackBar, restore session
    - Cancel: dismiss dialog, close swipe
    - NOT available on completed sessions
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

  - [x] 7.3 Implement empty states for ChatScreen
    - Active empty: illustration + "Belum ada sesi aktif" + "Mulai Cerita" button → switch to Persona tab
    - Completed empty: illustration + "Belum ada sesi yang selesai"
    - Show shimmer during loading (not empty state)
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [x] 7.4 Create SessionListTile widget di `lib/widgets/chat/session_list_tile.dart`
    - Reusable tile showing persona name, message preview, relative time, status badge
    - Support for scoreDelta display on completed sessions
    - Use `formatRelativeTime()` for time display
    - _Requirements: 6.2, 6.3_

- [x] 8. PersonaScreen implementation
  - [x] 8.1 Create PersonaScreen di `lib/screens/persona/persona_list_screen.dart`
    - 2-column grid layout (GridView.builder with crossAxisCount: 2)
    - Each card: avatar, name, short description (max 2 lines), upvote count, downvote count
    - NO vote buttons on grid cards
    - Infinite scroll: detect scroll near bottom → PersonaProvider.fetchNextPage()
    - Stop fetching when currentPage == totalPages (no bottom loading indicator)
    - Shimmer skeleton for first page load
    - Loading indicator at bottom for subsequent pages
    - Pull-to-refresh: PersonaProvider.refreshPersonas()
    - Error: show SnackBar with backend message
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8, 9.9_

  - [x] 8.2 Create PersonaGridCard widget di `lib/widgets/persona/persona_grid_card.dart`
    - Avatar image (CachedNetworkImage with placeholder)
    - Name text
    - Description truncated to 2 lines
    - Upvote and downvote count display (no buttons)
    - Tap callback for navigation
    - _Requirements: 9.2, 9.3_

- [x] 9. PersonaDetailScreen implementation
  - [x] 9.1 Create PersonaDetailScreen di `lib/screens/persona/persona_detail_screen.dart`
    - Fetch persona detail via PersonaProvider.fetchPersonaDetail(id) on init
    - Display: name, avatar, full description, upvote count, downvote count
    - Vote buttons (UP, DOWN) with visual highlight for current user rating
    - No highlight when rating is NONE
    - Tap different vote: optimistic update via PersonaProvider.ratePersona()
    - Tap same vote (toggle off): send NONE, decrement count
    - Show session count with this persona (filter user sessions by personaId)
    - "Mulai Chat" button to create session
    - Shimmer loading state
    - Error: show SnackBar with backend message
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.9, 10.10_

  - [x] 9.2 Implement start chat from PersonaDetailScreen
    - "Mulai Chat" tap → SessionProvider.createSession(personaId)
    - Success (201): navigate to chat screen with new session ID
    - Failure: show error SnackBar, re-enable button
    - Loading: disable button + show loading indicator
    - Handle 404/400 errors for inactive/not-found persona
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 10. Checkpoint — Navigation and main screens
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. ProfileScreen implementation
  - [x] 11.1 Create ProfileScreen di `lib/screens/profile/profile_screen.dart`
    - Display circular avatar (CachedNetworkImage or default placeholder if null)
    - Display name, email, points with circular progress indicator (reuse ScoreCardWidget pattern)
    - Display join date formatted as "dd MMMM yyyy" using intl package with 'id' locale
    - Menu items: "Edit Profil" → EditProfileScreen, "Ubah Password" → ChangePasswordScreen, "Keluar" → logout
    - Shimmer loading state while profile data loads
    - Read user data from AuthProvider.currentUser
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6_

  - [x] 11.2 Implement logout functionality in ProfileScreen
    - Tap "Keluar" → show confirmation dialog: title "Konfirmasi Logout", message "Apakah kamu yakin ingin keluar?", buttons "Batal" and "Keluar"
    - Confirm: disable button, show loading, call AuthProvider.logout()
    - Logout completes → navigate to login (AuthStatus.unauthenticated triggers redirect)
    - Cancel: dismiss dialog
    - Network error on logout: still clear tokens and navigate to login
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [x] 12. EditProfileScreen implementation
  - [x] 12.1 Create EditProfileScreen di `lib/screens/profile/edit_profile_screen.dart`
    - Form with name TextField (pre-filled, max 50 chars) and avatar image picker
    - Image picker shows current avatar or default placeholder
    - Select new image → show preview replacing current avatar
    - Validate image: reject if > 5MB or not JPEG/PNG, show error SnackBar
    - Submit: PATCH /api/me as multipart/form-data with field "image" (if changed) and "name"
    - Validate name: non-empty, non-whitespace-only, max 50 chars
    - Success: navigate back to ProfileScreen, refresh user data via AuthProvider.fetchMe()
    - Failure: show error SnackBar with backend message
    - Loading: disable submit button + show loading indicator
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8_

  - [x] 12.2 Write property tests for image validation (Property 11)
    - **Property 11: Image file validation correctly accepts/rejects based on size and format**
    - Test with random file size (0-20MB) and random format
    - Verify: accept JPEG/PNG ≤ 5MB, reject others
    - **Validates: Requirements 13.3**

  - [x] 12.3 Write property tests for name validation (Property 12)
    - **Property 12: Name validation rejects empty and whitespace-only strings**
    - Test with random whitespace strings and random valid strings
    - Verify: reject empty/whitespace-only, accept non-empty with non-whitespace ≤ 50 chars
    - **Validates: Requirements 13.8**

- [x] 13. ChangePasswordScreen implementation
  - [x] 13.1 Create ChangePasswordScreen di `lib/screens/profile/change_password_screen.dart`
    - Form with 3 obscured password fields: old password, new password, confirm new password
    - Client-side validation: old not empty, new 8-128 chars, confirm matches new
    - Inline error messages beneath respective fields on validation failure
    - Submit: PATCH /api/me/password with { oldPassword, newPassword }
    - Success: show green SnackBar, navigate back to ProfileScreen
    - 401 "Password lama salah": show error SnackBar with exact message
    - Other errors: show error SnackBar with backend message
    - Loading: disable submit + show loading indicator
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8_

  - [x] 13.2 Write property tests for password validation (Property 13)
    - **Property 13: Password validation enforces all rules correctly**
    - Test with random string triples (oldPassword, newPassword, confirmPassword)
    - Verify: fail if old empty, fail if new < 8 or > 128, fail if confirm ≠ new, pass only when all satisfied
    - **Validates: Requirements 14.2**

- [x] 14. Final checkpoint — All screens complete
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- All API calls use `/api/` prefix — see `ApiEndpoints` class (already has session and persona endpoints)
- Response parsing always uses `response.data['data']` pattern
- Error handling: DioException → AppException.fromDioError() → expose errorMessage
- Loading states use Shimmer skeleton (not plain CircularProgressIndicator)
- Persona name resolution in session list: use `PersonaProvider.getById(session.personaId)`
- Upload avatar field name MUST be `image` (not `avatar` or `file`)
- `PATCH /api/me/password` returns 401 for wrong old password (not 400)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["1.4", "1.5", "1.6", "1.7", "2.1", "3.1"] },
    { "id": 2, "tasks": ["2.2", "2.3", "2.4", "3.2", "3.3", "3.4"] },
    { "id": 3, "tasks": ["5.1", "5.2", "5.3"] },
    { "id": 4, "tasks": ["6.1", "6.2", "7.1", "8.1"] },
    { "id": 5, "tasks": ["7.2", "7.3", "7.4", "8.2", "9.1"] },
    { "id": 6, "tasks": ["9.2", "11.1"] },
    { "id": 7, "tasks": ["11.2", "12.1"] },
    { "id": 8, "tasks": ["12.2", "12.3", "13.1"] },
    { "id": 9, "tasks": ["13.2"] }
  ]
}
```
