import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/persona_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common/app_surfaces.dart';
import '../../widgets/admin/deactivate_persona_dialog.dart';
import '../../widgets/admin/hard_delete_persona_dialog.dart';

/// Halaman daftar persona untuk admin — menampilkan semua persona (aktif & nonaktif).
///
/// Fitur:
/// - List persona dengan avatar, nama, deskripsi, status badge, upvote/downvote
/// - Infinite scroll pagination
/// - Shimmer skeleton untuk first page load
/// - Loading indicator di bottom untuk subsequent pages
/// - Pull-to-refresh
/// - Error SnackBar (merah) — preserve existing data
/// - Empty state "Belum ada persona"
/// - FAB "Tambah Persona" → navigate ke create form
/// - Delete action hanya pada persona dengan isActive = true
class AdminPersonaListScreen extends StatefulWidget {
  const AdminPersonaListScreen({super.key});

  @override
  State<AdminPersonaListScreen> createState() => _AdminPersonaListScreenState();
}

class _AdminPersonaListScreenState extends State<AdminPersonaListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPersonas();
    });
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
      context.read<AdminProvider>().fetchMorePersonas();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<AdminProvider>().fetchPersonas(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    // Listen for error messages
    _showErrorIfNeeded(adminProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Kelola Persona'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(adminProvider),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/personas/create'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Persona'),
      ),
    );
  }

  Widget _buildBody(AdminProvider provider) {
    // First page loading — show shimmer
    if (provider.isLoadingPersonas && provider.personas.isEmpty) {
      return _buildShimmerList();
    }

    // Empty state
    if (!provider.isLoadingPersonas && provider.personaTotal == 0) {
      return _buildEmptyState();
    }

    // List with data
    return _buildPersonaList(provider);
  }

  Widget _buildPersonaList(AdminProvider provider) {
    final personas = provider.personas;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: personas.length + (provider.isLoadingMorePersonas ? 1 : 0),
      itemBuilder: (context, index) {
        // Bottom loading indicator for subsequent pages
        if (index == personas.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return StaggeredFadeSlide(
          index: index % 8,
          child: _buildPersonaItem(personas[index]),
        );
      },
    );
  }

  Widget _buildPersonaItem(PersonaModel persona) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GlassPanel(
        onTap: () => context.push('/admin/personas/${persona.id}/edit'),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _buildAvatar(persona.avatarUrl, colorScheme),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status badge row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            persona.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(persona.isActive, colorScheme),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Description (truncated 2 lines)
                    Text(
                      persona.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Vote counts row
                    Row(
                      children: [
                        Icon(
                          Icons.thumb_up,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${persona.upvotes}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.thumb_down,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${persona.downvotes}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Deactivate button — only for active personas
                  if (persona.isActive)
                    IconButton(
                      onPressed: () => _showDeleteDialog(persona),
                      icon: const Icon(Icons.toggle_off_outlined),
                      tooltip: 'Nonaktifkan',
                    ),
                  // Hard delete button — always visible
                  IconButton(
                    onPressed: () => _showHardDeleteDialog(persona),
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    tooltip: 'Hapus Permanen',
                  ),
                ],
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
        backgroundColor: AppColors.surfaceContainerHighest,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Icon(Icons.smart_toy, color: colorScheme.onSurfaceVariant),
            errorWidget: (context, url, error) =>
                Icon(Icons.smart_toy, color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.surfaceContainerHighest,
      child: Icon(Icons.smart_toy, color: colorScheme.onSurfaceVariant),
    );
  }

  /// Badge status "Aktif" (hijau) atau "Nonaktif" (abu-abu).
  Widget _buildStatusBadge(bool isActive, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.success : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isActive ? AppColors.success : Colors.grey[400],
        ),
      ),
    );
  }

  /// Dialog konfirmasi deaktivasi persona.
  ///
  /// Menggunakan [DeactivatePersonaDialog] yang mengelola loading state sendiri.
  /// Returns:
  /// - `true` → success, tampilkan green SnackBar
  /// - `String` → error message, tampilkan red SnackBar
  /// - `null` → cancelled, no action
  Future<void> _showDeleteDialog(PersonaModel persona) async {
    final result = await DeactivatePersonaDialog.show(
      context,
      personaId: persona.id,
      personaName: persona.name,
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Persona berhasil dinonaktifkan'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result is String) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
    // null = cancelled, no action needed
  }

  /// Dialog konfirmasi hard delete (hapus permanen) persona.
  ///
  /// Menggunakan [HardDeletePersonaDialog] yang mengelola loading state sendiri.
  /// Returns:
  /// - `true` → success, tampilkan green SnackBar
  /// - `String` → error message, tampilkan red SnackBar
  /// - `null` → cancelled, no action
  Future<void> _showHardDeleteDialog(PersonaModel persona) async {
    final result = await HardDeletePersonaDialog.show(
      context,
      personaId: persona.id,
      personaName: persona.name,
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Persona berhasil dihapus permanen'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result is String) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.red),
      );
    }
    // null = cancelled, no action needed
  }

  /// Shimmer skeleton placeholder untuk first page load.
  Widget _buildShimmerList() {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLow,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
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
                const CircleAvatar(radius: 24, backgroundColor: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name placeholder
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description line 1
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Description line 2
                      Container(
                        height: 12,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Vote counts placeholder
                      Container(
                        height: 12,
                        width: 80,
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

  /// Empty state — tampilkan pesan "Belum ada persona".
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            children: [
              Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Belum ada persona',
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
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
          provider.clearError();
        }
      });
    }
  }
}
