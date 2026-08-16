import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UnreadService {
  UnreadService({FirebaseFirestore? database, FirebaseAuth? auth})
    : _database = database ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _database;
  final FirebaseAuth _auth;

  String get _userId => _auth.currentUser!.uid;

  Stream<int> totalUnread() {
    late StreamController<int> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? directSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? groupSubscription;
    var directUnread = 0;
    var groupUnread = 0;

    void emit() {
      if (!controller.isClosed) controller.add(directUnread + groupUnread);
    }

    controller = StreamController<int>(
      onListen: () {
        directSubscription = _database
            .collection('conversations')
            .where('memberIds', arrayContains: _userId)
            .snapshots()
            .listen((snapshot) {
              directUnread = snapshot.docs.fold<int>(0, (total, document) {
                final data = document.data();
                if (data['unreadFor'] != _userId) return total;
                return total + (data['unreadCount'] as num? ?? 0).toInt();
              });
              emit();
            }, onError: controller.addError);

        groupSubscription = _database
            .collection('groups')
            .where('memberIds', arrayContains: _userId)
            .snapshots()
            .listen((snapshot) {
              groupUnread = snapshot.docs.fold<int>(0, (total, document) {
                final counts = document.data()['unreadCounts'];
                if (counts is! Map) return total;
                return total + (counts[_userId] as num? ?? 0).toInt();
              });
              emit();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await directSubscription?.cancel();
        await groupSubscription?.cancel();
      },
    );
    return controller.stream;
  }
}
