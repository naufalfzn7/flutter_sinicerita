import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

/// Halaman daftar user untuk admin — read-only.
///
/// Fitur:
/// - List user dengan avatar, nama, email, role badge, health points, tanggal registrasi
/// - Infinite scroll pagination
/// - Shimmer skeleton untuk first page load
/// - Loading indicator di bottom untuk subsequent pages
/// - Pull-to-refresh
/// - Error SnackBar (merah) dengan pesan eksak dari backend
/// - Empty state ketika tidak ada user
/// - Tap user item → navigate ke detail user
class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _dateFormattingInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initDateFormatting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
  }

  Future<void> _initDateFormatting() async {
    await initializeDateFormatting('id_ID', null);
    if (mounted) {
      setState(() {
        _dateFormattingInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 200) {
      context.read<AdminProvider>().fetchMoreUsers();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<AdminProvider>().fetchUsers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    // Listen for error messages
    _showErrorIfNeeded(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar User'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/users/create'),
        tooltip: 'Tambah User',
        child: const Icon(Icons.person_add),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(adminProvider),
      ),
    );
  }

  Widget _buildBody(AdminProvider provider) {
    // First page loading — show shimmer
    if (provider.isLoadingUsers && provider.users.isEmpty) {
      return _buildShimmerList();
    }

    // Empty state
    if (!provider.isLoadingUsers && provider.users.isEmpty) {
      return _buildEmptyState();
    }

    // List with data
    return _buildUserList(provider);
  }

  Widget _buildUserList(AdminProvider provider) {
    final users = provider.users;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: users.length + (provider.isLoadingMoreUsers ? 1 : 0),
      itemBuilder: (context, index) {
        // Bottom loading indicator for subsequent pages
        if (index == users.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildUserItem(users[index]);
      },
    );
  }

  Widget _buildUserItem(UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/admin/users/${user.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(user.avatarUrl, colorScheme),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + role badge row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(user.role, colorScheme),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Health points + registration date row
                    Row(
                      children: [
                        // Health points
                        Icon(
                          Icons.favorite,
                          size: 14,
                          color: _getPointsColor(user.points),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HP: ${user.points}/100',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        // Registration date
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(user.createdAt),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build avatar — CachedNetworkImage jika URL tersedia, placeholder jika null.
  Widget _buildAvatar(String? avatarUrl, ColorScheme colorScheme) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: colorScheme.surfaceContainerHigh,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (context, url) => Icon(
              Icons.person,
              color: colorScheme.onSurfaceVariant,
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.person,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.surfaceContainerHigh,
      child: Icon(
        Icons.person,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Badge role "Admin" (ungu) atau "User" (biru).
  Widget _buildRoleBadge(String role, ColorScheme colorScheme) {
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.purple.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? Colors.purple : Colors.blue,
          width: 0.5,
        ),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'User',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isAdmin ? Colors.purple[700] : Colors.blue[700],
        ),
      ),
    );
  }

  /// Warna health points berdasarkan nilai.
  Color _getPointsColor(int points) {
    if (points >= 70) return Colors.green;
    if (points >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Format tanggal registrasi ke "dd MMMM yyyy" dengan locale id_ID.
  String _formatDate(DateTime date) {
    if (!_dateFormattingInitialized) return '';
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  /// Shimmer skeleton placeholder untuk first page load.
  Widget _buildShimmerList() {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLow,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: 6,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar placeholder
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name placeholder
                      Container(
                        height: 16,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Email placeholder
                      Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // HP + date placeholder
                      Container(
                        height: 12,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empty state — tampilkan pesan ketika tidak ada user.
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada user terdaftar',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tampilkan SnackBar merah jika ada error dari provider.
  void _showErrorIfNeeded(AdminProvider provider) {
    if (provider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final message = provider.errorMessage;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
          provider.clearError();
        }
      });
    }
  }
}
