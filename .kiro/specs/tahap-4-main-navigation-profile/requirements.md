# Requirements Document

## Introduction

Tahap 4 membangun shell navigasi utama aplikasi SiniCerita setelah user berhasil login. Fitur ini menggantikan placeholder MainScreen dengan BottomNavigationBar 4 tab (Beranda, Chat, Persona, Profil) beserta seluruh screen dan fungsionalitas di dalamnya: dashboard home dengan greeting dan score card, manajemen sesi chat, daftar persona dengan detail dan voting, serta profil user dengan edit dan change password.

## Glossary

- **Main_Shell**: Widget utama setelah login yang menampung BottomNavigationBar dan 4 tab content
- **Home_Screen**: Tab pertama yang menampilkan dashboard berisi greeting, score card, session summary, quick action, dan daily tips
- **Chat_Screen**: Tab kedua yang menampilkan daftar sesi chat user (aktif dan selesai)
- **Persona_Screen**: Tab ketiga yang menampilkan daftar persona AI dalam grid layout
- **Profile_Screen**: Tab keempat yang menampilkan informasi profil user
- **Score_Card**: Widget circular progress indicator yang menampilkan mental health points (0-100)
- **Session_Provider**: ChangeNotifier yang mengelola state sesi chat (CRUD, list, delete)
- **Persona_Provider**: ChangeNotifier yang mengelola state persona (list, detail, rating)
- **Navigation_Bar**: BottomNavigationBar dengan 4 tab: Beranda, Chat, Persona, Profil
- **Edit_Profile_Screen**: Screen untuk mengedit nama dan upload foto profil
- **Change_Password_Screen**: Screen untuk mengubah password user
- **Persona_Detail_Screen**: Screen detail persona dengan info lengkap, voting, dan tombol mulai chat
- **Daily_Tip**: Tips kesehatan mental harian yang dipilih dari array lokal berdasarkan tanggal

## Requirements

### Requirement 1: Bottom Navigation Shell

**User Story:** As a logged-in user, I want a bottom navigation bar with 4 tabs, so that I can easily switch between main sections of the app.

#### Acceptance Criteria

1. THE Main_Shell SHALL display a BottomNavigationBar with exactly 4 tabs in this order: Beranda (Icons.home), Chat (Icons.chat_bubble), Persona (Icons.people), Profil (Icons.person), with Beranda selected as the default active tab on initial display
2. WHEN a tab is tapped, THE Main_Shell SHALL switch the displayed content to the corresponding screen without pushing a new route, and the transition SHALL complete within a single frame (no page transition animation)
3. THE Main_Shell SHALL preserve the state of each tab when switching between tabs, such that scroll position and previously loaded data remain intact when returning to a previously visited tab
4. THE Navigation_Bar SHALL highlight the currently active tab by applying a differentiated color to both the icon and label of the selected tab, distinguishable from the unselected tabs' icon and label color
5. WHEN the Main_Shell is displayed, THE Navigation_Bar SHALL be visible and accessible on all 4 tab screens without being obscured by screen content

### Requirement 2: Home Dashboard — Greeting

**User Story:** As a user, I want to see a personalized time-based greeting, so that the app feels welcoming and contextual.

#### Acceptance Criteria

1. WHEN the current device time is between 00:00 and 10:59, THE Home_Screen SHALL display "Selamat pagi, {user name}" where {user name} is the name field from the authenticated user's profile
2. WHEN the current device time is between 11:00 and 14:59, THE Home_Screen SHALL display "Selamat siang, {user name}" where {user name} is the name field from the authenticated user's profile
3. WHEN the current device time is between 15:00 and 17:59, THE Home_Screen SHALL display "Selamat sore, {user name}" where {user name} is the name field from the authenticated user's profile
4. WHEN the current device time is between 18:00 and 23:59, THE Home_Screen SHALL display "Selamat malam, {user name}" where {user name} is the name field from the authenticated user's profile
5. IF the user's name is null or empty, THEN THE Home_Screen SHALL display the greeting text without appending a name (e.g., "Selamat pagi")
6. WHEN the Home_Screen is visible and the device time crosses a greeting time boundary, THE Home_Screen SHALL update the greeting text to match the new time range within 60 seconds
7. THE Home_Screen SHALL truncate the displayed user name to a maximum of 30 characters followed by an ellipsis if the name exceeds that length

### Requirement 3: Home Dashboard — Mental Health Score Card

**User Story:** As a user, I want to see my mental health score visually, so that I can quickly understand my current emotional state.

#### Acceptance Criteria

1. THE Score_Card SHALL display the user's current points as an integer (0-100) inside a circular progress indicator
2. THE Score_Card SHALL render the circular progress indicator fill proportional to the points value divided by 100 (e.g., 75 points = 75% fill)
3. IF the user's points are between 0 and 39, THEN THE Score_Card SHALL display the status text "Kamu butuh perhatian lebih, yuk cerita" and render the circular progress indicator in a red-tone color
4. IF the user's points are between 40 and 69, THEN THE Score_Card SHALL display the status text "Keadaanmu cukup stabil, tetap semangat" and render the circular progress indicator in a yellow-tone color
5. IF the user's points are between 70 and 100, THEN THE Score_Card SHALL display the status text "Keadaanmu baik, pertahankan ya!" and render the circular progress indicator in a green-tone color
6. THE Score_Card SHALL obtain the points value from the authenticated user's profile data exposed by the AuthProvider
7. WHILE the user profile data is being loaded, THE Score_Card SHALL display a shimmer skeleton placeholder matching the card dimensions

### Requirement 4: Home Dashboard — Session Summary Cards

**User Story:** As a user, I want to see a summary of my chat sessions, so that I can quickly know my activity status.

#### Acceptance Criteria

1. WHEN the Beranda tab is selected, THE Home_Screen SHALL fetch session data from GET /api/sessions and persona count from GET /api/personas to calculate summary counts
2. THE Home_Screen SHALL display three summary cards: "Sesi Aktif" (count of sessions with status "active"), "Sesi Selesai" (count of sessions with status "completed"), and "Persona Tersedia" (total persona count obtained from the meta.total field of GET /api/personas response)
3. WHILE session data or persona data is being fetched, THE Home_Screen SHALL display shimmer skeleton placeholders for all three summary cards
4. IF the session data fetch or persona data fetch fails, THEN THE Home_Screen SHALL display zero for the affected counts and show an error SnackBar with the backend error message
5. WHEN the user pulls down on the Home_Screen, THE Home_Screen SHALL re-fetch both session and persona data to update the summary card counts

### Requirement 5: Home Dashboard — Quick Action and Daily Tips

**User Story:** As a user, I want a quick way to start chatting and see daily mental health tips, so that I am encouraged to use the app regularly.

#### Acceptance Criteria

1. THE Home_Screen SHALL display a "Mulai Cerita" button that is visible without scrolling on the dashboard
2. WHEN the "Mulai Cerita" button is tapped, THE Main_Shell SHALL switch the active tab to the Persona tab
3. THE Home_Screen SHALL display a Daily_Tip card containing a tip text string selected from a local array of at least 7 tips
4. THE Daily_Tip SHALL use the current date as a seed (date modulo array length) so that the same tip is shown throughout the entire day and consecutive days display a different tip
5. WHEN the app is open and the device date changes to the next day, THE Daily_Tip SHALL update to display the tip corresponding to the new date's index

### Requirement 6: Chat Tab — Session List with TabBar

**User Story:** As a user, I want to see my active and completed chat sessions in separate tabs, so that I can manage my conversations effectively.

#### Acceptance Criteria

1. THE Chat_Screen SHALL display a TabBar with two tabs: "Aktif" (selected by default) and "Selesai"
2. WHEN the "Aktif" tab is selected, THE Chat_Screen SHALL display a list of sessions with status "active" ordered by most recently updated first, showing persona name (resolved via Persona_Provider), last message preview truncated to a maximum of 50 characters, last message time formatted as relative time (e.g., "2 menit lalu", "1 jam lalu", or date if older than 24 hours), and a status badge "Aktif"
3. WHEN the "Selesai" tab is selected, THE Chat_Screen SHALL display a list of sessions with status "completed" ordered by completedAt descending, showing persona name (resolved via Persona_Provider), last message preview truncated to a maximum of 50 characters, last message time formatted as relative time, a status badge "Selesai", and the score delta value displayed with sign prefix (e.g., "+5", "-3")
4. WHEN an active session item is tapped, THE Chat_Screen SHALL navigate to the chat screen for that session
5. WHEN a completed session item is tapped, THE Chat_Screen SHALL navigate to a read-only chat view for that session
6. WHILE session list data is being fetched, THE Chat_Screen SHALL display shimmer skeleton placeholders
7. WHEN the user pulls down on the session list, THE Chat_Screen SHALL refresh the session data from the backend
8. IF the session data fetch fails, THEN THE Chat_Screen SHALL display an error SnackBar with the backend error message and retain any previously loaded session data

### Requirement 7: Chat Tab — Session Deletion

**User Story:** As a user, I want to delete active sessions I no longer need, so that I can keep my chat list clean.

#### Acceptance Criteria

1. WHEN the user swipes left on an active session item, THE Chat_Screen SHALL reveal a delete button
2. WHEN the user taps the revealed delete button, THE Chat_Screen SHALL display a confirmation dialog asking the user to confirm the deletion
3. WHEN the user confirms the deletion in the dialog, THE Session_Provider SHALL optimistically remove the session from the list and call DELETE /api/sessions/:id
4. IF the delete request fails, THEN THE Chat_Screen SHALL show an error SnackBar with the backend error message and restore the session to its original position in the list
5. IF the user cancels the confirmation dialog, THEN THE Chat_Screen SHALL dismiss the dialog and close the swipe action without removing the session
6. THE Chat_Screen SHALL NOT display swipe-to-delete functionality on completed session items

### Requirement 8: Chat Tab — Empty State

**User Story:** As a user with no sessions, I want to see a helpful empty state, so that I know how to start using the chat feature.

#### Acceptance Criteria

1. WHEN the active session list fetch completes with zero results, THE Chat_Screen SHALL display an illustration, a descriptive text "Belum ada sesi aktif", and a "Mulai Cerita" button
2. WHEN the "Mulai Cerita" button in the empty state is tapped, THE Chat_Screen SHALL navigate the user to the Persona tab by switching the active bottom navigation index
3. WHEN the completed session list fetch completes with zero results, THE Chat_Screen SHALL display an illustration and the text "Belum ada sesi yang selesai"
4. WHILE session data is being fetched, THE Chat_Screen SHALL display shimmer skeleton placeholders instead of the empty state

### Requirement 9: Persona Tab — Grid List with Pagination

**User Story:** As a user, I want to browse available AI personas in a grid, so that I can choose who to chat with.

#### Acceptance Criteria

1. THE Persona_Screen SHALL display personas in a 2-column grid layout
2. THE Persona_Screen SHALL show each persona card with: avatar image, name, short description (truncated to a maximum of 2 lines), upvote count, and downvote count
3. THE Persona_Screen SHALL NOT display vote buttons on the grid list cards
4. WHEN the user scrolls to the bottom of the list, THE Persona_Provider SHALL fetch the next page of personas from GET /api/personas with limit=10
5. IF the current page equals totalPages from the meta response, THEN THE Persona_Provider SHALL NOT fetch additional pages and THE Persona_Screen SHALL NOT display a loading indicator at the bottom
6. WHILE persona data is being fetched for the first page, THE Persona_Screen SHALL display shimmer skeleton placeholders filling the grid area
7. WHILE the Persona_Provider is fetching subsequent pages, THE Persona_Screen SHALL display a loading indicator at the bottom of the grid
8. WHEN the user pulls down on the persona grid, THE Persona_Screen SHALL refresh the persona list from page 1 and replace all currently displayed items
9. IF the persona fetch request fails, THEN THE Persona_Screen SHALL display an error SnackBar with the backend error message

### Requirement 10: Persona Detail Screen

**User Story:** As a user, I want to see full details of a persona and rate them, so that I can make an informed choice and provide feedback.

#### Acceptance Criteria

1. WHEN a persona card is tapped, THE Persona_Screen SHALL navigate to the Persona_Detail_Screen passing the persona's ID
2. WHEN the Persona_Detail_Screen is opened, THE Persona_Provider SHALL fetch persona detail from GET /api/personas/:id and display: persona name, avatar, full description, upvote count, and downvote count
3. WHILE persona detail data is being fetched, THE Persona_Detail_Screen SHALL display shimmer skeleton placeholders
4. IF the persona detail fetch fails, THEN THE Persona_Detail_Screen SHALL show an error SnackBar with the backend error message
5. THE Persona_Detail_Screen SHALL display vote buttons (UP, DOWN) where the currently active vote is visually highlighted, and no highlight is shown if the user has not rated (NONE state)
6. WHEN a vote button is tapped that differs from the user's current rating state, THE Persona_Provider SHALL optimistically update the local vote counts and send POST /api/personas/:id/rate with the selected type (UP or DOWN)
7. WHEN the currently highlighted vote button is tapped again, THE Persona_Provider SHALL optimistically update the local vote counts (decrement the active vote) and send POST /api/personas/:id/rate with type NONE
8. IF the rate request fails, THEN THE Persona_Provider SHALL revert the optimistic update to the previous counts and rating state, and THE Persona_Detail_Screen SHALL show an error SnackBar with the backend error message
9. THE Persona_Detail_Screen SHALL display the count of sessions the user has had with this persona, derived from the user's session list filtered by this persona's ID
10. THE Persona_Detail_Screen SHALL display a "Mulai Chat" button

### Requirement 11: Persona Detail — Start Chat

**User Story:** As a user, I want to start a new chat session with a persona directly from their detail page, so that I can begin a conversation quickly.

#### Acceptance Criteria

1. WHEN the "Mulai Chat" button is tapped, THE Session_Provider SHALL call POST /api/sessions with a JSON body containing the persona's ID to create a new session
2. WHEN the session is created successfully (HTTP 201), THE Persona_Detail_Screen SHALL navigate to the chat screen passing the newly created session ID
3. IF the session creation fails, THEN THE Persona_Detail_Screen SHALL show an error SnackBar with the backend error message and re-enable the "Mulai Chat" button
4. WHILE the session is being created, THE Persona_Detail_Screen SHALL disable the "Mulai Chat" button and show a loading indicator to prevent duplicate submissions
5. IF the session creation returns HTTP 404 or HTTP 400 indicating the persona is not found or inactive, THEN THE Persona_Detail_Screen SHALL show an error SnackBar with the backend error message and re-enable the "Mulai Chat" button

### Requirement 12: Profile Screen — Display Information

**User Story:** As a user, I want to see my profile information, so that I can verify my account details.

#### Acceptance Criteria

1. THE Profile_Screen SHALL display the user's avatar image as a circular image, or a default placeholder icon if avatarUrl is null
2. THE Profile_Screen SHALL display the user's name, email, current mental health points (0-100), and join date with createdAt formatted as "dd MMMM yyyy" (e.g., "01 Januari 2024")
3. THE Profile_Screen SHALL display the mental health points inside a circular progress indicator filled proportional to points divided by 100, matching the Score_Card visual pattern
4. THE Profile_Screen SHALL provide navigation to Edit_Profile_Screen, Change_Password_Screen, and a logout action as distinct tappable menu items
5. WHILE user profile data is being loaded, THE Profile_Screen SHALL display shimmer skeleton placeholders in place of the profile information
6. THE Profile_Screen SHALL retrieve user data from the AuthProvider's current user state obtained via GET /api/me

### Requirement 13: Edit Profile Screen

**User Story:** As a user, I want to edit my name and upload a profile photo, so that I can personalize my account.

#### Acceptance Criteria

1. THE Edit_Profile_Screen SHALL display a form with the current name pre-filled in a text field (maximum 50 characters) and an avatar image picker showing the current avatar or default placeholder
2. WHEN the user selects a new image, THE Edit_Profile_Screen SHALL display a preview of the selected image replacing the current avatar in the picker area
3. IF the user selects an image file larger than 5 MB or not in JPEG/PNG format, THEN THE Edit_Profile_Screen SHALL show an error SnackBar indicating the file constraint violation and not attach the image
4. WHEN the form is submitted with a valid name (non-empty, at most 50 characters), THE Edit_Profile_Screen SHALL send PATCH /api/me as multipart/form-data with field name "image" for the photo (if changed) and "name" for the name
5. WHEN the update is successful, THE Edit_Profile_Screen SHALL navigate back to Profile_Screen and refresh the user data
6. IF the update fails, THEN THE Edit_Profile_Screen SHALL show an error SnackBar with the backend error message
7. WHILE the update is in progress, THE Edit_Profile_Screen SHALL disable the submit button and show a loading indicator
8. IF the user submits the form with an empty or whitespace-only name, THEN THE Edit_Profile_Screen SHALL display a validation error on the name field and not send the request

### Requirement 14: Change Password Screen

**User Story:** As a user, I want to change my password, so that I can maintain account security.

#### Acceptance Criteria

1. THE Change_Password_Screen SHALL display a form with three obscured password fields: old password, new password, and confirm new password
2. THE Change_Password_Screen SHALL validate that old password is not empty, that new password is at least 8 characters and at most 128 characters, and that confirm new password matches new password before enabling submission
3. IF client-side validation fails, THEN THE Change_Password_Screen SHALL display inline error messages beneath the respective fields indicating the specific validation failure
4. WHEN the form is submitted with valid data, THE Change_Password_Screen SHALL send PATCH /api/me/password with oldPassword and newPassword
5. WHEN the password change is successful, THE Change_Password_Screen SHALL show a success SnackBar and navigate back to Profile_Screen
6. IF the backend returns 401 with "Password lama salah", THEN THE Change_Password_Screen SHALL show an error SnackBar with that exact message
7. IF the backend returns any other error, THEN THE Change_Password_Screen SHALL show an error SnackBar with the backend error message
8. WHILE the password change is in progress, THE Change_Password_Screen SHALL disable the submit button and show a loading indicator

### Requirement 15: Logout

**User Story:** As a user, I want to log out of my account, so that I can secure my session when I am done.

#### Acceptance Criteria

1. WHEN the logout button is tapped, THE Profile_Screen SHALL display a confirmation dialog with the title "Konfirmasi Logout", the message "Apakah kamu yakin ingin keluar?", a cancel button labeled "Batal", and a confirm button labeled "Keluar"
2. WHEN the user confirms logout, THE Profile_Screen SHALL disable the confirm button, show a loading indicator, and call the existing AuthProvider.logout() method which sends POST /api/auth/logout with the refresh token
3. WHEN logout completes, THE Main_Shell SHALL navigate the user to the login screen by setting AuthStatus to unauthenticated
4. IF the user cancels the confirmation dialog, THEN THE Profile_Screen SHALL dismiss the dialog and remain on the profile screen
5. IF the logout API call fails due to network error or server error, THEN THE Profile_Screen SHALL still clear local tokens and navigate to the login screen without showing an error

### Requirement 16: Session Provider — State Management

**User Story:** As a developer, I want a dedicated provider for session management, so that session state is centralized and reusable across screens.

#### Acceptance Criteria

1. THE Session_Provider SHALL expose a list of active sessions and a list of completed sessions, each containing SessionModel objects parsed from the API response
2. THE Session_Provider SHALL provide a method to fetch sessions filtered by status (active or completed) from GET /api/sessions with query parameters page (default 1) and limit (default 10), and SHALL track currentPage, totalPages, and hasMorePages from the response meta object
3. THE Session_Provider SHALL provide a method to create a new session via POST /api/sessions accepting a personaId parameter, and SHALL add the newly created session to the active sessions list upon success
4. THE Session_Provider SHALL provide a method to delete an active session via DELETE /api/sessions/:id, and SHALL remove the session from the active sessions list upon success
5. IF an API call (fetch, create, or delete) fails, THEN THE Session_Provider SHALL catch the DioException, convert it to an AppException, and expose the error message via the errorMessage state
6. THE Session_Provider SHALL expose isLoading and errorMessage states following the Provider pattern, setting isLoading to true before each API call and to false after completion, and clearing errorMessage to null before each new operation
7. THE Session_Provider SHALL parse response data from response.data['data'] following the project convention and SHALL call notifyListeners() after any state change

### Requirement 17: Persona Provider — State Management

**User Story:** As a developer, I want a dedicated provider for persona management, so that persona state is centralized and reusable across screens.

#### Acceptance Criteria

1. THE Persona_Provider SHALL expose a paginated list of personas fetched from GET /api/personas with a page size of 10 items per request
2. THE Persona_Provider SHALL provide a method to fetch persona detail from GET /api/personas/:id and expose the fetched persona detail as observable state
3. THE Persona_Provider SHALL provide a method to rate a persona via POST /api/personas/:id/rate with a type value of "UP", "DOWN", or "NONE", applying an optimistic update to the local upvote and downvote counts and the user's current rating state before the API responds
4. IF the rating API call fails, THEN THE Persona_Provider SHALL revert the local optimistic update to the previous upvote count, downvote count, and user rating state
5. THE Persona_Provider SHALL expose isLoading and errorMessage states following the Provider pattern
6. THE Persona_Provider SHALL support pagination by tracking current page and totalPages from the meta response, and SHALL provide a method to reset pagination that clears the current list and fetches from page 1
7. THE Persona_Provider SHALL parse response data from response.data['data'] and pagination metadata from response.data['meta'] following the project convention
8. THE Persona_Provider SHALL expose the current user's rating state (UP, DOWN, or NONE) for each persona so that the UI can reflect the active vote selection
