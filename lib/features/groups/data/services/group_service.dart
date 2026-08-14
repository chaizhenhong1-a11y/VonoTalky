import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../../chat/data/models/message_reply.dart';
import '../models/chat_group.dart';

class GroupService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String get myId {
    final uid = _auth.currentUser!.uid;
    GroupServiceIdentity.currentUid = uid;
    return uid;
  }

  Stream<List<ChatGroup>> groups() => _db.collection('groups').where('memberIds', arrayContains: myId).snapshots().map((snapshot) {
        final groups = snapshot.docs.map(ChatGroup.fromDoc).toList();
        groups.sort((a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(a.updatedAt ?? DateTime(1970)));
        return groups;
      });

  Stream<ChatGroup?> group(String groupId) => _db
      .collection('groups')
      .doc(groupId)
      .snapshots()
      .map((document) => document.exists ? ChatGroup.fromDoc(document) : null);

  Future<List<ChatUser>> memberUsers(Iterable<String> ids) async {
    final documents = await Future.wait(
      ids.map((uid) => _db.collection('users').doc(uid).get()),
    );
    return documents.where((doc) => doc.exists).map(ChatUser.fromDoc).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> updateDetails(String groupId, String name, String description) =>
      _db.collection('groups').doc(groupId).update({
        'name': name.trim(),
        'description': description.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<String?> pickAndUploadAvatar(String groupId) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) throw Exception('Image is over 8 MB.');
    final reference = FirebaseStorage.instance.ref('group_avatars/$groupId/avatar.jpg');
    await reference.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await reference.getDownloadURL();
    await _db.collection('groups').doc(groupId).update({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  Future<void> addMembers(String groupId, Iterable<String> userIds) async {
    final ids = userIds.toSet();
    if (ids.isEmpty) return;
    await _db.runTransaction((transaction) async {
      final reference = _db.collection('groups').doc(groupId);
      final snapshot = await transaction.get(reference);
      final data = snapshot.data()!;
      final members = <String>{...List<String>.from(data['memberIds'] as List), ...ids}.toList()..sort();
      final update = <String, dynamic>{'memberIds': members, 'memberCount': members.length, 'updatedAt': FieldValue.serverTimestamp()};
      for (final uid in ids) update['unreadCounts.$uid'] = 0;
      transaction.update(reference, update);
    });
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
      'unreadCounts.$userId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAdmin(String groupId, String userId, bool enabled) =>
      _db.collection('groups').doc(groupId).update({
        'adminIds': enabled ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> transferOwnership(String groupId, String newOwnerId) =>
      _db.collection('groups').doc(groupId).update({
        'ownerId': newOwnerId,
        'adminIds': FieldValue.arrayUnion([newOwnerId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> leaveGroup(String groupId) => removeMember(groupId, myId);
  Future<void> deleteGroup(String groupId) => _db.collection('groups').doc(groupId).delete();

  Future<String> createGroup({required String name, required String description, required Iterable<String> selectedMemberIds}) async {
    final cleanName = name.trim();
    if (cleanName.length < 2) throw ArgumentError('Group name must contain at least 2 characters.');
    final members = <String>{myId, ...selectedMemberIds}.toList()..sort();
    if (members.length < 2) throw ArgumentError('Select at least one group member.');
    final group = _db.collection('groups').doc();
    await group.set({
      'name': cleanName,
      'description': description.trim(),
      'photoUrl': null,
      'ownerId': myId,
      'adminIds': [myId],
      'memberIds': members,
      'memberCount': members.length,
      'lastMessage': 'Group created',
      'lastSenderId': myId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts': {for (final uid in members) uid: 0},
    });
    return group.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String groupId) => _db
      .collection('groups')
      .doc(groupId)
      .collection('messages')
      .orderBy('sentAt', descending: true)
      .limit(100)
      .snapshots();

  Future<void> sendText(ChatGroup group, String text, {MessageReply? reply}) => _send(
        group: group,
        type: 'text',
        preview: text.trim(),
        payload: {'text': text.trim()},
        reply: reply,
      );

  Future<void> sendImage(ChatGroup group, String url, String path, {MessageReply? reply}) => _send(
        group: group,
        type: 'image',
        preview: '📷 Photo',
        payload: {'imageUrl': url, 'storagePath': path},
        reply: reply,
      );

  Future<void> sendFile(ChatGroup group, {required String url, required String path, required String name, required String extension, required int size, MessageReply? reply}) => _send(
        group: group,
        type: 'file',
        preview: '📎 $name',
        payload: {'fileUrl': url, 'storagePath': path, 'fileName': name, 'fileExtension': extension, 'fileSize': size},
        reply: reply,
      );

  Future<void> sendVoice(ChatGroup group, {required String url, required String path, required int durationMs, MessageReply? reply}) => _send(
        group: group,
        type: 'voice',
        preview: '🎤 Voice message',
        payload: {'audioUrl': url, 'storagePath': path, 'durationMs': durationMs},
        reply: reply,
      );

  Future<void> _send({required ChatGroup group, required String type, required String preview, required Map<String, dynamic> payload, MessageReply? reply}) async {
    if (preview.isEmpty) return;
    final user = await _db.collection('users').doc(myId).get();
    final senderName = user.data()?['displayName'] as String? ?? 'VonoTalky user';
    final senderPhotoUrl = user.data()?['photoUrl'] as String?;
    final reference = _db.collection('groups').doc(group.id);
    final message = reference.collection('messages').doc();
    final batch = _db.batch();
    final update = <String, dynamic>{
      'lastMessage': preview,
      'lastSenderId': myId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    for (final uid in group.memberIds) {
      update['unreadCounts.$uid'] = uid == myId ? 0 : FieldValue.increment(1);
    }
    batch.update(reference, update);
    batch.set(message, {
      'senderId': myId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type,
      ...payload,
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [myId],
      'isDeleted': false,
      if (reply != null) 'replyTo': reply.toMap(),
    });
    await batch.commit();
  }

  Future<void> markRead(String groupId) async {
    final group = _db.collection('groups').doc(groupId);
    await group.update({'unreadCounts.$myId': 0});
    final snapshot = await group.collection('messages').orderBy('sentAt', descending: true).limit(100).get();
    final batch = _db.batch();
    for (final message in snapshot.docs) {
      final readBy = List<String>.from(message.data()['readBy'] as List? ?? const []);
      if (!readBy.contains(myId)) batch.update(message.reference, {'readBy': FieldValue.arrayUnion([myId])});
    }
    await batch.commit();
  }

  Future<void> recall(String groupId, String messageId) => _db
      .collection('groups')
      .doc(groupId)
      .collection('messages')
      .doc(messageId)
      .update({'text': '', 'isDeleted': true});

  Future<void> forward(ChatGroup group, Map<String, dynamic> source) {
    final type = source['type'] as String? ?? 'text';
    if (type == 'image') {
      return sendImage(
        group,
        source['imageUrl'] as String,
        source['storagePath'] as String? ?? '',
      );
    }
    if (type == 'voice') {
      return sendVoice(
        group,
        url: source['audioUrl'] as String,
        path: source['storagePath'] as String? ?? '',
        durationMs: (source['durationMs'] as num? ?? 0).toInt(),
      );
    }
    if (type == 'file') {
      return sendFile(
        group,
        url: source['fileUrl'] as String,
        path: source['storagePath'] as String? ?? '',
        name: source['fileName'] as String? ?? 'File',
        extension: source['fileExtension'] as String? ?? '',
        size: (source['fileSize'] as num? ?? 0).toInt(),
      );
    }
    return sendText(group, source['text'] as String? ?? '');
  }
}
