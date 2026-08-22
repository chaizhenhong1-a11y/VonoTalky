import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../../chat/presentation/pages/real_chat_room_page.dart';
import '../../data/services/contact_qr_service.dart';

class ContactQrPreviewPage extends StatefulWidget {
  const ContactQrPreviewPage({super.key, required this.lookup});

  final ContactQrLookup lookup;

  @override
  State<ContactQrPreviewPage> createState() => _ContactQrPreviewPageState();
}

class _ContactQrPreviewPageState extends State<ContactQrPreviewPage> {
  final ContactQrService _service = ContactQrService();

  late ContactQrRelationship _relationship = widget.lookup.relationship;
  bool _sending = false;

  ChatUser get user => widget.lookup.user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelf = user.uid == _service.myId;
    final username = widget.lookup.username.trim();
    final bio = widget.lookup.bio.trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    decoration: BoxDecoration(
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
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: .55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(
                            alpha: isDark ? .18 : .08,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _ProfileIdentity(user: user, username: username),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        colors.primary.withValues(alpha: isDark ? .07 : .045),
                        colors.surfaceContainerHighest,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: .5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.format_quote_rounded,
                                size: 17,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Bio',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          bio.isEmpty ? 'No bio yet.' : bio,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: bio.isEmpty
                                ? (isDark ? Colors.white54 : Colors.black45)
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(height: 52, child: _buildPrimaryAction(isSelf)),
                  if (!isSelf) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                        ),
                        label: const Text('Scan another code'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(bool isSelf) {
    if (isSelf) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.person_rounded),
        label: const Text('This is your profile'),
      );
    }

    switch (_relationship) {
      case ContactQrRelationship.contact:
        return FilledButton.icon(
          onPressed: _openChat,
          icon: const Icon(Icons.chat_bubble_rounded),
          label: const Text('Message'),
        );

      case ContactQrRelationship.available:
        return FilledButton.icon(
          onPressed: _sending ? null : _sendRequest,
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add Friend'),
        );

      case ContactQrRelationship.pending:
        return FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule_rounded),
          label: const Text('Request Pending'),
        );

      case ContactQrRelationship.rejected:
        return FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.info_outline_rounded),
          label: const Text('Request Previously Declined'),
        );
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RealChatRoomPage(user: user)),
    );
  }

  Future<void> _sendRequest() async {
    setState(() => _sending = true);

    try {
      await _service.sendRequest(user.uid);

      if (!mounted) return;
      setState(() {
        _relationship = ContactQrRelationship.pending;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${user.name}')),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      _showMessage(error.message.toString());
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not send friend request.');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.user, required this.username});

  final ChatUser user;
  final String username;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ProfileAvatar(user: user),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              if (username.isNotEmpty) ...[
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoUrl?.trim();

    final colors = Theme.of(context).colorScheme;

    Widget fallbackFace() => CircleAvatar(
      radius: 43,
      backgroundColor: colors.surfaceContainerHighest,
      child: Text(
        user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    Widget framed(Widget child) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );

    if (photoUrl == null || photoUrl.isEmpty) {
      return framed(fallbackFace());
    }

    return framed(
      ClipOval(
        child: Image.network(
          photoUrl,
          width: 86,
          height: 86,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallbackFace(),
        ),
      ),
    );
  }
}
