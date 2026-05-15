# Requirements Document

## Introduction

Fitur Admin Panel menyediakan antarmuka terpisah bagi pengguna dengan role "admin" untuk mengelola data aplikasi SiniCerita. Setelah login, admin diarahkan ke layout khusus admin (bukan layout user biasa) yang memiliki navigasi sendiri. Admin dapat melakukan CRUD persona (menggunakan endpoint admin yang sudah tersedia di backend) dan melihat daftar user beserta detailnya. Fitur user management di sisi Flutter bersifat read-only karena backend belum menyediakan endpoint admin untuk mengelola user — hanya persona management yang memiliki endpoint admin lengkap.

## Glossary

- **Admin_Panel**: Layout dan halaman khusus yang hanya bisa diakses oleh pengguna dengan role "admin", terpisah dari layout user biasa
- **Admin_Provider**: ChangeNotifier yang mengelola state dan logika bisnis untuk fitur admin (persona CRUD dan user list)
- **Persona_Form**: Form untuk membuat atau mengedit persona, berisi field name, description, systemPrompt, dan image
- **Admin_Navigation**: Sidebar atau bottom navigation khusus admin dengan menu: Dashboard, Kelola Persona, Daftar User
- **Admin_Dashboard**: Halaman utama admin yang menampilkan ringkasan statistik (jumlah user, jumlah persona aktif)
- **GoRouter**: Library navigasi yang digunakan aplikasi, dengan redirect guard berdasarkan auth status dan role
- **Soft_Delete**: Mekanisme penghapusan persona yang hanya mengubah flag `isActive` menjadi false tanpa menghapus data dari database

## Requirements

### Requirement 1: Admin Route Guard dan Redirect

**User Story:** Sebagai admin, saya ingin langsung diarahkan ke halaman admin setelah login, sehingga saya tidak perlu navigasi manual ke panel admin.

#### Acceptance Criteria

1. WHEN a user with role "admin" reaches AuthStatus.authenticated (via login or checkAuthStatus on app relaunch), THE GoRouter SHALL redirect to `/admin` instead of `/main`
2. WHEN a user with role "user" attempts to access any route whose path starts with `/admin`, THE GoRouter SHALL redirect to `/main`
3. WHEN a user with role "admin" attempts to access `/main`, THE GoRouter SHALL redirect to `/admin`
4. WHEN an unauthenticated user (AuthStatus.unauthenticated) attempts to access any route whose path starts with `/admin`, THE GoRouter SHALL redirect to `/login`
5. WHEN the admin invokes logout from the Admin_Panel, THE Auth_Provider SHALL clear all tokens from SecureStorage, set AuthStatus to unauthenticated, and THE GoRouter SHALL redirect to `/login`
6. IF the authenticated user's role field is neither "admin" nor "user", THEN THE GoRouter SHALL treat the user as role "user" and redirect to `/main`

### Requirement 2: Admin Panel Layout dan Navigasi

**User Story:** Sebagai admin, saya ingin memiliki layout terpisah dengan navigasi khusus admin, sehingga saya bisa mengakses semua fitur manajemen dengan mudah.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display a dedicated navigation structure with menu items in this order: "Dashboard", "Kelola Persona", and "Daftar User"
2. THE Admin_Panel SHALL display the admin's name (truncated with ellipsis if exceeding 20 characters) and avatar in the navigation header area, using the data from Auth_Provider's current user model. IF the admin's avatarUrl is null, THEN THE Admin_Panel SHALL display a default placeholder icon in place of the avatar
3. WHEN a navigation menu item is tapped, THE Admin_Panel SHALL navigate to the corresponding admin sub-page using GoRouter shell route, preserving the navigation layout while replacing only the content area
4. THE Admin_Panel SHALL visually distinguish the currently active menu item from inactive items by applying a different background color or font weight to the active item
5. WHEN the admin taps the logout button, THE Admin_Panel SHALL display a confirmation dialog with message "Apakah Anda yakin ingin keluar?". WHEN the admin confirms, THE Admin_Panel SHALL trigger the Auth_Provider logout flow. IF the admin cancels, THEN THE Admin_Panel SHALL dismiss the dialog without any action
6. THE Admin_Panel SHALL display all UI text in Bahasa Indonesia

### Requirement 3: Admin Dashboard

**User Story:** Sebagai admin, saya ingin melihat ringkasan statistik aplikasi di halaman utama admin, sehingga saya bisa memantau kondisi platform secara cepat.

#### Acceptance Criteria

1. WHEN the Admin_Dashboard is loaded, THE Admin_Provider SHALL fetch the persona list from GET `/api/personas` with limit sufficient to obtain the total count from meta
2. THE Admin_Dashboard SHALL display the total number of active personas retrieved from the pagination meta `total` field
3. WHILE the Admin_Dashboard data is being fetched, THE Admin_Dashboard SHALL display shimmer skeleton placeholders
4. IF the data fetch fails, THEN THE Admin_Dashboard SHALL display an error message in a red SnackBar with the exact backend error message
5. WHEN the admin pulls down on the Admin_Dashboard, THE Admin_Dashboard SHALL refresh all displayed statistics

### Requirement 4: Persona List (Admin View)

**User Story:** Sebagai admin, saya ingin melihat daftar semua persona termasuk yang tidak aktif, sehingga saya bisa mengelola persona secara menyeluruh.

#### Acceptance Criteria

1. WHEN the Kelola Persona page is loaded, THE Admin_Provider SHALL fetch personas from GET `/api/personas?includeInactive=true` with pagination (page=1, limit=10) to retrieve both active and inactive personas
2. THE Kelola Persona page SHALL display each persona item with: avatar (or a default placeholder if avatarUrl is null), name, description (truncated to 2 lines), status badge indicating "Aktif" or "Nonaktif" based on the isActive field, upvote count, and downvote count
3. WHEN the admin scrolls such that the last persona item becomes visible, THE Admin_Provider SHALL fetch the next page of personas
4. IF the current page equals totalPages from the meta response, THEN THE Admin_Provider SHALL NOT fetch additional pages
5. WHILE persona data is being fetched for the first page, THE Kelola Persona page SHALL display shimmer skeleton placeholders in place of the list
6. WHILE the Admin_Provider is fetching a subsequent page (page > 1), THE Kelola Persona page SHALL display a loading indicator at the bottom of the list
7. WHEN the admin pulls down on the persona list, THE Admin_Provider SHALL refresh the list from page 1 and replace all currently displayed items with the fresh response
8. IF the persona fetch request fails, THEN THE Kelola Persona page SHALL display a red error SnackBar with the exact backend error message and preserve any previously loaded persona items on screen
9. IF the persona list response returns zero items (meta.total equals 0), THEN THE Kelola Persona page SHALL display an empty state message "Belum ada persona" in place of the list
10. THE Kelola Persona page SHALL provide a floating action button labeled "Tambah Persona" to navigate to the create persona form

### Requirement 5: Create Persona

**User Story:** Sebagai admin, saya ingin membuat persona baru, sehingga user memiliki lebih banyak pilihan AI companion untuk ngobrol.

#### Acceptance Criteria

1. THE Persona_Form for creation SHALL contain input fields for: name (required, maximum 100 characters), description (required, maximum 500 characters), systemPrompt (required, maximum 2000 characters), and image (optional)
2. THE Persona_Form SHALL validate client-side that name, description, and systemPrompt each contain at least 1 non-whitespace character before enabling submission, and SHALL display an inline error message below each invalid field indicating the field is required
3. WHEN the admin submits a valid Persona_Form, THE Admin_Provider SHALL send a POST request to `/api/personas` with multipart/form-data containing the field values (image field name MUST be "image")
4. WHEN the POST request succeeds (201), THE Admin_Provider SHALL add the new persona to the local list and THE Persona_Form SHALL navigate back to the Kelola Persona page with a green success SnackBar
5. IF the POST request fails, THEN THE Persona_Form SHALL display a red error SnackBar with the exact backend error message
6. WHILE the form is being submitted, THE Persona_Form SHALL disable the submit button to prevent double-tap
7. THE Persona_Form SHALL allow the admin to pick an image from the device gallery using image_picker, SHALL display a thumbnail preview of the selected image, and SHALL provide a remove button to clear the selected image before submission
8. IF the admin selects an image file larger than 5 MB, THEN THE Persona_Form SHALL display an inline error message indicating the maximum allowed file size and SHALL NOT attach the file to the form

### Requirement 6: Edit Persona

**User Story:** Sebagai admin, saya ingin mengedit persona yang sudah ada, sehingga saya bisa memperbarui informasi atau system prompt persona.

#### Acceptance Criteria

1. WHEN the admin taps an edit action on a persona item, THE Admin_Panel SHALL navigate to the Persona_Form pre-filled with the persona's current data (name, description, systemPrompt, current avatar, and isActive status)
2. THE Persona_Form for editing SHALL allow the admin to modify any combination of: name (maximum 100 characters), description (maximum 500 characters), systemPrompt (maximum 2000 characters), image, and isActive status
3. THE Persona_Form for editing SHALL validate client-side that name is not empty, description is not empty, and systemPrompt is not empty before allowing submission
4. WHEN the admin submits the edited Persona_Form with valid fields, THE Admin_Provider SHALL send a PATCH request to `/api/personas/:id` with multipart/form-data containing only the changed fields (image field name MUST be "image")
5. WHEN the PATCH request succeeds (200), THE Admin_Provider SHALL update the persona in the local list and THE Persona_Form SHALL navigate back to the Kelola Persona page with a green success SnackBar
6. IF the PATCH request fails, THEN THE Persona_Form SHALL display a red error SnackBar with the exact backend error message
7. WHILE the form is being submitted, THE Persona_Form SHALL disable the submit button and display a loading indicator to prevent double-tap
8. THE Persona_Form for editing SHALL include a toggle switch for the isActive field with label "Persona Aktif"
9. IF client-side validation fails, THEN THE Persona_Form SHALL display inline error messages below each invalid field indicating the validation issue

### Requirement 7: Delete (Deactivate) Persona

**User Story:** Sebagai admin, saya ingin menonaktifkan persona yang tidak lagi relevan, sehingga user tidak bisa memulai sesi baru dengan persona tersebut.

#### Acceptance Criteria

1. WHEN the admin taps a delete action on a persona item, THE Admin_Panel SHALL display a confirmation dialog that includes the persona's name and the message "Apakah Anda yakin ingin menonaktifkan persona ini?"
2. WHEN the admin confirms the deletion, THE Admin_Provider SHALL send a DELETE request to `/api/personas/:id`
3. WHEN the DELETE request succeeds (200), THE Admin_Provider SHALL update the persona's isActive status to false in the local list and display a green success SnackBar with message "Persona berhasil dinonaktifkan"
4. IF the DELETE request fails, THEN THE Admin_Panel SHALL display a red error SnackBar with the exact backend error message
5. IF the admin cancels the confirmation dialog, THEN THE Admin_Panel SHALL dismiss the dialog without making any changes
6. WHILE the delete request is in progress, THE confirmation dialog SHALL display a loading indicator, disable the confirm button, and disable the cancel button to prevent dismissal
7. THE Admin_Panel SHALL only display the delete action on persona items that have isActive status equal to true

### Requirement 8: User List (Read-Only)

**User Story:** Sebagai admin, saya ingin melihat daftar user yang terdaftar di platform, sehingga saya bisa memantau pertumbuhan pengguna.

#### Acceptance Criteria

1. WHEN the Daftar User page is loaded, THE Admin_Provider SHALL fetch user data from GET `/api/admin/users` with pagination (page=1, limit=10)
2. THE Daftar User page SHALL display each user item with: avatar (using cached_network_image with fallback placeholder if null), name, email, role ("user" or "admin"), health points (integer 0–100), and registration date formatted as "dd MMMM yyyy" using the intl package with Indonesian locale
3. WHEN the admin scrolls to the bottom of the list, THE Admin_Provider SHALL fetch the next page of users
4. IF the current page equals totalPages from the meta response, THEN THE Admin_Provider SHALL NOT fetch additional pages
5. WHILE user data is being fetched for the first page, THE Daftar User page SHALL display shimmer skeleton placeholders matching the layout of user list items
6. WHILE additional pages are being fetched, THE Daftar User page SHALL display a loading indicator at the bottom of the list
7. WHEN the admin pulls down on the user list, THE Admin_Provider SHALL refresh the list from page 1 and reset pagination state
8. IF the user fetch request fails, THEN THE Daftar User page SHALL display a red error SnackBar with the exact backend error message
9. IF the user list is empty (meta total equals 0), THEN THE Daftar User page SHALL display an empty state message indicating no users are registered
10. WHEN the admin taps a user item, THE Admin_Panel SHALL navigate to the user detail view (Requirement 9) passing the selected user's id
11. WHILE the Daftar User page is performing a pull-to-refresh, THE Daftar User page SHALL show the refresh indicator until the fetch completes or fails

### Requirement 9: User Detail (Read-Only)

**User Story:** Sebagai admin, saya ingin melihat detail lengkap seorang user, sehingga saya bisa memahami aktivitas dan status user tersebut.

#### Acceptance Criteria

1. WHEN the user detail page is loaded, THE Admin_Provider SHALL fetch user data from GET `/api/admin/users/:id` and THE Admin_Panel SHALL display the user's: avatar (displayed at a maximum width of 120 logical pixels), name, email, role, health points (integer 0–100), and registration date formatted using the intl package in "dd MMMM yyyy" pattern (locale: id_ID)
2. THE user detail page SHALL display all information in a read-only format without edit capabilities
3. WHILE the user detail data is being loaded, THE user detail page SHALL display shimmer skeleton placeholders matching the layout of the detail fields
4. IF the user detail fetch request fails, THEN THE user detail page SHALL display a red error SnackBar with the exact backend error message
5. IF the user has no avatar, THEN THE user detail page SHALL display a default placeholder icon in place of the avatar image
6. THE user detail page SHALL provide a back navigation button to return to the Daftar User page

### Requirement 10: Admin API Endpoint Constants

**User Story:** Sebagai developer, saya ingin semua admin endpoint terdefinisi di satu tempat, sehingga mudah di-maintain dan konsisten dengan konvensi project.

#### Acceptance Criteria

1. THE ApiEndpoints class SHALL contain a constant `adminPersonas` with value `/api/personas` for the admin POST (create persona) operation
2. THE ApiEndpoints class SHALL provide a static method `adminPersonaDetail(String id)` returning `/api/personas/$id` for admin PATCH (update persona) and DELETE (soft-delete persona) operations
3. THE ApiEndpoints class SHALL contain a constant `adminUsers` with value `/api/admin/users` for the admin users list endpoint
4. THE ApiEndpoints class SHALL provide a static method `adminUserDetail(String id)` returning `/api/admin/users/$id` for admin user detail operations
5. WHEN a new admin-only endpoint is added to the backend, THE ApiEndpoints class SHALL be the single location where that endpoint path is defined, following the existing naming convention of camelCase constants for fixed paths and static methods for parameterized paths
