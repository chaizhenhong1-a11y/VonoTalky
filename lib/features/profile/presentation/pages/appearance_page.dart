import 'package:flutter/material.dart';

import '../../../../app/theme/theme_controller.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<VonoThemePreferences>(
    valueListenable: VonoThemeController.instance,
    builder: (context, preferences, _) {
      final colors = Theme.of(context).colorScheme;
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _Label('THEME MODE'),
            const SizedBox(height: 8),
            _ModeSelector(current: preferences.mode),
            const SizedBox(height: 28),
            const _Label('THEME COLOR'),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: VonoThemeColor.values
                  .map(
                    (theme) => _ColorChoice(
                      theme: theme,
                      selected: preferences.color == theme,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: .55),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'This is how VonoTalky looks with ${preferences.color.label} and ${_modeLabel(preferences.mode)} mode.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.forum_rounded),
                          label: Text('${preferences.color.label} VonoTalky'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your choice is saved automatically and applies to Login, Register, Chats, Contacts, Pet, Profile and the bottom navigation.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    },
  );

  static String _modeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 11,
      letterSpacing: .7,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.current});
  final ThemeMode current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          _ModeItem(
            icon: Icons.phone_android_rounded,
            label: 'System',
            selected: current == ThemeMode.system,
            onTap: () => VonoThemeController.instance.setMode(ThemeMode.system),
          ),
          _ModeItem(
            icon: Icons.light_mode_rounded,
            label: 'Light',
            selected: current == ThemeMode.light,
            onTap: () => VonoThemeController.instance.setMode(ThemeMode.light),
          ),
          _ModeItem(
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            selected: current == ThemeMode.dark,
            onTap: () => VonoThemeController.instance.setMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: .16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? colors.primary : colors.onSurface,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({required this.theme, required this.selected});
  final VonoThemeColor theme;
  final bool selected;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => VonoThemeController.instance.setColor(theme),
    borderRadius: BorderRadius.circular(30),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? theme.seed : Colors.transparent,
                width: 2,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.seed,
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            theme.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? theme.seed
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
