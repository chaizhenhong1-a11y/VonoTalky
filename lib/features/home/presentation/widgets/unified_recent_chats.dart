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
import '../pages/archived_chats_page.dart';

class UnifiedRecentChats extends StatelessWidget {
  const UnifiedRecentChats({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final groupService = GroupService();
    final groupRecentChatService = GroupRecentChatService();
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
              return const _EmptyState(
                icon: Icons.cloud_off_rounded,
                text: 'Unable to load conversations',
              );
            }

            if (!chatSnapshot.hasData || !groupSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final preferences = preferenceSnapshot.data ?? const {};

            final items = <_ThreadItem>[
              ...chatSnapshot.data!
                  .map(
                    (document) => _ThreadItem.direct(
                      document,
                      chatService.myId,
                      preferences,
                    ),
                  )
                  .where((item) => !item.archived),
              ...groupSnapshot.data!
                  .where(
                    (group) =>
                        query.isEmpty ||
                        group.name.toLowerCase().contains(query) ||
                        group.description.toLowerCase().contains(query),
                  )
                  .map((group) => _ThreadItem.group(group, preferences))
                  .where((item) => !item.archived),
            ]..sort((a, b) {
                if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
                return b.updatedAt.compareTo(a.updatedAt);
              });

            if (items.isEmpty) {
              return const _EmptyState(
                icon: Icons.forum_outlined,
                text: 'Start your first conversation',
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: Material(
                    color: const Color(0xFFF0E9F8),
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: const Icon(
                        Icons.archive_outlined,
                        color: Color(0xFF805BB3),
                      ),
                      title: const Text(
                        'Archived Chats',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ArchivedChatsPage(),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 12,
                      color: Color(0xFFE8E3EC),
                    ),
                    itemBuilder: (_, index) {
                final item = items[index];

                if (item.group != null) {
                  final group = item.group!;
                  final groupPreference =
                      preferences['group_${group.id}'] ??
                          const <String, dynamic>{};
                  final groupDraft =
                      groupPreference['draft'] as String? ?? '';

                  return _SwipeActions(
                    key: ValueKey('group_${group.id}'),
                    archiveLabel: 'Archive group',
                    readLabel: group.unreadCount > 0
                        ? 'Mark read'
                        : 'Mark unread',
                    onArchive: () async {
                      await groupRecentChatService.setArchived(group.id, true);
                      if (context.mounted) {
                        _showActionMessage(context, 'Group archived');
                      }
                    },
                    onReadToggle: () async {
                      if (group.unreadCount > 0) {
                        await groupService.markRead(group.id);
                        if (context.mounted) {
                          _showActionMessage(context, 'Group marked as read');
                        }
                      } else {
                        await groupRecentChatService.markUnread(group.id);
                        if (context.mounted) {
                          _showActionMessage(context, 'Group marked as unread');
                        }
                      }
                    },
                    child: _GroupThreadTile(
                      group: group,
                      pinned: item.pinned,
                      draft: groupDraft,
                      onLongPress: () => _showGroupChatActions(
                        context: context,
                        group: group,
                        pinned: item.pinned,
                        groupService: groupService,
                        groupRecentChatService: groupRecentChatService,
                      ),
                    ),
                  );
                }

                final data = item.conversation!.data();
                final ids = List<String>.from(data['memberIds'] as List);
                final otherId =
                    ids.firstWhere((id) => id != chatService.myId);

                return FutureBuilder<ChatUser?>(
                  future: chatService.user(otherId),
                  builder: (context, snapshot) {
                    final user = snapshot.data;

                    if (user == null) {
                      return const SizedBox(height: 70);
                    }

                    if (query.isNotEmpty &&
                        !user.name.toLowerCase().contains(query)) {
                      return const SizedBox.shrink();
                    }

                    final unread = data['unreadFor'] == chatService.myId
                        ? (data['unreadCount'] as num? ?? 0).toInt()
                        : 0;
                    final draft =
                        preferences[otherId]?['draft'] as String? ?? '';

                    return _SwipeActions(
                      key: ValueKey('direct_$otherId'),
                      archiveLabel: 'Archive chat',
                      readLabel: unread > 0 ? 'Mark read' : 'Mark unread',
                      onArchive: () async {
                        await detailService.setPreference(
                          otherId,
                          'archived',
                          true,
                        );
                        if (context.mounted) {
                          _showActionMessage(context, 'Chat archived');
                        }
                      },
                      onReadToggle: () async {
                        if (unread > 0) {
                          await chatService.markRead(otherId);
                          if (context.mounted) {
                            _showActionMessage(context, 'Marked as read');
                          }
                        } else {
                          await chatService.markUnread(otherId);
                          if (context.mounted) {
                            _showActionMessage(context, 'Marked as unread');
                          }
                        }
                      },
                      child: _ThreadTile(
                        avatar: _UserAvatar(user: user),
                        title: user.name,
                        subtitle: draft.trim().isNotEmpty
                            ? draft
                            : data['lastMessage'] as String? ?? '',
                        draft: draft.trim().isNotEmpty,
                        time: _time(
                          (data['updatedAt'] as Timestamp?)?.toDate(),
                        ),
                        unread: unread,
                        pinned: item.pinned,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RealChatRoomPage(user: user),
                          ),
                        ),
                        onLongPress: () => _showDirectChatActions(
                          context: context,
                          user: user,
                          otherId: otherId,
                          pinned: item.pinned,
                          unread: unread,
                          chatService: chatService,
                          detailService: detailService,
                        ),
                      ),
                    );
                  },
                );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showDirectChatActions({
    required BuildContext context,
    required ChatUser user,
    required String otherId,
    required bool pinned,
    required int unread,
    required ChatService chatService,
    required ContactDetailService detailService,
  }) async {
    final action = await showModalBottomSheet<_DirectChatAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24,
                offset: Offset(0, 10),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D3DE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                ListTile(
                  leading: _UserAvatar(user: user),
                  title: Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Conversation options'),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: pinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                  title: pinned ? 'Unpin chat' : 'Pin chat',
                  subtitle: pinned
                      ? 'Return this chat to normal ordering'
                      : 'Keep this chat at the top of Recent Chats',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _DirectChatAction.togglePin,
                  ),
                ),
                _ActionTile(
                  icon: unread > 0
                      ? Icons.mark_chat_read_rounded
                      : Icons.mark_chat_unread_rounded,
                  title: unread > 0 ? 'Mark as read' : 'Mark as unread',
                  subtitle: unread > 0
                      ? 'Clear the unread badge for this conversation'
                      : 'Add an unread reminder to this conversation',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    unread > 0
                        ? _DirectChatAction.markRead
                        : _DirectChatAction.markUnread,
                  ),
                ),
                _ActionTile(
                  icon: Icons.archive_outlined,
                  title: 'Archive chat',
                  subtitle: 'Hide this conversation from Recent Chats',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _DirectChatAction.archive,
                  ),
                ),
                _ActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Open chat',
                  subtitle: 'Go to the conversation',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _DirectChatAction.open,
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (action == null || !context.mounted) return;

    try {
      switch (action) {
        case _DirectChatAction.togglePin:
          await detailService.setPreference(otherId, 'pinned', !pinned);
          if (context.mounted) {
            _showActionMessage(
              context,
              pinned ? 'Chat unpinned' : 'Chat pinned to the top',
            );
          }
          break;

        case _DirectChatAction.markRead:
          await chatService.markRead(otherId);
          if (context.mounted) {
            _showActionMessage(context, 'Marked as read');
          }
          break;

        case _DirectChatAction.markUnread:
          await chatService.markUnread(otherId);
          if (context.mounted) {
            _showActionMessage(context, 'Marked as unread');
          }
          break;

        case _DirectChatAction.archive:
          await detailService.setPreference(otherId, 'archived', true);
          if (context.mounted) {
            _showActionMessage(context, 'Chat archived');
          }
          break;

        case _DirectChatAction.open:
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RealChatRoomPage(user: user),
              ),
            );
          }
          break;
      }
    } catch (_) {
      if (context.mounted) {
        _showActionMessage(
          context,
          'Unable to update this conversation right now',
        );
      }
    }
  }

  Future<void> _showGroupChatActions({
    required BuildContext context,
    required ChatGroup group,
    required bool pinned,
    required GroupService groupService,
    required GroupRecentChatService groupRecentChatService,
  }) async {
    final unread = group.unreadCount;
    final action = await showModalBottomSheet<_GroupChatAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24,
                offset: Offset(0, 10),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D3DE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                ListTile(
                  leading: _GroupAvatar(group: group),
                  title: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${group.memberCount} members · Group options'),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: pinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                  title: pinned ? 'Unpin group' : 'Pin group',
                  subtitle: pinned
                      ? 'Return this group to normal ordering'
                      : 'Keep this group at the top of Recent Chats',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _GroupChatAction.togglePin,
                  ),
                ),
                _ActionTile(
                  icon: unread > 0
                      ? Icons.mark_chat_read_rounded
                      : Icons.mark_chat_unread_rounded,
                  title: unread > 0 ? 'Mark as read' : 'Mark as unread',
                  subtitle: unread > 0
                      ? 'Clear the unread badge for this group'
                      : 'Add an unread reminder to this group',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    unread > 0
                        ? _GroupChatAction.markRead
                        : _GroupChatAction.markUnread,
                  ),
                ),
                _ActionTile(
                  icon: Icons.archive_outlined,
                  title: 'Archive group',
                  subtitle: 'Hide this group from Recent Chats',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _GroupChatAction.archive,
                  ),
                ),
                _ActionTile(
                  icon: Icons.groups_rounded,
                  title: 'Open group',
                  subtitle: 'Go to the group conversation',
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _GroupChatAction.open,
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (action == null || !context.mounted) return;

    try {
      switch (action) {
        case _GroupChatAction.togglePin:
          await groupRecentChatService.setPinned(group.id, !pinned);
          if (context.mounted) {
            _showActionMessage(
              context,
              pinned ? 'Group unpinned' : 'Group pinned to the top',
            );
          }
          break;

        case _GroupChatAction.markRead:
          await groupService.markRead(group.id);
          if (context.mounted) {
            _showActionMessage(context, 'Group marked as read');
          }
          break;

        case _GroupChatAction.markUnread:
          await groupRecentChatService.markUnread(group.id);
          if (context.mounted) {
            _showActionMessage(context, 'Group marked as unread');
          }
          break;

        case _GroupChatAction.archive:
          await groupRecentChatService.setArchived(group.id, true);
          if (context.mounted) {
            _showActionMessage(context, 'Group archived');
          }
          break;

        case _GroupChatAction.open:
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupChatRoomPage(group: group),
              ),
            );
          }
          break;
      }
    } catch (_) {
      if (context.mounted) {
        _showActionMessage(
          context,
          'Unable to update this group right now',
        );
      }
    }
  }

  void _showActionMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

enum _DirectChatAction {
  togglePin,
  markRead,
  markUnread,
  archive,
  open,
}

enum _GroupChatAction {
  togglePin,
  markRead,
  markUnread,
  archive,
  open,
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E9F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF6E489E)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
      );
}


class _SwipeActions extends StatelessWidget {
  const _SwipeActions({
    super.key,
    required this.child,
    required this.onArchive,
    required this.onReadToggle,
    required this.archiveLabel,
    required this.readLabel,
  });

  final Widget child;
  final Future<void> Function() onArchive;
  final Future<void> Function() onReadToggle;
  final String archiveLabel;
  final String readLabel;

  @override
  Widget build(BuildContext context) => Dismissible(
        key: key!,
        direction: DismissDirection.horizontal,
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.32,
          DismissDirection.endToStart: 0.32,
        },
        background: _SwipeBackground(
          alignment: Alignment.centerLeft,
          icon: Icons.mark_chat_read_rounded,
          label: readLabel,
        ),
        secondaryBackground: _SwipeBackground(
          alignment: Alignment.centerRight,
          icon: Icons.archive_rounded,
          label: archiveLabel,
        ),
        confirmDismiss: (direction) async {
          try {
            if (direction == DismissDirection.startToEnd) {
              await onReadToggle();
            } else if (direction == DismissDirection.endToStart) {
              await onArchive();
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Unable to update this conversation'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          }

          // The Firestore stream removes/rebuilds the tile when needed.
          // Returning false prevents Dismissible from deleting the widget
          // before the real data source confirms the change.
          return false;
        },
        child: child,
      );
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final left = alignment == Alignment.centerLeft;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      decoration: BoxDecoration(
        color: const Color(0xFFE8DDF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: left
            ? [
                Icon(icon, color: const Color(0xFF6E489E)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF5F3792),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF5F3792),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: const Color(0xFF6E489E)),
              ],
      ),
    );
  }
}

class _GroupThreadTile extends StatelessWidget {
  const _GroupThreadTile({
    required this.group,
    required this.pinned,
    required this.draft,
    required this.onLongPress,
  });

  final ChatGroup group;
  final bool pinned;
  final String draft;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => _ThreadTile(
        avatar: _GroupAvatar(group: group),
        title: group.name,
        subtitle: draft.trim().isNotEmpty
            ? draft
            : group.lastMessage.isEmpty
                ? '${group.memberCount} members'
                : group.lastMessage,
        time: _time(group.updatedAt),
        unread: group.unreadCount,
        group: true,
        pinned: pinned,
        draft: draft.trim().isNotEmpty,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatRoomPage(group: group),
          ),
        ),
        onLongPress: onLongPress,
      );
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group});

  final ChatGroup group;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 25,
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
      );
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.onTap,
    this.onLongPress,
    this.group = false,
    this.pinned = false,
    this.draft = false,
  });

  final Widget avatar;
  final String title;
  final String subtitle;
  final String time;
  final int unread;
  final bool group;
  final bool pinned;
  final bool draft;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Material(
        color: pinned ? const Color(0xFFF6F0FB) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          leading: avatar,
          title: Row(
            children: [
              if (group) ...[
                const Icon(
                  Icons.groups_rounded,
                  size: 14,
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
              if (pinned) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.push_pin_rounded,
                  size: 15,
                  color: Color(0xFF805BB3),
                ),
              ],
            ],
          ),
          subtitle: draft
              ? Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Draft: ',
                        style: TextStyle(
                          color: Color(0xFF805BB3),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: subtitle.replaceAll('\n', ' '),
                        style: const TextStyle(
                          color: Color(0xFF805BB3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF756E7C),
                ),
              ),
              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF805BB3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      );
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) =>
      Stack(clipBehavior: Clip.none, children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE5DAF5),
          backgroundImage:
              user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
          child:
              user.photoUrl == null ? Text(user.name[0].toUpperCase()) : null,
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
      ]);
}

class _ThreadItem {
  const _ThreadItem({
    this.conversation,
    this.group,
    required this.updatedAt,
    this.pinned = false,
    this.archived = false,
    this.draft = '',
  });

  final QueryDocumentSnapshot<Map<String, dynamic>>? conversation;
  final ChatGroup? group;
  final DateTime updatedAt;
  final bool pinned;
  final bool archived;
  final String draft;

  factory _ThreadItem.direct(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String myId,
    Map<String, Map<String, dynamic>> preferences,
  ) {
    final ids = List<String>.from(doc.data()['memberIds'] as List);
    final otherId = ids.firstWhere((id) => id != myId);

    final preference = preferences[otherId] ?? const <String, dynamic>{};
    final draft = preference['draft'] as String? ?? '';
    final conversationUpdatedAt =
        (doc.data()['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
    final draftUpdatedAt =
        (preference['draftUpdatedAt'] as Timestamp?)?.toDate();

    return _ThreadItem(
      conversation: doc,
      updatedAt: draft.trim().isNotEmpty &&
              draftUpdatedAt != null &&
              draftUpdatedAt.isAfter(conversationUpdatedAt)
          ? draftUpdatedAt
          : conversationUpdatedAt,
      pinned: preference['pinned'] as bool? ?? false,
      archived: preference['archived'] as bool? ?? false,
      draft: draft,
    );
  }

  factory _ThreadItem.group(
    ChatGroup group,
    Map<String, Map<String, dynamic>> preferences,
  ) {
    final preference =
        preferences['group_${group.id}'] ?? const <String, dynamic>{};
    final draft = preference['draft'] as String? ?? '';
    final conversationUpdatedAt = group.updatedAt ?? DateTime(1970);
    final draftUpdatedAt =
        (preference['draftUpdatedAt'] as Timestamp?)?.toDate();

    return _ThreadItem(
      group: group,
      updatedAt: draft.trim().isNotEmpty &&
              draftUpdatedAt != null &&
              draftUpdatedAt.isAfter(conversationUpdatedAt)
          ? draftUpdatedAt
          : conversationUpdatedAt,
      pinned: preference['pinned'] as bool? ?? false,
      archived: preference['archived'] as bool? ?? false,
      draft: draft,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: const Color(0xFF805BB3),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

String _time(DateTime? value) => value == null
    ? ''
    : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
