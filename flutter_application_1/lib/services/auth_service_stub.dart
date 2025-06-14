import 'package:google_sign_in/google_sign_in.dart';

/// Signs in with Google and returns the idToken, or null if failed.
/// Send this token to your backend for verification and login.
Future<String?> redirectToGoogleAuth([String? url]) async {
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      // Add other scopes if needed
    ],
  );

  try {
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account != null) {
      final GoogleSignInAuthentication auth = await account.authentication;
      print('Google ID Token: ${auth.idToken}');
      // Return the idToken so AuthService can send it to your backend
      return auth.idToken;
    }
  } catch (error) {
    print('Google sign-in error: $error');
  }
  return null;
}