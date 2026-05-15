import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/session_model.dart';
import '../../providers/persona_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/chat/session_list_tile.dart';
import '../main/main_screen.dart';

/// ChatListScreen — Tab kedua di MainScreen.
///
/// Menampilkan daftar sesi chat user dalam 2 tab:
/// - "Aktif": sesi dengan status active, diurutkan updatedAt descending
/// - "Selesai": sesi dengan status completed, diurutkan completedAt descending
///
/// Setiap item menampilkan nama persona, preview pesan terakhir,
/// waktu relatif, dan status badge. Sesi selesai juga menampilkan scoreDelta.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _initialFetchDone = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialFetchDone) {
      _initialFetchDone = true;
      Future.microtask(() {
        if (mounted) {
          _fetchAllSessions();
        }
      });
    }
  }

  Future<void> _fetchAllSessions() async {
    final sessionProvider = context.read<SessionProvider>();
    await Future.wait([
      sessionProvider.fetchSessions(status: 'active'),
      sessionProvider.fetchSessions(status: 'completed'),
    ]);
    if (!mounted) return;
    _showErrorIfAny();
  }

  Future<void> _refreshActiveSessions() async {
    await context.read<SessionProvider>().fetchSessions(status: 'active');
    if (!mounted) return;
    _showErrorIfAny();
  }

  Future<void> _refreshCompletedSessions() async {
    await context.read<SessionProvider>().fetchSessions(status: 'completed');
    if (!mounted) return;
    _showErrorIfAny();
  }

  void _showErrorIfAny() {
    final error = context.read<SessionProvider>().errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
      context.read<SessionProvider>().clearError();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveSessionsTab(onRefresh: _refreshActiveSessions),
          _CompletedSessionsTab(onRefresh: _refreshCompletedSessions),
        ],
      ),
    );
  }
}

// ─── Active Sessions Tab ──────────────────────────────────────────────────────

class _ActiveSessionsTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _ActiveSessionsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final personaProvider = context.watch<PersonaProvider>();
    final sessions = sessionProvider.activeSessions;
    final isLoading = sessionProvider.isLoading;

    if (isLoading && sessions.isEmpty) {
      return const _ShimmerSessionList();
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: sessions.isEmpty
          ? _buildActiveEmptyState(context)
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _DismissibleSessionItem(
                  session: session,
                  personaProvider: personaProvider,
                  onTap: () => context.push('/chat/${session.id}'),
                );
              },
            ),
    );
  }

  Widget _buildActiveEmptyState(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.chat_bubble_outline,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Belum ada sesi aktif',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              context
                  .findAncestorStateOfType<MainScreenState>()
                  ?.switchTab(2);
            },
            icon: const Icon(Icons.add),
            label: const Text('Mulai Cerita'),
          ),
        ),
      ],
    );
  }
}

// ─── Dismissible Session Item (Active only) ───────────────────────────────────

class _DismissibleSessionItem extends StatelessWidget {
  final SessionModel session;
  final PersonaProvider personaProvider;
  final VoidCallback onTap;

  const _DismissibleSessionItem({
    required this.session,
    required this.personaProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final persona = personaProvider.getById(session.personaId);
    final personaName = persona?.name ?? 'Persona';

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmation(context),
      child: SessionListTile(
        session: session,
        personaName: personaName,
        showScoreDelta: false,
        onTap: onTap,
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final sessionProvider = context.read<SessionProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Sesi'),
        content: const Text('Apakah kamu yakin ingin menghapus sesi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    // User confirmed — perform optimistic delete
    final success = await sessionProvider.deleteSession(session.id);

    if (!success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(sessionProvider.errorMessage ?? 'Gagal menghapus sesi'),
          backgroundColor: Colors.red,
        ),
      );
      sessionProvider.clearError();
    }

    // Return false because SessionProvider already handles removal/revert
    // We don't want Dismissible to also animate the removal
    return false;
  }
}

// ─── Completed Sessions Tab ───────────────────────────────────────────────────

class _CompletedSessionsTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _CompletedSessionsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final personaProvider = context.watch<PersonaProvider>();
    final sessions = sessionProvider.completedSessions;
    final isLoading = sessionProvider.isLoading;

    if (isLoading && sessions.isEmpty) {
      return const _ShimmerSessionList();
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: sessions.isEmpty
          ? _buildCompletedEmptyState()
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final persona = personaProvider.getById(session.personaId);
                final personaName = persona?.name ?? 'Persona';
                return SessionListTile(
                  session: session,
                  personaName: personaName,
                  showScoreDelta: true,
                  onTap: () =>
                      context.push('/session-detail/${session.id}'),
                );
              },
            ),
    );
  }

  Widget _buildCompletedEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Belum ada sesi yang selesai',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

// ─── Shimmer Loading ──────────────────────────────────────────────────────────

class _ShimmerSessionList extends StatelessWidget {
  const _ShimmerSessionList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (_, _) => const _ShimmerSessionTile(),
      ),
    );
  }
}

class _ShimmerSessionTile extends StatelessWidget {
  const _ShimmerSessionTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.white,
      ),
      title: Row(
        children: [
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 40),
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Container(
              height: 12,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 16,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}
