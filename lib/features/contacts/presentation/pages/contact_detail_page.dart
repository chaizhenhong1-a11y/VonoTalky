import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../data/services/contact_detail_service.dart';

class ContactDetailPage extends StatelessWidget {
  ContactDetailPage({super.key, required this.user, required this.onMessage});

  final ChatUser user;
  final VoidCallback onMessage;
  final ContactDetailService _service = ContactDetailService();

  @override
  Widget build(BuildContext context) => StreamBuilder<ChatUser?>(
    stream: _service.user(user.uid),
    initialData: user,
    builder: (context, userSnapshot) {
      final current = userSnapshot.data ?? user;
      return Scaffold(
        backgroundColor: const Color(0xFFF7F4F9),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(user: current)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MainAction(
                          icon: Icons.chat_bubble_rounded,
                          label: 'Message',
                          onTap: onMessage,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MainAction(
                          icon: Icons.call_rounded,
                          label: 'Voice',
                          onTap: () =>
                              _notice(context, 'Voice calls are coming next.'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MainAction(
                          icon: Icons.videocam_rounded,
                          label: 'Video',
                          onTap: () =>
                              _notice(context, 'Video calls are coming next.'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(user: current),
                  const SizedBox(height: 16),
                  StreamBuilder<Map<String, dynamic>>(
                    stream: _service.preferences(current.uid),
                    builder: (context, snapshot) {
                      final preferences = snapshot.data ?? {};
                      return _Card(
                        children: [
                          SwitchListTile(
                            secondary: const _SmallIcon(Icons.push_pin_rounded),
                            title: const Text('Pin Conversation'),
                            value: preferences['pinned'] as bool? ?? false,
                            activeTrackColor: const Color(0xFFB593E4),
                            onChanged: (value) => _service.setPreference(
                              current.uid,
                              'pinned',
                              value,
                            ),
                          ),
                          const _Divider(),
                          SwitchListTile(
                            secondary: const _SmallIcon(
                              Icons.notifications_off_rounded,
                            ),
                            title: const Text('Mute Notifications'),
                            value: preferences['muted'] as bool? ?? false,
                            activeTrackColor: const Color(0xFFB593E4),
                            onChanged: (value) => _service.setPreference(
                              current.uid,
                              'muted',
                              value,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    children: [
                      _DangerTile(
                        icon: Icons.person_remove_rounded,
                        title: 'Remove Contact',
                        onTap: () => _remove(context, current),
                      ),
                      const _Divider(),
                      _DangerTile(
                        icon: Icons.block_rounded,
                        title: 'Block User',
                        onTap: () => _block(context, current),
                      ),
                      const _Divider(),
                      _DangerTile(
                        icon: Icons.flag_rounded,
                        title: 'Report User',
                        onTap: () => _report(context, current),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _remove(BuildContext context, ChatUser current) async {
    final confirmed = await _confirm(
      context,
      title: 'Remove ${current.name}?',
      message: 'This contact will disappear from your contacts list.',
      action: 'Remove',
    );
    if (!confirmed) return;
    try {
      await _service.removeContact(current.uid);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) _notice(context, 'Could not remove this contact.');
    }
  }

  Future<void> _block(BuildContext context, ChatUser current) async {
    final confirmed = await _confirm(
      context,
      title: 'Block ${current.name}?',
      message: 'They will be removed from contacts and added to Blocked Users.',
      action: 'Block',
    );
    if (!confirmed) return;
    try {
      await _service.block(current);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) _notice(context, 'Could not block this user.');
    }
  }

  Future<void> _report(BuildContext context, ChatUser current) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Report user',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final item in const [
                'Spam',
                'Harassment',
                'Fake account',
                'Inappropriate content',
              ])
                ListTile(
                  title: Text(item),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, item),
                ),
            ],
          ),
        ),
      ),
    );
    if (reason == null) return;
    try {
      await _service.report(current, reason);
      if (context.mounted) _notice(context, 'Report submitted. Thank you.');
    } catch (_) {
      if (context.mounted) _notice(context, 'Could not submit the report.');
    }
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB14E68),
              ),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  static void _notice(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final ChatUser user;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      12,
      MediaQuery.paddingOf(context).top + 4,
      12,
      24,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF7DCEA), Color(0xFFDCCCF2)],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        Stack(
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: Colors.white,
              backgroundImage: user.photoUrl == null
                  ? null
                  : NetworkImage(user.photoUrl!),
              child: user.photoUrl == null
                  ? Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 34),
                    )
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                right: 3,
                bottom: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25C77A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          user.isOnline ? 'Online' : 'Offline',
          style: const TextStyle(color: Color(0xFF615968)),
        ),
        if (user.bio.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(user.bio, textAlign: TextAlign.center),
        ],
      ],
    ),
  );
}

class _MainAction extends StatelessWidget {
  const _MainAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7653A5)),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});
  final ChatUser user;

  @override
  Widget build(BuildContext context) => _Card(
    children: [
      _InfoTile(icon: Icons.email_rounded, text: user.email),
      if (user.phone.trim().isNotEmpty) ...[
        const _Divider(),
        _InfoTile(icon: Icons.phone_rounded, text: user.phone),
      ],
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(children: children),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) =>
      ListTile(leading: _SmallIcon(icon), title: Text(text));
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon, color: const Color(0xFFB14E68)),
    title: Text(
      title,
      style: const TextStyle(
        color: Color(0xFFB14E68),
        fontWeight: FontWeight.w700,
      ),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: const Color(0xFFF0E8FC),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(icon, color: const Color(0xFF7653A5), size: 20),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 66, color: Color(0xFFEDE8F0));
}
