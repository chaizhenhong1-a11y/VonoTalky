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
            title: const Text(
              'Profile',
              style: TextStyle(fontWeight: FontWeight.w800),
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
                          _ProfileHeader(
                            name: name,
                            username: username,
                            bio: bio,
                            photoUrl: photoUrl,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditProfilePage(data: data),
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(42),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: .10),
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showQrCode(context, service.uid, name),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(42),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'QR Code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({
    required this.name,
    required this.username,
    required this.bio,
    required this.photoUrl,
  });

  final String name;
  final String username;
  final String bio;
  final String? photoUrl;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bio = widget.bio.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 43,
              backgroundColor: primary.withValues(alpha: .10),
              backgroundImage: widget.photoUrl == null
                  ? null
                  : NetworkImage(widget.photoUrl!),
              child: widget.photoUrl == null
                  ? Text(
                      widget.name.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    )
                  : null,
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (widget.username.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${widget.username}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (bio.length > 90)
            InkWell(
              onTap: () => setState(() => expanded = !expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  expanded ? 'Less' : 'More',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
  );
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .55),
      ),
    ),
    child: Column(children: children),
  );
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
