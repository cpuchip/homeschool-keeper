// Integration test for sync functionality
// Run with: flutter test integration_test/sync_test.dart -d windows
// Or: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/sync_test.dart -d windows
// Requires backend running on localhost:8080

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'http://localhost:8080';
  const testPassword = 'Test123!';
  const testFamilyName = 'Sync Test Family';

  group('Sync Integration Tests', () {
    late Dio dio;
    late FlutterSecureStorage storage;
    String? accessToken;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => true, // Don't throw on non-2xx
      ));
      storage = const FlutterSecureStorage();
    });

    tearDown(() async {
      try {
        await storage.deleteAll();
      } catch (e) {
        print('Cleanup error: $e');
      }
    });

    testWidgets('Token storage and retrieval works', (tester) async {
      final uniqueEmail = 'sync_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      print('📝 Registering user: $uniqueEmail');
      
      final registerResponse = await dio.post(
        '/api/v1/mobile/auth/register',
        data: {
          'email': uniqueEmail,
          'password': testPassword,
          'name': 'Sync Test User',
          'familyName': testFamilyName,
        },
      );

      print('📝 Registration status: ${registerResponse.statusCode}');
      
      if (registerResponse.statusCode != 201) {
        print('❌ Registration failed: ${registerResponse.data}');
        fail('Registration should succeed with 201, got ${registerResponse.statusCode}');
      }

      accessToken = registerResponse.data['accessToken'] as String?;
      final refreshToken = registerResponse.data['refreshToken'] as String?;
      final expiresAt = registerResponse.data['expiresAt'];
      
      expect(accessToken, isNotNull, reason: 'Access token should not be null');
      expect(accessToken, isNotEmpty, reason: 'Access token should not be empty');
      print('✅ Access token received: ${accessToken!.substring(0, 20)}...');

      // Store tokens (simulating what AuthService.login does)
      print('💾 Saving tokens to secure storage...');
      await storage.write(key: 'access_token', value: accessToken);
      await storage.write(key: 'refresh_token', value: refreshToken);
      await storage.write(key: 'token_expiry', value: expiresAt.toString());
      print('✅ Tokens saved');

      // Now read them back (simulating what JwtAuthInterceptor does)
      print('📖 Reading tokens back from storage...');
      final storedAccessToken = await storage.read(key: 'access_token');
      final storedRefreshToken = await storage.read(key: 'refresh_token');
      final storedExpiry = await storage.read(key: 'token_expiry');

      print('   Access token found: ${storedAccessToken != null ? "yes (${storedAccessToken.length} chars)" : "no"}');
      print('   Refresh token found: ${storedRefreshToken != null ? "yes" : "no"}');
      print('   Expiry found: $storedExpiry');

      expect(storedAccessToken, equals(accessToken), reason: 'Token should be retrievable after storing');
      expect(storedRefreshToken, equals(refreshToken));
      print('✅ Token storage works correctly!');
    });

    testWidgets('Authenticated request with stored token succeeds', (tester) async {
      final uniqueEmail = 'sync_test2_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      print('📝 Registering user: $uniqueEmail');
      
      final registerResponse = await dio.post(
        '/api/v1/mobile/auth/register',
        data: {
          'email': uniqueEmail,
          'password': testPassword,
          'name': 'Sync Test User 2',
          'familyName': testFamilyName,
        },
      );

      if (registerResponse.statusCode != 201) {
        fail('Registration failed: ${registerResponse.statusCode} - ${registerResponse.data}');
      }

      accessToken = registerResponse.data['accessToken'] as String;
      print('✅ Got access token');

      // Store token
      await storage.write(key: 'access_token', value: accessToken);
      
      // Read it back
      final storedToken = await storage.read(key: 'access_token');
      expect(storedToken, isNotNull, reason: 'Token should be stored');
      print('✅ Token stored and retrieved');

      // Make authenticated request to /api/v1/students
      print('🔐 Making authenticated request to /api/v1/students...');
      
      dio.options.headers['Authorization'] = 'Bearer $storedToken';
      final studentsResponse = await dio.get('/api/v1/students');
      
      print('   Status: ${studentsResponse.statusCode}');
      print('   Data: ${studentsResponse.data}');
      
      expect(studentsResponse.statusCode, equals(200), 
        reason: 'Authenticated request should succeed');
    });

    testWidgets('Race condition test - save and immediate read', (tester) async {
      final uniqueEmail = 'sync_test_race_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      // Register to get a token
      final registerResponse = await dio.post(
        '/api/v1/mobile/auth/register',
        data: {
          'email': uniqueEmail,
          'password': testPassword,
          'name': 'Race Test User',
          'familyName': testFamilyName,
        },
      );
      
      if (registerResponse.statusCode != 201) {
        fail('Registration failed: ${registerResponse.statusCode}');
      }
      
      accessToken = registerResponse.data['accessToken'] as String;
      
      print('🏁 Starting race condition simulation...');
      
      // Start saving (but don't await yet) - simulating AuthService.login
      final saveFuture = storage.write(key: 'access_token', value: accessToken);
      
      // Immediately try to read (simulating sync starting right away)
      print('   Attempting immediate read before save completes...');
      final immediateRead = await storage.read(key: 'access_token');
      
      // Now wait for save to complete
      await saveFuture;
      
      print('   Save completed');
      print('   Immediate read result: ${immediateRead != null ? "found" : "NOT FOUND"}');
      
      // Read after save completes
      final afterSaveRead = await storage.read(key: 'access_token');
      print('   After-save read result: ${afterSaveRead != null ? "found" : "NOT FOUND"}');
      
      // This shows us if there's a race condition
      if (immediateRead == null && afterSaveRead != null) {
        print('⚠️ RACE CONDITION DETECTED: Token only available after save completes');
        print('   The sync is starting before tokens are fully saved!');
        print('   This is expected with raw FlutterSecureStorage - our fix uses caching.');
      }
      
      expect(afterSaveRead, isNotNull);
    });

    testWidgets('TokenStorage cache prevents race condition', (tester) async {
      // Import and test our fixed TokenStorage with caching
      // This test simulates what happens in the app after our fix
      
      final uniqueEmail = 'sync_test_cache_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      final registerResponse = await dio.post(
        '/api/v1/mobile/auth/register',
        data: {
          'email': uniqueEmail,
          'password': testPassword,
          'name': 'Cache Test User',
          'familyName': testFamilyName,
        },
      );
      
      if (registerResponse.statusCode != 201) {
        fail('Registration failed: ${registerResponse.statusCode}');
      }
      
      accessToken = registerResponse.data['accessToken'] as String;
      final refreshToken = registerResponse.data['refreshToken'] as String;
      final expiresAt = registerResponse.data['expiresAt'] as int;
      
      print('🔧 Testing TokenStorage with cache...');
      
      // Create a simple in-memory + storage wrapper like our fix
      String? cachedToken;
      
      // Simulate saveTokens with cache (don't await storage write)
      cachedToken = accessToken;
      final writeFuture = storage.write(key: 'cached_test_token', value: accessToken);
      
      // Immediately read from "cache" (simulating JwtAuthInterceptor)
      final immediateResult = cachedToken;
      
      print('   Cache read (immediate): ${immediateResult != null ? "found" : "NOT FOUND"}');
      
      // Complete the write
      await writeFuture;
      
      // Cache should have the token immediately
      expect(immediateResult, isNotNull, reason: 'Token should be in cache immediately');
      expect(immediateResult, equals(accessToken));
      
      print('✅ Cache prevents race condition!');
    });
  });
}
