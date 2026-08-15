import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../chat/presentation/pages/real_chat_room_page.dart';
import '../../../contacts/data/services/contact_detail_service.dart';
import '../../../groups/data/models/chat_group.dart';
import '../../../groups/data/services/group_recent_chat_service.dart';
import '../../../groups/data/services/group_service.dart';
import '../../../groups/presentation/pages/group_chat_room_page.dart';

class ArchivedChatsPage extends StatelessWidget {
  const ArchivedChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final groupService = GroupService();
    final detailService = ContactDetailService();
    final groupRecentChatService = GroupRecentChatService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F7FC),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Archived Chats',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: chatService.conversations(),
        builder: (context, chatSnapshot) => StreamBuilder<List<ChatGroup>>(
          stream: groupService.groups(),
          builder: (context, groupSnapshot) =>
              StreamBuilder<Map<String, Map<String, dynamic>>>(
            stream: detailService.allPreferences(),
            initialData: const {},
            builder: (context, preferenceSnapshot) {
              if (chatSnapshot.hasError || groupSnapshot.hasError) {
                return const _StateMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Unable to load archived chats',
                  subtitle: 'Check your connection and try again.',
                );
              }

              if (!chatSnapshot.hasData || !groupSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final preferences = preferenceSnapshot.data ?? const {};
              final items = <_ArchivedItem>[
                ...chatSnapshot.data!
                    .map(
                      (doc) => _ArchivedItem.direct(
                        doc,
                        chatService.myId,
                        preferences,
                      ),
                    )
                    .where((item) => item.archived),
                ...groupSnapshot.data!
                    .map(
                      (group) => _ArchivedItem.group(
                        group,
                        preferences,
                      ),
                    )
                    .where((item) => item.archived),
              ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              if (items.isEmpty) {
                return const _StateMessage(
                  icon: Icons.archive_outlined,
                  title: 'No archived chats',
                  subtitle:
                      'Chats you archive from Recent Chats will appear here.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = items[index];

                  if (item.group != null) {
                    return _ArchivedGroupTile(
                      group: item.group!,
                      onOpen: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GroupChatRoomPage(group: item.group!),
                        ),
                      ),
                      onUnarchive: () async {
                        await groupRecentChatService.setArchived(
                          item.group!.id,
                          false,
                        );
                        if (context.mounted) {
                          _showMessage(context, 'Group restored to Recent Chats');
                        }
                      },
                    );
                  }

                  final data = item.conversation!.data();
                  final memberIds =
                      List<String>.from(data['memberIds'] as List);
                  final otherId =
                      memberIds.firstWhere((id) => id != chatService.myId);

                  return FutureBuilder<ChatUser?>(
                    future: chatService.user(otherId),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      if (user == null) {
                        return const SizedBox.shrink();
                      }

                      return _ArchivedDirectTile(
                        user: user,
                        subtitle: data['lastMessage'] as String? ?? '',
                        onOpen: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RealChatRoomPage(user: user),
                          ),
                        ),
                        onUnarchive: () async {
                          await detailService.setPreference(
                            otherId,
                            'archived',
                            false,
                          );
                          if (context.mounted) {
                            _showMessage(
                              context,
                              'Chat restored to Recent Chats',
                            );
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _ArchivedDirectTile extends StatelessWidget {
  const _ArchivedDirectTile({
    required this.user,
    required this.subtitle,
    required this.onOpen,
    required this.onUnarchive,
  });

  final ChatUser user;
  final String subtitle;
  final VoidCallback onOpen;
  final Future<void> Function() onUnarchive;

  @override
  Widget build(BuildContext context) => _ArchivedCard(
        leading: _UserAvatar(user: user),
        title: user.name,
        subtitle: subtitle.isEmpty ? 'Archived conversation' : subtitle,
        onTap: onOpen,
        onUnarchive: onUnarchive,
      );
}

class _ArchivedGroupTile extends StatelessWidget {
  const _ArchivedGroupTile({
    required this.group,
    required this.onOpen,
    required this.onUnarchive,
  });

  final ChatGroup group;
  final VoidCallback onOpen;
  final Future<void> Function() onUnarchive;

  @override
  Widget build(BuildContext context) => _ArchivedCard(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFE5DAF5),
          backgroundImage:
              group.photoUrl == null ? null : NetworkImage(group.photoUrl!),
          child: group.photoUrl == null
              ? Text(
                  group.name.isEmpty ? '?' : group.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF65439B),
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        title: group.name,
        subtitle: group.lastMessage.isEmpty
            ? '${group.memberCount} members'
            : group.lastMessage,
        onTap: onOpen,
        onUnarchive: onUnarchive,
        isGroup: true,
      );
}

class _ArchivedCard extends StatelessWidget {
  const _ArchivedCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onUnarchive,
    this.isGroup = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Future<void> Function() onUnarchive;
  final bool isGroup;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          leading: leading,
          title: Row(
            children: [
              if (isGroup) ...[
                const Icon(
                  Icons.groups_rounded,
                  size: 15,
                  color: Color(0xFF805BB3),
                ),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: 'Unarchive',
            onPressed: () async => onUnarchive(),
            icon: const Icon(
              Icons.unarchive_outlined,
              color: Color(0xFF805BB3),
            ),
          ),
          onTap: onTap,
        ),
      );
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE5DAF5),
            backgroundImage:
                user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
            child: user.photoUrl == null
                ? Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF65439B),
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          if (user.isOnline)
            Positioned(
              right: 0,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF24C77A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0E9F8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: const Color(0xFF805BB3),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF756E7C),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ArchivedItem {
  const _ArchivedItem({
    this.conversation,
    this.group,
    required this.updatedAt,
    required this.archived,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>>? conversation;
  final ChatGroup? group;
  final DateTime updatedAt;
  final bool archived;

  factory _ArchivedItem.direct(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String myId,
    Map<String, Map<String, dynamic>> preferences,
  ) {
    final ids = List<String>.from(doc.data()['memberIds'] as List);
    final otherId = ids.firstWhere((id) => id != myId);

    return _ArchivedItem(
      conversation: doc,
      updatedAt:
          (doc.data()['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
      archived: preferences[otherId]?['archived'] as bool? ?? false,
    );
  }

  factory _ArchivedItem.group(
    ChatGroup group,
    Map<String, Map<String, dynamic>> preferences,
  ) =>
      _ArchivedItem(
        group: group,
        updatedAt: group.updatedAt ?? DateTime(1970),
        archived:
            preferences['group_${group.id}']?['archived'] as bool? ?? false,
      );
}
