import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/home_helpers.dart';
import '../../models/session_model.dart';
import '../common/app_surfaces.dart';

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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassPanel(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            GradientIconBubble(
              icon: isCompleted ? Icons.check_rounded : Icons.chat_rounded,
              color: isCompleted ? AppColors.success : AppColors.primary,
              size: 50,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          personaName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        relativeTime,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildBadge(context),
                      if (showScoreDelta && session.scoreDelta != null) ...[
                        const SizedBox(width: 6),
                        _buildScoreDelta(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Mendapatkan preview text untuk subtitle.
  ///
  /// Menggunakan analysisSummary jika tersedia (untuk completed sessions),
  /// atau placeholder text.
  /// Truncate ke maksimal 50 karakter.
  String _getPreview() {
    final text = session.analysisSummary ?? '';
    if (text.trim().isEmpty) {
      return session.status == 'active'
          ? 'Ketuk untuk melanjutkan...'
          : 'Ketuk untuk melihat detail';
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
            ? AppColors.success.withValues(alpha: 0.14)
            : AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Selesai',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isActive ? AppColors.success : AppColors.primary,
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
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
    );
  }
}
