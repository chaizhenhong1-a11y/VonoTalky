import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../../chat/presentation/pages/real_chat_room_page.dart';
import '../../../contacts/presentation/pages/contacts_page.dart';
import '../../../home/data/services/unread_service.dart';
import '../../../home/presentation/pages/chat_home_page.dart';
import '../../../pet/presentation/pages/pet_home_page.dart';
import '../../../pet/presentation/pages/shared_pet_detail_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../presence/data/services/presence_service.dart';
import '../../../pet/data/services/pet_notification_service.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage>
    with WidgetsBindingObserver {
  int selectedIndex = 0;
  final presence = PresenceService();
  final petNotifications = PetNotificationService();
  StreamSubscription<RemoteMessage>? notificationOpenSubscription;
  late final Stream<int> unreadStream = UnreadService().totalUnread();

  late final pages = <Widget>[
    const ChatHomePage(embedded: true),
    const ContactsPage(embedded: true),
    const PetHomePage(),
    ProfilePage(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    presence.start();
    petNotifications.initialize();
    notificationOpenSubscription = petNotifications.openedMessages.listen(
      _openNotificationTarget,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      presence.start();
    } else {
      presence.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    presence.stop();
    notificationOpenSubscription?.cancel();
    petNotifications.dispose();
    super.dispose();
  }

  Future<void> _openNotificationTarget(RemoteMessage message) async {
    if (!mounted) return;

    final data = message.data;
    final type = data['type'];

    if (type == 'direct_message') {
      await _openDirectMessageNotification(data);
      return;
    }

    final petId = data['petId'];
    if (type == 'care_request' && petId is String && petId.isNotEmpty) {
      setState(() => selectedIndex = 2);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SharedPetDetailPage(petId: petId),
        ),
      );
      return;
    }

    if (type == 'pet_invite') {
      // A new invite does not have a shared pet yet. Pet Center already
      // contains the real-time invitation inbox, so route there.
      setState(() => selectedIndex = 2);
    }
  }

  Future<void> _openDirectMessageNotification(Map<String, dynamic> data) async {
    final friendId = data['friendId'];

    // Always land on Chats if the payload is incomplete or the profile
    // cannot be resolved.
    setState(() => selectedIndex = 0);

    if (friendId is! String || friendId.isEmpty) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();

      if (!mounted || !snapshot.exists) {
        return;
      }

      final friend = ChatUser.fromDoc(snapshot);

      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => RealChatRoomPage(user: friend)),
      );
    } catch (_) {
      // The Chats tab is already visible as a safe fallback.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: selectedIndex, children: pages),
    bottomNavigationBar: StreamBuilder<int>(
      stream: unreadStream,
      initialData: 0,
      builder: (context, snapshot) => NavigationBar(
        height: 66,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: _UnreadIcon(
              icon: Icons.home_outlined,
              unread: snapshot.data ?? 0,
            ),
            selectedIcon: _UnreadIcon(
              icon: Icons.home_rounded,
              unread: snapshot.data ?? 0,
            ),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded),
            label: 'Contacts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded),
            label: 'Pet',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}

class _UnreadIcon extends StatelessWidget {
  const _UnreadIcon({required this.icon, required this.unread});

  final IconData icon;
  final int unread;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(icon),
      if (unread > 0)
        Positioned(
          top: -7,
          right: -11,
          child: Container(
            constraints: const BoxConstraints(minWidth: 17),
            height: 17,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE34B62),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              unread > 99 ? '99+' : '$unread',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
    ],
  );
}
