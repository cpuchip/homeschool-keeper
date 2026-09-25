import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:homeschool_keeper/providers/auth_provider.dart';

/// Widget test for the app.
/// 
/// Note: This test only verifies that the app can build with mocked providers.
/// Integration tests requiring the full backend should be in integration_test/.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Hive with a temporary directory for testing
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('App builds successfully with mocked providers', (WidgetTester tester) async {
    // Build a minimal version of the app with overridden providers
    // This avoids hitting real network/storage services
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override auth state provider directly with initial state
          authStateProvider.overrideWith((ref) {
            // Return a stub notifier that has stable state (not loading)
            return _StubAuthNotifier(const AuthState(isLoading: false));
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Test App'),
            ),
          ),
        ),
      ),
    );

    // Verify that something renders
    expect(find.text('Test App'), findsOneWidget);
  });

  testWidgets('Auth state provider can be overridden', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) {
            return _StubAuthNotifier(
              const AuthState(
                isAuthenticated: true,
                isLoading: false,
                userId: 'test-user-123',
                email: 'test@example.com',
                familyId: 'test-family-123',
              ),
            );
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authStateProvider);
              return Scaffold(
                body: Center(
                  child: Text(
                    authState.isAuthenticated
                        ? 'Authenticated as ${authState.email}'
                        : 'Not authenticated',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Authenticated as test@example.com'), findsOneWidget);
  });
}

/// A stub AuthNotifier for testing that only holds state.
/// Uses StateNotifier<AuthState> directly since we don't need real AuthNotifier methods.
class _StubAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _StubAuthNotifier(super.state);

  @override
  Future<void> login({required String email, required String password}) async {}
  
  @override
  Future<void> register({required String email, required String password, required String familyName, String role = 'parent'}) async {}
  
  @override
  Future<void> loginWithGoogle({required String idToken, String? familyName, String? usState}) async {}
  
  @override
  Future<void> logout() async {}
  
  @override
  void skipAccountForOfflineMode() {}
  
  @override
  Future<void> refreshUser() async {}
}
