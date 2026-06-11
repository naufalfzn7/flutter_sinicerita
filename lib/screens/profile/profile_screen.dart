import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/home_helpers.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_surfaces.dart';

/// ProfileScreen — Tab Profil yang menampilkan informasi user,
/// circular progress indicator untuk poin, dan menu navigasi.
///
/// Membaca data user dari AuthProvider.currentUser.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _dateFormattingInitialized = false;

  @override
  void initState() {
    super.initState();
    _initDateFormatting();
  }

  Future<void> _initDateFormatting() async {
    await initializeDateFormatting('id');
    if (mounted) {
      setState(() {
        _dateFormattingInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Profil'), centerTitle: true),
      body: user == null || !_dateFormattingInitialized
          ? _buildShimmer()
          : _buildContent(context, user),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          StaggeredFadeSlide(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: AppSpacing.borderRadiusXl,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.24),
                    AppColors.primaryContainer.withValues(alpha: 0.34),
                    AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                  ],
                ),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                children: [
                  _buildAvatar(user.avatarUrl),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          StaggeredFadeSlide(index: 1, child: _buildPointsCard(user.points)),
          const SizedBox(height: 16),
          StaggeredFadeSlide(index: 2, child: _buildJoinDate(user.createdAt)),
          const SizedBox(height: 32),
          StaggeredFadeSlide(index: 3, child: _buildMenuItems(context)),
          const SizedBox(height: 112),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: 92,
          height: 92,
          child: avatarUrl != null
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, url) => _avatarFallback(),
                  errorWidget: (_, url, error) => _avatarFallback(),
                )
              : _avatarFallback(),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppColors.surfaceContainerHighest,
      child: const Icon(
        Icons.person,
        size: 42,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPointsCard(int points) {
    final scoreStatus = getScoreStatus(points);
    final color = _getColor(scoreStatus.colorCategory);
    final progress = points.clamp(0, 100) / 100;

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CustomPaint(
                painter: _CircularProgressPainter(
                  progress: value,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.18),
                ),
                child: Center(
                  child: Text(
                    '${points.clamp(0, 100)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skor Kesehatan Mental',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  scoreStatus.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinDate(DateTime createdAt) {
    final formattedDate = DateFormat('dd MMMM yyyy', 'id').format(createdAt);
    return GlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 16,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Bergabung $formattedDate',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.edit,
            title: 'Edit Profil',
            onTap: () => context.push('/edit-profile'),
          ),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Ubah Password',
            onTap: () => context.push('/change-password'),
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Keluar',
            onTap: () => _showLogoutDialog(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.coral : AppColors.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.coral : AppColors.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isLoggingOut = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah kamu yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: isLoggingOut
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: isLoggingOut
                    ? null
                    : () async {
                        setDialogState(() {
                          isLoggingOut = true;
                        });
                        // AuthProvider.logout() always clears tokens and sets
                        // status to unauthenticated, even on network error.
                        // GoRouter redirect will handle navigation to login.
                        await this.context.read<AuthProvider>().logout();
                      },
                child: isLoggingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Text('Keluar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[600]!,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar shimmer
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            // Name shimmer
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Email shimmer
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            // Points card shimmer
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            // Join date shimmer
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 32),
            // Menu items shimmer
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(String colorCategory) {
    switch (colorCategory) {
      case 'red':
        return AppColors.coral;
      case 'yellow':
        return AppColors.tertiary;
      case 'green':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

/// Custom painter untuk circular progress indicator (reused pattern from ScoreCardWidget).
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 10.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
