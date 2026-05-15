import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/routing/redirect_logic.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/persona_provider.dart';
import 'providers/session_provider.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/session_summary_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/persona/persona_detail_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_layout.dart';
import 'screens/admin/admin_persona_form_screen.dart';
import 'screens/admin/admin_persona_list_screen.dart';
import 'screens/admin/admin_user_detail_screen.dart';
import 'screens/admin/admin_user_form_screen.dart';
import 'screens/admin/admin_user_list_screen.dart';
import 'screens/session/session_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar icons (light content on dark background)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final secureStorage = SecureStorage();
  final apiClient = ApiClient(storage: secureStorage);
  final authProvider = AuthProvider(apiClient: apiClient);
  final sessionProvider = SessionProvider(apiClient: apiClient);
  final personaProvider = PersonaProvider(apiClient: apiClient);
  final adminProvider = AdminProvider(apiClient: apiClient);

  runApp(MyApp(
    authProvider: authProvider,
    sessionProvider: sessionProvider,
    personaProvider: personaProvider,
    adminProvider: adminProvider,
  ));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final SessionProvider sessionProvider;
  final PersonaProvider personaProvider;
  final AdminProvider adminProvider;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.sessionProvider,
    required this.personaProvider,
    required this.adminProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
        ChangeNotifierProvider.value(value: personaProvider),
        ChangeNotifierProvider.value(value: adminProvider),
      ],
      child: MaterialApp.router(
        title: 'SiniCerita',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: _createRouter(authProvider),
      ),
    );
  }
}

GoRouter _createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      return computeRedirect(
        status: authProvider.status,
        firstLaunchCompleted: authProvider.firstLaunchCompleted,
        location: state.matchedLocation,
        role: authProvider.currentUser?.role,
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (_, state) {
          final email = state.extra as String?;
          if (email == null) return const ForgotPasswordScreen();
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final raw = state.extra;
          if (raw is! Map) return const ForgotPasswordScreen();
          final email = raw['email'] as String?;
          final code = raw['code'] as String?;
          if (email == null || code == null) {
            return const ForgotPasswordScreen();
          }
          return ResetPasswordScreen(email: email, code: code);
        },
      ),
      GoRoute(path: '/main', builder: (_, _) => const MainScreen()),
      GoRoute(
        path: '/persona-detail/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return PersonaDetailScreen(personaId: id);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/chat/:sessionId',
        builder: (_, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return ChatScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/session-detail/:sessionId',
        builder: (_, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return SessionDetailScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/session-summary',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SessionSummaryScreen(
            scoreDelta: extra['scoreDelta'] as int,
            newPoints: extra['newPoints'] as int,
            summary: extra['summary'] as String,
          );
        },
      ),
      // Admin ShellRoute — wraps all /admin/* routes with AdminLayout
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            redirect: (_, _) => '/admin/dashboard',
          ),
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, _) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/personas',
            builder: (_, _) => const AdminPersonaListScreen(),
          ),
          GoRoute(
            path: '/admin/personas/create',
            builder: (_, _) => const AdminPersonaFormScreen(),
          ),
          GoRoute(
            path: '/admin/personas/:id/edit',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return AdminPersonaFormScreen(personaId: id);
            },
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, _) => const AdminUserListScreen(),
          ),
          GoRoute(
            path: '/admin/users/create',
            builder: (_, _) => const AdminUserFormScreen(),
          ),
          GoRoute(
            path: '/admin/users/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return AdminUserDetailScreen(userId: id);
            },
          ),
          GoRoute(
            path: '/admin/users/:id/edit',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return AdminUserFormScreen(userId: id);
            },
          ),
        ],
      ),
    ],
  );
}
