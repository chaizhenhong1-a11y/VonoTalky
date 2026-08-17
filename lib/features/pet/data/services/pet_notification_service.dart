import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PetNotificationService {
  PetNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  static bool _initialized = false;

  static final StreamController<RemoteMessage> _foregroundMessages =
      StreamController<RemoteMessage>.broadcast();
  static final StreamController<RemoteMessage> _openedMessages =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;
  Stream<RemoteMessage> get openedMessages => _openedMessages.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final user = _auth.currentUser;
    if (user == null) {
      _initialized = false;
      return;
    }

    await _requestPermission();
    await _syncToken(user.uid);

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      await _saveToken(user.uid, token);
    });

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedAppMessage,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedAppMessage(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
  }

  Future<void> _syncToken(String userId) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _saveToken(userId, token);
  }

  Future<void> _saveToken(String userId, String token) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(_deviceDocumentId(token))
        .set({
          'fcmToken': token,
          'platform': _platformLabel(),
          'notificationsEnabled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> setActiveConversation(String conversationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(_deviceDocumentId(token))
        .set({
          'activeConversationId': conversationId,
          'activeConversationUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> clearActiveConversation(String conversationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    final reference = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(_deviceDocumentId(token));

    final snapshot = await reference.get();
    if (!snapshot.exists) return;

    final current = snapshot.data()?['activeConversationId'];
    if (current != conversationId) return;

    await reference.set({
      'activeConversationId': FieldValue.delete(),
      'activeConversationUpdatedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> disableCurrentToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(_deviceDocumentId(token))
        .set({
          'notificationsEnabled': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == null) return;
    _foregroundMessages.add(message);
  }

  void _handleOpenedAppMessage(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == null) return;
    _openedMessages.add(message);
  }

  String _deviceDocumentId(String token) {
    // Firestore document IDs cannot contain '/'.
    return token.replaceAll('/', '_');
  }

  String _platformLabel() {
    // Keep the foundation dependency-light. Cloud Functions only need
    // a descriptive value here; exact OS detection is not security-critical.
    return 'flutter';
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _initialized = false;
  }
}
