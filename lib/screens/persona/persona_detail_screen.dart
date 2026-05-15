import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/persona_provider.dart';
import '../../providers/session_provider.dart';

/// PersonaDetailScreen — Menampilkan detail persona dengan voting dan tombol mulai chat.
///
/// Fitur:
/// - Fetch persona detail via PersonaProvider.fetchPersonaDetail(id) on init
/// - Display: name, avatar, full description, upvote count, downvote count
/// - Vote buttons (UP, DOWN) dengan visual highlight untuk current user rating
/// - No highlight ketika rating NONE/null
/// - Tap different vote: optimistic update via PersonaProvider.ratePersona()
/// - Tap same vote (toggle off): send NONE, decrement count
/// - Show session count with this persona
/// - "Mulai Chat" button untuk create session
/// - Shimmer loading state
/// - Error: show SnackBar dengan backend message
class PersonaDetailScreen extends StatefulWidget {
  final String personaId;

  const PersonaDetailScreen({super.key, required this.personaId});

  @override
  State<PersonaDetailScreen> createState() => _PersonaDetailScreenState();
}

class _PersonaDetailScreenState extends State<PersonaDetailScreen> {
  bool _hasFetched = false;
  bool _isCreatingSession = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      _hasFetched = true;
      // Gunakan Future.microtask agar notifyListeners() tidak dipanggil
      // saat widget tree masih dalam proses build.
      Future.microtask(() {
        if (mounted) {
          context.read<PersonaProvider>().fetchPersonaDetail(widget.personaId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final personaProvider = context.watch<PersonaProvider>();
    final sessionProvider = context.watch<SessionProvider>();

    // Listen for error messages
    _showErrorIfNeeded(personaProvider);

    final persona = personaProvider.selectedPersona;
    final isLoading = personaProvider.isLoadingDetail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Persona'),
      ),
      body: isLoading
          ? _buildShimmer()
          : persona == null
              ? _buildErrorState()
              : _buildContent(persona, sessionProvider),
      bottomNavigationBar: (!isLoading && persona != null)
          ? _buildBottomButton()
          : null,
    );
  }

  Widget _buildContent(
    dynamic persona,
    SessionProvider sessionProvider,
  ) {
    // Hitung session count dengan persona ini
    final sessionCount = sessionProvider.activeSessions
            .where((s) => s.personaId == widget.personaId)
            .length +
        sessionProvider.completedSessions
            .where((s) => s.personaId == widget.personaId)
            .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          ClipOval(
            child: SizedBox(
              width: 100,
              height: 100,
              child: persona.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: persona.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 48),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 48),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            persona.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Vote buttons
          _buildVoteButtons(persona),
          const SizedBox(height: 24),

          // Full description
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              persona.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Session count
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    'Jumlah sesi dengan persona ini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$sessionCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Extra space for bottom button
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildVoteButtons(dynamic persona) {
    final currentRating = persona.userRating;
    final isUpActive = currentRating == 'UP';
    final isDownActive = currentRating == 'DOWN';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Upvote button
        _VoteButton(
          icon: isUpActive ? Icons.thumb_up : Icons.thumb_up_outlined,
          count: persona.upvotes,
          isActive: isUpActive,
          activeColor: Colors.blue,
          onTap: () => _onVote('UP'),
        ),
        const SizedBox(width: 32),
        // Downvote button
        _VoteButton(
          icon: isDownActive ? Icons.thumb_down : Icons.thumb_down_outlined,
          count: persona.downvotes,
          isActive: isDownActive,
          activeColor: Colors.red,
          onTap: () => _onVote('DOWN'),
        ),
      ],
    );
  }

  Future<void> _onVote(String type) async {
    final success = await context.read<PersonaProvider>().ratePersona(
          widget.personaId,
          type,
        );

    if (!mounted) return;

    if (!success) {
      final error = context.read<PersonaProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal memberikan rating'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isCreatingSession ? null : _onStartChat,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isCreatingSession
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Mulai Sesi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _onStartChat() async {
    setState(() => _isCreatingSession = true);

    final session = await context.read<SessionProvider>().createSession(
          widget.personaId,
        );

    if (!mounted) return;

    setState(() => _isCreatingSession = false);

    if (session != null) {
      context.push('/chat/${session.id}');
    } else {
      final error = context.read<SessionProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal membuat sesi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar shimmer
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            // Name shimmer
            Container(
              width: 150,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            // Vote buttons shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 32),
                Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Description shimmer
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            // Session count shimmer
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat detail persona',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context
                  .read<PersonaProvider>()
                  .fetchPersonaDetail(widget.personaId);
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
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

/// Widget tombol vote yang reusable.
class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
