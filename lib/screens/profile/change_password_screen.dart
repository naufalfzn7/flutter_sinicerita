import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

/// ChangePasswordScreen — Form untuk mengubah password user.
///
/// - 3 obscured password fields: old, new, confirm
/// - Client-side validation: old not empty, new 8-128 chars, confirm matches new
/// - Submit: PATCH /api/me/password with { oldPassword, newPassword }
/// - 401 "Password lama salah": show error SnackBar with exact message
/// - Success: green SnackBar + navigate back
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Password'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Old password field
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Lama',
                  hintText: 'Masukkan password lama',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: _validateOldPassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // New password field
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  hintText: 'Masukkan password baru',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: _validateNewPassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  hintText: 'Masukkan ulang password baru',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: _validateConfirmPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onSubmit(),
              ),
              const SizedBox(height: 32),
              // Submit button
              SizedBox(
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
                      : const Text('Ubah Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateOldPassword(String? value) {
    return Validators.validateOldPassword(value);
  }

  String? _validateNewPassword(String? value) {
    return Validators.validateNewPassword(value, _oldPasswordController.text);
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != _newPasswordController.text) {
      return 'Konfirmasi password tidak cocok';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      await authProvider.apiClient.dio.patch(
        ApiEndpoints.changePassword,
        data: {
          'oldPassword': _oldPasswordController.text,
          'newPassword': _newPasswordController.text,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah'),
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
