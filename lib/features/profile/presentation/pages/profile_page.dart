import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../auth/data/services/auth_service.dart';
import '../../../presence/data/services/presence_service.dart';
import '../../data/services/profile_service.dart';
import 'edit_profile_page.dart';
import 'privacy_security_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key, this.embedded = false});
  final bool embedded;
  final service = ProfileService();

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
        final email = data['email'] as String? ?? '';
        final bio = (data['bio'] as String? ?? '').trim();
        final photo = data['photoUrl'] as String?;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F4F9),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopProfile(
                      name: name,
                      username: data['username'] as String? ?? '',
                      bio: bio.isEmpty
                          ? 'Designing pixels & exploring peaks 🏔️'
                          : bio,
                      photoUrl: photo,
                    ),
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                15,
                                14,
                                15,
                                14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x17000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'User Info',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B1620),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _UserInfo(
                                    phone:
                                        data['phone'] as String? ??
                                        '+1 555-0123',
                                    email: email,
                                    birthDate:
                                        data['birthDate'] as String? ??
                                        'Dec 12, 1993',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Title('Quick Actions'),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.edit_rounded,
                              label: 'Edit Profile',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfilePage(data: data),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.settings_rounded,
                              label: 'Settings',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SettingsPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.shield_rounded,
                              label: 'Privacy &\nSecurity',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PrivacySecurityPage(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      const _Title('Activity'),
                      _Activity(service: service),
                      const SizedBox(height: 11),
                      _ContactQr(uid: service.uid, name: name),
                      const SizedBox(height: 14),
                      const _SignOutButton(),
                    ],
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
                    if (index == 0) Navigator.pop(context);
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
}

class _TopProfile extends StatelessWidget {
  const _TopProfile({
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF8DCEB), Color(0xFFEEDDF4), Color(0xFFDCCCF2)],
          stops: [0, 0.48, 1],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: double.infinity,
                height: 118,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF65439B), Color(0xFF8C63B8)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: const SafeArea(bottom: false, child: SizedBox.shrink()),
              ),
              Positioned(
                bottom: -48,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: photoUrl == null
                              ? null
                              : NetworkImage(photoUrl!),
                          child: photoUrl == null
                              ? Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 34),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 5,
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C77A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 55),
          Text(
            name,
            style: const TextStyle(
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17131C),
            ),
          ),
          const SizedBox(height: 5),
          if (username.isNotEmpty) ...[
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF65439B),
              ),
            ),
            const SizedBox(height: 3),
          ],
          const Text(
            'Offline | Last seen 5 mins ago',
            style: TextStyle(fontSize: 12, color: Color(0xFF59525F)),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF27202D)),
            ),
          ),
          const SizedBox(height: 55),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1B1620),
      ),
    ),
  );
}

class _UserInfo extends StatelessWidget {
  const _UserInfo({
    required this.phone,
    required this.email,
    required this.birthDate,
  });
  final String phone;
  final String email;
  final String birthDate;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _InfoLine(Icons.phone_rounded, phone),
      const SizedBox(height: 9),
      _InfoLine(Icons.email_rounded, email),
      const SizedBox(height: 9),
      _InfoLine(Icons.cake_rounded, birthDate),
    ],
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF7350A3)),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
    borderRadius: BorderRadius.circular(12),
    elevation: 2,
    shadowColor: const Color(0x22000000),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF7653A5), size: 27),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, height: 1.05),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Activity extends StatelessWidget {
  const _Activity({required this.service});
  final ProfileService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: service.conversationCount(),
    builder: (context, snapshot) => Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(child: _Bars()),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages Sent: ${(snapshot.data ?? 0) * 250}+ ',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Active Chats: ${snapshot.data ?? 0}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 5),
            FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7653A5),
                minimumSize: const Size(132, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('Add Contact', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Bars extends StatelessWidget {
  const _Bars();
  @override
  Widget build(BuildContext context) {
    const heights = [13.0, 23.0, 17.0, 32.0, 20.0, 38.0, 49.0];
    return SizedBox(
      height: 55,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heights
            .map(
              (height) => Expanded(
                child: Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: height > 35
                        ? const Color(0xFF7653A5)
                        : const Color(0xFFC5B2DF),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ContactQr extends StatelessWidget {
  const _ContactQr({required this.uid, required this.name});
  final String uid;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 6)],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Contact QR Code',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B6370)),
              ),
            ],
          ),
        ),
        QrImageView(
          data: 'vonotalky://user/$uid',
          size: 65,
          padding: EdgeInsets.zero,
        ),
      ],
    ),
  );
}

class _SignOutButton extends StatefulWidget {
  const _SignOutButton();

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _isSigningOut = false;

  Future<void> _confirmSignOut() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0E8FC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF7653A5),
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Sign out of VonoTalky?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can sign back in at any time.',
                style: TextStyle(color: Color(0xFF6B6370)),
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
                        backgroundColor: const Color(0xFFB593E4),
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
    setState(() => _isSigningOut = true);

    try {
      await PresenceService().setOnline(false);
    } catch (_) {
      // Signing out must still work when presence cannot be updated.
    }

    try {
      await AuthService().signOut();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _isSigningOut ? null : _confirmSignOut,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      foregroundColor: const Color(0xFF7653A5),
      side: const BorderSide(color: Color(0xFFD6C3EE)),
      backgroundColor: const Color(0xFFF5EFFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    icon: _isSigningOut
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.logout_rounded),
    label: Text(_isSigningOut ? 'Signing out...' : 'Sign Out'),
  );
}
