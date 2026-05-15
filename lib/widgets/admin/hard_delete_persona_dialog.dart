import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';

/// Dialog konfirmasi hapus permanen persona.
///
/// Menampilkan nama persona dan pesan konfirmasi ireversibel.
/// Saat proses hard delete berlangsung:
/// - Tampilkan CircularProgressIndicator
/// - Disable tombol "Batal" dan "Hapus Permanen"
///
/// Returns:
/// - `true` jika berhasil hard delete
/// - `String` (error message) jika gagal
/// - `null` jika user cancel
class HardDeletePersonaDialog extends StatefulWidget {
  /// ID persona yang akan di-hard delete.
  final String personaId;

  /// Nama persona untuk ditampilkan di dialog.
  final String personaName;

  const HardDeletePersonaDialog({
    super.key,
    required this.personaId,
    required this.personaName,
  });

  static Future<Object?> show(
    BuildContext context, {
    required String personaId,
    required String personaName,
  }) {
    return showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HardDeletePersonaDialog(
        personaId: personaId,
        personaName: personaName,
      ),
    );
  }

  @override
  State<HardDeletePersonaDialog> createState() =>
      _HardDeletePersonaDialogState();
}

class _HardDeletePersonaDialogState extends State<HardDeletePersonaDialog> {
  bool _isDeleting = false;

  Future<void> _onConfirm() async {
    setState(() {
      _isDeleting = true;
    });

    final success =
        await context.read<AdminProvider>().hardDeletePersona(widget.personaId);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      // Get error message from provider
      final errorMessage =
          context.read<AdminProvider>().errorMessage ?? 'Terjadi kesalahan';
      Navigator.of(context).pop(errorMessage);
    }
  }

  void _onCancel() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Hapus Permanen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apakah Anda yakin ingin menghapus permanen persona ini? '
            'Tindakan ini tidak dapat dibatalkan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '"${widget.personaName}"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (_isDeleting) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : _onCancel,
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
          child: const Text('Hapus Permanen'),
        ),
      ],
    );
  }
}
