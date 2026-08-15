import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupRecentChatService {
  GroupRecentChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _myId => _auth.currentUser!.uid;

  String preferenceId(String groupId) => 'group_$groupId';

  Future<String> loadDraft(String groupId) async {
    final document = await _db
        .collection('users')
        .doc(_myId)
        .collection('contactPreferences')
        .doc(preferenceId(groupId))
        .get();

    return document.data()?['draft'] as String? ?? '';
  }

  Future<void> setDraft(String groupId, String value) => _db
      .collection('users')
      .doc(_myId)
      .collection('contactPreferences')
      .doc(preferenceId(groupId))
      .set({
        'draft': value,
        'draftUpdatedAt': FieldValue.serverTimestamp(),
        'type': 'group',
      }, SetOptions(merge: true));

  Future<void> setArchived(String groupId, bool value) => _db
      .collection('users')
      .doc(_myId)
      .collection('contactPreferences')
      .doc(preferenceId(groupId))
      .set({
        'archived': value,
        'type': 'group',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> setPinned(String groupId, bool value) => _db
      .collection('users')
      .doc(_myId)
      .collection('contactPreferences')
      .doc(preferenceId(groupId))
      .set({
        'pinned': value,
        'type': 'group',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> markUnread(String groupId) => _db
      .collection('groups')
      .doc(groupId)
      .update({'unreadCounts.$_myId': 1});
}
