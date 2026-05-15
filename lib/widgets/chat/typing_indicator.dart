import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Widget animasi tiga titik berkedip yang menunjukkan AI sedang memproses respons.
///
/// Ditampilkan di sisi kiri (sama seperti pesan AI) dengan bubble style
/// serupa ChatBubble untuk pesan model.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 48, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return _buildDot(index);
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    // Staggered delay: each dot starts animating slightly after the previous
    final delay = index * 0.2;
    final animationValue = _controller.value;

    // Calculate opacity with staggered offset
    final adjustedValue = (animationValue - delay) % 1.0;
    final opacity = _calculateOpacity(adjustedValue);
    final scale = _calculateScale(adjustedValue);

    return Container(
      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  /// Menghitung opacity berdasarkan posisi animasi.
  /// Menggunakan sine wave untuk efek berkedip yang halus.
  double _calculateOpacity(double value) {
    // Sine wave: 0.4 → 1.0 → 0.4
    return 0.4 + 0.6 * math.sin(value * math.pi);
  }

  /// Menghitung scale berdasarkan posisi animasi.
  /// Dot sedikit membesar saat opacity tinggi.
  double _calculateScale(double value) {
    // Scale: 0.8 → 1.0 → 0.8
    return 0.8 + 0.2 * math.sin(value * math.pi);
  }
}
