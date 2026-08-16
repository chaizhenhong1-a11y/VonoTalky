import 'package:flutter/material.dart';

import '../../data/services/settings_service.dart';

class BlockedUsersPage extends StatelessWidget {
  BlockedUsersPage({super.key});

  final SettingsService _service = SettingsService();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F4F9),
    appBar: AppBar(
      title: const Text(
        'Blocked Users',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: const Color(0xFFF7F4F9),
      surfaceTintColor: Colors.transparent,
    ),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.blockedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? const <Map<String, dynamic>>[];
        if (users.isEmpty) {
          return const _EmptyBlockedUsers();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final user = users[index];
            final uid = user['uid'] as String;
            final name = (user['displayName'] as String?)?.trim();
            final label = name == null || name.isEmpty
                ? 'VonoTalky User'
                : name;
            final photoUrl = user['photoUrl'] as String?;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE9DDF8),
                  backgroundImage: photoUrl == null
                      ? null
                      : NetworkImage(photoUrl),
                  child: photoUrl == null ? Text(label[0].toUpperCase()) : null,
                ),
                title: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: TextButton(
                  onPressed: () => _unblock(context, uid),
                  child: const Text('Unblock'),
                ),
              ),
            );
          },
        );
      },
    ),
  );

  Future<void> _unblock(BuildContext context, String uid) async {
    try {
      await _service.unblockUser(uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User unblocked.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not unblock this user.')),
      );
    }
  }
}

class _EmptyBlockedUsers extends StatelessWidget {
  const _EmptyBlockedUsers();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFF0E8FC),
            child: Icon(
              Icons.person_off_rounded,
              size: 32,
              color: Color(0xFF7653A5),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No blocked users',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'People you block will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF716A77)),
          ),
        ],
      ),
    ),
  );
}
