import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../../chat/presentation/pages/real_chat_room_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../data/models/friend_request.dart';
import '../../data/services/contact_service.dart';
import 'add_contact_page.dart';
import 'contact_detail_page.dart';
import 'friend_requests_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final contactService = ContactService();
  String query = '';
  String? selectedLetter;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF9F7FC),
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [Color(0xFFF8DCEB), Color(0xFFEBDDF5), Color(0xFFDCCFF3)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 10, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'VonoTalky',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5F3792),
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  _RequestButton(
                    service: contactService,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FriendRequestsPage()),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _notice('Use the search bar below.'),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: TextField(
                onChanged: (value) => setState(() {
                  query = value.trim().toLowerCase();
                  selectedLetter = null;
                }),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: const Icon(Icons.mic_none_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F7FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: StreamBuilder<List<ChatUser>>(
                  stream: contactService.contacts(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Unable to load contacts'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users =
                        snapshot.data!.where((user) {
                          final matchesQuery =
                              query.isEmpty ||
                              user.name.toLowerCase().contains(query) ||
                              user.email.toLowerCase().contains(query);
                          final matchesLetter =
                              selectedLetter == null ||
                              user.name.toUpperCase().startsWith(
                                selectedLetter!,
                              );
                          return matchesQuery && matchesLetter;
                        }).toList()..sort(
                          (a, b) => a.name.toLowerCase().compareTo(
                            b.name.toLowerCase(),
                          ),
                        );
                    if (users.isEmpty) {
                      return const Center(child: Text('No contacts yet'));
                    }
                    return Stack(
                      children: [
                        ListView.separated(
                          padding: const EdgeInsets.fromLTRB(10, 8, 27, 92),
                          itemCount: users.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            indent: 62,
                            color: Color(0xFFE8E3EC),
                          ),
                          itemBuilder: (_, index) => _ContactTile(
                            user: users[index],
                            onOpenDetails: () => _openDetails(users[index]),
                            onMessage: () => _openChat(users[index]),
                            onVoiceCall: () =>
                                _notice('Voice call is coming next.'),
                            onVideoCall: () =>
                                _notice('Video call is coming next.'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _AlphabetIndex(
                            selected: selectedLetter,
                            onSelected: (letter) => setState(() {
                              selectedLetter = selectedLetter == letter
                                  ? null
                                  : letter;
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      heroTag: null,
      backgroundColor: const Color(0xFF805BB3),
      foregroundColor: Colors.white,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddContactPage()),
      ),
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
      label: const Text('Add Contact'),
    ),
    bottomNavigationBar: widget.embedded
        ? null
        : NavigationBar(
            height: 66,
            selectedIndex: 1,
            onDestinationSelected: (index) {
              if (index == 0) Navigator.pop(context);
              if (index == 2) _notice('Groups are coming next.');
              if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                label: 'Chats',
              ),
              NavigationDestination(
                icon: Icon(Icons.badge_rounded),
                label: 'Contacts',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                label: 'Groups',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Profile',
              ),
            ],
          ),
  );

  void _openChat(ChatUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RealChatRoomPage(user: user)),
    );
  }

  void _openDetails(ChatUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ContactDetailPage(user: user, onMessage: () => _openChat(user)),
      ),
    );
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _RequestButton extends StatelessWidget {
  const _RequestButton({required this.service, required this.onTap});
  final ContactService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<FriendRequest>>(
    stream: service.incomingRequests(),
    builder: (context, snapshot) {
      final count = snapshot.data?.length ?? 0;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          if (count > 0)
            Positioned(
              right: 5,
              top: 3,
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
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.user,
    required this.onOpenDetails,
    required this.onMessage,
    required this.onVoiceCall,
    required this.onVideoCall,
  });
  final ChatUser user;
  final VoidCallback onOpenDetails;
  final VoidCallback onMessage;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: 5,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    leading: CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFFE5DAF5),
      backgroundImage: user.photoUrl == null
          ? null
          : NetworkImage(user.photoUrl!),
      child: user.photoUrl == null
          ? Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF65439B),
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    ),
    title: Text(
      user.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    subtitle: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: user.isOnline
                ? const Color(0xFF24C77A)
                : const Color(0xFFE1A43A),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          user.isOnline ? 'Available' : 'Offline',
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(icon: Icons.chat_bubble_rounded, onTap: onMessage),
        _ActionIcon(icon: Icons.call_rounded, onTap: onVoiceCall),
        _ActionIcon(icon: Icons.videocam_rounded, onTap: onVideoCall),
      ],
    ),
    onTap: onOpenDetails,
  );
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 34, minHeight: 38),
    onPressed: onTap,
    icon: Icon(icon, size: 19, color: const Color(0xFF805BB3)),
  );
}

class _AlphabetIndex extends StatelessWidget {
  const _AlphabetIndex({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String> onSelected;

  static const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4, top: 6, bottom: 80),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: letters
          .split('')
          .map(
            (letter) => GestureDetector(
              onTap: () => onSelected(letter),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 9,
                  height: 1,
                  fontWeight: selected == letter
                      ? FontWeight.w900
                      : FontWeight.w500,
                  color: selected == letter
                      ? const Color(0xFF5F3792)
                      : const Color(0xFF716A78),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
