import 'dart:io';

import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/form_data_utils.dart';
import '../../models/persona_model.dart';
import '../../providers/admin_provider.dart';

/// Form screen untuk membuat atau mengedit persona (admin).
///
/// Mode ditentukan oleh [personaId]:
/// - null → mode create (POST /api/personas)
/// - non-null → mode edit (PATCH /api/personas/:id, hanya field yang berubah)
class AdminPersonaFormScreen extends StatefulWidget {
  final String? personaId;

  const AdminPersonaFormScreen({super.key, this.personaId});

  @override
  State<AdminPersonaFormScreen> createState() => _AdminPersonaFormScreenState();
}

class _AdminPersonaFormScreenState extends State<AdminPersonaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();

  bool _isEdit = false;
  bool _isActive = true;
  File? _selectedImage;
  String? _imageError;
  bool _isSubmitting = false;

  // Original values for differential update in edit mode
  PersonaModel? _originalPersona;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEdit = widget.personaId != null;

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillForm();
      });
    }
  }

  void _prefillForm() {
    final adminProvider = context.read<AdminProvider>();
    final persona = adminProvider.personas.firstWhere(
      (p) => p.id == widget.personaId,
      orElse: () => const PersonaModel(
        id: '',
        name: '',
        description: '',
        isActive: true,
        upvotes: 0,
        downvotes: 0,
      ),
    );

    if (persona.id.isEmpty) return;

    _originalPersona = persona;
    setState(() {
      _nameController.text = persona.name;
      _descriptionController.text = persona.description;
      _systemPromptController.text = persona.systemPrompt ?? '';
      _isActive = persona.isActive;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  // ─── Validation ─────────────────────────────────────────────────────────────

  String? _validateRequired(String? value, String fieldName, int maxLength) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }
    if (value.length > maxLength) {
      return 'Maksimal $maxLength karakter';
    }
    return null;
  }

  // ─── Image Picker ───────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileSize = await file.length();

    // 5 MB = 5 * 1024 * 1024 bytes
    if (fileSize > 5 * 1024 * 1024) {
      setState(() {
        _imageError = 'Ukuran gambar maksimal 5 MB';
        _selectedImage = null;
      });
      return;
    }

    setState(() {
      _selectedImage = file;
      _imageError = null;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageError = null;
    });
  }

  // ─── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final adminProvider = context.read<AdminProvider>();
    bool success;

    if (_isEdit) {
      success = await _submitEdit(adminProvider);
    } else {
      success = await _submitCreate(adminProvider);
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Persona berhasil diperbarui'
                : 'Persona berhasil dibuat',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final errorMessage = adminProvider.errorMessage ?? 'Terjadi kesalahan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _submitCreate(AdminProvider provider) async {
    final formData = FormData.fromMap({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'systemPrompt': _systemPromptController.text.trim(),
    });

    if (_selectedImage != null) {
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            _selectedImage!.path,
            filename: _selectedImage!.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }

    return provider.createPersona(formData);
  }

  Future<bool> _submitEdit(AdminProvider provider) async {
    final formData = buildDifferentialFormData(
      originalName: _originalPersona?.name,
      modifiedName: _nameController.text.trim(),
      originalDescription: _originalPersona?.description,
      modifiedDescription: _descriptionController.text.trim(),
      originalSystemPrompt: _originalPersona?.systemPrompt,
      modifiedSystemPrompt: _systemPromptController.text.trim(),
      originalIsActive: _originalPersona?.isActive,
      modifiedIsActive: _isActive,
    );

    // Add image if a new one was selected
    if (_selectedImage != null) {
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            _selectedImage!.path,
            filename: _selectedImage!.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }

    return provider.updatePersona(widget.personaId!, formData);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Persona' : 'Tambah Persona'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              _buildNameField(),
              const SizedBox(height: 16),

              // Description field
              _buildDescriptionField(),
              const SizedBox(height: 16),

              // System Prompt field
              _buildSystemPromptField(),
              const SizedBox(height: 16),

              // Image picker
              _buildImagePicker(),
              const SizedBox(height: 16),

              // isActive toggle (edit mode only)
              if (_isEdit) ...[
                _buildIsActiveToggle(),
                const SizedBox(height: 24),
              ],

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      maxLength: 100,
      decoration: const InputDecoration(
        labelText: 'Nama Persona',
        hintText: 'Masukkan nama persona',
        border: OutlineInputBorder(),
      ),
      validator: (value) => _validateRequired(value, 'Nama', 100),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLength: 500,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Deskripsi',
        hintText: 'Masukkan deskripsi persona',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (value) => _validateRequired(value, 'Deskripsi', 500),
    );
  }

  Widget _buildSystemPromptField() {
    return TextFormField(
      controller: _systemPromptController,
      maxLength: 2000,
      maxLines: 5,
      decoration: const InputDecoration(
        labelText: 'System Prompt',
        hintText: 'Masukkan system prompt untuk persona',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (value) => _validateRequired(value, 'System Prompt', 2000),
    );
  }

  Widget _buildImagePicker() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gambar (opsional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),

        // Thumbnail preview
        if (_selectedImage != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Pick image button
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: Text(
            _selectedImage != null ? 'Ganti Gambar' : 'Pilih Gambar',
          ),
        ),

        // Image error message
        if (_imageError != null) ...[
          const SizedBox(height: 4),
          Text(
            _imageError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildIsActiveToggle() {
    return SwitchListTile(
      title: const Text('Persona Aktif'),
      value: _isActive,
      onChanged: (value) {
        setState(() {
          _isActive = value;
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isSubmitting ? null : _onSubmit,
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(_isEdit ? 'Simpan Perubahan' : 'Buat Persona'),
    );
  }
}
