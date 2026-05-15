import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Halaman welcome/landing page — ditampilkan saat user pertama kali
/// membuka aplikasi sebelum diarahkan ke login/register.
///
/// Layout: logo centered upper, tagline middle, tombol "Mulai" bottom.
/// On tap "Mulai": simpan first-launch flag → navigate ke /login.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            children: [
              // ─── Logo (upper portion, centered) ─────────────────
              const Spacer(flex: 2),
              Center(
                child: SvgPicture.asset(
                  'assets/images/logo-with-text.svg',
                  width: 180,
                ),
              ),
              const Spacer(flex: 1),

              // ─── Tagline (middle) ──────────────────────────────
              Text(
                'Selamat datang di SiniCerita',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Teman curhat AI yang siap mendengarkan ceritamu kapan saja, tanpa menghakimi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(flex: 2),

              // ─── Tombol "Mulai" (bottom, full-width) ───────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().completeFirstLaunch();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  child: const Text('Mulai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
