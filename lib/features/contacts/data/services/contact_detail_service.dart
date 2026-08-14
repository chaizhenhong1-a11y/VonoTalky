import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../chat/data/models/chat_user.dart';

class ContactDetailService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _myId => _auth.currentUser!.uid;

  Stream<ChatUser?> user(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(
            (document) => document.exists ? ChatUser.fromDoc(document) : null,
          );

  Stream<Map<String, dynamic>> preferences(String uid) => _db
      .collection('users')
      .doc(_myId)
      .collection('contactPreferences')
      .doc(uid)
      .snapshots()
      .map((document) => document.data() ?? <String, dynamic>{});

  Stream<Map<String, Map<String, dynamic>>> allPreferences() => _db
      .collection('users')
      .doc(_myId)
      .collection('contactPreferences')
      .snapshots()
      .map(
        (snapshot) => {
          for (final document in snapshot.docs) document.id: document.data(),
        },
      );

  Future<void> setPreference(String uid, String key, bool value) => _db
      .collection('users')
      .doc(_myId)
      .collection('contactPreferences')
      .doc(uid)
      .set({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> removeContact(String uid) => _db
      .collection('users')
      .doc(_myId)
      .collection('contacts')
      .doc(uid)
      .delete();

  Future<void> block(ChatUser user) async {
    final batch = _db.batch();
    batch.set(
      _db
          .collection('users')
          .doc(_myId)
          .collection('blockedUsers')
          .doc(user.uid),
      {
        'uid': user.uid,
        'displayName': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'blockedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.delete(
      _db.collection('users').doc(_myId).collection('contacts').doc(user.uid),
    );
    await batch.commit();
  }

  Future<void> report(ChatUser user, String reason) =>
      _db.collection('userReports').add({
        'reporterId': _myId,
        'reportedUserId': user.uid,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
}
