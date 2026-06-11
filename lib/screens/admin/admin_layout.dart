import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_surfaces.dart';

/// Shell widget yang membungkus semua halaman admin dengan NavigationRail.
///
/// Menerima [child] dari GoRouter ShellRoute — content area di sebelah kanan.
/// NavigationRail di sebelah kiri menampilkan menu: Dashboard, Kelola Persona, Daftar User.
class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  /// Truncate nama admin ke 20 karakter + ellipsis jika melebihi.
  static String truncateName(String name) {
    if (name.length > 20) {
      return '${name.substring(0, 20)}\u2026';
    }
    return name;
  }

  /// Tentukan index navigasi aktif berdasarkan lokasi route saat ini.
  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/personas')) return 1;
    if (location.startsWith('/admin/users')) return 2;
    return 0; // default: dashboard
  }

  /// Navigasi ke route berdasarkan index yang dipilih.
  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
      case 1:
        context.go('/admin/personas');
      case 2:
        context.go('/admin/users');
      case 3:
        // Switch ke fitur user (main screen)
        context.go('/main');
    }
  }

  /// Tampilkan dialog konfirmasi logout.
  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final adminName = currentUser?.name ?? 'Admin';
    final avatarUrl = currentUser?.avatarUrl;
    final selectedIndex = _getSelectedIndex(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.surfaceContainerLow.withValues(
                alpha: 0.86,
              ),
              indicatorColor: AppColors.primary.withValues(alpha: 0.18),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    // Avatar admin
                    _buildAvatar(avatarUrl, colorScheme),
                    const SizedBox(height: 8),
                    // Nama admin (truncated)
                    SizedBox(
                      width: 72,
                      child: Text(
                        truncateName(adminName),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout),
                      tooltip: 'Keluar',
                    ),
                  ),
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: const Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.smart_toy_outlined),
                  selectedIcon: const Icon(Icons.smart_toy),
                  label: const Text('Kelola Persona'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.people_outlined),
                  selectedIcon: const Icon(Icons.people),
                  label: const Text('Daftar User'),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.chat_outlined),
                  selectedIcon: const Icon(Icons.chat),
                  label: const Text('Fitur User'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  /// Build avatar widget — gunakan CachedNetworkImage jika URL tersedia,
  /// atau placeholder icon jika null.
  Widget _buildAvatar(String? avatarUrl, ColorScheme colorScheme) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: colorScheme.surfaceContainerHigh,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                Icon(Icons.person, color: colorScheme.onSurfaceVariant),
            errorWidget: (_, _, _) =>
                Icon(Icons.person, color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: colorScheme.surfaceContainerHigh,
      child: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
    );
  }
}
