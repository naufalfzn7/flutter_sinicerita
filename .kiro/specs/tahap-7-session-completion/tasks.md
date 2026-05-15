# Implementation Plan: Tahap 7 — Session Completion

## Overview

Implementasi fitur session completion pada aplikasi SiniCerita. User dapat mengakhiri sesi chat aktif, memicu analisis AI di backend, dan menerima hasil berupa score delta dan ringkasan yang ditampilkan di Session Summary Screen. Implementasi menggunakan Flutter/Dart dengan Provider pattern, Dio HTTP client, dan GoRouter navigation.

## Tasks

- [x] 1. Create CompletionResult model and API endpoint constant
  - [x] 1.1 Add `sessionComplete` endpoint to `api_endpoints.dart`
    - Add static method `sessionComplete(String id)` returning `/api/sessions/$id/complete`
    - Follow existing pattern in the file for parameterized endpoints
    - _Requirements: 2.1_

  - [x] 1.2 Create `CompletionResult` value object in `lib/models/completion_result.dart`
    - Define immutable class with fields: `scoreDelta` (int), `newPoints` (int), `previousPoints` (int), `summary` (String)
    - Add const constructor with required named parameters
    - _Requirements: 2.2, 2.3_

- [x] 2. Implement SessionProvider `completeSession` method
  - [x] 2.1 Add `isCompleting` state and `completeSession` method to `lib/providers/session_provider.dart`
    - Add `_isCompleting` private field (default false) with public getter
    - Implement `Future<CompletionResult?> completeSession(String sessionId, AuthProvider authProvider)`
    - Set `isCompleting = true` and `_errorMessage = null`, call `notifyListeners()` at start
    - Send PATCH request to `ApiEndpoints.sessionComplete(sessionId)` with no body
    - On success: parse `response.data['data']['scoreDelta']`, `['newPoints']`, `['summary']`
    - Calculate `previousPoints = newPoints - scoreDelta`
    - Update session status from 'active' to 'completed' in local state (move between lists)
    - Call `authProvider.updatePoints(newPoints)`
    - Set `isCompleting = false`, call `notifyListeners()`, return `CompletionResult`
    - On `DioException`: convert via `AppException.fromDioError()`, set `_errorMessage`, return null
    - Ensure `isCompleting` is always reset to false in finally block
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 4.1, 4.3, 4.4_

  - [x] 2.2 Write property test: previousPoints Calculation (Property 1)
    - **Property 1: previousPoints Calculation**
    - For any valid `newPoints` (0–100) and `scoreDelta` (-20 to +20), verify `previousPoints == newPoints - scoreDelta`
    - **Validates: Requirements 2.3, 3.3**

  - [x] 2.3 Write property test: isCompleting Lifecycle Invariant (Property 2)
    - **Property 2: isCompleting Lifecycle Invariant**
    - For any call to `completeSession()` (success or failure), verify `isCompleting` is true during execution and false after
    - **Validates: Requirements 2.8, 2.9**

  - [x] 2.4 Write property test: Session State Transition on Success (Property 3)
    - **Property 3: Session State Transition on Success**
    - For any active session successfully completed, verify session removed from active list and added to beginning of completed list with correct status, scoreDelta, and analysisSummary
    - **Validates: Requirements 2.4, 4.3**

  - [x] 2.5 Write property test: Error Preservation Invariant (Property 5)
    - **Property 5: Error Preservation Invariant**
    - For any failed completion, verify session remains in active list unchanged, AuthProvider points unchanged, and errorMessage is non-null
    - **Validates: Requirements 4.4**

  - [x] 2.6 Write property test: DioException to AppException Mapping (Property 7)
    - **Property 7: DioException to AppException Mapping**
    - For any DioExceptionType, verify `AppException.fromDioError()` produces non-empty error message exposed via `errorMessage`
    - **Validates: Requirements 2.7**

- [x] 3. Implement AuthProvider `updatePoints` method
  - [x] 3.1 Add `updatePoints(int newPoints)` method to `lib/providers/auth_provider.dart`
    - If `_currentUser` is null, return immediately (no-op)
    - Create new `UserModel` instance with updated `points` field (immutable pattern)
    - Assign to `_currentUser` and call `notifyListeners()`
    - Synchronous method — no async, no API call
    - _Requirements: 4.1, 4.2_

  - [x] 3.2 Write property test: Global Points Update on Success (Property 4)
    - **Property 4: Global Points Update on Success**
    - For any `newPoints` (0–100), verify `authProvider.currentUser.points == newPoints` after calling `updatePoints`
    - **Validates: Requirements 4.1, 4.2**

- [x] 4. Checkpoint - Ensure provider logic is correct
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Modify ChatScreen for session completion UI
  - [x] 5.1 Add "Akhiri Sesi" button and confirmation dialog to `lib/screens/chat/chat_screen.dart`
    - Add `TextButton` with text "Akhiri Sesi" in AppBar `actions` (visible only when session is active)
    - On tap: show `AlertDialog` with title "Akhiri Sesi?" and content explaining AI analysis
    - Dialog has "Batal" (cancel) and "Ya, Akhiri" (confirm) buttons
    - Cancel dismisses dialog, no state change
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 5.2 Add loading state and completion logic to ChatScreen
    - Listen to `SessionProvider.isCompleting` via `context.watch<SessionProvider>()`
    - When `isCompleting == true`: disable "Akhiri Sesi" button, disable message input field and send button
    - Show `LoadingOverlay` (semi-transparent overlay with CircularProgressIndicator) blocking all interaction
    - On confirm: call `sessionProvider.completeSession(sessionId, authProvider)`
    - On success (result != null): navigate via `context.go('/session-summary', extra: {...})`
    - On failure (result == null): show red SnackBar with `sessionProvider.errorMessage`
    - If error is "Sesi sudah selesai" or "Akses ditolak: sesi bukan milik Anda": navigate to `/main` after 2s delay
    - Otherwise: stay on chat screen, button re-enabled
    - _Requirements: 1.4, 1.5, 1.6, 1.7, 1.8, 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 6. Create SessionSummaryScreen
  - [x] 6.1 Create `lib/screens/chat/session_summary_screen.dart`
    - StatelessWidget receiving `scoreDelta` (int), `newPoints` (int), `summary` (String) via constructor
    - Calculate `previousPoints = newPoints - scoreDelta` locally
    - AppBar: title "Ringkasan Sesi", no back button (use `automaticallyImplyLeading: false`)
    - Score Delta card: large text with color coding (green > 0, red < 0, grey == 0)
    - Prefix formatting: "+" for positive, no prefix for negative/zero
    - Points comparison section: previousPoints → newPoints with arrow indicator
    - Summary card: AI analysis text in scrollable container
    - "Kembali ke Beranda" full-width button at bottom → `context.go('/main')`
    - Wrap with `PopScope(canPop: false)` — back gesture/button → `context.go('/main')`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

  - [x] 6.2 Write property test: ScoreDelta Display Formatting (Property 6)
    - **Property 6: ScoreDelta Display Formatting**
    - For any `scoreDelta` (-20 to +20), verify: green when > 0, red when < 0, grey when == 0; "+" prefix for positive, no prefix for negative/zero
    - **Validates: Requirements 3.2, 3.7**

- [x] 7. Add GoRouter route for SessionSummaryScreen
  - [x] 7.1 Register `/session-summary` route in `main.dart`
    - Add `GoRoute` with path `/session-summary`
    - Builder extracts `state.extra` as `Map<String, dynamic>` with keys: `scoreDelta`, `newPoints`, `summary`
    - Pass extracted values to `SessionSummaryScreen` constructor
    - Place route at top-level (not nested under shell route) so navigation stack is replaced on `context.go`
    - _Requirements: 3.1, 3.6, 3.8_

- [x] 8. Checkpoint - Ensure full flow works end-to-end
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The design uses Dart/Flutter — all code examples use Dart
- `previousPoints` is NOT in the API response — must be calculated as `newPoints - scoreDelta`
- Use `context.go()` (not `context.push()`) for navigation to session-summary to replace the stack
- Error messages from backend must be displayed exactly as received (no translation)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["2.1", "3.1"] },
    { "id": 2, "tasks": ["2.2", "2.3", "2.4", "2.5", "2.6", "3.2"] },
    { "id": 3, "tasks": ["5.1", "6.1", "7.1"] },
    { "id": 4, "tasks": ["5.2", "6.2"] }
  ]
}
```
