# Implementation Plan: Admin Panel

## Overview

Implementasi Admin Panel untuk aplikasi Flutter SiniCerita. Fitur ini menambahkan layout admin terpisah dengan GoRouter ShellRoute, AdminProvider untuk state management, CRUD persona (admin), dan user list read-only. Implementasi menggunakan Dart/Flutter dengan Provider pattern sesuai konvensi project.

## Tasks

- [x] 1. Set up admin API endpoints and extend PersonaModel
  - [x] 1.1 Add admin endpoint constants to ApiEndpoints class
    - Add `adminPersonas` constant with value `/api/personas`
    - Add `adminPersonaDetail(String id)` static method returning `/api/personas/$id`
    - Add `adminUsers` constant with value `/api/admin/users`
    - Add `adminUserDetail(String id)` static method returning `/api/admin/users/$id`
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [x] 1.2 Extend PersonaModel with full copyWith method
    - Add `copyWith` method supporting all fields: name, description, systemPrompt, avatarUrl, isActive, upvotes, downvotes, userRating
    - Include `clearAvatarUrl` and `clearUserRating` boolean flags for nullable field clearing
    - _Requirements: 6.1, 6.4_

  - [x] 1.3 Write property test for endpoint path correctness
    - **Property 7: Parameterized endpoint path correctness**
    - Generate random non-empty id strings, verify `adminPersonaDetail(id)` returns `/api/personas/$id` and `adminUserDetail(id)` returns `/api/admin/users/$id`
    - **Validates: Requirements 10.2, 10.4**

- [x] 2. Implement computeRedirect role-based routing
  - [x] 2.1 Extend computeRedirect with role parameter
    - Add `String? role` parameter to `computeRedirect` function in `lib/core/routing/redirect_logic.dart`
    - Implement rules: admin at non-admin route → `/admin`, admin at `/admin/*` → null, user at `/admin/*` → `/main`, unauthenticated at `/admin/*` → `/login`, unknown role → treat as "user"
    - Ensure existing auth/splash redirect logic remains intact
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6_

  - [x] 2.2 Write property test for route redirect correctness
    - **Property 1: Route redirect correctness**
    - Generate random combinations of (AuthStatus, role, location) tuples, verify computeRedirect produces correct redirect target per the defined rules
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.6**

  - [x] 2.3 Update GoRouter configuration with admin ShellRoute
    - Add `ShellRoute` wrapping all `/admin/*` routes with `AdminLayout` as shell builder
    - Define routes: `/admin` (redirect to `/admin/dashboard`), `/admin/dashboard`, `/admin/personas`, `/admin/personas/create`, `/admin/personas/:id/edit`, `/admin/users`, `/admin/users/:id`
    - Update `redirect` callback to pass `role` from AuthProvider's currentUser to `computeRedirect`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.3_

- [x] 3. Checkpoint - Ensure routing compiles and tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement AdminProvider
  - [x] 4.1 Create AdminProvider with persona management methods
    - Create `lib/providers/admin_provider.dart` with ChangeNotifier
    - Implement state fields: personas list, pagination (page, totalPages, total), loading flags (isLoadingPersonas, isLoadingMorePersonas, isSubmittingPersona, isDeletingPersona), errorMessage
    - Implement `fetchPersonas({bool refresh})` — GET `/api/personas?includeInactive=true&page=N&limit=10`
    - Implement `fetchMorePersonas()` — fetch next page only if currentPage < totalPages
    - Implement `createPersona(FormData data)` — POST `/api/personas`
    - Implement `updatePersona(String id, FormData data)` — PATCH `/api/personas/$id`
    - Implement `deletePersona(String id)` — DELETE `/api/personas/$id`, update local isActive to false
    - Parse responses using `response.data['data']` and `response.data['meta']`
    - Error handling: catch DioException → AppException.fromDioError → set errorMessage
    - _Requirements: 3.1, 4.1, 4.3, 4.4, 4.7, 4.8, 5.3, 5.4, 5.5, 6.4, 6.5, 6.6, 7.2, 7.3, 7.4_

  - [x] 4.2 Add user management methods to AdminProvider
    - Implement state fields: users list, pagination (userPage, userTotalPages), loading flags (isLoadingUsers, isLoadingMoreUsers, isLoadingUserDetail), selectedUser
    - Implement `fetchUsers({bool refresh})` — GET `/api/admin/users?page=N&limit=10`
    - Implement `fetchMoreUsers()` — fetch next page only if currentPage < totalPages
    - Implement `fetchUserDetail(String id)` — GET `/api/admin/users/$id`
    - Implement `fetchDashboardStats()` — fetch persona total from meta for dashboard
    - _Requirements: 3.1, 3.2, 8.1, 8.3, 8.4, 8.7, 8.8, 9.1, 9.4_

  - [x] 4.3 Write property test for pagination boundary
    - **Property 4: Pagination stops at last page**
    - Generate random page/totalPages combinations, verify fetchMore does NOT trigger API call when page >= totalPages, and DOES trigger when page < totalPages
    - **Validates: Requirements 4.4, 8.4**

  - [x] 4.4 Write property test for edit form differential update
    - **Property 5: Edit form sends only changed fields**
    - Generate random original/modified persona data pairs, verify PATCH FormData contains only fields whose values differ
    - **Validates: Requirements 6.4**

- [x] 5. Register AdminProvider in app
  - [x] 5.1 Add AdminProvider to MultiProvider in main.dart
    - Register AdminProvider in the MultiProvider widget tree
    - Ensure AdminProvider receives ApiClient dependency
    - _Requirements: 4.1, 8.1_

- [x] 6. Checkpoint - Ensure provider compiles and tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement Admin Layout and Navigation
  - [x] 7.1 Create AdminLayout widget with NavigationRail
    - Create `lib/screens/admin/admin_layout.dart`
    - Implement NavigationRail with destinations: "Dashboard", "Kelola Persona", "Daftar User"
    - Display admin name (truncated to 20 chars with ellipsis if exceeding) and avatar from AuthProvider's currentUser
    - Show default placeholder icon if avatarUrl is null
    - Highlight active navigation item with different background/font weight
    - Add logout button with confirmation dialog "Apakah Anda yakin ingin keluar?"
    - On confirm: trigger AuthProvider.logout → GoRouter redirects to `/login`
    - All UI text in Bahasa Indonesia
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 1.5_

  - [x] 7.2 Write property test for admin name truncation
    - **Property 2: Admin name truncation**
    - Generate random strings of varying length, verify strings > 20 chars are truncated to 20 + ellipsis, strings ≤ 20 chars displayed in full
    - **Validates: Requirements 2.2**

- [x] 8. Implement Admin Dashboard Screen
  - [x] 8.1 Create AdminDashboard screen
    - Create `lib/screens/admin/admin_dashboard_screen.dart`
    - On load: call `AdminProvider.fetchDashboardStats()`
    - Display total active personas from pagination meta `total` field
    - Show shimmer skeleton while loading
    - Show red SnackBar on error with exact backend message
    - Implement pull-to-refresh to reload stats
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 9. Implement Persona List Screen (Admin)
  - [x] 9.1 Create AdminPersonaList screen
    - Create `lib/screens/admin/admin_persona_list_screen.dart`
    - On load: call `AdminProvider.fetchPersonas()`
    - Display each persona: avatar (placeholder if null), name, description (truncated 2 lines), status badge "Aktif"/"Nonaktif", upvote count, downvote count
    - Infinite scroll: fetch next page when last item visible
    - Shimmer skeleton for first page load
    - Loading indicator at bottom for subsequent pages
    - Pull-to-refresh: reload from page 1
    - Red SnackBar on error, preserve existing data
    - Empty state: "Belum ada persona" when total = 0
    - FAB "Tambah Persona" → navigate to create form
    - Show delete action only on personas with isActive = true
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 7.7_

  - [x] 9.2 Write property test for delete action visibility
    - **Property 6: Delete action visibility matches isActive status**
    - Generate random personas with varying isActive values, verify delete action visible iff isActive == true
    - **Validates: Requirements 7.7**

- [x] 10. Implement Persona Form (Create & Edit)
  - [x] 10.1 Create AdminPersonaForm screen
    - Create `lib/screens/admin/admin_persona_form_screen.dart`
    - Support both create and edit modes (determined by route parameter)
    - Fields: name (required, max 100), description (required, max 500), systemPrompt (required, max 2000), image (optional)
    - Edit mode: pre-fill with existing persona data, add isActive toggle with label "Persona Aktif"
    - Client-side validation: reject whitespace-only input, show inline error below invalid fields
    - Image picker from gallery, show thumbnail preview, remove button to clear selection
    - Reject images > 5 MB with inline error message
    - Submit button disabled while submitting (prevent double-tap)
    - Create: POST to `/api/personas` with multipart/form-data (image field name = "image")
    - Edit: PATCH to `/api/personas/:id` with only changed fields in FormData
    - On success: navigate back to persona list + green SnackBar
    - On failure: red SnackBar with exact backend error, form stays open, button re-enabled
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9_

  - [x] 10.2 Write property test for form validation whitespace rejection
    - **Property 3: Form validation rejects whitespace-only input**
    - Generate random whitespace-only strings, verify validation rejects them. Generate strings with at least one non-whitespace char, verify validation accepts them (within length constraints)
    - **Validates: Requirements 5.2, 6.3**

- [x] 11. Implement Delete (Deactivate) Persona Dialog
  - [x] 11.1 Create persona deactivation confirmation dialog
    - Show confirmation dialog with persona name and message "Apakah Anda yakin ingin menonaktifkan persona ini?"
    - On confirm: call `AdminProvider.deletePersona(id)` → DELETE `/api/personas/:id`
    - On success: update local persona isActive to false, green SnackBar "Persona berhasil dinonaktifkan"
    - On failure: red SnackBar with exact backend error, dialog dismissed, list unchanged
    - On cancel: dismiss dialog without action
    - While deleting: show loading indicator, disable confirm and cancel buttons
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [x] 12. Checkpoint - Ensure persona management compiles and tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 13. Implement User List Screen
  - [x] 13.1 Create AdminUserList screen
    - Create `lib/screens/admin/admin_user_list_screen.dart`
    - On load: call `AdminProvider.fetchUsers()`
    - Display each user: avatar (cached_network_image with placeholder), name, email, role badge, health points (0–100), registration date formatted "dd MMMM yyyy" (intl, locale id_ID)
    - Infinite scroll: fetch next page when scrolled to bottom
    - Shimmer skeleton for first page load
    - Loading indicator at bottom for subsequent pages
    - Pull-to-refresh: reload from page 1, show refresh indicator until complete
    - Red SnackBar on error with exact backend message
    - Empty state message when total = 0
    - Tap user item → navigate to `/admin/users/:id`
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10, 8.11_

- [x] 14. Implement User Detail Screen
  - [x] 14.1 Create AdminUserDetail screen
    - Create `lib/screens/admin/admin_user_detail_screen.dart`
    - On load: call `AdminProvider.fetchUserDetail(id)`
    - Display: avatar (max width 120 logical pixels, placeholder if null), name, email, role, health points, registration date "dd MMMM yyyy" (intl, locale id_ID)
    - All fields read-only, no edit capabilities
    - Shimmer skeleton while loading
    - Red SnackBar on error with exact backend message
    - Back navigation button to return to Daftar User
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [x] 15. Final checkpoint - Ensure all tests pass and feature compiles
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- All UI text must be in Bahasa Indonesia
- Use `response.data['data']` for response parsing (not `response.data` directly)
- Image upload field name MUST be "image"
- Use shimmer skeletons for loading states (not plain spinners)
- Error SnackBars must display exact backend error messages without translation

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "2.1"] },
    { "id": 2, "tasks": ["2.2", "2.3"] },
    { "id": 3, "tasks": ["4.1", "4.2"] },
    { "id": 4, "tasks": ["4.3", "4.4", "5.1"] },
    { "id": 5, "tasks": ["7.1"] },
    { "id": 6, "tasks": ["7.2", "8.1", "9.1"] },
    { "id": 7, "tasks": ["9.2", "10.1", "11.1", "13.1"] },
    { "id": 8, "tasks": ["10.2", "14.1"] }
  ]
}
```
