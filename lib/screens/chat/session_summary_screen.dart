import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

/// SessionSummaryScreen — Menampilkan hasil analisis AI setelah sesi selesai.
///
/// Fitur:
/// - Score delta dengan color coding (hijau/merah/abu-abu)
/// - Perbandingan poin sebelum dan sesudah
/// - Ringkasan analisis AI dalam area scrollable
/// - Tombol "Kembali ke Beranda" → context.go('/main')
/// - PopScope mencegah back gesture kembali ke ChatScreen
class SessionSummaryScreen extends StatelessWidget {
  final int scoreDelta;
  final int newPoints;
  final String summary;

  const SessionSummaryScreen({
    super.key,
    required this.scoreDelta,
    required this.newPoints,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final previousPoints = newPoints - scoreDelta;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/main');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Ringkasan Sesi'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildScoreDeltaCard(context),
                        const SizedBox(height: 16),
                        _buildPointsComparisonSection(
                            context, previousPoints),
                        const SizedBox(height: 16),
                        _buildSummaryCard(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildBackButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreDeltaCard(BuildContext context) {
    final color = _getScoreDeltaColor();
    final prefix = _getScoreDeltaPrefix();

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
              '$prefix$scoreDelta',
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

  Widget _buildPointsComparisonSection(
      BuildContext context, int previousPoints) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPointColumn('Sebelum', previousPoints),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.arrow_forward,
                size: 28,
                color: Colors.grey,
              ),
            ),
            _buildPointColumn('Sesudah', newPoints),
          ],
        ),
      ),
    );
  }

  Widget _buildPointColumn(String label, int points) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$points',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'poin',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
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
            Text(
              summary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go('/main'),
        child: const Text('Kembali ke Beranda'),
      ),
    );
  }

  Color _getScoreDeltaColor() {
    if (scoreDelta > 0) return Colors.green;
    if (scoreDelta < 0) return Colors.red;
    return Colors.grey;
  }

  String _getScoreDeltaPrefix() {
    if (scoreDelta > 0) return '+';
    return '';
  }
}
