import 'package:flutter/material.dart';

import '../../data/services/settings_service.dart';
import 'blocked_users_page.dart';

class PrivacySecurityPage extends StatelessWidget {
  PrivacySecurityPage({super.key});

  final SettingsService _service = SettingsService();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F4F9),
        appBar: AppBar(
          title: const Text(
            'Privacy & Security',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: const Color(0xFFF7F4F9),
          surfaceTintColor: Colors.transparent,
        ),
        body: StreamBuilder<Map<String, dynamic>>(
          stream: _service.watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final settings = snapshot.data!;
            bool value(String key, {bool fallback = true}) =>
                settings[key] as bool? ?? fallback;
            final visibility =
                settings['profileVisibility'] as String? ?? 'Contacts';

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                const _SectionTitle('Visibility'),
                _Card(
                  children: [
                    _SwitchRow(
                      icon: Icons.circle,
                      title: 'Online Status',
                      subtitle: 'Let contacts see when you are online',
                      value: value('showOnlineStatus'),
                      onChanged: (next) =>
                          _service.setBool('showOnlineStatus', next),
                    ),
                    const _Divider(),
                    _SwitchRow(
                      icon: Icons.schedule_rounded,
                      title: 'Last Seen',
                      subtitle: 'Show when you were last active',
                      value: value('showLastSeen'),
                      onChanged: (next) =>
                          _service.setBool('showLastSeen', next),
                    ),
                    const _Divider(),
                    _ActionRow(
                      icon: Icons.account_circle_rounded,
                      title: 'Profile Visibility',
                      trailing: visibility,
                      onTap: () => _selectVisibility(context, visibility),
                    ),
                  ],
                ),
                const _SectionTitle('Messages'),
                _Card(
                  children: [
                    _SwitchRow(
                      icon: Icons.done_all_rounded,
                      title: 'Read Receipts',
                      subtitle: 'Show when messages have been read',
                      value: value('readReceipts'),
                      onChanged: (next) =>
                          _service.setBool('readReceipts', next),
                    ),
                    const _Divider(),
                    _SwitchRow(
                      icon: Icons.mark_chat_unread_rounded,
                      title: 'Message Requests',
                      subtitle: 'Allow messages from people outside contacts',
                      value: value('allowMessageRequests'),
                      onChanged: (next) =>
                          _service.setBool('allowMessageRequests', next),
                    ),
                    const _Divider(),
                    _ActionRow(
                      icon: Icons.block_rounded,
                      title: 'Blocked Users',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BlockedUsersPage()),
                      ),
                    ),
                  ],
                ),
                const _SectionTitle('Account Security'),
                _Card(
                  children: [
                    _ActionRow(
                      icon: Icons.lock_reset_rounded,
                      title: 'Change Password',
                      subtitle: 'Receive a secure reset link by email',
                      onTap: () => _sendPasswordReset(context),
                    ),
                    const _Divider(),
                    _ActionRow(
                      icon: Icons.phonelink_lock_rounded,
                      title: 'App Lock',
                      subtitle: 'Protect VonoTalky on this device',
                      onTap: () => _comingSoon(context),
                    ),
                    const _Divider(),
                    _ActionRow(
                      icon: Icons.devices_rounded,
                      title: 'Active Sessions',
                      subtitle: 'Review devices using your account',
                      onTap: () => _comingSoon(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

  Future<void> _selectVisibility(
    BuildContext context,
    String current,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Who can see your profile?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final option in const ['Everyone', 'Contacts', 'Nobody'])
                RadioListTile<String>(
                  value: option,
                  groupValue: current,
                  activeColor: const Color(0xFF9B77CD),
                  title: Text(option),
                  onChanged: (value) => Navigator.pop(sheetContext, value),
                ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      await _service.setValue('profileVisibility', selected);
    }
  }

  Future<void> _sendPasswordReset(BuildContext context) async {
    try {
      await _service.sendPasswordReset();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset sent to ${_service.currentEmail}.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send the reset email.')),
      );
    }
  }

  static void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This security option is coming next.')),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(5, 18, 5, 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF7653A5),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFFB593E4),
        secondary: _IconBox(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: _IconBox(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(color: Color(0xFF817989), fontSize: 12),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 5),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF817989)),
            ],
          ],
        ),
      );
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF0E8FC),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: const Color(0xFF7653A5), size: 21),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: 66,
        endIndent: 14,
        color: Color(0xFFEDE8F0),
      );
}
