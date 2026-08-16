import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../../contacts/data/services/contact_service.dart';
import '../../data/services/group_service.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});
  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final groupService = GroupService();
  final contactService = ContactService();
  final selectedIds = <String>{};
  String query = '';
  bool creating = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF9F7FC),
    appBar: AppBar(
      title: const Text('Create Group'),
      backgroundColor: const Color(0xFFEBDDF5),
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  maxLength: 120,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) =>
                      setState(() => query = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search members',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select members',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${selectedIds.length} selected'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatUser>>(
              stream: contactService.contacts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users =
                    snapshot.data!
                        .where(
                          (user) =>
                              query.isEmpty ||
                              user.name.toLowerCase().contains(query) ||
                              user.email.toLowerCase().contains(query),
                        )
                        .toList()
                      ..sort((a, b) => a.name.compareTo(b.name));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: users.length,
                  itemBuilder: (_, index) {
                    final user = users[index];
                    final selected = selectedIds.contains(user.uid);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (_) => setState(
                        () => selected
                            ? selectedIds.remove(user.uid)
                            : selectedIds.add(user.uid),
                      ),
                      secondary: CircleAvatar(
                        backgroundImage: user.photoUrl == null
                            ? null
                            : NetworkImage(user.photoUrl!),
                        child: user.photoUrl == null
                            ? Text(user.name[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      heroTag: null,
      onPressed: creating ? null : _create,
      backgroundColor: const Color(0xFF805BB3),
      foregroundColor: Colors.white,
      icon: creating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_rounded),
      label: Text(creating ? 'Creating...' : 'Create Group'),
    ),
  );

  Future<void> _create() async {
    if (nameController.text.trim().length < 2 || selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a group name and select at least one member.'),
        ),
      );
      return;
    }
    setState(() => creating = true);
    try {
      await groupService.createGroup(
        name: nameController.text,
        description: descriptionController.text,
        selectedMemberIds: selectedIds,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create group: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }
}
