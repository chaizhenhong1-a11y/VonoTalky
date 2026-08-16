import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error.code));
    }
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const AuthFailure('Account creation failed.');

      await user.updateDisplayName(displayName.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': displayName.trim(),
        'displayNameLower': displayName.trim().toLowerCase(),
        'email': email.trim().toLowerCase(),
        'photoUrl': null,
        'bio': '',
        'onboardingComplete': false,
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error.code));
    } on FirebaseException {
      throw const AuthFailure(
        'Your account was created, but the profile could not be saved.',
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _messageFor(String code) {
    return switch (code) {
      'invalid-email' => 'The email address is invalid.',
      'invalid-credential' => 'Email or password is incorrect.',
      'user-disabled' => 'This account has been disabled.',
      'email-already-in-use' => 'An account already uses this email.',
      'weak-password' => 'Choose a stronger password.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'Check your internet connection.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}
