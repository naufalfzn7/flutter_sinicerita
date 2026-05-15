# Implementation Plan: Session Detail Completed

## Overview

Implementasi fitur detail sesi selesai (completed) yang diakses dari tab "Selesai" di ChatListScreen. Meliputi: penambahan state & method di SessionProvider, pembuatan helper functions, pembuatan SessionDetailScreen, penambahan route GoRouter, update SessionListTile (chevron + navigasi), dan update ChatScreen untuk read-only mode pada sesi completed.

## Tasks

- [x] 1. Create helper functions and extend SessionProvider
  - [x] 1.1 Create session detail helper functions
    - Create file `lib/core/utils/session_detail_helpers.dart`
    - Implement `formatScoreDelta(int delta)` → "+N" / "-N" / "0"
    - Implement `getScoreDeltaColor(int delta)` → green / red / grey
    - Implement `isAnalysisSummaryEmpty(String? summary)` → true for null/empty/whitespace
    - Implement `truncateWithEllipsis(String text, int maxLength)` → truncate + "..." or unchanged
    - Implement `formatDateTimeIndonesian(DateTime dateTime)` → "d MMMM yyyy, HH:mm" with 'id_ID' locale using intl package
    - _Requirements: 2.1, 2.2, 3.3, 4.2, 7.1, 7.2, 7.3_

  - [x] 1.2 Add `fetchSessionDetail` method and state fields to SessionProvider
    - Add private fields: `_sessionDetail` (SessionModel?), `_detailPersona` (PersonaModel?), `_isLoadingDetail` (bool)
    - Add public getters: `sessionDetail`, `detailPersona`, `isLoadingDetail`
    - Implement `fetchSessionDetail(String sessionId)`: set loading, GET /api/sessions/:id, parse SessionModel + embedded PersonaModel, handle DioException → AppException → errorMessage
    - Implement `clearDetailState()` to reset detail-related fields
    - Import PersonaModel in session_provider.dart
    - _Requirements: 1.3, 1.4, 1.5, 1.6, 6.1, 6.2, 6.3, 6.4_

  - [x] 1.3 Write property tests for helper functions (Properties 2, 3, 4, 5)
    - Create file `test/core/utils/session_detail_helpers_property_test.dart`
    - **Property 2: ScoreDelta display formatting correctness**
    - **Validates: Requirements 2.1, 2.2, 7.3**
    - For any integer scoreDelta in [-20, +20], verify prefix "+" for positive, inherent "-" for negative, "0" for zero; verify color green/red/grey respectively
    - **Property 3: Empty summary detection**
    - **Validates: Requirements 3.3, 7.2**
    - For any string that is null/empty/whitespace-only → true; for any string with at least one non-whitespace char → false
    - **Property 4: Analysis summary truncation**
    - **Validates: Requirements 7.1**
    - For any non-empty string, if length > 50 → first 50 chars + "..."; if length ≤ 50 → unchanged
    - **Property 5: Date formatting produces valid Indonesian locale output**
    - **Validates: Requirements 4.2**
    - For any valid DateTime, output matches pattern "d MMMM yyyy, HH:mm" with Indonesian month names and 24-hour time
    - Use minimum 100 iterations per property

- [x] 2. Checkpoint - Ensure helper functions and provider compile correctly
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Create SessionDetailScreen and register route
  - [x] 3.1 Create SessionDetailScreen widget
    - Create file `lib/screens/session/session_detail_screen.dart`
    - StatefulWidget receiving `sessionId` via constructor
    - Call `fetchSessionDetail(sessionId)` in initState (via addPostFrameCallback)
    - Show shimmer skeleton while `isLoadingDetail` is true
    - Display score delta section: large font (24sp+), color coded, with prefix sign; hide entire section if scoreDelta is null
    - Display "Analisis AI" Card with scrollable analysisSummary content; show "Analisis tidak tersedia" placeholder if summary is null/empty/whitespace
    - Display metadata: persona name from `detailPersona` (fallback text if null), startedAt and completedAt formatted with `formatDateTimeIndonesian`
    - Display "Lihat Riwayat Chat" button (ElevatedButton, full width, visible without scroll)
    - AppBar with back button calling `context.pop()`
    - Handle error state: red SnackBar with exact backend message, "Coba Lagi" button for network/server errors, "Kembali" button for 404/403
    - Call `clearDetailState()` on dispose
    - _Requirements: 1.1, 1.2, 1.4, 1.5, 1.6, 2.1, 2.2, 2.5, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 6.4_

  - [x] 3.2 Add GoRouter route for SessionDetailScreen
    - Add route `/session-detail/:sessionId` in `lib/main.dart`
    - Extract `sessionId` from `state.pathParameters['sessionId']`
    - Pass sessionId to `SessionDetailScreen(sessionId: sessionId)`
    - Add import for `SessionDetailScreen`
    - _Requirements: 1.1, 1.2_

  - [x] 3.3 Write property test for session detail response parsing (Property 1)
    - Create file `test/providers/session_detail_property_test.dart`
    - **Property 1: Session detail response parsing preserves all fields**
    - **Validates: Requirements 1.3**
    - For any valid session detail JSON with id, status, scoreDelta, analysisSummary, startedAt, completedAt, and embedded persona, parsing via SessionModel.fromJson and PersonaModel.fromJson preserves all field values
    - Use minimum 100 iterations

- [x] 4. Update SessionListTile and ChatScreen
  - [x] 4.1 Update SessionListTile for completed sessions
    - Add chevron icon (`Icons.arrow_forward_ios`, size 16) in trailing position for completed sessions
    - Ensure preview uses "Analisis tidak tersedia" placeholder for null/empty analysisSummary (already implemented, verify)
    - Ensure truncation at 50 chars with ellipsis (already implemented, verify)
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [x] 4.2 Update navigation for completed sessions in ChatListScreen
    - When tapping a completed session item, navigate to `/session-detail/:sessionId` instead of `/chat/:sessionId`
    - Keep active session tap behavior unchanged (navigate to `/chat/:sessionId`)
    - _Requirements: 1.1_

  - [x] 4.3 Update ChatScreen for read-only mode on completed sessions
    - Hide the entire input area (text field + send button) when session status is 'completed'
    - Determine completed status: session is NOT in `activeSessions` list AND messages loaded successfully
    - Show an informational banner/text indicating the chat is read-only (e.g., "Sesi ini telah selesai. Chat hanya bisa dibaca.")
    - Keep "Akhiri Sesi" button hidden (already handled by `isSessionActive` check)
    - _Requirements: 5.4_

  - [x] 4.4 Write property test for error message passthrough (Property 6)
    - Create file `test/providers/session_error_property_test.dart`
    - **Property 6: Error message passthrough integrity**
    - **Validates: Requirements 6.1**
    - For any DioException with a badResponse containing a message field, AppException.fromDioError preserves the exact backend message string, and the provider exposes this exact string via errorMessage
    - Use minimum 100 iterations

- [x] 5. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using glados library
- Unit tests validate specific examples and edge cases
- Design decision: only `scoreDelta` is displayed (not full points comparison) since `newPoints` is not available in GET /api/sessions/:id response
- The existing `SessionListTile._getPreview()` already handles truncation and placeholder — task 4.1 focuses on adding the chevron icon
- Persona name on SessionDetailScreen comes from the embedded `persona` object in the detail response (via `detailPersona`), not from PersonaProvider

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "3.1", "3.2"] },
    { "id": 2, "tasks": ["3.3", "4.1", "4.2", "4.3"] },
    { "id": 3, "tasks": ["4.4"] }
  ]
}
```
