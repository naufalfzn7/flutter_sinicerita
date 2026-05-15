import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';

/// Dialog konfirmasi deaktivasi persona.
///
/// Menampilkan nama persona dan pesan konfirmasi.
/// Saat proses delete berlangsung:
/// - Tampilkan CircularProgressIndicator
/// - Disable tombol "Batal" dan "Nonaktifkan"
///
/// Returns:
/// - `true` jika berhasil deactivate
/// - `String` (error message) jika gagal
/// - `null` jika user cancel
class DeactivatePersonaDialog extends StatefulWidget {
  /// ID persona yang akan di-deactivate.
  final String personaId;

  /// Nama persona untuk ditampilkan di dialog.
  final String personaName;

  const DeactivatePersonaDialog({
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
      builder: (_) => DeactivatePersonaDialog(
        personaId: personaId,
        personaName: personaName,
      ),
    );
  }

  @override
  State<DeactivatePersonaDialog> createState() =>
      _DeactivatePersonaDialogState();
}

class _DeactivatePersonaDialogState extends State<DeactivatePersonaDialog> {
  bool _isDeleting = false;

  Future<void> _onConfirm() async {
    setState(() {
      _isDeleting = true;
    });

    final success =
        await context.read<AdminProvider>().deletePersona(widget.personaId);

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
      title: const Text('Nonaktifkan Persona'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apakah Anda yakin ingin menonaktifkan persona ini?',
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
          child: const Text('Nonaktifkan'),
        ),
      ],
    );
  }
}
