import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/navigation/app_navigator.dart';
import '../../../../firebase_options.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../chat/presentation/pages/real_chat_room_page.dart';
import '../../../groups/data/services/group_service.dart';
import '../../../groups/presentation/pages/group_chat_room_page.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final messaging = FirebaseMessaging.instance;
  final auth = FirebaseAuth.instance;
  final database = FirebaseFirestore.instance;
  StreamSubscription<User?>? authSubscription;
  StreamSubscription<String>? tokenSubscription;
  StreamSubscription<RemoteMessage>? foregroundSubscription;
  StreamSubscription<RemoteMessage>? openedSubscription;
  String? currentToken;
  String? boundUserId;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    foregroundSubscription = FirebaseMessaging.onMessage.listen(_showInAppBanner);
    openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
    tokenSubscription = messaging.onTokenRefresh.listen(_saveToken);
    authSubscription = auth.authStateChanges().listen(_bindUser);
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      Future<void>.delayed(const Duration(milliseconds: 1200), () => _openMessage(initialMessage));
    }
  }

  Future<void> _bindUser(User? user) async {
    if (boundUserId != null && currentToken != null && boundUserId != user?.uid) {
      await _deviceReference(boundUserId!, currentToken!).delete().catchError((_) {});
    }
    boundUserId = user?.uid;
    if (user == null) return;
    final token = await messaging.getToken();
    if (token != null) await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    currentToken = token;
    final userId = auth.currentUser?.uid;
    if (userId == null) return;
    boundUserId = userId;
    await _deviceReference(userId, token).set({
      'token': token,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'enabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _deviceReference(
    String userId,
    String token,
  ) {
    final deviceId = token.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return database.collection('users').doc(userId).collection('devices').doc(deviceId);
  }

  void _showInAppBanner(RemoteMessage message) {
    final context = AppNavigator.key.currentContext;
    if (context == null) return;
    final title = message.notification?.title ?? message.data['title'] ?? 'New message';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE5DAF5),
          child: Icon(Icons.message_rounded, color: Color(0xFF65439B)),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (body.isNotEmpty) Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              _openMessage(message);
            },
            child: const Text('Open'),
          ),
          IconButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
    Timer(const Duration(seconds: 5), messenger.hideCurrentMaterialBanner);
  }

  Future<void> _openMessage(RemoteMessage message) async {
    final navigator = AppNavigator.key.currentState;
    if (navigator == null || auth.currentUser == null) return;
    final type = message.data['type'];
    if (type == 'direct') {
      final senderId = message.data['senderId'];
      if (senderId == null) return;
      final user = await ChatService().user(senderId);
      if (user != null) {
        navigator.push(MaterialPageRoute(builder: (_) => RealChatRoomPage(user: user)));
      }
    }
    if (type == 'group') {
      final groupId = message.data['groupId'];
      if (groupId == null) return;
      final group = await GroupService().group(groupId).first;
      if (group != null) {
        navigator.push(MaterialPageRoute(builder: (_) => GroupChatRoomPage(group: group)));
      }
    }
  }
}
