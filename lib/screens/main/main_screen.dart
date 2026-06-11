import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/common/app_surfaces.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_list_screen.dart';
import '../home/home_screen.dart';
import '../persona/persona_list_screen.dart';
import '../profile/profile_screen.dart';

/// MainScreen — Shell navigasi utama setelah login.
///
/// Menampung BottomNavigationBar dengan 4 tab (Beranda, Chat, Persona, Profil)
/// dan IndexedStack untuk mempertahankan state setiap tab.
/// Jika user adalah admin, tampilkan FAB untuk kembali ke Admin Panel.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

/// State class dibuat public (tanpa underscore) agar child widgets
/// bisa mengakses [switchTab] via `findAncestorStateOfType<MainScreenState>()`.
class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  /// Pindah tab secara programatis dari child widget.
  ///
  /// Contoh penggunaan dari child:
  /// ```dart
  /// context.findAncestorStateOfType<MainScreenState>()?.switchTab(2);
  /// ```
  void switchTab(int index) {
    if (index < 0 || index > 3) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.currentUser?.role == 'admin';

    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),
            ChatListScreen(),
            PersonaListScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/admin'),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin Panel'),
            )
          : null,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: switchTab,
            height: 74,
            elevation: 0,
            backgroundColor: AppColors.surfaceContainerLow.withValues(
              alpha: 0.96,
            ),
            indicatorColor: AppColors.primary.withValues(alpha: 0.18),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Persona',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
