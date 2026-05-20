import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          ChatListScreen(),
          PersonaListScreen(),
          ProfileScreen(),
        ],
      ),
      // FAB untuk admin kembali ke Admin Panel
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/admin'),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin Panel'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => switchTab(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Persona',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
