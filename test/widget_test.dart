import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sinicerita/core/api/api_client.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';
import 'package:sinicerita/main.dart';
import 'package:sinicerita/providers/admin_provider.dart';
import 'package:sinicerita/providers/auth_provider.dart';
import 'package:sinicerita/providers/persona_provider.dart';
import 'package:sinicerita/providers/session_provider.dart';

void main() {
  testWidgets('App starts on splash screen', (WidgetTester tester) async {
    final secureStorage = SecureStorage();
    final apiClient = ApiClient(storage: secureStorage);
    final authProvider = AuthProvider(apiClient: apiClient);
    final sessionProvider = SessionProvider(apiClient: apiClient);
    final personaProvider = PersonaProvider(apiClient: apiClient);
    final adminProvider = AdminProvider(apiClient: apiClient);

    await tester.pumpWidget(MyApp(
      authProvider: authProvider,
      sessionProvider: sessionProvider,
      personaProvider: personaProvider,
      adminProvider: adminProvider,
    ));

    // Splash screen shows a CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
