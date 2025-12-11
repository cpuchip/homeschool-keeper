import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/logs/presentation/quick_log_screen.dart';
import '../features/logs/presentation/logs_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/students/presentation/students_screen.dart';
import '../features/subjects/presentation/subjects_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/trash_screen.dart';
import '../features/settings/presentation/export_screen.dart';
import '../features/shell/app_shell.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      // Allow access if authenticated OR in offline mode
      final canAccessApp = authState.isAuthenticated || authState.isOfflineMode;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register';
      
      // Still loading auth state - don't redirect yet
      if (authState.isLoading) {
        return null;
      }
      
      if (!canAccessApp && !isAuthRoute) {
        return '/login';
      }
      if (canAccessApp && isAuthRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // App routes (with shell)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/quick-log',
            builder: (context, state) => const QuickLogScreen(),
          ),
          GoRoute(
            path: '/logs',
            builder: (context, state) => const LogsScreen(),
          ),
          GoRoute(
            path: '/students',
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: '/subjects',
            builder: (context, state) => const SubjectsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/trash',
            builder: (context, state) => const TrashScreen(),
          ),
          GoRoute(
            path: '/export',
            builder: (context, state) => const ExportScreen(),
          ),
        ],
      ),
    ],
  );
});
