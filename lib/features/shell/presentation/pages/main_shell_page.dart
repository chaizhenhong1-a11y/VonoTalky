import 'package:flutter/material.dart';

import '../../../contacts/presentation/pages/contacts_page.dart';
import '../../../groups/presentation/pages/groups_page.dart';
import '../../../home/data/services/unread_service.dart';
import '../../../home/presentation/pages/chat_home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../presence/data/services/presence_service.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage>
    with WidgetsBindingObserver {
  int selectedIndex = 0;
  final presence = PresenceService();
  late final Stream<int> unreadStream = UnreadService().totalUnread();

  late final pages = <Widget>[
    const ChatHomePage(embedded: true),
    const ContactsPage(embedded: true),
    const GroupsPage(),
    ProfilePage(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    presence.start();
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
    super.dispose();
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
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Groups',
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
