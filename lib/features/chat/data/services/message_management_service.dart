import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageManagementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> savedMessages() => _db
      .collection('users')
      .doc(_uid)
      .collection('savedMessages')
      .orderBy('savedAt', descending: true)
      .snapshots();

  Future<void> save({
    required String conversationId,
    required String messageId,
    required String contactName,
    required Map<String, dynamic> message,
  }) =>
      _db
          .collection('users')
          .doc(_uid)
          .collection('savedMessages')
          .doc('${conversationId}_$messageId')
          .set({
        'conversationId': conversationId,
        'messageId': messageId,
        'contactName': contactName,
        'message': message,
        'savedAt': FieldValue.serverTimestamp(),
      });

  Future<void> remove(String id) => _db
      .collection('users')
      .doc(_uid)
      .collection('savedMessages')
      .doc(id)
      .delete();
}
