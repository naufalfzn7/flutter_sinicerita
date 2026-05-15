# Requirements Document

## Introduction

Fitur ini menambahkan kemampuan hard delete (hapus permanen) pada manajemen persona di admin panel, serta memigrasikan endpoint deaktivasi dari `DELETE /api/personas/:id` ke `PATCH /api/personas/:id/deactivate`. Saat ini admin hanya bisa menonaktifkan persona (soft delete). Dengan fitur ini, admin memiliki dua aksi terpisah: deaktivasi (soft delete) yang menonaktifkan persona tanpa menghapus data, dan hapus permanen (hard delete) yang menghapus persona dari database secara ireversibel.

## Glossary

- **Admin_Provider**: ChangeNotifier yang mengelola state dan logika bisnis untuk fitur admin, termasuk persona CRUD dan user list
- **Hard_Delete**: Operasi penghapusan permanen yang menghilangkan data persona dari database secara ireversibel melalui endpoint `DELETE /api/personas/:id`
- **Soft_Delete**: Operasi deaktivasi persona yang mengubah flag `isActive` menjadi false tanpa menghapus data dari database, melalui endpoint `PATCH /api/personas/:id/deactivate`
- **Deactivate_Persona_Dialog**: Widget dialog konfirmasi yang digunakan untuk aksi deaktivasi persona
- **Hard_Delete_Persona_Dialog**: Widget dialog konfirmasi yang digunakan untuk aksi hapus permanen persona
- **Persona_List_Screen**: Halaman daftar persona di admin panel yang menampilkan semua persona aktif dan nonaktif
- **ApiEndpoints**: Class yang menyimpan semua URL constant untuk komunikasi dengan backend

## Requirements

### Requirement 1: Migrasi Endpoint Deaktivasi Persona

**User Story:** Sebagai developer, saya ingin endpoint deaktivasi persona diperbarui ke `PATCH /api/personas/:id/deactivate`, sehingga sesuai dengan perubahan backend terbaru dan memisahkan aksi deaktivasi dari hard delete.

#### Acceptance Criteria

1. WHEN the admin confirms the deactivation via the DeactivatePersonaDialog, THE Admin_Provider SHALL send a PATCH request with no request body to `/api/personas/:id/deactivate` instead of a DELETE request to `/api/personas/:id`
2. WHEN the PATCH deactivation request returns HTTP status 200, THE Admin_Provider SHALL set the matching persona's `isActive` field to `false` in the local persona list without re-fetching from the server
3. IF the PATCH deactivation request returns a non-2xx HTTP status, THEN THE Admin_Provider SHALL set the `errorMessage` field to the value of the `message` property from the backend response envelope
4. THE ApiEndpoints class SHALL provide a static method `adminPersonaDeactivate(String id)` returning the string `/api/personas/$id/deactivate`
5. THE Admin_Provider SHALL NOT send a DELETE request to `/api/personas/:id` for persona deactivation

### Requirement 2: Hard Delete Persona

**User Story:** Sebagai admin, saya ingin bisa menghapus persona secara permanen dari database, sehingga persona yang tidak dibutuhkan lagi bisa dihilangkan sepenuhnya dari sistem.

#### Acceptance Criteria

1. WHEN the admin confirms a hard delete action, THE Admin_Provider SHALL send a DELETE request to `/api/personas/:id` using the `ApiEndpoints.adminPersonaDetail(id)` URL
2. WHEN the DELETE request succeeds (200), THE Admin_Provider SHALL remove the persona from the local persona list and decrement the personaTotal count by 1
3. IF the DELETE request fails, THEN THE Admin_Provider SHALL convert the DioException to an AppException and set the errorMessage with the exact backend error message
4. THE Admin_Provider SHALL expose a method `hardDeletePersona(String id)` returning `Future<bool>` that returns true on success and false on failure, distinct from the existing `deletePersona(String id)` method used for deactivation
5. WHILE the hard delete request is in progress, THE Admin_Provider SHALL set a loading state flag to true and set it back to false when the request completes or fails

### Requirement 3: Aksi Deaktivasi pada Persona Aktif

**User Story:** Sebagai admin, saya ingin bisa menonaktifkan persona yang aktif, sehingga user tidak bisa memulai sesi baru dengan persona tersebut tanpa menghapus datanya.

#### Acceptance Criteria

1. THE Persona_List_Screen SHALL display a deactivate action button on each persona item that has isActive equal to true
2. WHEN the admin taps the deactivate action on an active persona, THE Persona_List_Screen SHALL display the Deactivate_Persona_Dialog with the persona's name and the message "Apakah Anda yakin ingin menonaktifkan persona ini?"
3. WHEN the admin confirms the deactivation and the Admin_Provider deactivation method completes successfully, THE Deactivate_Persona_Dialog SHALL dismiss itself and THE Persona_List_Screen SHALL display a green SnackBar with message "Persona berhasil dinonaktifkan" and update the persona item to reflect isActive equal to false, removing the deactivate button from that item
4. IF the deactivation fails, THEN THE Persona_List_Screen SHALL dismiss the Deactivate_Persona_Dialog and display a red SnackBar with the exact backend error message
5. IF the admin cancels the Deactivate_Persona_Dialog, THEN THE Persona_List_Screen SHALL dismiss the dialog without making any changes
6. WHILE the deactivation request is in progress, THE Deactivate_Persona_Dialog SHALL display a loading indicator and disable both the confirm and cancel buttons

### Requirement 4: Aksi Hard Delete pada Semua Persona

**User Story:** Sebagai admin, saya ingin bisa menghapus permanen persona manapun (aktif maupun nonaktif), sehingga saya bisa membersihkan data persona yang tidak relevan dari database.

#### Acceptance Criteria

1. THE Persona_List_Screen SHALL display a hard delete action button on every persona item regardless of isActive status
2. WHEN the admin taps the hard delete action on a persona, THE Persona_List_Screen SHALL display the Hard_Delete_Persona_Dialog with the persona's name and the message "Apakah Anda yakin ingin menghapus permanen persona ini? Tindakan ini tidak dapat dibatalkan."
3. WHEN the admin confirms the hard delete and the Admin_Provider hardDeletePersona method returns success, THE Hard_Delete_Persona_Dialog SHALL dismiss itself and THE Persona_List_Screen SHALL display a green SnackBar with message "Persona berhasil dihapus permanen"
4. IF the hard delete fails, THEN THE Hard_Delete_Persona_Dialog SHALL dismiss itself and THE Persona_List_Screen SHALL display a red SnackBar with the exact backend error message
5. IF the admin cancels the Hard_Delete_Persona_Dialog, THEN THE Persona_List_Screen SHALL dismiss the dialog without making any changes
6. WHILE the hard delete request is in progress, THE Hard_Delete_Persona_Dialog SHALL display a loading indicator and disable both the confirm and cancel buttons

### Requirement 5: UI Aksi Persona pada List Item

**User Story:** Sebagai admin, saya ingin melihat aksi yang tersedia untuk setiap persona secara jelas, sehingga saya bisa memilih antara deaktivasi dan hapus permanen dengan mudah.

#### Acceptance Criteria

1. THE Persona_List_Screen SHALL display the deactivate action button only on persona items where isActive equals true, using a toggle-off icon to represent deactivation
2. THE Persona_List_Screen SHALL display the hard delete action button on all persona items regardless of isActive status, using a delete icon styled with the theme's error color
3. THE Persona_List_Screen SHALL display the deactivate action button with a tooltip "Nonaktifkan" in Bahasa Indonesia
4. THE Persona_List_Screen SHALL display the hard delete action button with a tooltip "Hapus Permanen" in Bahasa Indonesia
5. THE Persona_List_Screen SHALL position the action buttons at the trailing end of each persona list item row, with the deactivate button appearing before the hard delete button when both are visible
6. IF a persona item has isActive equal to false, THEN THE Persona_List_Screen SHALL display only the hard delete button in the trailing action area, maintaining the same position as when both buttons are visible
7. THE Persona_List_Screen SHALL render each action button with a minimum tap target size of 48x48 density-independent pixels

### Requirement 6: Endpoint Constant untuk Deaktivasi

**User Story:** Sebagai developer, saya ingin endpoint deaktivasi terdefinisi di ApiEndpoints class, sehingga konsisten dengan konvensi project dan mudah di-maintain.

#### Acceptance Criteria

1. THE ApiEndpoints class SHALL provide a static method `adminPersonaDeactivate(String id)` that returns the string `/api/personas/$id/deactivate`
2. THE existing `adminPersonaDetail(String id)` method SHALL continue to return `/api/personas/$id` without modification
3. WHEN the Admin_Provider performs a deactivation, THE Admin_Provider SHALL use `ApiEndpoints.adminPersonaDeactivate(id)` as the URL for the PATCH request
4. WHEN the Admin_Provider performs a hard delete, THE Admin_Provider SHALL use `ApiEndpoints.adminPersonaDetail(id)` as the URL for the DELETE request
5. THE `adminPersonaDeactivate` method SHALL be placed in the Admin section of the ApiEndpoints class, following the same static method pattern as `adminPersonaDetail`
