import 'package:flutter/material.dart';

import '../../../contacts/data/services/contact_service.dart';
import '../../../groups/data/models/chat_group.dart';
import '../../../groups/data/services/group_service.dart';
import '../../data/models/chat_user.dart';
import '../../data/services/chat_service.dart';

class ForwardMessagePage extends StatefulWidget {
  const ForwardMessagePage({super.key, required this.messages});
  final List<Map<String, dynamic>> messages;

  @override
  State<ForwardMessagePage> createState() => _ForwardMessagePageState();
}

class _ForwardMessagePageState extends State<ForwardMessagePage> {
  final contacts = ContactService();
  final chat = ChatService();
  final groups = GroupService();
  String query = '';
  String? sendingTo;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F4F9),
        appBar: AppBar(title: const Text('Forward To', style: TextStyle(fontWeight: FontWeight.w800))),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                onChanged: (value) => setState(() => query = value.toLowerCase()),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search contacts'),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatUser>>(
                stream: contacts.contacts(),
                builder: (context, contactSnapshot) =>
                    StreamBuilder<List<ChatGroup>>(
                  stream: groups.groups(),
                  builder: (context, groupSnapshot) {
                  if (!contactSnapshot.hasData || !groupSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = contactSnapshot.data!
                      .where((user) => user.name.toLowerCase().contains(query))
                      .toList();
                  final groupItems = groupSnapshot.data!
                      .where((group) => group.name.toLowerCase().contains(query))
                      .toList();
                  return ListView(
                    children: [
                      if (users.isNotEmpty) const _SectionLabel('Contacts'),
                      ...users.map((user) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE9DDF8),
                          backgroundImage: user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
                          child: user.photoUrl == null ? Text(user.name[0].toUpperCase()) : null,
                        ),
                        title: Text(user.name),
                        trailing: sendingTo == user.uid
                            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded, color: Color(0xFF9C7AC8)),
                        onTap: sendingTo == null ? () => _forwardUser(user) : null,
                      )),
                      if (groupItems.isNotEmpty) const _SectionLabel('Groups'),
                      ...groupItems.map((group) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE9DDF8),
                          backgroundImage: group.photoUrl == null ? null : NetworkImage(group.photoUrl!),
                          child: group.photoUrl == null ? const Icon(Icons.groups_rounded) : null,
                        ),
                        title: Text(group.name),
                        subtitle: Text('${group.memberCount} members'),
                        trailing: sendingTo == 'group:${group.id}'
                            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded, color: Color(0xFF9C7AC8)),
                        onTap: sendingTo == null ? () => _forwardGroup(group) : null,
                      )),
                    ],
                  );
                },
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _forwardUser(ChatUser user) async {
    setState(() => sendingTo = user.uid);
    try {
      for (final message in widget.messages) {
        await chat.forward(user.uid, message);
      }
      if (!mounted) return;
      Navigator.pop(context, user.name);
    } catch (_) {
      if (mounted) {
        setState(() => sendingTo = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forward failed')));
      }
    }
  }

  Future<void> _forwardGroup(ChatGroup group) async {
    setState(() => sendingTo = 'group:${group.id}');
    try {
      for (final message in widget.messages) {
        await groups.forward(group, message);
      }
      if (!mounted) return;
      Navigator.pop(context, group.name);
    } catch (_) {
      if (mounted) {
        setState(() => sendingTo = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forward failed')));
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF7653A5), fontWeight: FontWeight.w800),
        ),
      );
}
