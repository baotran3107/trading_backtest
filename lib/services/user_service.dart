import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../model/user_model.dart';
import '../constants/auth_constants.dart';

@lazySingleton
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = FirestoreCollections.users;

  /// Check if a user exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check if user exists: $e');
    }
  }

  /// Create a new user in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      final userData = user.toMap();
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['lastLoginAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(userData, SetOptions(merge: false));
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user's last login time
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last login: $e');
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Update user data in Firestore
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user from Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }
}
