import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// SplashScreen — tampilkan branding app sambil cek status autentikasi.
///
/// GoRouter akan otomatis redirect berdasarkan perubahan AuthStatus
/// via `refreshListenable`.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    await context.read<AuthProvider>().checkAuthStatus();
    if (!mounted) return;
    // GoRouter will handle navigation via refreshListenable
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo with text (branding utama)
            SvgPicture.asset(
              'assets/images/logo-with-text.svg',
              width: 180,
            ),
            const SizedBox(height: 16),
            // Subtitle
            Text(
              'Teman cerita kamu',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
