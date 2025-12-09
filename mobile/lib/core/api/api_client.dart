import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

/// Keys for storing tokens in secure storage
class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String familyId = 'family_id';
}

/// Token storage service using flutter_secure_storage
class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage(this._storage);

  Future<String?> getAccessToken() =>
      _storage.read(key: StorageKeys.accessToken);
  Future<String?> getRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);
  Future<String?> getTokenExpiry() =>
      _storage.read(key: StorageKeys.tokenExpiry);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresAt,
  }) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
      _storage.write(key: StorageKeys.tokenExpiry, value: expiresAt.toString()),
    ]);
  }

  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String familyId,
  }) async {
    await Future.wait([
      _storage.write(key: StorageKeys.userId, value: userId),
      _storage.write(key: StorageKeys.userEmail, value: email),
      _storage.write(key: StorageKeys.familyId, value: familyId),
    ]);
  }

  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
      _storage.delete(key: StorageKeys.tokenExpiry),
      _storage.delete(key: StorageKeys.userId),
      _storage.delete(key: StorageKeys.userEmail),
      _storage.delete(key: StorageKeys.familyId),
    ]);
  }

  Future<bool> isTokenExpired() async {
    final expiryStr = await getTokenExpiry();
    if (expiryStr == null) return true;

    final expiry = int.tryParse(expiryStr);
    if (expiry == null) return true;

    // Add 30 second buffer before expiry
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    return DateTime.now().add(const Duration(seconds: 30)).isAfter(expiryTime);
  }
}

/// JWT Auth interceptor that handles token refresh and adds Authorization header
class JwtAuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;

  JwtAuthInterceptor(this._dio, this._tokenStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints
    final isAuthEndpoint = options.path.contains('/mobile/auth/login') ||
        options.path.contains('/mobile/auth/register') ||
        options.path.contains('/mobile/auth/refresh');

    if (!isAuthEndpoint) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        // Check if token is about to expire
        if (await _tokenStorage.isTokenExpired() && !_isRefreshing) {
          await _refreshToken();
          final newToken = await _tokenStorage.getAccessToken();
          if (newToken != null) {
            options.headers['Authorization'] = 'Bearer $newToken';
          }
        } else {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If 401 Unauthorized, try to refresh token
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the original request
        final options = err.requestOptions;
        final token = await _tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        try {
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await _tokenStorage.clearAll();
        return false;
      }

      final response = await _dio.post(
        ApiConstants.mobileRefresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresAt: data['expiresAt'],
        );
        return true;
      }
    } catch (e) {
      await _tokenStorage.clearAll();
    } finally {
      _isRefreshing = false;
    }

    return false;
  }
}

/// API client wrapper for making HTTP requests
class ApiClient {
  final Dio _dio;
  final TokenStorage tokenStorage;

  ApiClient(this._dio, this.tokenStorage);

  Dio get dio => _dio;

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      options: options,
    );
  }
}

/// Providers

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return TokenStorage(storage);
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.timeout,
      receiveTimeout: ApiConstants.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add JWT interceptor
  dio.interceptors.add(
    JwtAuthInterceptor(dio, tokenStorage),
  );

  // Add logging interceptor in debug mode
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (log) => debugPrint('[API] $log'),
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) {
    final dio = ref.watch(dioProvider);
    final tokenStorage = ref.watch(tokenStorageProvider);
    return ApiClient(dio, tokenStorage);
  },
);
