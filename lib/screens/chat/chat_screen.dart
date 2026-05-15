import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';

/// ChatScreen — Halaman utama percakapan dengan persona AI.
///
/// Fitur:
/// - Fetch riwayat pesan saat mount (via SessionProvider.fetchMessages)
/// - ListView reverse:true untuk menampilkan pesan terbaru di bawah
/// - Auto-scroll ke pesan terbaru saat pesan baru ditambahkan
/// - Shimmer skeleton saat loading
/// - Empty state saat messages kosong
/// - ChatBubble untuk setiap message
/// - TypingIndicator saat isTyping true
class ChatScreen extends StatefulWidget {
  final String sessionId;

  const ChatScreen({super.key, required this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  int _previousMessageCount = 0;
  bool _canSend = false;
  bool _isOverLimit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SessionProvider>().fetchMessages(widget.sessionId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onInputChanged(String value) {
    final trimmed = value.trim();
    final canSend = trimmed.isNotEmpty && trimmed.length <= 5000;
    final overLimit = trimmed.length > 5000;
    if (canSend != _canSend || overLimit != _isOverLimit) {
      setState(() {
        _canSend = canSend;
        _isOverLimit = overLimit;
      });
    }
  }

  Future<void> _onSendPressed() async {
    final trimmedContent = _textController.text.trim();
    if (trimmedContent.isEmpty || trimmedContent.length > 5000) return;

    // Clear text field immediately
    _textController.clear();
    setState(() {
      _canSend = false;
    });

    // Call sendMessage — returns content string if failed, null if success
    final failedContent = await context
        .read<SessionProvider>()
        .sendMessage(widget.sessionId, trimmedContent);

    if (!mounted) return;

    // Restore content if sendMessage failed
    if (failedContent != null) {
      _textController.text = failedContent;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: failedContent.length),
      );
      setState(() {
        final trimmed = failedContent.trim();
        _canSend = trimmed.isNotEmpty && trimmed.length <= 5000;
        _isOverLimit = trimmed.length > 5000;
      });
    }
  }

  void _showEndSessionDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Akhiri Sesi?'),
          content: const Text(
            'Sesi akan dianalisis oleh AI untuk menentukan perubahan skor kesehatan mental Anda.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _onCompleteConfirmed();
              },
              child: const Text('Ya, Akhiri'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onCompleteConfirmed() async {
    final result = await context.read<SessionProvider>().completeSession(
          widget.sessionId,
          context.read<AuthProvider>(),
        );
    if (!mounted) return;

    if (result != null) {
      // Success → navigate to summary
      context.go('/session-summary', extra: {
        'scoreDelta': result.scoreDelta,
        'newPoints': result.newPoints,
        'summary': result.summary,
      });
    } else {
      // Error → show red SnackBar
      final error = context.read<SessionProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      // 409 or 403 → navigate home after 2s delay
      if (error == 'Sesi sudah selesai' ||
          error == 'Akses ditolak: sesi bukan milik Anda') {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/main');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final messages = sessionProvider.messages;
    final isLoading = sessionProvider.isLoading;
    final isTyping = sessionProvider.isTyping;
    final isSendingMessage = sessionProvider.isSendingMessage;
    final isCompleting = sessionProvider.isCompleting;

    // Auto-scroll saat pesan baru ditambahkan
    if (messages.length > _previousMessageCount && _previousMessageCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    _previousMessageCount = messages.length;

    // Show error via SnackBar
    _showErrorIfNeeded(sessionProvider);

    // Use tracked over-limit state
    final isOverLimit = _isOverLimit;

    // Check if session is active (show "Akhiri Sesi" button only for active sessions)
    final isSessionActive = sessionProvider.activeSessions
        .any((s) => s.id == widget.sessionId);

    // Session is completed if NOT in activeSessions and messages loaded successfully
    final isSessionCompleted = !isSessionActive && !isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Chat'),
        actions: [
          if (isSessionActive)
            TextButton(
              onPressed: isCompleting ? null : () => _showEndSessionDialog(),
              child: const Text('Akhiri Sesi'),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? _buildShimmerSkeleton()
                    : messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(messages, isTyping),
              ),
              if (isSessionCompleted)
                _buildReadOnlyBanner()
              else
                _buildInputArea(isSendingMessage, isOverLimit, isCompleting),
            ],
          ),
          if (isCompleting) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isSendingMessage, bool isOverLimit, bool isCompleting) {
    final sendEnabled = _canSend && !isSendingMessage && !isCompleting;
    final inputEnabled = !isCompleting;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOverLimit)
              const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  'Pesan melebihi batas 5000 karakter',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onChanged: _onInputChanged,
                    enabled: inputEnabled,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: sendEnabled ? _onSendPressed : null,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        border: Border(
          top: BorderSide(
            color: Colors.blueGrey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Text(
          'Sesi ini telah selesai. Chat hanya bisa dibaca.',
          style: TextStyle(
            color: Colors.blueGrey[700],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(
    List messages,
    bool isTyping,
  ) {
    // Total item count: messages + typing indicator (if active)
    final itemCount = messages.length + (isTyping ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Karena reverse:true, index 0 = item paling bawah
        if (isTyping && index == 0) {
          return const TypingIndicator();
        }

        // Adjust index jika ada typing indicator
        final messageIndex =
            messages.length - 1 - (isTyping ? index - 1 : index);

        if (messageIndex < 0 || messageIndex >= messages.length) {
          return const SizedBox.shrink();
        }

        final message = messages[messageIndex];
        return ChatBubble(
          message: message,
          isUser: message.isUser,
        );
      },
    );
  }

  Widget _buildShimmerSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fake AI bubble (kiri)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 220,
                height: 48,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Fake user bubble (kanan)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 180,
                height: 40,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Fake AI bubble (kiri)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 260,
                height: 64,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Fake user bubble (kanan)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 150,
                height: 40,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Fake AI bubble (kiri)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 200,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Belum ada pesan. Mulai percakapan!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showErrorIfNeeded(SessionProvider provider) {
    final error = provider.errorMessage;
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
        provider.clearError();

        // Navigate back jika error "Sesi tidak ditemukan" atau "Akses ditolak"
        if (error.contains('Sesi tidak ditemukan') ||
            error.contains('Akses ditolak')) {
          context.pop();
        }
      });
    }
  }
}
