import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_user.dart';
import '../models/message_reply.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get myId => _auth.currentUser!.uid;
  String roomId(String otherId) => ([myId, otherId]..sort()).join('_');

  Stream<List<ChatUser>> users() => _db
      .collection('users')
      .snapshots()
      .map(
        (event) => event.docs
            .where((doc) => doc.id != myId)
            .map(ChatUser.fromDoc)
            .toList(),
      );

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> conversations() {
    return _db
        .collection('conversations')
        .where('memberIds', arrayContains: myId)
        .snapshots()
        .map((event) {
          final docs = event.docs.toList();
          docs.sort((a, b) {
            final x = a.data()['updatedAt'] as Timestamp?;
            final y = b.data()['updatedAt'] as Timestamp?;
            return (y?.millisecondsSinceEpoch ?? 0).compareTo(
              x?.millisecondsSinceEpoch ?? 0,
            );
          });
          return docs;
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String otherId) => _db
      .collection('conversations')
      .doc(roomId(otherId))
      .collection('messages')
      .orderBy('sentAt', descending: true)
      .limit(100)
      .snapshots();

  Stream<bool> typing(String otherId) => _db
      .collection('conversations')
      .doc(roomId(otherId))
      .collection('typing')
      .doc(otherId)
      .snapshots()
      .map((doc) => doc.data()?['isTyping'] as bool? ?? false);

  Future<ChatUser?> user(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? ChatUser.fromDoc(doc) : null;
  }

  Future<void> send(String otherId, String text, {MessageReply? reply}) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final members = [myId, otherId]..sort();
    final conversation = _db.collection('conversations').doc(roomId(otherId));
    final message = conversation.collection('messages').doc();
    final batch = _db.batch();
    batch.set(conversation, {
      'memberIds': members,
      'lastMessage': value,
      'lastSenderId': myId,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadFor': otherId,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(message, {
      'senderId': myId,
      'receiverId': otherId,
      'text': value,
      'sentAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'isDeleted': false,
      if (reply != null) 'replyTo': reply.toMap(),
    });
    await batch.commit();
  }

  Future<void> ensureConversation(String otherId) async {
    final members = [myId, otherId]..sort();
    await _db.collection('conversations').doc(roomId(otherId)).set({
      'memberIds': members,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendImage({
    required String otherId,
    required String imageUrl,
    required String storagePath,
    MessageReply? reply,
  }) async {
    final members = [myId, otherId]..sort();
    final conversation = _db.collection('conversations').doc(roomId(otherId));
    final message = conversation.collection('messages').doc();
    final batch = _db.batch();
    batch.set(conversation, {
      'memberIds': members,
      'lastMessage': '📷 Photo',
      'lastSenderId': myId,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadFor': otherId,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(message, {
      'senderId': myId,
      'receiverId': otherId,
      'text': '',
      'type': 'image',
      'imageUrl': imageUrl,
      'storagePath': storagePath,
      'sentAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'isDeleted': false,
      if (reply != null) 'replyTo': reply.toMap(),
    });
    await batch.commit();
  }

  Future<void> sendVoice({
    required String otherId,
    required String audioUrl,
    required String storagePath,
    required int durationMs,
    MessageReply? reply,
  }) async {
    final members = [myId, otherId]..sort();
    final conversation = _db.collection('conversations').doc(roomId(otherId));
    final message = conversation.collection('messages').doc();
    final batch = _db.batch();
    batch.set(conversation, {
      'memberIds': members,
      'lastMessage': '🎤 Voice message',
      'lastSenderId': myId,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadFor': otherId,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(message, {
      'senderId': myId,
      'receiverId': otherId,
      'text': '',
      'type': 'voice',
      'audioUrl': audioUrl,
      'storagePath': storagePath,
      'durationMs': durationMs,
      'sentAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'isDeleted': false,
      if (reply != null) 'replyTo': reply.toMap(),
    });
    await batch.commit();
  }

  Future<void> sendFile({
    required String otherId,
    required String fileUrl,
    required String storagePath,
    required String fileName,
    required String extension,
    required int fileSize,
    MessageReply? reply,
  }) async {
    final members = [myId, otherId]..sort();
    final conversation = _db.collection('conversations').doc(roomId(otherId));
    final message = conversation.collection('messages').doc();
    final batch = _db.batch();
    batch.set(conversation, {
      'memberIds': members,
      'lastMessage': '📎 $fileName',
      'lastSenderId': myId,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadFor': otherId,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(message, {
      'senderId': myId,
      'receiverId': otherId,
      'text': '',
      'type': 'file',
      'fileUrl': fileUrl,
      'storagePath': storagePath,
      'fileName': fileName,
      'fileExtension': extension,
      'fileSize': fileSize,
      'sentAt': FieldValue.serverTimestamp(),
      'readAt': null,
      'isDeleted': false,
      if (reply != null) 'replyTo': reply.toMap(),
    });
    await batch.commit();
  }

  Future<void> setTyping(String otherId, bool value) => _db
      .collection('conversations')
      .doc(roomId(otherId))
      .collection('typing')
      .doc(myId)
      .set({
        'uid': myId,
        'isTyping': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> markRead(String otherId) async {
    final conversation = _db.collection('conversations').doc(roomId(otherId));
    final conversationData = await conversation.get();
    if (conversationData.data()?['unreadFor'] == myId) {
      await conversation.update({'unreadFor': null, 'unreadCount': 0});
    }
    final snapshot = await conversation
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(100)
        .get();
    final unread = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['receiverId'] == myId && data['readAt'] == null;
    });
    final batch = _db.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  Future<void> markUnread(String otherId) async {
    final conversation = _db.collection('conversations').doc(roomId(otherId));
    await conversation.update({'unreadFor': myId, 'unreadCount': 1});
  }

  Future<void> recall(String otherId, String messageId) => _db
      .collection('conversations')
      .doc(roomId(otherId))
      .collection('messages')
      .doc(messageId)
      .update({'text': '', 'isDeleted': true});

  Future<void> forward(String otherId, Map<String, dynamic> source) async {
    final type = source['type'] as String? ?? 'text';
    if (type == 'image') {
      return sendImage(
        otherId: otherId,
        imageUrl: source['imageUrl'] as String,
        storagePath: source['storagePath'] as String? ?? '',
      );
    }
    if (type == 'voice') {
      return sendVoice(
        otherId: otherId,
        audioUrl: source['audioUrl'] as String,
        storagePath: source['storagePath'] as String? ?? '',
        durationMs: (source['durationMs'] as num? ?? 0).toInt(),
      );
    }
    if (type == 'file') {
      return sendFile(
        otherId: otherId,
        fileUrl: source['fileUrl'] as String,
        storagePath: source['storagePath'] as String? ?? '',
        fileName: source['fileName'] as String? ?? 'File',
        extension: source['fileExtension'] as String? ?? '',
        fileSize: (source['fileSize'] as num? ?? 0).toInt(),
      );
    }
    return send(otherId, source['text'] as String? ?? '');
  }

  Future<void> editMessage(String otherId, String messageId, String text) => _db
      .collection('conversations')
      .doc(roomId(otherId))
      .collection('messages')
      .doc(messageId)
      .update({'text': text.trim(), 'editedAt': FieldValue.serverTimestamp()});

  Future<void> toggleReaction(
    String otherId,
    String messageId,
    String emoji,
  ) async {
    final reference = _db
        .collection('conversations')
        .doc(roomId(otherId))
        .collection('messages')
        .doc(messageId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data() ?? <String, dynamic>{};
      final reactions = Map<String, dynamic>.from(
        data['reactions'] as Map? ?? {},
      );
      final users = List<String>.from(reactions[emoji] as List? ?? const []);
      users.contains(myId) ? users.remove(myId) : users.add(myId);
      if (users.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = users;
      }
      transaction.update(reference, {'reactions': reactions});
    });
  }

  Future<void> hideForMe(String otherId, Iterable<String> messageIds) async {
    final batch = _db.batch();
    final messages = _db
        .collection('conversations')
        .doc(roomId(otherId))
        .collection('messages');
    for (final messageId in messageIds) {
      batch.update(messages.doc(messageId), {
        'hiddenFor': FieldValue.arrayUnion([myId]),
      });
    }
    await batch.commit();
  }

  Future<void> clearForMe(String otherId) async {
    final snapshot = await _db
        .collection('conversations')
        .doc(roomId(otherId))
        .collection('messages')
        .get();
    const batchSize = 400;
    for (var start = 0; start < snapshot.docs.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, snapshot.docs.length).toInt();
      final batch = _db.batch();
      for (final document in snapshot.docs.sublist(start, end)) {
        batch.update(document.reference, {
          'hiddenFor': FieldValue.arrayUnion([myId]),
        });
      }
      await batch.commit();
    }
  }
}
