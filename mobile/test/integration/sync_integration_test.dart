// Integration test for sync functionality
// Run with: flutter test test/integration/sync_integration_test.dart
// Requires backend running on localhost:8080

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Simplified test that doesn't require full Flutter widget tree
// Uses direct HTTP calls to test the auth + sync flow

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'http://localhost:8080';
  const testPassword = 'Test123!';
  const testFamilyName = 'Sync Test Family';

  group('Sync Integration Tests', () {
    late Dio dio;
    late FlutterSecureStorage storage;
    String? accessToken;
    String? refreshToken;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),);
      storage = const FlutterSecureStorage();
    });

    tearDown(() async {
      await storage.deleteAll();
    });

    test('Login stores token and can be retrieved', () async {
      // First, register a new user
      final uniqueEmail = 'sync_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      print('📝 Registering user: $uniqueEmail');
      
      try {
        final registerResponse = await dio.post(
          '/api/v1/mobile/auth/register',
          data: {
            'email': uniqueEmail,
            'password': testPassword,
            'name': 'Sync Test User',
            'familyName': testFamilyName,
          },
        );

        print('✅ Registration response: ${registerResponse.statusCode}');
        print('   User ID: ${registerResponse.data['user']['id']}');
        
        accessToken = registerResponse.data['accessToken'];
        refreshToken = registerResponse.data['refreshToken'];
        final expiresAt = registerResponse.data['expiresAt'];
        
        expect(accessToken, isNotNull);
        expect(accessToken, isNotEmpty);
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
        expect(storedExpiry, equals(expiresAt.toString()));

        print('✅ Token storage works correctly!');

      } on DioException catch (e) {
        print('❌ HTTP Error: ${e.response?.statusCode} - ${e.response?.data}');
        fail('Registration failed: ${e.message}');
      }
    });

    test('Authenticated request with stored token succeeds', () async {
      // Register and get token
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

      accessToken = registerResponse.data['accessToken'];
      expect(accessToken, isNotNull);
      print('✅ Got access token');

      // Store token
      await storage.write(key: 'access_token', value: accessToken);
      
      // Read it back
      final storedToken = await storage.read(key: 'access_token');
      expect(storedToken, isNotNull);
      print('✅ Token stored and retrieved');

      // Make authenticated request to /api/v1/students
      print('🔐 Making authenticated request to /api/v1/students...');
      
      final authenticatedDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $storedToken',
        },
      ),);

      try {
        final studentsResponse = await authenticatedDio.get('/api/v1/students');
        print('✅ Students response: ${studentsResponse.statusCode}');
        print('   Data: ${studentsResponse.data}');
        expect(studentsResponse.statusCode, equals(200));
      } on DioException catch (e) {
        print('❌ Request failed: ${e.response?.statusCode}');
        print('   Response: ${e.response?.data}');
        fail('Authenticated request should succeed but got: ${e.response?.statusCode}');
      }
    });

    test('Request without token fails with 401', () async {
      print('🔐 Making unauthenticated request to /api/v1/students...');
      
      try {
        await dio.get('/api/v1/students');
        fail('Should have thrown 401');
      } on DioException catch (e) {
        print('✅ Got expected 401: ${e.response?.statusCode}');
        expect(e.response?.statusCode, equals(401));
      }
    });

    test('Full login -> store -> retrieve -> request flow', () async {
      final uniqueEmail = 'sync_test3_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      // Step 1: Login
      print('📝 Step 1: Registering...');
      final registerResponse = await dio.post(
        '/api/v1/mobile/auth/register',
        data: {
          'email': uniqueEmail,
          'password': testPassword,
          'name': 'Sync Test User 3',
          'familyName': testFamilyName,
        },
      );
      accessToken = registerResponse.data['accessToken'];
      final expiresAt = registerResponse.data['expiresAt'];
      print('   Got token: ${accessToken!.substring(0, 20)}...');

      // Step 2: Store (await the write)
      print('💾 Step 2: Storing token...');
      await storage.write(key: 'access_token', value: accessToken);
      await storage.write(key: 'token_expiry', value: expiresAt.toString());
      print('   Store completed');

      // Step 3: Read back immediately
      print('📖 Step 3: Reading token back immediately...');
      final token = await storage.read(key: 'access_token');
      
      if (token == null) {
        print('❌ CRITICAL: Token is null immediately after storing!');
        print('   This is the bug - FlutterSecureStorage write is not persisting on this platform');
        fail('Token should not be null after storing');
      }
      print('   Token retrieved: ${token.substring(0, 20)}...');

      // Step 4: Make authenticated request
      print('🔐 Step 4: Making authenticated request...');
      dio.options.headers['Authorization'] = 'Bearer $token';
      
      final studentsResponse = await dio.get('/api/v1/students');
      print('✅ Request succeeded: ${studentsResponse.statusCode}');
      
      expect(studentsResponse.statusCode, equals(200));
    });

    test('Simulated concurrent save and read (race condition test)', () async {
      final uniqueEmail = 'sync_test4_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
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
      accessToken = registerResponse.data['accessToken'];
      
      // This simulates what happens in the app:
      // AuthService.login() saves tokens
      // Then immediately, sync tries to read them
      
      print('🏁 Starting race condition simulation...');
      
      // Start saving (but don't await yet)
      final saveFuture = storage.write(key: 'access_token', value: accessToken);
      
      // Immediately try to read (simulating sync starting right away)
      // This is the problematic pattern!
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
      }
      
      expect(afterSaveRead, isNotNull);
    });
  });
}
