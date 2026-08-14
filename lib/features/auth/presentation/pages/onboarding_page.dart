import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../profile/data/services/profile_service.dart';
import '../../data/services/onboarding_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.initialData});
  final Map<String, dynamic> initialData;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final formKey = GlobalKey<FormState>();
  final onboarding = OnboardingService();
  final profile = ProfileService();
  late final name = TextEditingController(text: widget.initialData['displayName'] as String? ?? '');
  final username = TextEditingController();
  final bio = TextEditingController();
  String? photoUrl;
  Uint8List? avatarBytes;
  bool contactsSync = false;
  bool pushNotifications = true;
  bool saving = false;
  bool uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    photoUrl = widget.initialData['photoUrl'] as String?;
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (uploadingAvatar) return;
    setState(() => uploadingAvatar = true);
    try {
      final result = await profile.pickAndUploadAvatar();
      if (result != null && mounted) {
        setState(() {
          photoUrl = result.url;
          avatarBytes = result.bytes;
        });
      }
    } catch (_) {
      if (mounted) _notice('Avatar upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  Future<void> _complete() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      await onboarding.complete(
        displayName: name.text,
        username: username.text,
        bio: bio.text,
        contactsSync: contactsSync,
        pushNotifications: pushNotifications,
      );
    } on OnboardingFailure catch (error) {
      if (mounted) _notice(error.message);
    } catch (_) {
      if (mounted) _notice('Profile setup could not be completed.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8F5FA),
        body: SafeArea(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                const _ProgressHeader(),
                const SizedBox(height: 26),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFF2BFD9), Color(0xFF9D79CF)],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: const Color(0xFFE9DDF8),
                          backgroundImage: avatarBytes != null
                              ? MemoryImage(avatarBytes!)
                              : photoUrl == null
                                  ? null
                                  : NetworkImage(photoUrl!),
                          child: photoUrl == null && avatarBytes == null
                              ? const Icon(Icons.person_rounded, size: 50, color: Color(0xFF7653A5))
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 2,
                        child: IconButton.filled(
                          onPressed: uploadingAvatar ? null : _pickAvatar,
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF9D79CF)),
                          icon: uploadingAvatar
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_rounded, size: 19),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                TextFormField(
                  controller: name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Enter at least 2 characters'
                      : null,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: username,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'your_username',
                    prefixText: '@',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                    helperText: 'Unique · 3–20 letters, numbers or underscores',
                  ),
                  validator: (value) => RegExp(r'^[a-zA-Z0-9_]{3,20}$')
                          .hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Choose a valid username',
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: bio,
                  maxLength: 120,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell people a little about you',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                const _SectionLabel('Your preferences'),
                _PreferenceCard(
                  children: [
                    SwitchListTile(
                      value: contactsSync,
                      onChanged: (value) => setState(() => contactsSync = value),
                      activeTrackColor: const Color(0xFFB593E4),
                      secondary: const Icon(Icons.contacts_rounded, color: Color(0xFF7653A5)),
                      title: const Text('Sync Contacts', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Help find people you already know'),
                    ),
                    const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      value: pushNotifications,
                      onChanged: (value) => setState(() => pushNotifications = value),
                      activeTrackColor: const Color(0xFFB593E4),
                      secondary: const Icon(Icons.notifications_rounded, color: Color(0xFF7653A5)),
                      title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Messages and contact requests'),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                const _PermissionNote(),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: saving ? null : _complete,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9D79CF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                    ),
                    child: saving
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Finish Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  void _notice(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();
  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set up your profile', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          SizedBox(height: 5),
          Text('Make VonoTalky feel like yours.', style: TextStyle(color: Color(0xFF716A77))),
          SizedBox(height: 14),
          LinearProgressIndicator(
            value: 1,
            minHeight: 5,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            color: Color(0xFF9D79CF),
            backgroundColor: Color(0xFFE9DDF8),
          ),
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text, style: const TextStyle(color: Color(0xFF7653A5), fontWeight: FontWeight.w800)),
      );
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(children: children),
      );
}

class _PermissionNote extends StatelessWidget {
  const _PermissionNote();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0E8FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.privacy_tip_rounded, color: Color(0xFF7653A5)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Camera and microphone access are requested only when you send photos or record voice messages.',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          ],
        ),
      );
}
