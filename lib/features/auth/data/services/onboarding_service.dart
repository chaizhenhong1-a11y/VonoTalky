import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => _auth.currentUser!.uid;

  Future<void> complete({
    required String displayName,
    required String username,
    required String bio,
    required bool contactsSync,
    required bool pushNotifications,
  }) async {
    final cleanName = displayName.trim();
    final cleanUsername = username.trim().toLowerCase();
    if (cleanName.length < 2) {
      throw const OnboardingFailure('Enter your display name.');
    }
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(cleanUsername)) {
      throw const OnboardingFailure(
        'Username must be 3–20 letters, numbers or underscores.',
      );
    }

    final usernameRef = _db.collection('usernames').doc(cleanUsername);
    final userRef = _db.collection('users').doc(_uid);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(usernameRef);
      if (existing.exists && existing.data()?['uid'] != _uid) {
        throw const OnboardingFailure('This username is already taken.');
      }
      if (!existing.exists) {
        transaction.set(usernameRef, {
          'uid': _uid,
          'username': cleanUsername,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.update(userRef, {
        'displayName': cleanName,
        'displayNameLower': cleanName.toLowerCase(),
        'username': cleanUsername,
        'usernameLower': cleanUsername,
        'bio': bio.trim(),
        'contactsSyncEnabled': contactsSync,
        'settings.pushNotifications': pushNotifications,
        'onboardingComplete': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await _auth.currentUser!.updateDisplayName(cleanName);
  }
}

class OnboardingFailure implements Exception {
  const OnboardingFailure(this.message);
  final String message;
}
