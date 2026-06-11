import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/persona_model.dart';
import '../common/app_surfaces.dart';

/// Reusable card widget untuk menampilkan persona dalam grid layout.
///
/// Menampilkan:
/// - Avatar (CachedNetworkImage dalam ClipOval 56x56, placeholder jika null)
/// - Nama (bold, centered, max 1 line, ellipsis)
/// - Deskripsi (max 2 lines, ellipsis, smaller grey text)
/// - Vote counts (thumb_up + count, thumb_down + count, tanpa button)
/// - Card dengan rounded corners dan elevation
/// - Tap seluruh card triggers [onTap] callback
class PersonaGridCard extends StatelessWidget {
  final PersonaModel persona;
  final VoidCallback onTap;

  const PersonaGridCard({
    super.key,
    required this.persona,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.95),
                    AppColors.lavender.withValues(alpha: 0.75),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: persona.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: persona.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _avatarPlaceholder(),
                          errorWidget: (context, url, error) =>
                              _avatarPlaceholder(),
                        )
                      : _avatarPlaceholder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            persona.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),

          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                persona.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              const Icon(
                Icons.thumb_up_outlined,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${persona.upvotes}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.thumb_down_outlined,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${persona.downvotes}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: AppColors.surfaceContainerHighest,
      child: const Icon(
        Icons.person,
        size: 32,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
