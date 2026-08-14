import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Timer? _heartbeatTimer;

  Future<void> start() async {
    _heartbeatTimer?.cancel();
    await setOnline(true);
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setOnline(true),
    );
  }

  Future<void> stop({bool markOffline = true}) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (markOffline) await setOnline(false);
  }

  Future<void> setOnline(bool online) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'isOnline': online,
      'presenceUpdatedAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
