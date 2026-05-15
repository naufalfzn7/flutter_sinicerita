import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/persona_model.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/persona/persona_grid_card.dart';

/// PersonaScreen — Menampilkan daftar persona AI dalam grid 2 kolom.
///
/// Fitur:
/// - Grid 2 kolom dengan avatar, nama, deskripsi, upvote/downvote count
/// - Infinite scroll pagination
/// - Shimmer skeleton untuk first page load
/// - Loading indicator di bottom untuk subsequent pages
/// - Pull-to-refresh
/// - Error SnackBar
class PersonaListScreen extends StatefulWidget {
  const PersonaListScreen({super.key});

  @override
  State<PersonaListScreen> createState() => _PersonaListScreenState();
}

class _PersonaListScreenState extends State<PersonaListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      _hasFetched = true;
      Future.microtask(() {
        if (mounted) {
          context.read<PersonaProvider>().fetchPersonas();
        }
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
      final provider = context.read<PersonaProvider>();
      if (provider.hasMorePages && !provider.isLoading) {
        provider.fetchNextPage();
      }
    }
  }

  Future<void> _onRefresh() async {
    await context.read<PersonaProvider>().refreshPersonas();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonaProvider>();

    // Listen for error messages
    _showErrorIfNeeded(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persona'),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(PersonaProvider provider) {
    // First page loading — show shimmer
    if (provider.isLoading && provider.personas.isEmpty) {
      return _buildShimmerGrid();
    }

    // Empty state (no personas after load)
    if (!provider.isLoading && provider.personas.isEmpty) {
      return _buildEmptyState();
    }

    // Grid with data
    return _buildPersonaGrid(provider);
  }

  Widget _buildPersonaGrid(PersonaProvider provider) {
    final personas = provider.personas;

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildPersonaCard(personas[index]);
              },
              childCount: personas.length,
            ),
          ),
        ),
        // Bottom loading indicator for subsequent pages
        if (provider.isLoading && provider.hasMorePages)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonaCard(PersonaModel persona) {
    return PersonaGridCard(
      persona: persona,
      onTap: () => context.push('/persona-detail/${persona.id}'),
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Avatar placeholder
                const CircleAvatar(radius: 28, backgroundColor: Colors.white),
                const SizedBox(height: 8),
                // Name placeholder
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                // Description placeholder
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
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
        ),
      ),
    );
  }

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
                'Belum ada persona tersedia',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showErrorIfNeeded(PersonaProvider provider) {
    final error = provider.errorMessage;
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();
      });
    }
  }
}
