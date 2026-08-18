import 'package:flutter/material.dart';

import '../../data/services/chat_service.dart';
import '../../data/models/chat_user.dart';
import 'shared_media_page.dart';

class SharedMediaDirectoryPage extends StatelessWidget {
  SharedMediaDirectoryPage({super.key});

  final ChatService service = ChatService();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Shared Media',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: StreamBuilder(
      stream: service.conversations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversations = snapshot.data!;
        if (conversations.isEmpty) {
          return const Center(
            child: Text('No conversations with shared content yet'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: conversations.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = conversations[index].data();
            final members = List<String>.from(
              data['memberIds'] as List? ?? const <String>[],
            );
            final otherId = members.firstWhere(
              (id) => id != service.myId,
              orElse: () => '',
            );

            if (otherId.isEmpty) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<ChatUser?>(
              future: service.user(otherId),
              builder: (context, userSnapshot) {
                final user = userSnapshot.data;
                final name = user?.name ?? 'Conversation';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .10),
                    backgroundImage: user?.photoUrl == null
                        ? null
                        : NetworkImage(user!.photoUrl!),
                    child: user?.photoUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Photos, files and voice messages'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SharedMediaPage(otherId: otherId),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ),
  );
}
