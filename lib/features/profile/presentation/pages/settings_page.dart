import 'package:flutter/material.dart';

import '../../../../app/theme/theme_controller.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../presence/data/services/presence_service.dart';
import '../../../chat/presentation/pages/saved_messages_page.dart';
import '../../../chat/presentation/pages/shared_media_directory_page.dart';
import '../../data/services/settings_service.dart';
import 'appearance_page.dart';
import 'privacy_security_page.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final SettingsService _service = SettingsService();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: const Text(
        'Settings',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            const _SectionTitle('Your stuff'),
            _SettingsCard(
              children: [
                _NavigationTile(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'Saved Messages',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SavedMessagesPage()),
                  ),
                ),
                const _Divider(),
                _NavigationTile(
                  icon: Icons.perm_media_outlined,
                  title: 'Shared Media',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SharedMediaDirectoryPage(),
                    ),
                  ),
                ),
                const _Divider(),
                _NavigationTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy & Security',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PrivacySecurityPage()),
                  ),
                ),
              ],
            ),
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
                  onChanged: (next) => _service.setBool('messagePreview', next),
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
                  onChanged: (next) => _service.setBool('readReceipts', next),
                ),
                const _Divider(),
                _SwitchTile(
                  icon: Icons.download_rounded,
                  title: 'Save Photos',
                  subtitle: 'Save received photos to this device',
                  value: value('savePhotos', fallback: false),
                  onChanged: (next) => _service.setBool('savePhotos', next),
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
                ValueListenableBuilder<VonoThemePreferences>(
                  valueListenable: VonoThemeController.instance,
                  builder: (context, preferences, _) => _NavigationTile(
                    icon: Icons.palette_rounded,
                    title: 'Appearance',
                    trailing:
                        '${_themeModeLabel(preferences.mode)} · ${preferences.color.label}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AppearancePage(),
                      ),
                    ),
                  ),
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
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  onTap: () => _comingSoon(context),
                ),
                const _Divider(),
                const _NavigationTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About VonoTalky',
                  trailing: '1.0.0',
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SettingsSignOutTile(),
          ],
        );
      },
    ),
  );

  static String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  static void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This option is coming next.')),
    );
  }
}

class _SettingsSignOutTile extends StatefulWidget {
  const _SettingsSignOutTile();

  @override
  State<_SettingsSignOutTile> createState() => _SettingsSignOutTileState();
}

class _SettingsSignOutTileState extends State<_SettingsSignOutTile> {
  bool signingOut = false;

  Future<void> _signOut() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sign out of VonoTalky?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'You can sign back in at any time.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => signingOut = true);

    try {
      await PresenceService().setOnline(false);
    } catch (_) {}

    try {
      await AuthService().signOut();
    } finally {
      if (mounted) {
        setState(() => signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .65)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: signingOut ? null : _signOut,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.logout_rounded, color: scheme.primary, size: 21),
        ),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: signingOut
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              )
            : Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
      ),
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
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
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
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .5),
      ),
    ),
    clipBehavior: Clip.antiAlias,
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
    activeTrackColor: Theme.of(context).colorScheme.primary,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        if (onTap != null) ...[
          const SizedBox(width: 5),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    ),
  );
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: primary, size: 21),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 66,
    endIndent: 14,
    color: Theme.of(context).dividerColor,
  );
}
