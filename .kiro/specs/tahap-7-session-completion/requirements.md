# Requirements Document

## Introduction

Tahap 7 menambahkan fitur penyelesaian sesi chat (session completion) pada aplikasi SiniCerita. Setelah user selesai bercerita, user dapat mengakhiri sesi dan menerima analisis AI berupa perubahan skor kesehatan mental (score delta) beserta ringkasan. Hasil analisis ditampilkan di layar ringkasan sesi (Session Summary Screen) dengan visualisasi perubahan poin.

## Glossary

- **Session_Provider**: ChangeNotifier yang mengelola state sesi chat, termasuk CRUD sessions, messages, dan completion
- **Chat_Screen**: Halaman percakapan aktif antara user dan persona AI
- **Session_Summary_Screen**: Halaman yang menampilkan hasil analisis AI setelah sesi selesai
- **Score_Delta**: Nilai perubahan skor kesehatan mental dari analisis AI, berkisar -20 sampai +20
- **Health_Points**: Skor kesehatan mental user, berkisar 0 sampai 100
- **Completion_API**: Endpoint `PATCH /api/sessions/:id/complete` yang menganalisis percakapan dan mengembalikan hasil
- **Confirmation_Dialog**: Dialog konfirmasi sebelum mengakhiri sesi
- **Auth_Provider**: ChangeNotifier yang mengelola state autentikasi dan data user (termasuk points)

## Requirements

### Requirement 1: Tombol Akhiri Sesi di Chat Screen

**User Story:** As a user, I want to end an active chat session from the chat screen, so that I can get AI analysis of my conversation.

#### Acceptance Criteria

1. WHILE a session has status 'active', THE Chat_Screen SHALL display an "Akhiri Sesi" button in the app bar
2. WHEN the user taps the "Akhiri Sesi" button, THE Chat_Screen SHALL show a Confirmation_Dialog with title "Akhiri Sesi?" and explanation text describing that the session will be analyzed
3. WHEN the user dismisses or cancels the Confirmation_Dialog, THE Chat_Screen SHALL close the dialog and take no further action, leaving the session in 'active' status
4. WHEN the user confirms the Confirmation_Dialog, THE Session_Provider SHALL call the Completion_API with the session ID
5. WHILE the Completion_API call is in progress, THE Chat_Screen SHALL disable the "Akhiri Sesi" button and show a loading indicator
6. WHILE the Completion_API call is in progress, THE Chat_Screen SHALL prevent the user from sending new messages
7. WHEN the Completion_API call returns successfully, THE Chat_Screen SHALL navigate the user to the Session_Summary_Screen displaying the scoreDelta, newPoints, and analysis summary from the response
8. IF the Completion_API call fails, THEN THE Chat_Screen SHALL re-enable the "Akhiri Sesi" button, hide the loading indicator, and display a red SnackBar with the error message returned by the backend

### Requirement 2: API Communication untuk Session Completion

**User Story:** As a user, I want the app to communicate with the backend to complete my session, so that I receive accurate AI analysis results.

#### Acceptance Criteria

1. WHEN the Session_Provider calls the Completion_API, THE Session_Provider SHALL send a PATCH request to `/api/sessions/:id/complete` with no request body
2. WHEN the Completion_API returns status 200, THE Session_Provider SHALL parse `scoreDelta` (int), `newPoints` (int), and `summary` (string) from `response.data['data']`
3. WHEN the Completion_API returns status 200, THE Session_Provider SHALL calculate `previousPoints` as `newPoints - scoreDelta`
4. WHEN the Completion_API returns status 200, THE Session_Provider SHALL update the session status from 'active' to 'completed' in local state
5. IF the Completion_API returns status 409, THEN THE Session_Provider SHALL set errorMessage to the exact backend message "Sesi sudah selesai"
6. IF the Completion_API returns status 403, THEN THE Session_Provider SHALL set errorMessage to the exact backend message "Akses ditolak: sesi bukan milik Anda"
7. IF a network error occurs during the Completion_API call, THEN THE Session_Provider SHALL set errorMessage to the error description from AppException
8. WHILE the Completion_API call is in progress, THE Session_Provider SHALL set a `isCompleting` flag to true and call `notifyListeners()` so the UI can reflect the loading state
9. WHEN the Completion_API call completes (success or failure), THE Session_Provider SHALL set the `isCompleting` flag to false and call `notifyListeners()`

### Requirement 3: Session Summary Screen

**User Story:** As a user, I want to see a summary of my session results after completion, so that I can understand how the conversation affected my mental health score.

#### Acceptance Criteria

1. WHEN the Completion_API returns successfully, THE Chat_Screen SHALL navigate to the Session_Summary_Screen passing scoreDelta (int), newPoints (int), and summary (string) from the completion response
2. THE Session_Summary_Screen SHALL display the Score_Delta value with color coding: green for positive values (greater than 0), red for negative values (less than 0), and grey for zero
3. THE Session_Summary_Screen SHALL display the previous Health_Points value (calculated as newPoints - scoreDelta) with a label identifying it as the previous score
4. THE Session_Summary_Screen SHALL display the new Health_Points value with a label identifying it as the current score
5. THE Session_Summary_Screen SHALL display the AI analysis summary text in a scrollable area
6. WHEN the user taps the "Kembali ke Beranda" button, THE Session_Summary_Screen SHALL navigate the user to the home screen and remove the Session_Summary_Screen and Chat_Screen from the navigation stack
7. THE Session_Summary_Screen SHALL display a "+" prefix for positive Score_Delta values, no prefix for negative values (negative sign is inherent), and no prefix for zero
8. WHEN the user presses the system back button or performs a back gesture on the Session_Summary_Screen, THE Session_Summary_Screen SHALL navigate to the home screen instead of returning to the Chat_Screen

### Requirement 4: Update Health Points Secara Global

**User Story:** As a user, I want my health points to be updated across the app after session completion, so that I see my current score everywhere.

#### Acceptance Criteria

1. WHEN the Completion_API returns successfully with `newPoints` (integer, 0-100), `scoreDelta` (integer, -20 to +20), and `summary` (string), THE Session_Provider SHALL call a method on the Auth_Provider to update the user's Health_Points to the `newPoints` value and SHALL call `notifyListeners()` so that all widgets consuming Auth_Provider rebuild with the updated points
2. WHEN the Auth_Provider receives the updated points value, THE Auth_Provider SHALL replace the `points` field in the local `currentUser` model with the `newPoints` value and SHALL call `notifyListeners()` within the same synchronous execution frame
3. WHEN the session is completed successfully, THE Session_Provider SHALL remove the session from the active sessions list, create an updated session object with `status` set to `'completed'`, `scoreDelta` set to the response value, and `analysisSummary` set to the response `summary` value, and add it to the beginning of the completed sessions list
4. IF the Completion_API returns an error (network failure or non-2xx status), THEN THE Session_Provider SHALL preserve the session in the active sessions list unchanged, SHALL NOT update Health_Points in the Auth_Provider, and SHALL expose the backend error message via `errorMessage` for display in a red SnackBar

### Requirement 5: Error Handling dan UI Feedback

**User Story:** As a user, I want clear error feedback when something goes wrong during session completion, so that I know what happened and can take action.

#### Acceptance Criteria

1. IF the Completion_API returns an error (status other than 409), THEN THE Chat_Screen SHALL display a red SnackBar with the exact error message from the backend for 4 seconds and remain on the chat screen with the complete button re-enabled
2. IF the Completion_API returns status 409 ("Sesi sudah selesai"), THEN THE Chat_Screen SHALL display a red SnackBar with the error message and navigate back to the home screen after a 2-second delay
3. IF a network error occurs during the completion request, THEN THE Chat_Screen SHALL display a red SnackBar with the AppException message for 4 seconds and remain on the chat screen with the complete button re-enabled
4. WHILE the completion request is loading, THE Chat_Screen SHALL disable the complete button and show a loading overlay that blocks user interaction to prevent duplicate submissions
5. IF the Completion_API returns status 403 ("Akses ditolak: sesi bukan milik Anda"), THEN THE Chat_Screen SHALL display a red SnackBar with the exact error message from the backend and navigate back to the home screen after a 2-second delay
