import 'package:flutter/material.dart';

import '../../core/utils/home_helpers.dart';
import '../../models/session_model.dart';

/// Reusable tile widget untuk menampilkan item sesi chat di list.
///
/// Menampilkan:
/// - Leading: CircleAvatar dengan huruf pertama nama persona
/// - Title row: nama persona (kiri) + waktu relatif (kanan)
/// - Subtitle row: preview pesan (kiri, truncated 50 chars) + status badge + scoreDelta
///
/// Status badge: "Aktif" (hijau) atau "Selesai" (biru).
/// ScoreDelta: "+5" (hijau) atau "-3" (merah) — hanya ditampilkan jika
/// [showScoreDelta] true dan session.scoreDelta tidak null.
class SessionListTile extends StatelessWidget {
  final SessionModel session;
  final String personaName;
  final bool showScoreDelta;
  final VoidCallback onTap;

  const SessionListTile({
    super.key,
    required this.session,
    required this.personaName,
    required this.showScoreDelta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final relativeTime = formatRelativeTime(session.lastActivityAt, now);
    final preview = _getPreview();
    final isCompleted = session.status == 'completed';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          personaName.isNotEmpty ? personaName[0].toUpperCase() : 'P',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              personaName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            relativeTime,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildBadge(context),
          if (showScoreDelta && session.scoreDelta != null) ...[
            const SizedBox(width: 6),
            _buildScoreDelta(),
          ],
        ],
      ),
      trailing: isCompleted
          ? const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            )
          : null,
    );
  }

  /// Mendapatkan preview text untuk subtitle.
  ///
  /// Menggunakan analysisSummary jika tersedia (untuk completed sessions),
  /// atau placeholder text untuk active sessions.
  /// Truncate ke maksimal 50 karakter.
  String _getPreview() {
    final text = session.analysisSummary ?? '';
    if (text.trim().isEmpty) {
      return session.status == 'active'
          ? 'Ketuk untuk melanjutkan...'
          : 'Analisis tidak tersedia';
    }
    return text.length > 50 ? '${text.substring(0, 50)}...' : text;
  }

  /// Badge status: "Aktif" (hijau) atau "Selesai" (biru).
  Widget _buildBadge(BuildContext context) {
    final isActive = session.status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Selesai',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.green : Colors.blue,
        ),
      ),
    );
  }

  /// ScoreDelta display: "+5" (hijau) atau "-3" (merah).
  Widget _buildScoreDelta() {
    final delta = session.scoreDelta!;
    final isPositive = delta >= 0;
    final text = isPositive ? '+$delta' : '$delta';
    final color = isPositive ? Colors.green : Colors.red;

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
