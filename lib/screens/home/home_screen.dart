import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/home_helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/persona_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/common/app_surfaces.dart';
import '../main/main_screen.dart';

/// Array tips kesehatan mental harian (Bahasa Indonesia).
const _dailyTips = [
  'Luangkan waktu 5 menit untuk bernapas dalam-dalam hari ini.',
  'Tuliskan 3 hal yang kamu syukuri hari ini.',
  'Jangan lupa minum air putih yang cukup ya!',
  'Istirahat sejenak dari layar bisa menyegarkan pikiran.',
  'Ceritakan perasaanmu pada seseorang yang kamu percaya.',
  'Gerakan tubuh ringan bisa meningkatkan mood-mu.',
  'Tidak apa-apa untuk tidak baik-baik saja hari ini.',
  'Tidur yang cukup adalah investasi untuk kesehatanmu.',
  'Batasi konsumsi berita negatif untuk menjaga pikiranmu.',
  'Apresiasi dirimu atas hal kecil yang sudah kamu capai.',
];

/// HomeScreen — Tab Beranda yang menampilkan dashboard.
///
/// Berisi: greeting, score card, session summary cards,
/// quick action "Mulai Cerita", dan daily tip.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingData = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
      _hasError = false;
    });

    final sessionProvider = context.read<SessionProvider>();
    final personaProvider = context.read<PersonaProvider>();

    // Fetch both in parallel
    await Future.wait([
      sessionProvider.fetchSessions(status: 'active'),
      sessionProvider.fetchSessions(status: 'completed'),
      personaProvider.fetchPersonas(page: 1, limit: 10),
    ]);

    if (!mounted) return;

    // Check for errors
    final sessionError = sessionProvider.errorMessage;
    final personaError = personaProvider.errorMessage;

    if (sessionError != null || personaError != null) {
      _hasError = true;
      final errorMsg = sessionError ?? personaError ?? 'Terjadi kesalahan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isLoadingData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final sessionProvider = context.watch<SessionProvider>();
    final personaProvider = context.watch<PersonaProvider>();

    final greeting = getGreeting(DateTime.now().hour, user?.name);
    final points = user?.points ?? 50;
    final scoreStatus = getScoreStatus(points);
    final tipIndex = getDailyTipIndex(DateTime.now(), _dailyTips.length);
    final dailyTip = _dailyTips[tipIndex];

    final activeCount = sessionProvider.activeSessions.length;
    final completedCount = sessionProvider.completedSessions.length;
    final personaCount = personaProvider.totalPersonas;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
              vertical: AppSpacing.md,
            ),
            children: [
              StaggeredFadeSlide(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Semoga harimu lebih tenang dari kemarin.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              StaggeredFadeSlide(
                index: 1,
                child: _isLoadingData
                    ? _buildScoreCardShimmer()
                    : _buildScoreCard(points, scoreStatus),
              ),
              const SizedBox(height: AppSpacing.lg),

              StaggeredFadeSlide(
                index: 2,
                child: _isLoadingData
                    ? _buildSummaryCardsShimmer()
                    : _buildSummaryCards(
                        activeCount,
                        completedCount,
                        personaCount,
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),

              StaggeredFadeSlide(index: 3, child: _buildQuickActionButton()),
              const SizedBox(height: AppSpacing.lg),

              StaggeredFadeSlide(index: 4, child: _buildDailyTipCard(dailyTip)),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(
    int points,
    ({String text, String colorCategory}) scoreStatus,
  ) {
    final color = _getScoreColor(scoreStatus.colorCategory);

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: points.clamp(0, 100) / 100),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 116,
                      height: 116,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: color.withValues(alpha: 0.18),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$points',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          '/100',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Skor Kesehatan Mental',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    GradientIconBubble(
                      icon: Icons.favorite,
                      color: color,
                      size: 38,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  scoreStatus.text,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCardShimmer() {
    return GlassPanel(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Shimmer.fromColors(
          baseColor: AppColors.surfaceContainerHigh,
          highlightColor: AppColors.surfaceContainerHighest,
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    int activeCount,
    int completedCount,
    int personaCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Sesi Aktif',
            count: _hasError && activeCount == 0 ? 0 : activeCount,
            icon: Icons.chat_bubble_outline,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _SummaryCard(
            label: 'Sesi Selesai',
            count: _hasError && completedCount == 0 ? 0 : completedCount,
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _SummaryCard(
            label: 'Persona',
            count: _hasError && personaCount == 0 ? 0 : personaCount,
            icon: Icons.people_outline,
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCardsShimmer() {
    return Row(
      children: [
        Expanded(child: _buildSingleSummaryShimmer()),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildSingleSummaryShimmer()),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildSingleSummaryShimmer()),
      ],
    );
  }

  Widget _buildSingleSummaryShimmer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Shimmer.fromColors(
          baseColor: AppColors.surfaceContainerHigh,
          highlightColor: AppColors.surfaceContainerHighest,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: 24,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 50,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusLg,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: () {
          context.findAncestorStateOfType<MainScreenState>()?.switchTab(2);
        },
        icon: const Icon(Icons.menu_book_rounded),
        label: const Text('Mulai Cerita'),
      ),
    );
  }

  Widget _buildDailyTipCard(String tip) {
    return GlassPanel(
      padding: AppSpacing.paddingCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.tertiary, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Hari Ini',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(tip, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(String colorCategory) {
    switch (colorCategory) {
      case 'red':
        return Colors.redAccent;
      case 'yellow':
        return Colors.amberAccent;
      case 'green':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

/// Widget kartu ringkasan (Sesi Aktif, Sesi Selesai, Persona Tersedia).
class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          GradientIconBubble(icon: icon, color: color, size: 44),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$count',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
