import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/auth_service.dart';

/// Auth state class
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? email;
  final String? familyId;
  final String? role;
  final bool onboardingComplete;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.userId,
    this.email,
    this.familyId,
    this.role,
    this.onboardingComplete = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userId,
    String? email,
    String? familyId,
    String? role,
    bool? onboardingComplete,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      error: error,
    );
  }

  /// Create authenticated state from user info
  factory AuthState.authenticated(UserInfo user) {
    return AuthState(
      isAuthenticated: true,
      isLoading: false,
      userId: user.id,
      email: user.email,
      familyId: user.familyId,
      role: user.role,
      onboardingComplete: user.onboardingComplete,
    );
  }

  /// Create unauthenticated state
  factory AuthState.unauthenticated() {
    return const AuthState(
      isAuthenticated: false,
      isLoading: false,
    );
  }

  /// Create error state
  factory AuthState.error(String message) {
    return AuthState(
      isAuthenticated: false,
      isLoading: false,
      error: message,
    );
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(response.user);
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      rethrow;
    } catch (e) {
      state = AuthState.error('Login failed: $e');
      rethrow;
    }
  }

  /// Register a new user
  Future<void> register({
    required String email,
    required String password,
    required String familyName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.register(
        email: email,
        password: password,
        familyName: familyName,
      );
      state = AuthState.authenticated(response.user);
    } on AuthException catch (e) {
      state = AuthState.error(e.message);
      rethrow;
    } catch (e) {
      state = AuthState.error('Registration failed: $e');
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = AuthState.unauthenticated();
  }

  /// Refresh user info
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AuthState.authenticated(user);
    } catch (e) {
      // If refresh fails, logout
      await logout();
    }
  }
}

/// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
},);
