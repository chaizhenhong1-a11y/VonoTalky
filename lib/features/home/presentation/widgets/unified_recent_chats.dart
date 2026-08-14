import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../chat/presentation/pages/real_chat_room_page.dart';
import '../../../contacts/data/services/contact_detail_service.dart';
import '../../../groups/data/models/chat_group.dart';
import '../../../groups/data/services/group_service.dart';
import '../../../groups/presentation/pages/group_chat_room_page.dart';

class UnifiedRecentChats extends StatelessWidget {
  const UnifiedRecentChats({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final groupService = GroupService();
    final detailService = ContactDetailService();
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: chatService.conversations(),
      builder: (context, chatSnapshot) => StreamBuilder<List<ChatGroup>>(
        stream: groupService.groups(),
        builder: (context, groupSnapshot) =>
            StreamBuilder<Map<String, Map<String, dynamic>>>(
          stream: detailService.allPreferences(),
          initialData: const {},
          builder: (context, preferenceSnapshot) {
          if (chatSnapshot.hasError || groupSnapshot.hasError) {
            return const _EmptyState(icon: Icons.cloud_off_rounded, text: 'Unable to load conversations');
          }
          if (!chatSnapshot.hasData || !groupSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = <_ThreadItem>[
            ...chatSnapshot.data!.map(
              (document) => _ThreadItem.direct(
                document,
                chatService.myId,
                preferenceSnapshot.data ?? const {},
              ),
            ),
            ...groupSnapshot.data!
                .where((group) => query.isEmpty || group.name.toLowerCase().contains(query) || group.description.toLowerCase().contains(query))
                .map(_ThreadItem.group),
          ]..sort((a, b) {
              if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
              return b.updatedAt.compareTo(a.updatedAt);
            });
          if (items.isEmpty) return const _EmptyState(icon: Icons.forum_outlined, text: 'Start your first conversation');
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 12, color: Color(0xFFE8E3EC)),
            itemBuilder: (_, index) {
              final item = items[index];
              if (item.group != null) return _GroupThreadTile(group: item.group!);
              final data = item.conversation!.data();
              final ids = List<String>.from(data['memberIds'] as List);
              final otherId = ids.firstWhere((id) => id != chatService.myId);
              return FutureBuilder<ChatUser?>(
                future: chatService.user(otherId),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) return const SizedBox(height: 70);
                  if (query.isNotEmpty && !user.name.toLowerCase().contains(query)) return const SizedBox.shrink();
                  final unread = data['unreadFor'] == chatService.myId ? (data['unreadCount'] as num? ?? 0).toInt() : 0;
                  return _ThreadTile(
                    avatar: _UserAvatar(user: user),
                    title: user.name,
                    subtitle: data['lastMessage'] as String? ?? '',
                    time: _time((data['updatedAt'] as Timestamp?)?.toDate()),
                    unread: unread,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RealChatRoomPage(user: user))),
                  );
                },
              );
            },
          );
          },
        ),
      ),
    );
  }
}

class _GroupThreadTile extends StatelessWidget {
  const _GroupThreadTile({required this.group});
  final ChatGroup group;
  @override
  Widget build(BuildContext context) => _ThreadTile(
        avatar: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE5DAF5),
          backgroundImage: group.photoUrl == null ? null : NetworkImage(group.photoUrl!),
          child: group.photoUrl == null ? Text(group.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF65439B), fontWeight: FontWeight.w800)) : null,
        ),
        title: group.name,
        subtitle: group.lastMessage.isEmpty ? '${group.memberCount} members' : group.lastMessage,
        time: _time(group.updatedAt),
        unread: group.unreadCount,
        group: true,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatRoomPage(group: group))),
      );
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.avatar, required this.title, required this.subtitle, required this.time, required this.unread, required this.onTap, this.group = false});
  final Widget avatar;
  final String title;
  final String subtitle;
  final String time;
  final int unread;
  final bool group;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        leading: avatar,
        title: Row(children: [
          if (group) ...[const Icon(Icons.groups_rounded, size: 14, color: Color(0xFF805BB3)), const SizedBox(width: 5)],
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF756E7C))),
          if (unread > 0)
            Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF805BB3), borderRadius: BorderRadius.circular(20)),
              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ]),
        onTap: onTap,
      );
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});
  final ChatUser user;
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE5DAF5),
          backgroundImage: user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
          child: user.photoUrl == null ? Text(user.name[0].toUpperCase()) : null,
        ),
        if (user.isOnline)
          Positioned(right: 0, bottom: 1, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF24C77A), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
      ]);
}

class _ThreadItem {
  const _ThreadItem({
    this.conversation,
    this.group,
    required this.updatedAt,
    this.pinned = false,
  });
  final QueryDocumentSnapshot<Map<String, dynamic>>? conversation;
  final ChatGroup? group;
  final DateTime updatedAt;
  final bool pinned;
  factory _ThreadItem.direct(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String myId,
    Map<String, Map<String, dynamic>> preferences,
  ) {
    final ids = List<String>.from(doc.data()['memberIds'] as List);
    final otherId = ids.firstWhere((id) => id != myId);
    return _ThreadItem(
      conversation: doc,
      updatedAt: (doc.data()['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime(1970),
      pinned: preferences[otherId]?['pinned'] as bool? ?? false,
    );
  }
  factory _ThreadItem.group(ChatGroup group) => _ThreadItem(group: group, updatedAt: group.updatedAt ?? DateTime(1970));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 52, color: const Color(0xFF805BB3)), const SizedBox(height: 12), Text(text, style: const TextStyle(fontWeight: FontWeight.w700))]));
}

String _time(DateTime? value) => value == null ? '' : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
