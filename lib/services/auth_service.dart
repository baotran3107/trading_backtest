import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_model.dart';
import 'user_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Public API used by the app
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Signs in the user with Google and authenticates with Firebase.
  /// Returns null if the user cancels the Google account picker.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception('Google Sign-In failed: missing tokens');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      await _saveUserLoginState(true);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _clearAuthState();
      throw Exception('Authentication failed: ${e.message ?? e.code}');
    } catch (e) {
      await _clearAuthState();
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Attempts a silent sign-in with Google.
  /// Returns true if a session exists and Firebase has a current user.
  Future<bool> trySilentSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      return account != null && _firebaseAuth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Signs out from both Firebase and Google and clears local state.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } finally {
      await _saveUserLoginState(false);
    }
  }

  /// Returns cached login state; defaults to false on error.
  Future<bool> isUserLoggedIn() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('user_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearUserLoginState() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_logged_in');
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveUserLoginState(bool isLoggedIn) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_in', isLoggedIn);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _clearAuthState() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (_) {
      // ignore
    } finally {
      await clearUserLoginState();
    }
  }

  /// Returns the current user's profile from Firestore if available.
  /// If the user is signed in but not present in Firestore, creates
  /// a minimal profile from the Firebase user and returns it.
  Future<UserModel?> getCurrentUserModel() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final UserService userService = UserService();
    try {
      final UserModel? stored = await userService.getUser(user.uid);
      if (stored != null) {
        return stored;
      }

      // Create a basic profile if missing
      final UserModel newUser = UserModel.fromFirebaseUser(user);
      try {
        await userService.createUser(newUser);
      } catch (_) {
        // Non-fatal: continue returning the derived model
      }
      return newUser;
    } catch (_) {
      // Fallback to a model derived from Firebase user
      return UserModel.fromFirebaseUser(user);
    }
  }
}
