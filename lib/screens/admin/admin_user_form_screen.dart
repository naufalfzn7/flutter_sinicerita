import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

/// Form screen untuk membuat atau mengedit user (admin).
///
/// Mode ditentukan oleh [userId]:
/// - null → mode create (POST /api/admin/users)
/// - non-null → mode edit (PATCH /api/admin/users/:id, hanya field yang berubah)
class AdminUserFormScreen extends StatefulWidget {
  final String? userId;

  const AdminUserFormScreen({super.key, this.userId});

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pointsController = TextEditingController();

  bool _isEdit = false;
  String _selectedRole = 'user';
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  // Original values for differential update in edit mode
  UserModel? _originalUser;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.userId != null;

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillForm();
      });
    }
  }

  void _prefillForm() {
    final adminProvider = context.read<AdminProvider>();

    // Try from selectedUser first, then from users list
    UserModel? user = adminProvider.selectedUser;
    if (user == null || user.id != widget.userId) {
      final found = adminProvider.users.where((u) => u.id == widget.userId);
      if (found.isNotEmpty) {
        user = found.first;
      }
    }

    if (user == null) return;

    _originalUser = user;
    setState(() {
      _nameController.text = user!.name;
      _emailController.text = user.email;
      _pointsController.text = user.points.toString();
      _selectedRole = user.role;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  // ─── Validation ─────────────────────────────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama wajib diisi';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    // Password wajib saat create, opsional saat edit
    if (!_isEdit) {
      if (value == null || value.isEmpty) {
        return 'Password wajib diisi';
      }
      if (value.length < 8) {
        return 'Password minimal 8 karakter';
      }
    } else {
      // Edit mode: jika diisi, minimal 8 karakter
      if (value != null && value.isNotEmpty && value.length < 8) {
        return 'Password minimal 8 karakter';
      }
    }
    return null;
  }

  String? _validatePoints(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Health points wajib diisi';
    }
    final points = int.tryParse(value.trim());
    if (points == null) {
      return 'Harus berupa angka';
    }
    if (points < 0 || points > 100) {
      return 'Health points harus antara 0–100';
    }
    return null;
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
            _isEdit ? 'User berhasil diperbarui' : 'User berhasil dibuat',
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
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': _selectedRole,
      'points': int.parse(_pointsController.text.trim()),
    };

    return provider.createUser(data);
  }

  Future<bool> _submitEdit(AdminProvider provider) async {
    final data = <String, dynamic>{};

    // Only send changed fields
    final name = _nameController.text.trim();
    if (name != _originalUser?.name) {
      data['name'] = name;
    }

    final email = _emailController.text.trim();
    if (email != _originalUser?.email) {
      data['email'] = email;
    }

    if (_passwordController.text.isNotEmpty) {
      data['password'] = _passwordController.text;
    }

    if (_selectedRole != _originalUser?.role) {
      data['role'] = _selectedRole;
    }

    final points = int.parse(_pointsController.text.trim());
    if (points != _originalUser?.points) {
      data['points'] = points;
    }

    // If nothing changed, just pop
    if (data.isEmpty) {
      return true;
    }

    return provider.updateUser(widget.userId!, data);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit User' : 'Tambah User'),
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

              // Email field
              _buildEmailField(),
              const SizedBox(height: 16),

              // Password field
              _buildPasswordField(),
              const SizedBox(height: 16),

              // Role dropdown
              _buildRoleDropdown(),
              const SizedBox(height: 16),

              // Points field
              _buildPointsField(),
              const SizedBox(height: 24),

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
      decoration: const InputDecoration(
        labelText: 'Nama',
        hintText: 'Masukkan nama user',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: _validateName,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'Masukkan email user',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: _validateEmail,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: _isEdit ? 'Password (kosongkan jika tidak diubah)' : 'Password',
        hintText: _isEdit ? 'Kosongkan jika tidak diubah' : 'Minimal 8 karakter',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: _validatePassword,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      decoration: const InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
      ),
      items: const [
        DropdownMenuItem(value: 'user', child: Text('User')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRole = value;
          });
        }
      },
    );
  }

  Widget _buildPointsField() {
    return TextFormField(
      controller: _pointsController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Health Points (0–100)',
        hintText: 'Masukkan health points',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.favorite_outline),
      ),
      validator: _validatePoints,
      textInputAction: TextInputAction.done,
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
          : Text(_isEdit ? 'Simpan Perubahan' : 'Buat User'),
    );
  }
}
