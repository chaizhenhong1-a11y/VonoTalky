import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/services/profile_service.dart';
import '../../data/services/profile_pet_showcase_service.dart';
import '../widgets/profile_pet_showcase.dart';
import 'edit_profile_page.dart';
import 'pet_showcase_editor_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key, this.embedded = false});

  final bool embedded;
  final ProfileService service = ProfileService();
  final ProfilePetShowcaseService petShowcaseService =
      ProfilePetShowcaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.profile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() ?? <String, dynamic>{};
        final rawName = (data['displayName'] as String? ?? '').trim();
        final name = rawName.isEmpty ? 'VonoTalky User' : rawName;
        final username = (data['username'] as String? ?? '').trim();
        final bio = (data['bio'] as String? ?? '').trim();
        final phone = (data['phone'] as String? ?? '').trim();
        final email = (data['email'] as String? ?? '').trim();
        final birthday = (data['birthDate'] as String? ?? '').trim();
        final photoUrl = data['photoUrl'] as String?;

        final visibility = Map<String, dynamic>.from(
          data['profileVisibility'] as Map? ?? const <String, dynamic>{},
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            centerTitle: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage()),
                ),
                icon: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHero(
                            name: name,
                            username: username,
                            bio: bio,
                            photoUrl: photoUrl,
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfilePage(data: data),
                              ),
                            ),
                            onQr: () => _showQrCode(context, service.uid, name),
                          ),
                          const SizedBox(height: 28),
                          const _SectionLabel('Personal information'),
                          const SizedBox(height: 8),
                          _InfoGroup(
                            children: [
                              _VisibilityInfoRow(
                                label: 'Phone',
                                value: phone.isEmpty ? 'Add phone' : phone,
                                isPublic:
                                    (visibility['phone'] as String?) ==
                                    'public',
                                onVisibilityTap: () => _setVisibility(
                                  context,
                                  key: 'phone',
                                  currentlyPublic:
                                      (visibility['phone'] as String?) ==
                                      'public',
                                ),
                              ),
                              const _SoftDivider(),
                              _VisibilityInfoRow(
                                label: 'Email',
                                value: email.isEmpty ? 'Add email' : email,
                                isPublic:
                                    (visibility['email'] as String?) ==
                                    'public',
                                onVisibilityTap: () => _setVisibility(
                                  context,
                                  key: 'email',
                                  currentlyPublic:
                                      (visibility['email'] as String?) ==
                                      'public',
                                ),
                              ),
                              const _SoftDivider(),
                              _VisibilityInfoRow(
                                label: 'Birthday',
                                value: birthday.isEmpty
                                    ? 'Add birthday'
                                    : birthday,
                                isPublic:
                                    (visibility['birthday'] as String?) ==
                                    'public',
                                onVisibilityTap: () => _setVisibility(
                                  context,
                                  key: 'birthday',
                                  currentlyPublic:
                                      (visibility['birthday'] as String?) ==
                                      'public',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: petShowcaseService.watchUserShowcase(
                              service.uid,
                            ),
                            builder: (context, showcaseSnapshot) {
                              return ProfilePetShowcase(
                                pets:
                                    showcaseSnapshot.data ??
                                    const <Map<String, dynamic>>[],
                                onEdit: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PetShowcaseEditorPage(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: embedded
              ? null
              : NavigationBar(
                  height: 66,
                  selectedIndex: 3,
                  onDestinationSelected: (index) {
                    if (index == 0) {
                      Navigator.pop(context);
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      label: 'Chats',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.badge_outlined),
                      label: 'Contacts',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.groups_outlined),
                      label: 'Groups',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_rounded),
                      label: 'Profile',
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _setVisibility(
    BuildContext context, {
    required String key,
    required bool currentlyPublic,
  }) async {
    final next = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Only me'),
                trailing: !currentlyPublic
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, 'private'),
              ),
              ListTile(
                leading: const Icon(Icons.public_rounded),
                title: const Text('Public'),
                trailing: currentlyPublic
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, 'public'),
              ),
            ],
          ),
        ),
      ),
    );

    if (next == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(service.uid).set(
        {
          'profileVisibility': {key: next},
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update visibility')),
      );
    }
  }

  Future<void> _showQrCode(
    BuildContext context,
    String uid,
    String name,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final availableHeight = media.size.height - media.padding.top;
      final qrSize = (availableHeight * 0.34).clamp(150.0, 210.0).toDouble();

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: availableHeight * 0.82),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 2, 24, 20 + media.padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan to add this VonoTalky profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Theme.of(
                        sheetContext,
                      ).colorScheme.outlineVariant.withValues(alpha: .45),
                    ),
                  ),
                  child: QrImageView(
                    data: 'vonotalky://user/$uid',
                    size: qrSize,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'VonoTalky ID',
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                uid,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ProfileHero extends StatefulWidget {
  const _ProfileHero({
    required this.name,
    required this.username,
    required this.bio,
    required this.photoUrl,
    required this.onEdit,
    required this.onQr,
  });

  final String name;
  final String username;
  final String bio;
  final String? photoUrl;
  final VoidCallback onEdit;
  final VoidCallback onQr;

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bio = widget.bio.trim();
    final photoUrl = widget.photoUrl?.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            colors.primary.withValues(alpha: .18),
            colors.secondary.withValues(alpha: .13),
            colors.primary.withValues(alpha: .10),
          ],
          stops: const [0, 0.5, 1],
        ),
        border: Border.all(color: colors.primary.withValues(alpha: .16)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                  ),
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: colors.surfaceContainerHighest,
                  backgroundImage: photoUrl == null || photoUrl.isEmpty
                      ? null
                      : NetworkImage(photoUrl),
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Text(
                          widget.name.isEmpty
                              ? '?'
                              : widget.name.characters.first.toUpperCase(),
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            color: colors.onSurface,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                        color: colors.onSurface,
                      ),
                    ),
                    if (widget.username.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '@${widget.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              bio,
              maxLines: expanded ? null : 3,
              overflow: expanded ? null : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: colors.onSurface.withValues(alpha: .90),
              ),
            ),
            if (bio.length > 90)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => expanded = !expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5, right: 8, bottom: 3),
                  child: Text(
                    expanded ? 'Less' : 'More',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onEdit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 17),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onQr,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: colors.onSurface,
                    backgroundColor: colors.surface.withValues(alpha: .44),
                    side: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: .70),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text(
                    'QR Code',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w900,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .50)),
      ),
      child: Column(children: children),
    );
  }
}

class _VisibilityInfoRow extends StatelessWidget {
  const _VisibilityInfoRow({
    required this.label,
    required this.value,
    required this.isPublic,
    required this.onVisibilityTap,
  });

  final String label;
  final String value;
  final bool isPublic;
  final VoidCallback onVisibilityTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (label) {
      'Phone' => Icons.call_outlined,
      'Email' => Icons.mail_outline_rounded,
      'Birthday' => Icons.cake_outlined,
      _ => Icons.info_outline_rounded,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isPublic ? 'Public' : 'Only me',
            onPressed: onVisibilityTap,
            icon: Icon(
              isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
              size: 19,
              color: isPublic
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .5),
  );
}
