import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants.dart';
import '../utils/logger.dart';

/// Service for handling Google Sign-In
class GoogleSignInService {
  late final GoogleSignIn _googleSignIn;

  GoogleSignInService() {
    _googleSignIn = GoogleSignIn(
      // Use web client ID for ID token verification on backend
      serverClientId: GoogleAuthConfig.webClientId,
      scopes: ['email', 'profile'],
    );
  }

  /// Sign in with Google and return the ID token
  /// Returns null if sign-in was cancelled
  Future<GoogleSignInResult?> signIn() async {
    try {
      Log.auth.d('Starting Google Sign-In...');
      
      // Sign out first to ensure account picker is shown
      await _googleSignIn.signOut();
      
      final account = await _googleSignIn.signIn();
      if (account == null) {
        Log.auth.d('Google Sign-In cancelled by user');
        return null;
      }

      Log.auth.d('Google Sign-In successful: ${account.email}');
      
      // Get authentication tokens
      final auth = await account.authentication;
      final idToken = auth.idToken;
      
      if (idToken == null) {
        Log.auth.e('No ID token returned from Google Sign-In');
        throw GoogleSignInException('Failed to get ID token from Google');
      }

      return GoogleSignInResult(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
      );
    } catch (e) {
      Log.auth.e('Google Sign-In error', e);
      if (e is GoogleSignInException) rethrow;
      throw GoogleSignInException('Google Sign-In failed: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      Log.auth.d('Signed out from Google');
    } catch (e) {
      Log.auth.e('Error signing out from Google', e);
    }
  }

  /// Check if user is currently signed in to Google
  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }
}

/// Result from Google Sign-In
class GoogleSignInResult {
  final String idToken;
  final String email;
  final String? displayName;

  GoogleSignInResult({
    required this.idToken,
    required this.email,
    this.displayName,
  });
}

/// Exception for Google Sign-In errors
class GoogleSignInException implements Exception {
  final String message;

  GoogleSignInException(this.message);

  @override
  String toString() => message;
}

/// Provider for GoogleSignInService
final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});
