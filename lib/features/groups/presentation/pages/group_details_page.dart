import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../data/models/chat_group.dart';
import '../../data/services/group_service.dart';

class GroupDetailsPage extends StatefulWidget {
  const GroupDetailsPage({super.key, required this.groupId});
  final String groupId;
  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  final service = GroupService();
  bool uploading = false;

  @override
  Widget build(BuildContext context) => StreamBuilder<ChatGroup?>(
    stream: service.group(widget.groupId),
    builder: (context, snapshot) {
      final group = snapshot.data;
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (group == null) {
        return const Scaffold(
          body: Center(child: Text('This group no longer exists')),
        );
      }
      final owner = group.ownerId == service.myId;
      final admin = group.adminIds.contains(service.myId);
      return Scaffold(
        backgroundColor: const Color(0xFFF9F7FC),
        appBar: AppBar(
          title: const Text('Group Info'),
          backgroundColor: const Color(0xFFEBDDF5),
          surfaceTintColor: Colors.transparent,
          actions: [
            if (owner || admin)
              IconButton(
                onPressed: () => _editDetails(group),
                icon: const Icon(Icons.edit_rounded),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFFE5DAF5),
                    backgroundImage: group.photoUrl == null
                        ? null
                        : NetworkImage(group.photoUrl!),
                    child: group.photoUrl == null
                        ? Text(
                            group.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 34,
                              color: Color(0xFF65439B),
                            ),
                          )
                        : null,
                  ),
                  if (owner || admin)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        onPressed: uploading
                            ? null
                            : () => _uploadAvatar(group.id),
                        icon: uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded, size: 18),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              group.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                group.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF756E7C)),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${group.memberCount} Members',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (owner || admin)
                  TextButton.icon(
                    onPressed: () => _addMembers(group),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add'),
                  ),
              ],
            ),
            FutureBuilder<List<ChatUser>>(
              future: service.memberUsers(group.memberIds),
              builder: (context, memberSnapshot) {
                if (!memberSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: memberSnapshot.data!
                      .map(
                        (user) => _MemberTile(
                          user: user,
                          owner: user.uid == group.ownerId,
                          admin: group.adminIds.contains(user.uid),
                          canManage: owner || admin,
                          currentUserIsOwner: owner,
                          onAction: () => _memberActions(group, user),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            if (!owner)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _leave(group),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Leave Group'),
              ),
            if (owner)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _delete(group),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete Group'),
              ),
          ],
        ),
      );
    },
  );

  Future<void> _uploadAvatar(String groupId) async {
    setState(() => uploading = true);
    try {
      await service.pickAndUploadAvatar(groupId);
    } catch (e) {
      if (mounted) _notice('Avatar upload failed: $e');
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _editDetails(ChatGroup group) async {
    final name = TextEditingController(text: group.name);
    final description = TextEditingController(text: group.description);
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            TextField(
              controller: description,
              maxLength: 120,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save == true && name.text.trim().length >= 2) {
      await service.updateDetails(group.id, name.text, description.text);
    }
    name.dispose();
    description.dispose();
  }

  Future<void> _addMembers(ChatGroup group) async {
    final users = await ChatService().users().first;
    if (!mounted) return;
    final available = users
        .where((user) => !group.memberIds.contains(user.uid))
        .toList();
    final selected = <String>{};
    final add = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Add Members',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: available
                        .map(
                          (user) => CheckboxListTile(
                            value: selected.contains(user.uid),
                            onChanged: (_) => setSheetState(
                              () => selected.contains(user.uid)
                                  ? selected.remove(user.uid)
                                  : selected.add(user.uid),
                            ),
                            secondary: CircleAvatar(
                              backgroundImage: user.photoUrl == null
                                  ? null
                                  : NetworkImage(user.photoUrl!),
                              child: user.photoUrl == null
                                  ? Text(user.name[0])
                                  : null,
                            ),
                            title: Text(user.name),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(sheetContext, true),
                    child: Text('Add ${selected.length} Members'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (add == true) await service.addMembers(group.id, selected);
  }

  Future<void> _memberActions(ChatGroup group, ChatUser user) async {
    if (user.uid == group.ownerId || user.uid == service.myId) return;
    final owner = group.ownerId == service.myId;
    final isAdmin = group.adminIds.contains(user.uid);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            if (owner)
              ListTile(
                leading: Icon(
                  isAdmin
                      ? Icons.remove_moderator_rounded
                      : Icons.admin_panel_settings_rounded,
                ),
                title: Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await service.setAdmin(group.id, user.uid, !isAdmin);
                },
              ),
            if (owner)
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('Transfer Ownership'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (await _confirm('Transfer ownership to ${user.name}?')) {
                    await service.transferOwnership(group.id, user.uid);
                  }
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.person_remove_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Remove Member',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (await _confirm('Remove ${user.name} from this group?')) {
                  await service.removeMember(group.id, user.uid);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leave(ChatGroup group) async {
    if (await _confirm('Leave ${group.name}?')) {
      await service.leaveGroup(group.id);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  Future<void> _delete(ChatGroup group) async {
    if (await _confirm('Permanently delete ${group.name}?')) {
      await service.deleteGroup(group.id);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  Future<bool> _confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm'),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.user,
    required this.owner,
    required this.admin,
    required this.canManage,
    required this.currentUserIsOwner,
    required this.onAction,
  });
  final ChatUser user;
  final bool owner;
  final bool admin;
  final bool canManage;
  final bool currentUserIsOwner;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      backgroundImage: user.photoUrl == null
          ? null
          : NetworkImage(user.photoUrl!),
      child: user.photoUrl == null ? Text(user.name[0].toUpperCase()) : null,
    ),
    title: Text(user.name),
    subtitle: Text(
      owner
          ? 'Owner'
          : admin
          ? 'Admin'
          : user.isOnline
          ? 'Online'
          : 'Member',
    ),
    trailing: canManage && !owner && user.uid != GroupService().myId
        ? IconButton(
            onPressed: onAction,
            icon: const Icon(Icons.more_vert_rounded),
          )
        : null,
  );
}
