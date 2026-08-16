import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../chat/data/models/chat_user.dart';
import '../models/friend_request.dart';

class ContactService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get myId => _auth.currentUser!.uid;
  String pairId(String otherId) => ([myId, otherId]..sort()).join('_');

  Stream<List<ChatUser>> contacts() {
    late final StreamController<List<ChatUser>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subscription;
    Timer? refreshTimer;
    List<String> contactIds = const [];
    var loading = false;

    Future<void> refresh() async {
      if (loading || controller.isClosed) return;
      loading = true;
      try {
        final documents = await Future.wait(
          contactIds.map((id) => _db.collection('users').doc(id).get()),
        );
        final users =
            documents
                .where((document) => document.exists)
                .map(ChatUser.fromDoc)
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
        if (!controller.isClosed) controller.add(users);
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      } finally {
        loading = false;
      }
    }

    controller = StreamController<List<ChatUser>>(
      onListen: () {
        subscription = _db
            .collection('users')
            .doc(myId)
            .collection('contacts')
            .snapshots()
            .listen((snapshot) {
              contactIds = snapshot.docs
                  .map((document) => document.id)
                  .toList();
              refresh();
            }, onError: controller.addError);
        refreshTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => refresh(),
        );
      },
      onCancel: () async {
        refreshTimer?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<List<FriendRequest>> incomingRequests() => _db
      .collection('friendRequests')
      .where('memberIds', arrayContains: myId)
      .snapshots()
      .map((snapshot) {
        final requests = snapshot.docs
            .map(FriendRequest.fromDoc)
            .where(
              (request) =>
                  request.receiverId == myId && request.status == 'pending',
            )
            .toList();
        requests.sort(
          (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
            a.createdAt ?? DateTime(1970),
          ),
        );
        return requests;
      });

  Stream<String?> requestStatus(String otherId) => _db
      .collection('friendRequests')
      .where('memberIds', arrayContains: myId)
      .snapshots()
      .map((snapshot) {
        for (final document in snapshot.docs) {
          if (document.id == pairId(otherId)) {
            return document.data()['status'] as String?;
          }
        }
        return null;
      });

  Future<List<ChatUser>> search(String rawQuery) async {
    final query = rawQuery.trim().toLowerCase();
    if (query.length < 2) return const [];
    final results = <String, ChatUser>{};

    final username = await _db
        .collection('users')
        .where('usernameLower', isEqualTo: query.replaceFirst('@', ''))
        .limit(10)
        .get();
    for (final document in username.docs) {
      if (document.id != myId) {
        results[document.id] = ChatUser.fromDoc(document);
      }
    }

    final email = await _db
        .collection('users')
        .where('email', isEqualTo: query)
        .limit(10)
        .get();
    for (final document in email.docs) {
      if (document.id != myId) {
        results[document.id] = ChatUser.fromDoc(document);
      }
    }

    final names = await _db
        .collection('users')
        .orderBy('displayNameLower')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();
    for (final document in names.docs) {
      if (document.id != myId) {
        results[document.id] = ChatUser.fromDoc(document);
      }
    }
    return results.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<ChatUser?> user(String uid) async {
    final document = await _db.collection('users').doc(uid).get();
    return document.exists ? ChatUser.fromDoc(document) : null;
  }

  Future<void> sendRequest(String receiverId) async {
    if (receiverId == myId) throw StateError('You cannot add yourself.');
    final contact = await _db
        .collection('users')
        .doc(myId)
        .collection('contacts')
        .doc(receiverId)
        .get();
    if (contact.exists) throw StateError('This user is already a contact.');
    final reference = _db.collection('friendRequests').doc(pairId(receiverId));
    final existingRequests = await _db
        .collection('friendRequests')
        .where('memberIds', arrayContains: myId)
        .get();
    QueryDocumentSnapshot<Map<String, dynamic>>? existing;
    for (final document in existingRequests.docs) {
      if (document.id == pairId(receiverId)) {
        existing = document;
        break;
      }
    }
    if (existing != null) {
      final status = existing.data()['status'];
      if (status == 'pending') {
        throw StateError('A request is already pending.');
      }
      if (status == 'accepted') {
        throw StateError('This user is already a contact.');
      }
      throw StateError('This request was previously declined.');
    }
    await reference.set({
      'memberIds': [myId, receiverId]..sort(),
      'senderId': myId,
      'receiverId': receiverId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });
  }

  Future<void> accept(FriendRequest request) async {
    if (request.receiverId != myId) throw StateError('Invalid request.');
    final batch = _db.batch();
    final requestRef = _db.collection('friendRequests').doc(request.id);
    batch.update(requestRef, {
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _db
          .collection('users')
          .doc(myId)
          .collection('contacts')
          .doc(request.senderId),
      {
        'uid': request.senderId,
        'requestId': request.id,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(
      _db
          .collection('users')
          .doc(request.senderId)
          .collection('contacts')
          .doc(myId),
      {
        'uid': myId,
        'requestId': request.id,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  Future<void> reject(FriendRequest request) =>
      _db.collection('friendRequests').doc(request.id).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });
}
