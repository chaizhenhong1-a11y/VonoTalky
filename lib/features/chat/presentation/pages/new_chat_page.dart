import 'package:flutter/material.dart';

import '../../data/models/chat_user.dart';
import '../../../contacts/data/services/contact_service.dart';
import 'real_chat_room_page.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});
  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  String query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New message')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            onChanged: (v) => setState(() => query = v.toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'Search people',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatUser>>(
            stream: ContactService().contacts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = snapshot.data!
                  .where(
                    (u) =>
                        u.name.toLowerCase().contains(query) ||
                        u.email.toLowerCase().contains(query),
                  )
                  .toList();
              if (users.isEmpty) {
                return const Center(child: Text('No users found'));
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final user = users[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name[0].toUpperCase()),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RealChatRoomPage(user: user),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
