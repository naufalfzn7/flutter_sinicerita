# Implementation Plan: Admin Persona Hard Delete

## Overview

Implement two distinct persona management actions in the admin panel: migrate deactivation from DELETE to PATCH endpoint, and add a new hard delete (permanent removal) action. The UI is updated to show both actions clearly on each persona list item with separate confirmation dialogs.

## Tasks

- [x] 1. Add deactivate endpoint and update provider methods
  - [x] 1.1 Add `adminPersonaDeactivate` static method to ApiEndpoints class
    - Add `static String adminPersonaDeactivate(String id) => '/api/personas/$id/deactivate';` in the Admin section of `lib/core/api/api_endpoints.dart`
    - Place it after the existing `adminPersonaDetail` method
    - Existing `adminPersonaDetail(id)` remains unchanged
    - _Requirements: 6.1, 6.2, 6.5, 1.4_

  - [x] 1.2 Modify `AdminProvider.deletePersona` to use PATCH with new deactivate endpoint
    - Change the HTTP method from `_apiClient.dio.delete(...)` to `_apiClient.dio.patch(...)`
    - Change the URL from `ApiEndpoints.adminPersonaDetail(id)` to `ApiEndpoints.adminPersonaDeactivate(id)`
    - Keep the existing local state update logic (set `isActive=false` on target persona)
    - Keep the existing `_isDeletingPersona` loading flag behavior
    - _Requirements: 1.1, 1.2, 1.3, 1.5, 6.3_

  - [x] 1.3 Add `hardDeletePersona` method and `_isHardDeleting` state to AdminProvider
    - Add `bool _isHardDeleting = false;` field and `bool get isHardDeleting => _isHardDeleting;` getter
    - Implement `Future<bool> hardDeletePersona(String id)` method that:
      - Sets `_isHardDeleting = true`, clears error, notifies
      - Sends DELETE to `ApiEndpoints.adminPersonaDetail(id)`
      - On success: removes persona from `_personas` list, decrements `_personaTotal` by 1
      - On failure: converts DioException to AppException, sets `_errorMessage`
      - Always sets `_isHardDeleting = false` and notifies at end
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 6.4_

- [x] 2. Checkpoint - Verify provider changes compile
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Create HardDeletePersonaDialog widget
  - [x] 3.1 Create `lib/widgets/admin/hard_delete_persona_dialog.dart`
    - Follow the same pattern as `DeactivatePersonaDialog`
    - StatefulWidget with `personaId` and `personaName` parameters
    - Static `show()` method using `showDialog<Object>` with `barrierDismissible: false`
    - Title: "Hapus Permanen"
    - Message: "Apakah Anda yakin ingin menghapus permanen persona ini? Tindakan ini tidak dapat dibatalkan."
    - Display persona name in bold
    - Cancel button text: "Batal"
    - Confirm button text: "Hapus Permanen" with `colorScheme.error` background
    - Show `CircularProgressIndicator` during loading
    - Disable both buttons during loading
    - Call `context.read<AdminProvider>().hardDeletePersona(personaId)` on confirm
    - Return `true` on success, error message `String` on failure, `null` on cancel
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 4. Update AdminPersonaListScreen UI and actions
  - [x] 4.1 Modify `_buildPersonaItem` to show two action buttons
    - Replace the single `IconButton` with a `Row` of action buttons at the trailing position
    - Deactivate button: `Icons.toggle_off_outlined`, tooltip "Nonaktifkan", only shown when `persona.isActive == true`
    - Hard delete button: `Icons.delete_outline`, tooltip "Hapus Permanen", styled with `colorScheme.error`, shown on ALL personas
    - Button order: deactivate first, hard delete second (when both visible)
    - Each `IconButton` must have minimum 48x48dp tap target (default `IconButton` constraints)
    - Deactivate button calls existing `_showDeleteDialog(persona)`
    - Hard delete button calls new `_showHardDeleteDialog(persona)`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 3.1, 4.1_

  - [x] 4.2 Add `_showHardDeleteDialog` method to AdminPersonaListScreen
    - Import `HardDeletePersonaDialog`
    - Show `HardDeletePersonaDialog.show(context, personaId: persona.id, personaName: persona.name)`
    - On result `true`: show green SnackBar "Persona berhasil dihapus permanen"
    - On result `String`: show red SnackBar with the error message
    - On result `null`: no action (cancelled)
    - _Requirements: 4.2, 4.3, 4.4, 4.5_

  - [x] 4.3 Verify existing `_showDeleteDialog` works with migrated deactivation
    - Ensure the existing `_showDeleteDialog` still shows `DeactivatePersonaDialog`
    - Confirm green SnackBar message remains "Persona berhasil dinonaktifkan"
    - Confirm red SnackBar shows exact backend error message on failure
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 5. Final checkpoint - Ensure all changes compile and integrate correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 6. Write property-based tests for provider logic
  - [ ]* 6.1 Write property test for deactivation list integrity
    - **Property 1: Deactivation preserves list integrity**
    - For any persona list containing a target active persona, after successful deactivation, list length is unchanged, only target's `isActive` is `false`, all others unchanged
    - **Validates: Requirements 1.2**

  - [ ]* 6.2 Write property test for hard delete removal
    - **Property 2: Hard delete removes exactly one persona and decrements count**
    - For any persona list of length N containing a target, after hard delete, list length is N-1, target is absent, others unchanged, `personaTotal` decremented by 1
    - **Validates: Requirements 2.2**

  - [ ]* 6.3 Write property test for error message propagation
    - **Property 3: Error messages propagate exactly from backend response**
    - For any backend error with a `message` field, provider's `errorMessage` equals that exact string
    - **Validates: Requirements 1.3, 2.3**

  - [ ]* 6.4 Write property test for endpoint URL construction
    - **Property 4: Endpoint URL construction**
    - For any non-empty string ID, `adminPersonaDeactivate(id)` returns `/api/personas/$id/deactivate` and `adminPersonaDetail(id)` returns `/api/personas/$id`
    - **Validates: Requirements 1.4, 6.1, 6.2**

  - [ ]* 6.5 Write property test for loading state lifecycle
    - **Property 5: Loading state lifecycle**
    - For any call to `deletePersona` or `hardDeletePersona`, the corresponding loading flag is `true` during execution and `false` after completion (success or failure)
    - **Validates: Requirements 2.5, 3.6, 4.6**

- [ ]* 7. Write unit tests for provider and widget logic
  - [ ]* 7.1 Write unit tests for `deletePersona` (deactivation via PATCH)
    - Test success: mock Dio PATCH 200, verify `isActive=false` on target, list length unchanged
    - Test failure: mock Dio error, verify `errorMessage` set correctly
    - _Requirements: 1.1, 1.2, 1.3_

  - [ ]* 7.2 Write unit tests for `hardDeletePersona`
    - Test success: mock Dio DELETE 200, verify persona removed, `personaTotal` decremented
    - Test failure: mock Dio error, verify `errorMessage` set correctly
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ]* 7.3 Write widget tests for action button visibility
    - Active persona shows both deactivate and hard delete buttons
    - Inactive persona shows only hard delete button
    - Verify tooltips "Nonaktifkan" and "Hapus Permanen"
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.6_

  - [ ]* 7.4 Write widget tests for HardDeletePersonaDialog
    - Verify dialog title, message, persona name display
    - Verify loading state disables buttons and shows spinner
    - Verify cancel returns null
    - _Requirements: 4.2, 4.5, 4.6_

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit/widget tests validate specific examples and edge cases
- The design uses Dart/Flutter code directly — implementation language is Dart
- Follow existing patterns in `DeactivatePersonaDialog` for the new `HardDeletePersonaDialog`
- All UI text is in Bahasa Indonesia per project conventions

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3"] },
    { "id": 2, "tasks": ["3.1"] },
    { "id": 3, "tasks": ["4.1", "4.2", "4.3"] },
    { "id": 4, "tasks": ["6.1", "6.2", "6.3", "6.4", "6.5"] },
    { "id": 5, "tasks": ["7.1", "7.2", "7.3", "7.4"] }
  ]
}
```
