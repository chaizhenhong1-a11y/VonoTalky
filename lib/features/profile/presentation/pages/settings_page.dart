import 'package:flutter/material.dart';

import '../../data/services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final SettingsService _service = SettingsService();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F4F9),
        appBar: AppBar(
          title: const Text(
            'Settings',
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

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                const _SectionTitle('Notifications'),
                _SettingsCard(
                  children: [
                    _SwitchTile(
                      icon: Icons.notifications_rounded,
                      title: 'Push Notifications',
                      subtitle: 'New messages and contact requests',
                      value: value('pushNotifications'),
                      onChanged: (next) =>
                          _service.setBool('pushNotifications', next),
                    ),
                    const _Divider(),
                    _SwitchTile(
                      icon: Icons.message_rounded,
                      title: 'Message Preview',
                      subtitle: 'Show message text in notifications',
                      value: value('messagePreview'),
                      onChanged: (next) =>
                          _service.setBool('messagePreview', next),
                    ),
                    const _Divider(),
                    _SwitchTile(
                      icon: Icons.volume_up_rounded,
                      title: 'Sounds',
                      subtitle: 'Play a sound for incoming messages',
                      value: value('notificationSounds'),
                      onChanged: (next) =>
                          _service.setBool('notificationSounds', next),
                    ),
                  ],
                ),
                const _SectionTitle('Chat'),
                _SettingsCard(
                  children: [
                    _SwitchTile(
                      icon: Icons.done_all_rounded,
                      title: 'Read Receipts',
                      subtitle: 'Let contacts know when you read messages',
                      value: value('readReceipts'),
                      onChanged: (next) =>
                          _service.setBool('readReceipts', next),
                    ),
                    const _Divider(),
                    _SwitchTile(
                      icon: Icons.download_rounded,
                      title: 'Save Photos',
                      subtitle: 'Save received photos to this device',
                      value: value('savePhotos', fallback: false),
                      onChanged: (next) =>
                          _service.setBool('savePhotos', next),
                    ),
                  ],
                ),
                const _SectionTitle('App'),
                _SettingsCard(
                  children: [
                    _NavigationTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      trailing: 'English',
                      onTap: () => _comingSoon(context),
                    ),
                    const _Divider(),
                    _NavigationTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Appearance',
                      trailing: 'Light',
                      onTap: () => _comingSoon(context),
                    ),
                    const _Divider(),
                    _NavigationTile(
                      icon: Icons.storage_rounded,
                      title: 'Storage and Data',
                      onTap: () => _comingSoon(context),
                    ),
                  ],
                ),
                const _SectionTitle('Support'),
                _SettingsCard(
                  children: [
                    _NavigationTile(
                      icon: Icons.help_rounded,
                      title: 'Help Center',
                      onTap: () => _comingSoon(context),
                    ),
                    const _Divider(),
                    const _NavigationTile(
                      icon: Icons.info_rounded,
                      title: 'About VonoTalky',
                      trailing: '1.0.0',
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

  static void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This option is coming next.')),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
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

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: _IconBox(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
