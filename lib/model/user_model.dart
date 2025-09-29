import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String? provider;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.createdAt,
    this.lastLoginAt,
    this.provider,
    this.preferences,
  });

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'User',
      photoURL: user.photoURL,
      createdAt: user.metadata.creationTime,
      lastLoginAt: user.metadata.lastSignInTime,
      provider: user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'provider': provider,
      'preferences': preferences,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        // Attempt to parse ISO8601 strings if present
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return null;
    }

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'User',
      photoURL: map['photoURL'],
      createdAt: _parseDate(map['createdAt']),
      lastLoginAt: _parseDate(map['lastLoginAt']),
      provider: map['provider'],
      preferences: map['preferences'] != null
          ? Map<String, dynamic>.from(map['preferences'])
          : null,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? provider,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      provider: provider ?? this.provider,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, photoURL: $photoURL, createdAt: $createdAt, lastLoginAt: $lastLoginAt, provider: $provider, preferences: $preferences)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
