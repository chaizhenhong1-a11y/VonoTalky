import 'package:flutter/material.dart';

class ProfilePetShowcase extends StatelessWidget {
  const ProfilePetShowcase({
    super.key,
    required this.pets,
    this.onEdit,
    this.compact = false,
  });

  final List<Map<String, dynamic>> pets;
  final VoidCallback? onEdit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (pets.isEmpty && onEdit == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pets',
              style: TextStyle(
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            if (onEdit != null)
              TextButton(onPressed: onEdit, child: const Text('Edit showcase')),
          ],
        ),
        const SizedBox(height: 8),
        if (pets.isEmpty)
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: .05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withValues(alpha: .10)),
              ),
              child: Row(
                children: [
                  _BadgeIcon(primary: primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Choose pets to display on your profile',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: compact ? 112 : 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final pet = pets[index];
                final name = (pet['name'] as String? ?? 'Pet').trim();
                final level = pet['level'] as int? ?? 1;

                return Container(
                  width: compact ? 82 : 92,
                  padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: .055),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: primary.withValues(alpha: .10)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BadgeIcon(primary: primary),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lv.$level',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: .10),
          primary.withValues(alpha: .20),
        ],
      ),
      border: Border.all(color: primary.withValues(alpha: .20)),
    ),
    child: Icon(Icons.pets_rounded, color: primary, size: 20),
  );
}
