import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:sinicerita/core/theme/app_theme.dart';
import 'package:sinicerita/providers/auth_provider.dart';
import 'package:sinicerita/screens/auth/welcome_screen.dart';

// ─── Manual Mock: AuthProvider ─────────────────────────────────────────────

/// Minimal mock AuthProvider that tracks calls without needing ApiClient.
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _firstLaunchCompleted = false;
  bool completeFirstLaunchCalled = false;

  @override
  bool get firstLaunchCompleted => _firstLaunchCompleted;

  @override
  Future<void> completeFirstLaunch() async {
    completeFirstLaunchCalled = true;
    _firstLaunchCompleted = true;
    notifyListeners();
  }

  // ─── Unused AuthProvider members (satisfy interface) ───────────────────

  @override
  AuthStatus get status => AuthStatus.unauthenticated;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Test Helpers ──────────────────────────────────────────────────────────

/// Minimal valid SVG content for asset loading in tests.
const _minimalSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"></svg>';

/// Creates a test widget wrapped with required providers and router.
Widget _createTestWidget({
  required MockAuthProvider authProvider,
  required GoRouter router,
}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp.router(
      theme: AppTheme.dark,
      routerConfig: router,
    ),
  );
}

/// Creates a GoRouter that shows WelcomeScreen at initial location.
GoRouter _createTestRouter({
  required MockAuthProvider authProvider,
  List<String> navigatedTo = const [],
}) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          navigatedTo.add('/login');
          return const Scaffold(body: Text('Login Screen'));
        },
      ),
    ],
  );
}

void main() {
  // Set up fake asset bundle for SVG loading
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Provide a fake SVG asset for SvgPicture.asset
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key.contains('logo-with-text.svg')) {
          return Uint8List.fromList(utf8.encode(_minimalSvg)).buffer.asByteData();
        }
        return null;
      },
    );
  });

  tearDown(() {
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
  });

  group('WelcomeScreen', () {
    testWidgets('renders logo SVG image widget', (tester) async {
      final authProvider = MockAuthProvider();
      final router = _createTestRouter(authProvider: authProvider);

      await tester.pumpWidget(_createTestWidget(
        authProvider: authProvider,
        router: router,
      ));
      await tester.pumpAndSettle();

      // SvgPicture.asset renders an SvgPicture widget
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('renders tagline text containing "SiniCerita"', (tester) async {
      final authProvider = MockAuthProvider();
      final router = _createTestRouter(authProvider: authProvider);

      await tester.pumpWidget(_createTestWidget(
        authProvider: authProvider,
        router: router,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('SiniCerita'), findsOneWidget);
    });

    testWidgets('renders "Mulai" button', (tester) async {
      final authProvider = MockAuthProvider();
      final router = _createTestRouter(authProvider: authProvider);

      await tester.pumpWidget(_createTestWidget(
        authProvider: authProvider,
        router: router,
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Mulai'), findsOneWidget);
    });

    testWidgets(
      'tapping "Mulai" calls completeFirstLaunch() and navigates to /login',
      (tester) async {
        final authProvider = MockAuthProvider();
        final navigatedTo = <String>[];
        final router = _createTestRouter(
          authProvider: authProvider,
          navigatedTo: navigatedTo,
        );

        await tester.pumpWidget(_createTestWidget(
          authProvider: authProvider,
          router: router,
        ));
        await tester.pumpAndSettle();

        // Tap the "Mulai" button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Mulai'));
        await tester.pumpAndSettle();

        // Verify completeFirstLaunch was called
        expect(authProvider.completeFirstLaunchCalled, isTrue);

        // Verify navigation to /login occurred
        expect(navigatedTo, contains('/login'));
      },
    );

    testWidgets('uses dark theme (Brightness.dark)', (tester) async {
      final authProvider = MockAuthProvider();
      final router = _createTestRouter(authProvider: authProvider);

      await tester.pumpWidget(_createTestWidget(
        authProvider: authProvider,
        router: router,
      ));
      await tester.pumpAndSettle();

      // Get the MaterialApp's theme and verify it's dark
      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );
      expect(materialApp.theme?.brightness, Brightness.dark);
    });
  });
}
