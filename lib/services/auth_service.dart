import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';
import '../model/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  // Expose user service for external access
  UserService get userService => _userService;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Validate that we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Handle user data in Firestore
      if (userCredential.user != null) {
        await _handleUserData(userCredential.user!);
      }

      // Save user login state
      await _saveUserLoginState(true);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Clear all tokens on Firebase Auth exception
      await _clearAllTokens();
      // Handle Firebase Auth specific errors
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credential received is malformed or has expired.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Google sign-in is not enabled. Please contact support.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this credential.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-verification-code':
          errorMessage = 'The verification code is invalid.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'The verification ID is invalid.';
          break;
        default:
          errorMessage = 'Authentication failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Clear all tokens on any other exception
      await _clearAllTokens();
      // Handle other errors
      if (e.toString().contains('network_error') ||
          e.toString().contains('CONNECTION_ERROR')) {
        throw Exception(
            'Network error. Please check your internet connection and try again.');
      } else if (e.toString().contains('sign_in_canceled')) {
        throw Exception('Sign-in was cancelled by the user.');
      } else {
        throw Exception('Google Sign-In failed: ${e.toString()}');
      }
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      await _saveUserLoginState(false);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('user_logged_in') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveUserLoginState(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_in', isLoggedIn);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> clearUserLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_logged_in');
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clear all authentication tokens and states
  Future<void> _clearAllTokens() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        clearUserLoginState(),
      ]);
    } catch (e) {
      // Handle error silently - we're already in an error state
      print('Error clearing tokens: $e');
    }
  }

  /// Handle user data creation/update in Firestore
  Future<void> _handleUserData(User firebaseUser) async {
    try {
      final userExists = await _userService.userExists(firebaseUser.uid);

      if (!userExists) {
        // Create new user in Firestore
        final userModel = UserModel.fromFirebaseUser(firebaseUser);
        await _userService.createUser(userModel);
      } else {
        // Update last login time for existing user
        await _userService.updateLastLogin(firebaseUser.uid);
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking the sign-in flow
      print('Error handling user data: $e');
    }
  }

  /// Get current user model from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final existing = await _userService.getUser(currentUser.uid);
        if (existing != null) {
          return existing;
        }
        // If not found in Firestore, create a new user document using Firebase Auth data
        final fallback = UserModel.fromFirebaseUser(currentUser);
        await _userService.createUser(fallback);
        return fallback;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current user model: $e');
    }
  }

  /// Sign in with Google with retry logic
  Future<UserCredential?> signInWithGoogleWithRetry(
      {int maxRetries = 3}) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        return await signInWithGoogle();
      } catch (e) {
        lastException = e as Exception;
        attempts++;

        // Don't retry for user cancellation or account-specific errors
        if (e.toString().contains('cancelled') ||
            e.toString().contains('account-exists') ||
            e.toString().contains('user-disabled')) {
          break;
        }

        // Clear tokens before retry
        await _clearAllTokens();

        // Wait before retrying (exponential backoff)
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      }
    }

    // Final cleanup on complete failure
    await _clearAllTokens();
    throw lastException ??
        Exception('Sign-in failed after $maxRetries attempts');
  }

  /// Check if Google Sign-In is available
  Future<bool> isGoogleSignInAvailable() async {
    try {
      await _googleSignIn.isSignedIn();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get Google Sign-In account info
  Future<GoogleSignInAccount?> getGoogleAccount() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      return null;
    }
  }
}
