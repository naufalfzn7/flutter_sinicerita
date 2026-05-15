import 'package:flutter/material.dart';

/// Placeholder — will be fully implemented in a later tahap (chat room)
class ChatScreen extends StatelessWidget {
  final String sessionId;

  const ChatScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Center(child: Text('Chat Session: $sessionId\nComing soon')),
    );
  }
}
