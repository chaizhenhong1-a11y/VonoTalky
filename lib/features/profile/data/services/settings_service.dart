import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  SettingsService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid => _auth.currentUser!.uid;
  String get currentEmail => _auth.currentUser?.email ?? '';

  Stream<Map<String, dynamic>> watch() => _firestore
      .collection('users')
      .doc(_uid)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.data()?['settings'] as Map<String, dynamic>? ?? {},
      );

  Future<void> setBool(String key, bool value) => setValue(key, value);

  Future<void> setValue(String key, Object value) =>
      _firestore.collection('users').doc(_uid).update({
        'settings.$key': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<List<Map<String, dynamic>>> blockedUsers() => _firestore
      .collection('users')
      .doc(_uid)
      .collection('blockedUsers')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => <String, dynamic>{'uid': doc.id, ...doc.data()})
            .toList(),
      );

  Future<void> unblockUser(String uid) => _firestore
      .collection('users')
      .doc(_uid)
      .collection('blockedUsers')
      .doc(uid)
      .delete();

  Future<void> sendPasswordReset() async {
    final email = currentEmail;
    if (email.isEmpty) throw StateError('No email is linked to this account.');
    await _auth.sendPasswordResetEmail(email: email);
  }
}
