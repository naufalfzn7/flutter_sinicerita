import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/utils/session_detail_helpers.dart';
import '../../models/persona_model.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';

/// SessionDetailScreen — Menampilkan detail lengkap sesi yang sudah selesai.
///
/// Fitur:
/// - Score delta dengan color coding dan prefix tanda
/// - Ringkasan analisis AI dalam Card scrollable
/// - Metadata: nama persona, waktu mulai dan selesai (format Indonesia)
/// - Tombol "Lihat Riwayat Chat" → navigasi ke /chat/:sessionId
/// - Error handling: SnackBar merah + tombol "Coba Lagi" / "Kembali"
/// - Shimmer skeleton saat loading
class SessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SessionProvider>().fetchSessionDetail(widget.sessionId);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void deactivate() {
    context.read<SessionProvider>().clearDetailState();
    super.deactivate();
  }

  void _retryFetch() {
    setState(() {
      _hasShownError = false;
    });
    context.read<SessionProvider>().fetchSessionDetail(widget.sessionId);
  }

  /// Determine if error is a 404/403 (access/not-found) error.
  bool _isAccessError(String errorMessage) {
    return errorMessage.contains('tidak ditemukan') ||
        errorMessage.contains('Akses ditolak') ||
        errorMessage.contains('Data tidak ditemukan');
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final isLoading = sessionProvider.isLoadingDetail;
    final session = sessionProvider.sessionDetail;
    final persona = sessionProvider.detailPersona;
    final errorMessage = sessionProvider.errorMessage;

    // Show error SnackBar once
    if (errorMessage != null && !_hasShownError) {
      _hasShownError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }

    // Reset error shown flag when loading starts again
    if (isLoading) {
      _hasShownError = false;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detail Sesi'),
      ),
      body: _buildBody(isLoading, session, persona, errorMessage),
    );
  }

  Widget _buildBody(
    bool isLoading,
    SessionModel? session,
    PersonaModel? persona,
    String? errorMessage,
  ) {
    if (isLoading) {
      return _buildShimmerSkeleton();
    }

    if (errorMessage != null && session == null) {
      return _buildErrorState(errorMessage);
    }

    if (session == null) {
      return const SizedBox.shrink();
    }

    return _buildContent(session, persona);
  }

  Widget _buildContent(SessionModel session, PersonaModel? persona) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Score Delta Section
                  if (session.scoreDelta != null)
                    _buildScoreDeltaSection(session.scoreDelta!),

                  // Analisis AI Card
                  if (session.scoreDelta != null) const SizedBox(height: 16),
                  _buildAnalysisCard(session.analysisSummary),

                  const SizedBox(height: 16),

                  // Metadata Section
                  _buildMetadataSection(session, persona),
                ],
              ),
            ),
          ),

          // "Lihat Riwayat Chat" button — always visible without scroll
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/chat/${widget.sessionId}'),
                child: const Text('Lihat Riwayat Chat'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDeltaSection(int scoreDelta) {
    final color = getScoreDeltaColor(scoreDelta);
    final formatted = formatScoreDelta(scoreDelta);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'Perubahan Skor',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatted,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(String? analysisSummary) {
    final isEmpty = isAnalysisSummaryEmpty(analysisSummary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analisis AI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  isEmpty ? 'Analisis tidak tersedia' : analysisSummary!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isEmpty ? Colors.grey : null,
                    fontStyle: isEmpty ? FontStyle.italic : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(SessionModel session, PersonaModel? persona) {
    final personaName = persona?.name ?? 'Persona tidak diketahui';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Sesi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetadataRow(Icons.person, 'Persona', personaName),
            const SizedBox(height: 8),
            if (session.startedAt != null)
              _buildMetadataRow(
                Icons.play_arrow,
                'Dimulai',
                formatDateTimeIndonesian(session.startedAt!),
              ),
            if (session.startedAt != null) const SizedBox(height: 8),
            if (session.completedAt != null)
              _buildMetadataRow(
                Icons.check_circle,
                'Selesai',
                formatDateTimeIndonesian(session.completedAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String errorMessage) {
    final isAccessError = _isAccessError(errorMessage);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAccessError ? Icons.block : Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isAccessError)
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Kembali'),
              )
            else
              ElevatedButton(
                onPressed: _retryFetch,
                child: const Text('Coba Lagi'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score delta skeleton
            Card(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Analysis card skeleton
            Card(
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Metadata skeleton
            Card(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
