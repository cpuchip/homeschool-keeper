import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Auth state class
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? token;
  
  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.token,
  });
  
  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? email,
    String? token,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      token: token ?? this.token,
    );
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  
  AuthNotifier(this._storage) : super(const AuthState()) {
    _loadFromStorage();
  }
  
  Future<void> _loadFromStorage() async {
    final token = await _storage.read(key: 'auth_token');
    final userId = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    
    if (token != null) {
      state = AuthState(
        isAuthenticated: true,
        token: token,
        userId: userId,
        email: email,
      );
    }
  }
  
  Future<void> login({
    required String email,
    required String token,
    required String userId,
  }) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_id', value: userId);
    await _storage.write(key: 'user_email', value: email);
    
    state = AuthState(
      isAuthenticated: true,
      token: token,
      userId: userId,
      email: email,
    );
  }
  
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    
    state = const AuthState();
  }
}

/// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage);
});
