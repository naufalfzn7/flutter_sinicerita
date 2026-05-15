import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/errors/app_exception.dart';
import '../../providers/auth_provider.dart';

/// EditProfileScreen — Form untuk mengedit nama dan upload foto profil.
///
/// - Name TextField: pre-filled, max 50 chars, validasi non-empty/non-whitespace
/// - Avatar image picker: tampilkan current avatar atau placeholder
/// - Submit: PATCH /api/me sebagai multipart/form-data
/// - Field upload: "image" (BUKAN "avatar" atau "file")
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Avatar picker
              _buildAvatarPicker(user?.avatarUrl),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isLoading ? null : _pickImage,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Ganti Foto'),
              ),
              const SizedBox(height: 24),
              // Name field
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Masukkan nama kamu',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _validateName,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onSubmit(),
              ),
              const SizedBox(height: 32),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker(String? currentAvatarUrl) {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: ClipOval(
        child: SizedBox(
          width: 100,
          height: 100,
          child: _selectedImage != null
              ? Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                )
              : currentAvatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: currentAvatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.white54,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white54,
                      ),
                    ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length > 50) {
      return 'Nama maksimal 50 karakter';
    }
    return null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    // Validate file size (max 5MB)
    final file = File(pickedFile.path);
    final fileSize = await file.length();
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (fileSize > maxSize) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukuran file maksimal 5MB'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate file format (JPEG/PNG only)
    final extension = pickedFile.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format file harus JPEG atau PNG'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _selectedImage = file;
    });
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Build multipart form data
      final formData = FormData.fromMap({
        'name': _nameController.text.trim(),
        if (_selectedImage != null)
          'image': await MultipartFile.fromFile(
            _selectedImage!.path,
            filename: _selectedImage!.path.split(Platform.pathSeparator).last,
          ),
      });

      await authProvider.apiClient.dio.patch(
        ApiEndpoints.me,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (!mounted) return;

      // Refresh user data
      await context.read<AuthProvider>().fetchMe();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      final ex = AppException.fromDioError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ex.message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
