import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/google_sign_in_service.dart';

/// Google Sign-In button widget
class GoogleSignInButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Callback when Google sign-in succeeds with ID token
  final void Function(GoogleSignInResult result)? onSuccess;

  /// Callback when Google sign-in fails
  final void Function(String error)? onError;

  const GoogleSignInButton({
    super.key,
    this.text = 'Sign in with Google',
    this.onPressed,
    this.isLoading = false,
    this.onSuccess,
    this.onError,
  });

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isSigningIn = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn || widget.isLoading) return;

    setState(() => _isSigningIn = true);

    try {
      final googleSignIn = ref.read(googleSignInServiceProvider);
      final result = await googleSignIn.signIn();
      
      if (result != null) {
        widget.onSuccess?.call(result);
      }
      // If result is null, user cancelled - no action needed
    } on GoogleSignInException catch (e) {
      widget.onError?.call(e.message);
    } catch (e) {
      widget.onError?.call('Google sign-in failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSigningIn || widget.isLoading;

    return OutlinedButton(
      onPressed: isLoading ? null : (widget.onPressed ?? _handleGoogleSignIn),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google "G" logo
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
    );
  }
}
