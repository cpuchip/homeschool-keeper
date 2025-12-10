import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../constants.dart';

/// Auth service for handling authentication API calls
class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService(this._apiClient, this._tokenStorage);

  /// Login with email and password
  /// Returns the user data on success
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.mobileLogin,
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Save tokens
      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        expiresAt: authResponse.expiresAt,
      );

      // Save user info
      await _tokenStorage.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email,
        familyId: authResponse.user.familyId,
      );

      return authResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Register a new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String familyName,
    String role = 'parent',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.mobileRegister,
        data: {
          'email': email,
          'password': password,
          'familyName': familyName,
          'role': role,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Save tokens
      await _tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        expiresAt: authResponse.expiresAt,
      );

      // Save user info
      await _tokenStorage.saveUserInfo(
        userId: authResponse.user.id,
        email: authResponse.user.email,
        familyId: authResponse.user.familyId,
      );

      return authResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Refresh the access token
  Future<void> refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      throw AuthException('No refresh token available');
    }

    try {
      final response = await _apiClient.post(
        ApiConstants.mobileRefresh,
        data: {'refreshToken': refreshToken},
      );

      // Refresh endpoint only returns new access token, not new refresh token
      await _tokenStorage.saveTokens(
        accessToken: response.data['accessToken'],
        refreshToken: refreshToken, // Keep existing refresh token
        expiresAt: response.data['expiresAt'],
      );
    } on DioException catch (e) {
      await _tokenStorage.clearAll();
      throw _handleDioError(e);
    }
  }

  /// Get current user info
  Future<UserInfo> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.mobileMe);
      return UserInfo.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Logout - clears all stored tokens
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  /// Check if user is logged in (has valid tokens)
  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return false;

    // Check if we can refresh if token is expired
    if (await _tokenStorage.isTokenExpired()) {
      try {
        await refreshToken();
        return true;
      } catch (_) {
        return false;
      }
    }

    return true;
  }

  AuthException _handleDioError(DioException e) {
    final message = e.response?.data?['error'] ??
        e.response?.data?['message'] ??
        e.message ??
        'Unknown error occurred';
    return AuthException(message, statusCode: e.response?.statusCode);
  }
}

/// Auth response from login/register
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresAt;
  final UserInfo user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: json['expiresAt'] as int,
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// User info returned from API
class UserInfo {
  final String id;
  final String email;
  final String familyId;
  final String role;
  final bool onboardingComplete;

  UserInfo({
    required this.id,
    required this.email,
    required this.familyId,
    required this.role,
    required this.onboardingComplete,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      email: json['email'] as String,
      familyId: json['familyId'] as String,
      role: json['role'] as String? ?? 'parent',
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'familyId': familyId,
      'role': role,
      'onboardingComplete': onboardingComplete,
    };
  }
}

/// Auth exception with optional status code
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthService(apiClient, tokenStorage);
},);
