import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Halaman input 6-digit OTP code — step 2 dari forgot password flow.
class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isComplete = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value) {
    setState(() {
      _isComplete = value.length == 6;
    });
  }

  Future<void> _onVerify() async {
    final code = _otpController.text;
    final success = await context.read<AuthProvider>().verifyOtp(
      widget.email,
      code,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.read<AuthProvider>().successMessage ??
                  'OTP berhasil diverifikasi',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).size.height - 150,
            ),
          ),
        );
      context.push('/reset-password', extra: {
        'email': widget.email,
        'code': code,
      });
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.read<AuthProvider>().errorMessage ?? 'Terjadi kesalahan',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).size.height - 150,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi OTP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Masukkan 6 digit kode yang dikirim ke ${widget.email}'),
            const SizedBox(height: 24),

            // OTP PIN input
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              enableActiveFill: true,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 45,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                selectedFillColor: Colors.white,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.grey[300]!,
                selectedColor: Theme.of(context).colorScheme.primary,
              ),
              onChanged: _onOtpChanged,
            ),

            const SizedBox(height: 24),

            // Verify button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                    (!_isComplete || isLoading) ? null : _onVerify,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verifikasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
