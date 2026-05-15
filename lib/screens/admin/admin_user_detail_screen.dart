import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

/// Halaman detail user untuk admin — read-only.
///
/// Fitur:
/// - Avatar (max width 120 logical pixels, placeholder jika null)
/// - Nama, email, role badge, health points, tanggal registrasi
/// - Semua field read-only, tanpa edit
/// - Shimmer skeleton saat loading
/// - Red SnackBar on error dengan pesan eksak dari backend
/// - Back navigation button ke Daftar User
class AdminUserDetailScreen extends StatefulWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  bool _dateFormattingInitialized = false;

  @override
  void initState() {
    super.initState();
    _initDateFormatting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUserDetail(widget.userId);
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
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    // Listen for error messages
    _showErrorIfNeeded(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail User'),
        centerTitle: false,
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit User',
            onPressed: () {
              context.push('/admin/users/${widget.userId}/edit');
            },
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus User',
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: _buildBody(adminProvider),
    );
  }

  Widget _buildBody(AdminProvider provider) {
    // Loading state — show shimmer
    if (provider.isLoadingUserDetail) {
      return _buildShimmerSkeleton();
    }

    // Data loaded
    final user = provider.selectedUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Data user tidak ditemukan',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return _buildUserDetail(user);
  }

  Widget _buildUserDetail(UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          _buildAvatar(user.avatarUrl, colorScheme),
          const SizedBox(height: 24),

          // Name
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Role badge
          _buildRoleBadge(user.role, colorScheme),
          const SizedBox(height: 32),

          // Detail fields
          _buildDetailCard(user, colorScheme),
        ],
      ),
    );
  }

  /// Avatar — CachedNetworkImage jika URL tersedia, placeholder jika null.
  /// Max width 120 logical pixels.
  Widget _buildAvatar(String? avatarUrl, ColorScheme colorScheme) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 48,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Badge role "Admin" (ungu) atau "User" (biru).
  Widget _buildRoleBadge(String role, ColorScheme colorScheme) {
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.purple.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdmin ? Colors.purple : Colors.blue,
          width: 0.5,
        ),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'User',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isAdmin ? Colors.purple[700] : Colors.blue[700],
        ),
      ),
    );
  }

  /// Card berisi detail fields (email, health points, tanggal registrasi).
  Widget _buildDetailCard(UserModel user, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
              colorScheme: colorScheme,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.favorite,
              label: 'Health Points',
              value: 'HP: ${user.points}/100',
              colorScheme: colorScheme,
              valueColor: _getPointsColor(user.points),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Tanggal Registrasi',
              value: _formatDate(user.createdAt),
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  /// Baris detail dengan icon, label, dan value.
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: valueColor,
                      fontWeight:
                          valueColor != null ? FontWeight.w600 : null,
                    ),
              ),
            ],
          ),
        ),
      ],
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

  /// Shimmer skeleton placeholder saat loading.
  Widget _buildShimmerSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar placeholder
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 24),
            // Name placeholder
            Container(
              height: 24,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Role badge placeholder
            Container(
              height: 20,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 32),
            // Detail card placeholder
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildShimmerRow(),
                    const SizedBox(height: 24),
                    _buildShimmerRow(),
                    const SizedBox(height: 24),
                    _buildShimmerRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer row placeholder untuk detail field.
  Widget _buildShimmerRow() {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 16,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tampilkan dialog konfirmasi hapus user.
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus User'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus user ini secara permanen? '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deleteUser();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// Hapus user dan navigate kembali ke list.
  Future<void> _deleteUser() async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.deleteUser(widget.userId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminProvider.errorMessage ?? 'Gagal menghapus user'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
