import 'package:dio/dio.dart';

/// Builds FormData containing only fields that differ between original and modified values.
///
/// Used by the admin persona edit form to send PATCH requests with only changed fields.
/// This ensures minimal payload and follows the backend's partial update semantics.
FormData buildDifferentialFormData({
  required String? originalName,
  required String? modifiedName,
  required String? originalDescription,
  required String? modifiedDescription,
  required String? originalSystemPrompt,
  required String? modifiedSystemPrompt,
  required bool? originalIsActive,
  required bool? modifiedIsActive,
}) {
  final formData = FormData();

  if (modifiedName != null && modifiedName != originalName) {
    formData.fields.add(MapEntry('name', modifiedName));
  }

  if (modifiedDescription != null &&
      modifiedDescription != originalDescription) {
    formData.fields.add(MapEntry('description', modifiedDescription));
  }

  if (modifiedSystemPrompt != null &&
      modifiedSystemPrompt != originalSystemPrompt) {
    formData.fields.add(MapEntry('systemPrompt', modifiedSystemPrompt));
  }

  if (modifiedIsActive != null && modifiedIsActive != originalIsActive) {
    formData.fields.add(MapEntry('isActive', modifiedIsActive.toString()));
  }

  return formData;
}
