class FirestoreCollections {
  static const String users = 'users';
}

class SharedPrefKeys {
  static const String userLoggedIn = 'user_logged_in';
}

class FirebaseAuthErrorMessages {
  static const Map<String, String> byCode = {
    'account-exists-with-different-credential':
        'An account already exists with a different sign-in method.',
    'invalid-credential':
        'The credential received is malformed or has expired.',
    'operation-not-allowed':
        'Google sign-in is not enabled. Please contact support.',
    'user-disabled': 'This user account has been disabled.',
    'user-not-found': 'No user found with this credential.',
    'wrong-password': 'Wrong password provided.',
    'invalid-verification-code': 'The verification code is invalid.',
    'invalid-verification-id': 'The verification ID is invalid.',
  };
}

class GenericAuthMessages {
  static const String authFailedPrefix = 'Authentication failed: ';
  static const String googleSignInFailedPrefix = 'Google Sign-In failed: ';
  static const String networkError =
      'Network error. Please check your internet connection and try again.';
  static const String signInCancelled = 'Sign-in was cancelled by the user.';
  static const String signOutFailedPrefix = 'Sign out failed: ';
}

class AuthErrorSubstrings {
  static const String networkError = 'network_error';
  static const String connectionError = 'CONNECTION_ERROR';
  static const String signInCanceled = 'sign_in_canceled';
  static const String accountExists = 'account-exists';
  static const String userDisabled = 'user-disabled';
}
