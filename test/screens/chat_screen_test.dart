import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:sinicerita/models/completion_result.dart';
import 'package:sinicerita/models/message_model.dart';
import 'package:sinicerita/models/persona_model.dart';
import 'package:sinicerita/models/session_model.dart';
import 'package:sinicerita/providers/auth_provider.dart';
import 'package:sinicerita/providers/session_provider.dart';
import 'package:sinicerita/screens/chat/chat_screen.dart';
import 'package:sinicerita/widgets/chat/chat_bubble.dart';
import 'package:sinicerita/widgets/chat/typing_indicator.dart';

// ─── Mock SessionProvider ─────────────────────────────────────────────────────

/// A fake SessionProvider that exposes configurable state for widget testing.
/// Does NOT make real API calls — all state is set directly.
class MockSessionProvider extends ChangeNotifier implements SessionProvider {
  // Configurable state
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isSendingMessage = false;
  String? _errorMessage;

  // ─── Getters (from SessionProvider interface) ─────────────────────────────

  @override
  List<MessageModel> get messages => List.unmodifiable(_messages);

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isTyping => _isTyping;

  @override
  bool get isSendingMessage => _isSendingMessage;

  @override
  String? get errorMessage => _errorMessage;

  @override
  String? get currentChatSessionId => 'test-session-id';

  @override
  List<SessionModel> get activeSessions => [
        SessionModel(
          id: 'test-session-id',
          personaId: 'persona-1',
          status: 'active',
          createdAt: DateTime(2024, 1, 15),
        ),
      ];

  @override
  List<SessionModel> get completedSessions => [];

  @override
  bool get hasMoreActive => false;

  @override
  bool get hasMoreCompleted => false;

  @override
  bool get isCompleting => false;

  @override
  SessionModel? get sessionDetail => null;

  @override
  PersonaModel? get detailPersona => null;

  @override
  bool get isLoadingDetail => false;

  // ─── Setters for test configuration ───────────────────────────────────────

  set messages(List<MessageModel> value) {
    _messages = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set isTyping(bool value) {
    _isTyping = value;
    notifyListeners();
  }

  set isSendingMessage(bool value) {
    _isSendingMessage = value;
    notifyListeners();
  }

  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  // ─── Stub methods ─────────────────────────────────────────────────────────

  @override
  Future<void> fetchMessages(String sessionId) async {
    // No-op for widget tests — state is set directly
  }

  @override
  Future<String?> sendMessage(String sessionId, String content) async {
    return null; // success by default
  }

  @override
  Future<SessionModel?> createSession(String personaId) async {
    return null;
  }

  @override
  Future<void> fetchSessions({
    required String status,
    int page = 1,
    int limit = 10,
  }) async {}

  @override
  Future<bool> deleteSession(String sessionId) async => true;

  @override
  Future<CompletionResult?> completeSession(
    String sessionId,
    AuthProvider authProvider,
  ) async {
    return null;
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void clearChatState() {
    _messages = [];
    _isTyping = false;
    _isSendingMessage = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<void> fetchSessionDetail(String sessionId) async {
    // No-op for widget tests
  }

  @override
  void clearDetailState() {
    // No-op for widget tests
  }
}

// ─── Test Helpers ─────────────────────────────────────────────────────────────

/// Wraps ChatScreen with MaterialApp and Provider override for testing.
Widget buildTestWidget(MockSessionProvider mockProvider) {
  return ChangeNotifierProvider<SessionProvider>.value(
    value: mockProvider,
    child: const MaterialApp(
      home: ChatScreen(sessionId: 'test-session-id'),
    ),
  );
}

/// Creates a sample user message.
MessageModel createUserMessage({
  String content = 'Hello from user',
  DateTime? createdAt,
}) {
  return MessageModel(
    id: 'msg-user-1',
    sessionId: 'test-session-id',
    role: 'user',
    content: content,
    createdAt: createdAt ?? DateTime(2024, 1, 15, 10, 30),
  );
}

/// Creates a sample model (AI) message.
MessageModel createModelMessage({
  String content = 'Hello from AI',
  DateTime? createdAt,
}) {
  return MessageModel(
    id: 'msg-model-1',
    sessionId: 'test-session-id',
    role: 'model',
    content: content,
    createdAt: createdAt ?? DateTime(2024, 1, 15, 10, 31),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockSessionProvider mockProvider;

  setUp(() {
    mockProvider = MockSessionProvider();
  });

  group('ChatScreen Widget Tests', () {
    testWidgets('Shows Shimmer when isLoading=true', (tester) async {
      mockProvider._isLoading = true;

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // Shimmer widget should be present
      expect(find.byType(Shimmer), findsOneWidget);
      // Message list and empty state should NOT be visible
      expect(find.byType(ChatBubble), findsNothing);
      expect(find.text('Belum ada pesan. Mulai percakapan!'), findsNothing);
    });

    testWidgets('Shows empty state when messages=[] and isLoading=false',
        (tester) async {
      mockProvider._isLoading = false;
      mockProvider._messages = [];

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // Empty state text should be visible
      expect(
        find.text('Belum ada pesan. Mulai percakapan!'),
        findsOneWidget,
      );
      // Shimmer should NOT be visible
      expect(find.byType(Shimmer), findsNothing);
    });

    testWidgets('Shows ChatBubble aligned right for user messages',
        (tester) async {
      mockProvider._isLoading = false;
      mockProvider._messages = [createUserMessage()];

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // ChatBubble should be present
      expect(find.byType(ChatBubble), findsOneWidget);

      // Find the Row inside ChatBubble and verify alignment
      final chatBubble =
          tester.widget<ChatBubble>(find.byType(ChatBubble).first);
      expect(chatBubble.isUser, isTrue);

      // Verify the Row has MainAxisAlignment.end (right-aligned)
      final row = tester.widget<Row>(
        find.descendant(
          of: find.byType(ChatBubble),
          matching: find.byType(Row),
        ),
      );
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('Shows ChatBubble aligned left for model messages',
        (tester) async {
      mockProvider._isLoading = false;
      mockProvider._messages = [createModelMessage()];

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // ChatBubble should be present
      expect(find.byType(ChatBubble), findsOneWidget);

      // Find the ChatBubble and verify it's for model
      final chatBubble =
          tester.widget<ChatBubble>(find.byType(ChatBubble).first);
      expect(chatBubble.isUser, isFalse);

      // Verify the Row has MainAxisAlignment.start (left-aligned)
      final row = tester.widget<Row>(
        find.descendant(
          of: find.byType(ChatBubble),
          matching: find.byType(Row),
        ),
      );
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
    });

    testWidgets('Send button is disabled when TextField is empty',
        (tester) async {
      mockProvider._isLoading = false;
      mockProvider._messages = [];

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // Find the send IconButton
      final sendButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send),
      );

      // onPressed should be null (disabled)
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('Send button is disabled when isSendingMessage=true',
        (tester) async {
      mockProvider._isLoading = false;
      mockProvider._messages = [];
      mockProvider._isSendingMessage = true;

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // Enter text so the button would normally be enabled
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      // Send button should still be disabled because isSendingMessage=true
      final sendButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send),
      );
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('Shows TypingIndicator when isTyping=true', (tester) async {
      mockProvider._isLoading = false;
      mockProvider._messages = [createUserMessage()];
      mockProvider._isTyping = true;

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // TypingIndicator should be present
      expect(find.byType(TypingIndicator), findsOneWidget);
    });

    testWidgets('Shows red SnackBar when errorMessage is set',
        (tester) async {
      mockProvider._isLoading = false;
      mockProvider._messages = [];

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // Set error message to trigger SnackBar
      mockProvider.errorMessage = 'Sesi sudah selesai';
      await tester.pump(); // Trigger rebuild
      await tester.pump(); // Allow post-frame callback to fire

      // SnackBar should be visible with error text
      expect(find.text('Sesi sudah selesai'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // Verify SnackBar has red background
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.red);
    });

    testWidgets(
        'Send button is disabled when input exceeds 5000 chars after trim',
        (tester) async {
      mockProvider._isLoading = false;
      mockProvider._messages = [];

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // First enter valid text to set _canSend = true
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      // Now enter text exceeding 5000 characters — this triggers setState
      // because _canSend changes from true to false
      final longText = 'a' * 5001;
      await tester.enterText(find.byType(TextField), longText);
      await tester.pump();

      // Send button should be disabled
      final sendButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send),
      );
      expect(sendButton.onPressed, isNull);

      // Over-limit indicator text should be visible
      expect(
        find.text('Pesan melebihi batas 5000 karakter'),
        findsOneWidget,
      );
    });

    testWidgets('Send button is enabled when valid text is entered',
        (tester) async {
      mockProvider._isLoading = false;
      mockProvider._messages = [];

      await tester.pumpWidget(buildTestWidget(mockProvider));
      await tester.pump();

      // Enter valid text
      await tester.enterText(find.byType(TextField), 'Hello AI');
      await tester.pump();

      // Send button should be enabled
      final sendButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send),
      );
      expect(sendButton.onPressed, isNotNull);
    });
  });
}
